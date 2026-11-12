using CounselLink.API.Repositories;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Controllers;

[ApiController]
[Route("api/counselor-schedules")]
public sealed class CounselorSchedulesController : ControllerBase
{
    private readonly ICounselorScheduleRepository _repository;

    public CounselorSchedulesController(ICounselorScheduleRepository repository) => _repository = repository;

    /// <summary>Get privacy-safe Available/Unavailable time slots for a counselor.</summary>
    /// <remarks>
    /// Example: /api/counselor-schedules/availability?employeeId=EMP0001&amp;startDate=2026-11-16&amp;endDate=2026-11-20
    /// Inclusive range of up to 42 days. Times are Philippine local times.
    /// </remarks>
    [HttpGet("availability")]
    public async Task<IActionResult> GetAvailability(
        [FromQuery] string employeeId,
        [FromQuery] DateTime startDate,
        [FromQuery] DateTime endDate)
    {
        if (string.IsNullOrWhiteSpace(employeeId) || employeeId.Length > 7)
            return BadRequest(new { error = "Provide a valid counselor EmployeeID (up to 7 characters)." });
        if (startDate == default || endDate == default || endDate.Date < startDate.Date ||
            (endDate.Date - startDate.Date).TotalDays > 41)
            return BadRequest(new { error = "Provide an inclusive date range of at most 42 days." });

        try
        {
            var slots = await _repository.GetAvailabilityAsync(employeeId, startDate, endDate);
            return Ok(slots);
        }
        catch (SqlException ex) when (ex.Number >= 51001 && ex.Number <= 51004)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (SqlException)
        {
            return StatusCode(500, new { error = "Counselor availability could not be loaded." });
        }
    }
}
