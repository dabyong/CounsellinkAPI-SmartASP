using System.Data;
using CounselLink.API.Data;
using CounselLink.API.DTOs;
using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Controllers;

/// <summary>Save incomplete Draft (5), edit Draft, submit as Requested (1).</summary>
[ApiController]
[Route("api/appointment-drafts")]
public sealed class AppointmentDraftsController : ControllerBase
{
    private readonly IDbConnectionFactory _factory;
    public AppointmentDraftsController(IDbConnectionFactory factory) => _factory = factory;

    [HttpPost]
    public Task<IActionResult> Create([FromBody] DraftAppointmentDto dto) => Save(null,dto);

    [HttpPut("{appointmentId:int}")]
    public Task<IActionResult> Update(int appointmentId,[FromBody] DraftAppointmentDto dto)
        => Save(appointmentId,dto);

    private async Task<IActionResult> Save(int? id, DraftAppointmentDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.IDNumber)) return BadRequest(new {error="IDNumber is required."});
        try
        {
            using var db=_factory.CreateConnection();
            var p=new DynamicParameters();
            p.Add("@AppointmentID",id,DbType.Int32);
            p.Add("@IDNumber",dto.IDNumber,DbType.AnsiString,size:7);
            p.Add("@GradeOrYearLevel",dto.GradeOrYearLevel);
            p.Add("@ProgramOrCourse",dto.ProgramOrCourse);
            p.Add("@EmployeeID",dto.EmployeeID);
            p.Add("@AppointmentDate",dto.AppointmentDate?.Date);
            p.Add("@StartTime",dto.StartTime);
            p.Add("@EndTime",dto.EndTime);
            p.Add("@AppointmentTypeID",dto.AppointmentTypeID);
            p.Add("@ConcernTypeID",dto.ConcernTypeID);
            p.Add("@ConcernDescription",dto.ConcernDescription);
            p.Add("@ReferredBy",dto.ReferredBy);
            p.Add("@ReferralDate",dto.ReferralDate?.Date);
            p.Add("@NewID",dbType:DbType.Int32,direction:ParameterDirection.Output);
            p.Add("@Message",dbType:DbType.String,direction:ParameterDirection.Output,size:255);
            await db.ExecuteAsync("dbo.spAppointmentDraft_Save",p,commandType:CommandType.StoredProcedure);
            return Ok(new {appointmentId=p.Get<int>("@NewID"),statusId=5,status="Draft",
                message=p.Get<string>("@Message")});
        }
        catch(SqlException e) when(e.Number>=51900&&e.Number<52000)
        {return Conflict(new {error=e.Message});}
        catch(SqlException)
        {return StatusCode(500,new {error="Draft could not be saved."});}
    }

    [HttpPost("{appointmentId:int}/submit")]
    public async Task<IActionResult> Submit(int appointmentId,[FromBody] SubmitDraftDto dto)
    {
        try
        {
            using var db=_factory.CreateConnection();
            var p=new DynamicParameters();
            p.Add("@AppointmentID",appointmentId);
            p.Add("@IDNumber",dto.IDNumber);
            p.Add("@Message",dbType:DbType.String,direction:ParameterDirection.Output,size:255);
            await db.ExecuteAsync("dbo.spAppointmentDraft_Submit",p,commandType:CommandType.StoredProcedure);
            return Ok(new {appointmentId,statusId=1,status="Requested",message=p.Get<string>("@Message")});
        }
        catch(SqlException e) when(e.Number>=51900&&e.Number<52000)
        {return Conflict(new {error=e.Message});}
        catch(SqlException)
        {return StatusCode(500,new {error="Draft could not be submitted."});}
    }
}
