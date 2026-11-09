using CounselLink.API.DTOs;
using CounselLink.API.Repositories;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Controllers;

[ApiController]
[Route("api/counselors")]
public class CounselorsController : ControllerBase
{
    private readonly ICounselorRepository _repository;

    public CounselorsController(ICounselorRepository repository) => _repository = repository;

    /// <summary>GET /api/counselors -> dbo.spCounselor_Select</summary>
    [HttpGet]
    public async Task<IActionResult> Select()
    {
        try { return Ok(await _repository.SelectAsync()); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>POST /api/counselors -> dbo.spCounselor_Insert</summary>
    [HttpPost]
    public async Task<IActionResult> Insert([FromBody] CounselorDto dto)
    {
        try { return Ok(await _repository.InsertAsync(dto)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>PUT /api/counselors -> dbo.spCounselor_Update</summary>
    [HttpPut]
    public async Task<IActionResult> Update([FromBody] CounselorDto dto)
    {
        try { return Ok(await _repository.UpdateAsync(dto)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>DELETE /api/counselors/{employeeId} -> dbo.spCounselor_Delete</summary>
    [HttpDelete("{employeeId}")]
    public async Task<IActionResult> Delete(string employeeId)
    {
        try { return Ok(await _repository.DeleteAsync(employeeId)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }
}

[ApiController]
[Route("api/counselor-assignments")]
public class CounselorAssignmentsController : ControllerBase
{
    private readonly ICounselorAssignmentRepository _repository;

    public CounselorAssignmentsController(ICounselorAssignmentRepository repository) => _repository = repository;

    /// <summary>GET /api/counselor-assignments -> dbo.spCounselorAssignment_Select</summary>
    [HttpGet]
    public async Task<IActionResult> Select()
    {
        try { return Ok(await _repository.SelectAsync()); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>POST /api/counselor-assignments -> dbo.spCounselorAssignment_Insert</summary>
    [HttpPost]
    public async Task<IActionResult> Insert([FromBody] CounselorAssignmentDto dto)
    {
        try { return Ok(await _repository.InsertAsync(dto)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }
}
