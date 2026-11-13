using CounselLink.API.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Controllers;

/// <summary>
/// Counselor-only READ endpoints. Cannot be called without a verified portal
/// counselor role; EmployeeID is extracted from a signed token claim, not input.
/// </summary>
[ApiController]
[Route("api/counselor-records")]
[Authorize(Policy = "VerifiedCounselor")]
public sealed class CounselorRecordsController : ControllerBase
{
    private readonly ICounselorScopedRepository _repository;
    private readonly IConfiguration _configuration;
    private readonly ILogger<CounselorRecordsController> _logger;

    public CounselorRecordsController(
        ICounselorScopedRepository repository,
        IConfiguration configuration,
        ILogger<CounselorRecordsController> logger)
    {
        _repository = repository;
        _configuration = configuration;
        _logger = logger;
    }

    private string? VerifiedEmployeeId()
    {
        // Claims are trustworthy ONLY because VerifiedCounselor enforces token
        // validation and the role check in Program.cs.
        var claimName = _configuration["PortalAuth:EmployeeIdClaim"] ?? "employee_id";
        return User.FindFirst(claimName)?.Value?.Trim();
    }

    private async Task<IActionResult> ReadAsync(
        DateTime? schoolYear,
        Func<string, DateTime, Task<IEnumerable<dynamic>>> query)
    {
        if (!schoolYear.HasValue || schoolYear.Value == default)
            return BadRequest(new { error = "schoolYear is required (YYYY-MM-DD)." });

        var employeeId = VerifiedEmployeeId();
        if (string.IsNullOrWhiteSpace(employeeId) || employeeId.Length > 7)
            return Forbid();

        try
        {
            // A signed counselor role without an assignment must not receive records.
            var assignments = await _repository.GetAssignmentsAsync(
                employeeId, schoolYear.Value.Date);
            if (assignments.Count == 0)
                return Forbid();

            return Ok(await query(employeeId, schoolYear.Value.Date));
        }
        catch (SqlException ex)
        {
            _logger.LogError(ex, "Scoped counselor query failed");
            return StatusCode(500, new { error = "The counselor record query failed." });
        }
    }

    /// <summary>GET /api/counselor-records/me/assignments?schoolYear=2026-08-01</summary>
    [HttpGet("me/assignments")]
    public async Task<IActionResult> MyAssignments([FromQuery] DateTime? schoolYear)
        => await ReadAsync(schoolYear, async (id, year) =>
            (await _repository.GetAssignmentsAsync(id, year)).Cast<dynamic>());

    /// <summary>GET /api/counselor-records/appointments?schoolYear=2026-08-01</summary>
    [HttpGet("appointments")]
    public async Task<IActionResult> Appointments(
        [FromQuery] DateTime? schoolYear, [FromQuery] string? searchIDNumber)
        => await ReadAsync(schoolYear, (id, year) =>
            _repository.GetAppointmentsAsync(id, year, searchIDNumber));

    [HttpGet("sessions")]
    public async Task<IActionResult> Sessions([FromQuery] DateTime? schoolYear)
        => await ReadAsync(schoolYear, _repository.GetSessionsAsync);

    [HttpGet("assessments")]
    public async Task<IActionResult> Assessments([FromQuery] DateTime? schoolYear)
        => await ReadAsync(schoolYear, _repository.GetAssessmentsAsync);

    [HttpGet("follow-ups")]
    public async Task<IActionResult> FollowUps([FromQuery] DateTime? schoolYear)
        => await ReadAsync(schoolYear, _repository.GetFollowUpsAsync);

    [HttpGet("masterlist")]
    public async Task<IActionResult> Masterlist([FromQuery] DateTime? schoolYear)
        => await ReadAsync(schoolYear, _repository.GetMasterlistAsync);
}
