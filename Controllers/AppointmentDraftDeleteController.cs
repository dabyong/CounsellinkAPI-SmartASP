using System.Data;
using CounselLink.API.Data;
using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Controllers;

/// <summary>
/// Adds draft-only deletion without changing the current live
/// AppointmentDraftsController or the general appointments DELETE endpoint.
/// </summary>
[ApiController]
[Route("api/appointment-drafts")]
public sealed class AppointmentDraftDeleteController : ControllerBase
{
    private readonly IDbConnectionFactory _factory;

    public AppointmentDraftDeleteController(IDbConnectionFactory factory)
        => _factory = factory;

    /// <summary>
    /// Delete an unsubmitted Draft (AppointmentStatusID = 5) for the supplied
    /// student ID. The appointmentId is the same ID used by Draft update/submit.
    /// Example: DELETE /api/appointment-drafts/101?idNumber=2023001
    /// </summary>
    /// <response code="200">Draft deleted; returns appointmentId and message.</response>
    /// <response code="400">Invalid request or other business validation failure.</response>
    /// <response code="404">Draft not found for the appointmentId and idNumber.</response>
    /// <response code="409">Appointment is no longer a Draft.</response>
    [HttpDelete("{appointmentId:int}")]
    public async Task<IActionResult> DeleteDraft(
        [FromRoute] int appointmentId,
        [FromQuery] string? idNumber)
    {
        if (appointmentId <= 0)
            return BadRequest(new { error = "A valid appointmentId is required." });

        if (string.IsNullOrWhiteSpace(idNumber) || idNumber.Length > 7)
            return BadRequest(new { error = "idNumber is required (maximum 7 characters)." });

        var parameters = new DynamicParameters();
        parameters.Add("@AppointmentID", appointmentId, DbType.Int32);
        parameters.Add("@IDNumber", idNumber.Trim(), DbType.AnsiString, size: 7);
        parameters.Add("@Message", dbType: DbType.String,
                       direction: ParameterDirection.Output, size: 255);

        try
        {
            using var connection = _factory.CreateConnection();
            await connection.ExecuteAsync(
                "dbo.spAppointmentDraft_Delete",
                parameters,
                commandType: CommandType.StoredProcedure);

            var message = parameters.Get<string>("@Message")
                          ?? "Draft deleted successfully.";
            return Ok(new { appointmentId, message });
        }
        catch (SqlException ex) when (ex.Number == 50242)
        {
            return NotFound(new { error = ex.Message });
        }
        catch (SqlException ex) when (ex.Number == 50243)
        {
            return Conflict(new { error = ex.Message });
        }
        catch (SqlException ex) when (ex.Number == 50240 || ex.Number == 50241)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (SqlException ex)
        {
            return StatusCode(500, new { error = "Draft could not be deleted.", detail = ex.Message });
        }
    }
}
