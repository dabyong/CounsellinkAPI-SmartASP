using CounselLink.API.Repositories;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Controllers;

/// <summary>
/// TEMPORARY TEST-ONLY counselor record lookup: provide employeeId in the query.
/// Does not require a token or key. Do not use with real student records.
/// </summary>
[ApiController]
[Route("api/counselor-records")]
public sealed class CounselorRecordsController : ControllerBase
{
    private readonly ICounselorScopedRepository _repository;
    private readonly ILogger<CounselorRecordsController> _logger;

    public CounselorRecordsController(
        ICounselorScopedRepository repository,
        ILogger<CounselorRecordsController> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    private async Task<IActionResult> ReadAsync(
        string? employeeId,
        DateTime? schoolYear,
        Func<string, DateTime, Task<IEnumerable<dynamic>>> query)
    {
        if (string.IsNullOrWhiteSpace(employeeId) || employeeId.Trim().Length > 7)
            return BadRequest(new { error = "employeeId is required (e.g., EMP0001)." });
        if (!schoolYear.HasValue || schoolYear.Value == default)
            return BadRequest(new { error = "schoolYear is required (YYYY-MM-DD)." });

        var id = employeeId.Trim().ToUpperInvariant();
        var year = schoolYear.Value.Date;

        try
        {
            // Keep the existing departmental assignment filter.
            var assignments = await _repository.GetAssignmentsAsync(id, year);
            if (assignments.Count == 0)
                return NotFound(new { error = "No counselor assignment exists for that employeeId and schoolYear." });

            return Ok(await query(id, year));
        }
        catch (SqlException ex)
        {
            _logger.LogError(ex, "Counselor record query failed");
            return StatusCode(500, new { error = "The counselor record query failed." });
        }
    }

    [HttpGet("me/assignments")]
    public async Task<IActionResult> MyAssignments([FromQuery] string? employeeId, [FromQuery] DateTime? schoolYear)
        => await ReadAsync(employeeId, schoolYear, async (id, year) =>
            (await _repository.GetAssignmentsAsync(id, year)).Cast<dynamic>());

    [HttpGet("appointments")]
    public async Task<IActionResult> Appointments(
        [FromQuery] string? employeeId, [FromQuery] DateTime? schoolYear,
        [FromQuery] string? searchIDNumber)
        => await ReadAsync(employeeId, schoolYear, (id, year) =>
            _repository.GetAppointmentsAsync(id, year, searchIDNumber));

    [HttpGet("sessions")]
    public async Task<IActionResult> Sessions([FromQuery] string? employeeId, [FromQuery] DateTime? schoolYear)
        => await ReadAsync(employeeId, schoolYear, _repository.GetSessionsAsync);

    [HttpGet("assessments")]
    public async Task<IActionResult> Assessments([FromQuery] string? employeeId, [FromQuery] DateTime? schoolYear)
        => await ReadAsync(employeeId, schoolYear, _repository.GetAssessmentsAsync);

    [HttpGet("follow-ups")]
    public async Task<IActionResult> FollowUps([FromQuery] string? employeeId, [FromQuery] DateTime? schoolYear)
        => await ReadAsync(employeeId, schoolYear, _repository.GetFollowUpsAsync);

    [HttpGet("masterlist")]
    public async Task<IActionResult> Masterlist([FromQuery] string? employeeId, [FromQuery] DateTime? schoolYear)
        => await ReadAsync(employeeId, schoolYear, _repository.GetMasterlistAsync);
}
