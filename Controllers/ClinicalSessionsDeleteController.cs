using System.Data;
using CounselLink.API.Data;
using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Controllers;

/// <summary>
/// TEMPORARY TEST CLEANUP: deletes a completed clinical session, its appointment,
/// and dependent records via dbo.spClinical_DeleteCompletedAppointmentBySession.
/// No API key or authentication is required.
/// </summary>
[ApiController]
[Route("api/clinical/sessions")]
public sealed class ClinicalSessionsDeleteController : ControllerBase
{
    private readonly IDbConnectionFactory _factory;

    public ClinicalSessionsDeleteController(IDbConnectionFactory factory) => _factory = factory;

    /// <summary>DELETE /api/clinical/sessions/{sessionId}; uses SessionID, not AppointmentID.</summary>
    [HttpDelete("{sessionId:int}")]
    public async Task<IActionResult> DeleteCompletedSessionAndAppointment(int sessionId)
    {
        if (sessionId <= 0)
            return BadRequest(new { error = "SessionID must be a positive number." });

        try
        {
            using var connection = _factory.CreateConnection();
            var parameters = new DynamicParameters();
            parameters.Add("@SessionID", sessionId, DbType.Int32);
            parameters.Add("@DeletedAppointmentID", dbType: DbType.Int32,
                direction: ParameterDirection.Output);
            parameters.Add("@Message", dbType: DbType.String,
                direction: ParameterDirection.Output, size: 255);

            await connection.ExecuteAsync(
                "dbo.spClinical_DeleteCompletedAppointmentBySession",
                parameters,
                commandType: CommandType.StoredProcedure);

            return Ok(new
            {
                sessionId,
                deletedAppointmentId = parameters.Get<int?>("@DeletedAppointmentID"),
                message = parameters.Get<string>("@Message")
            });
        }
        catch (SqlException ex) when (ex.Number == 51041)
        {
            return NotFound(new { error = ex.Message });
        }
        catch (SqlException ex) when (ex.Number is 51042 or 51043 or 51044 or 51045 or 547)
        {
            return Conflict(new { error = ex.Message });
        }
        catch (SqlException ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }
}
