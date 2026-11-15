using System.Data;
using CounselLink.API.Data;
using CounselLink.API.DTOs;
using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Controllers;

/// <summary>
/// TESTING ONLY. The two distinct admin functions are NOT real account/role enforcement.
/// Current test build has no identity or authorization by project choice.
/// </summary>
[ApiController]
[Route("api/admin")]
public sealed class TestSuperAdminsController : ControllerBase
{
    private readonly IDbConnectionFactory _factory;
    public TestSuperAdminsController(IDbConnectionFactory factory)=>_factory=factory;

    [HttpGet("students/{idNumber}")]
    public async Task<IActionResult> GetStudentOverride(string idNumber)
    {
        if(!ValidId(idNumber)) return BadRequest(new {error="IDNumber must be 1-7 characters."});
        try
        {
            using var db=_factory.CreateConnection();
            var row=await db.QuerySingleOrDefaultAsync(
                "SELECT * FROM dbo.StudentProfileOverride WHERE IDNumber=@idNumber",new{idNumber});
            // This is the local override only; the external university base profile is NOT stored here.
            return Ok(new {idNumber,hasOverride=row is not null,localOverride=row});
        }
        catch(SqlException){return StatusCode(500,new {error="Could not load local student override."});}
    }

    [HttpPut("students/{idNumber}")]
    public async Task<IActionResult> PutStudentOverride(string idNumber,[FromBody] StudentProfileOverrideDto dto)
    {
        if(!ValidId(idNumber)) return BadRequest(new {error="IDNumber must be 1-7 characters."});
        if(dto.DepartmentID?.Length>10 || dto.ProgramID?.Length>10 || dto.ContactNumber?.Length>30 ||
           dto.FirstName?.Length>100 || dto.MiddleName?.Length>100 || dto.LastName?.Length>100 ||
           dto.Email?.Length>254 || dto.ProgramOrCourse?.Length>100)
           return BadRequest(new {error="One or more override fields are too long."});
        try
        {
            using var db=_factory.CreateConnection();
            // Intentionally do not touch external student service or any appointment/clinical rows.
            await db.ExecuteAsync(@"
                SET XACT_ABORT ON;
                BEGIN TRANSACTION;
                UPDATE dbo.StudentProfileOverride WITH(UPDLOCK,SERIALIZABLE)
                SET FirstName=@FirstName,MiddleName=@MiddleName,LastName=@LastName,
                    Email=@Email,ContactNumber=@ContactNumber,DepartmentID=@DepartmentID,
                    ProgramID=@ProgramID,ProgramOrCourse=@ProgramOrCourse,
                    GradeOrYearLevel=@GradeOrYearLevel,UpdatedAtUtc=SYSUTCDATETIME()
                WHERE IDNumber=@idNumber;
                IF @@ROWCOUNT=0
                    INSERT INTO dbo.StudentProfileOverride
                    (IDNumber,FirstName,MiddleName,LastName,Email,ContactNumber,DepartmentID,
                    ProgramID,ProgramOrCourse,GradeOrYearLevel)
                    VALUES(@idNumber,@FirstName,@MiddleName,@LastName,@Email,@ContactNumber,
                    @DepartmentID,@ProgramID,@ProgramOrCourse,@GradeOrYearLevel);
                COMMIT TRANSACTION;",
                new {idNumber,dto.FirstName,dto.MiddleName,dto.LastName,dto.Email,dto.ContactNumber,
                    dto.DepartmentID,dto.ProgramID,dto.ProgramOrCourse,dto.GradeOrYearLevel});
            return Ok(new {idNumber,message="Local student profile override saved.",externalUniversityProfileModified=false});
        }
        catch(SqlException){return StatusCode(500,new {error="Could not save local student override."});}
    }

    [HttpDelete("students/{idNumber}")]
    public async Task<IActionResult> ClearStudentOverride(string idNumber)
    {
        if(!ValidId(idNumber)) return BadRequest(new {error="IDNumber must be 1-7 characters."});
        try
        {
            using var db=_factory.CreateConnection();
            var rows=await db.ExecuteAsync("DELETE FROM dbo.StudentProfileOverride WHERE IDNumber=@idNumber",new{idNumber});
            return Ok(new {idNumber,overrideRemoved=rows>0,
                message="External profile remains unchanged. Frontend can display external values again."});
        }
        catch(SqlException){return StatusCode(500,new {error="Could not delete local override."});}
    }

    [HttpGet("counselors/{employeeId}")]
    public async Task<IActionResult> GetCounselor(string employeeId)
    {
        if(!ValidId(employeeId)) return BadRequest(new {error="Invalid employeeId."});
        try
        {
            using var db=_factory.CreateConnection();
            var c=await db.QuerySingleOrDefaultAsync("SELECT * FROM dbo.Counselor WHERE EmployeeID=@employeeId",new{employeeId});
            if(c is null)return NotFound(new {error="Counselor not found."});
            var a=await db.QueryAsync(@"SELECT AssignmentID,EmployeeID,DepartmentID,ProgramID,YearOrGradeLevel,SchoolYear
                FROM dbo.CounselorAssignment WHERE EmployeeID=@employeeId ORDER BY SchoolYear DESC,AssignmentID",new{employeeId});
            return Ok(new {counselor=c,assignments=a});
        }
        catch(SqlException){return StatusCode(500,new {error="Could not load counselor."});}
    }

    [HttpPut("counselors/{employeeId}")]
    public async Task<IActionResult> UpdateCounselor(string employeeId,[FromBody] CounselorAdminEditDto dto)
    {
        if(!ValidId(employeeId) || string.IsNullOrWhiteSpace(dto.FirstName) || string.IsNullOrWhiteSpace(dto.LastName))
            return BadRequest(new {error="Valid employeeId, firstName, and lastName are required."});
        try
        {
            using var db=_factory.CreateConnection();
            var p=new DynamicParameters();
            p.Add("@EmployeeID",employeeId);
            p.Add("@FirstName",dto.FirstName);
            p.Add("@LastName",dto.LastName);
            p.Add("@MiddleName",dto.MiddleName);
            p.Add("@Message",dbType:DbType.String,direction:ParameterDirection.Output,size:255);
            await db.ExecuteAsync("dbo.spCounselor_Update",p,commandType:CommandType.StoredProcedure);
            return Ok(new {employeeId,message=p.Get<string>("@Message")});
        }
        catch(SqlException){return StatusCode(500,new {error="Could not update counselor."});}
    }

    [HttpPost("counselors/{employeeId}/assignments")]
    public async Task<IActionResult> AddCounselorAssignment(string employeeId,[FromBody] CounselorAssignmentAdminDto dto)
    {
        if(!ValidId(employeeId) || (dto.DepartmentID is null && dto.ProgramID is null && dto.YearOrGradeLevel is null))
            return BadRequest(new {error="Provide employeeId and at least one assignment scope."});
        var now=DateTime.UtcNow.AddHours(8);
        var year=dto.SchoolYear?.Date ?? new DateTime(now.Month>=8?now.Year:now.Year-1,8,1);
        try
        {
            using var db=_factory.CreateConnection();
            var p=new DynamicParameters();
            p.Add("@EmployeeID",employeeId);p.Add("@DepartmentID",dto.DepartmentID);
            p.Add("@ProgramID",dto.ProgramID);p.Add("@YearOrGradeLevel",dto.YearOrGradeLevel);
            p.Add("@SchoolYear",year);
            p.Add("@NewID",dbType:DbType.Int32,direction:ParameterDirection.Output);
            p.Add("@Message",dbType:DbType.String,direction:ParameterDirection.Output,size:255);
            await db.ExecuteAsync("dbo.spCounselorAssignment_Insert",p,commandType:CommandType.StoredProcedure);
            return Ok(new {employeeId,assignmentId=p.Get<int?>("@NewID"),schoolYear=year.ToString("yyyy-MM-dd"),
                message=p.Get<string>("@Message")});
        }
        catch(SqlException){return StatusCode(500,new {error="Could not create counselor assignment."});}
    }

    [HttpPut("counselors/{employeeId}/assignments/{assignmentId:int}")]
    public async Task<IActionResult> EditCounselorAssignment(string employeeId,int assignmentId,
        [FromBody] CounselorAssignmentAdminDto dto)
    {
        if(!ValidId(employeeId) || assignmentId<=0 ||
           (dto.DepartmentID is null && dto.ProgramID is null && dto.YearOrGradeLevel is null))
            return BadRequest(new {error="Provide employeeId, assignmentId and at least one assignment scope."});
        var now=DateTime.UtcNow.AddHours(8);
        var year=dto.SchoolYear?.Date ?? new DateTime(now.Month>=8?now.Year:now.Year-1,8,1);
        try
        {
            using var db=_factory.CreateConnection();
            var count=await db.ExecuteAsync(@"
                UPDATE dbo.CounselorAssignment SET DepartmentID=@DepartmentID,ProgramID=@ProgramID,
                    YearOrGradeLevel=@YearOrGradeLevel,SchoolYear=@year
                WHERE EmployeeID=@employeeId AND AssignmentID=@assignmentId;",
                new {employeeId,assignmentId,dto.DepartmentID,dto.ProgramID,dto.YearOrGradeLevel,year});
            return count==0?NotFound(new {error="Assignment not found for counselor."}):
                Ok(new {employeeId,assignmentId,schoolYear=year.ToString("yyyy-MM-dd"),message="Assignment updated."});
        }
        catch(SqlException){return StatusCode(500,new {error="Could not update counselor assignment."});}
    }

    private static bool ValidId(string? id) => !string.IsNullOrWhiteSpace(id)&&id.Length<=7;
}
