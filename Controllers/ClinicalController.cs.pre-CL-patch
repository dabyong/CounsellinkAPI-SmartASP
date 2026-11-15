using CounselLink.API.DTOs;
using CounselLink.API.Repositories;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Controllers;

[ApiController]
[Route("api/clinical")]
public class ClinicalController : ControllerBase
{
    private readonly IClinicalRepository _repository;

    public ClinicalController(IClinicalRepository repository) => _repository = repository;

    /// <summary>POST /api/clinical/sessions -> dbo.spCounselingSession_Insert</summary>
    [HttpPost("sessions")]
    public async Task<IActionResult> InsertSession([FromBody] CounselingSessionDto dto)
    {
        try { return Ok(await _repository.InsertSessionAsync(dto)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>GET /api/clinical/sessions -> dbo.spCounselingSession_Select</summary>
    [HttpGet("sessions")]
    public async Task<IActionResult> SelectSessions([FromQuery] CounselingSessionFilterDto filter)
    {
        try { return Ok(await _repository.SelectSessionsAsync(filter)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>POST /api/clinical/assessments -> dbo.spStudentAssessment_Insert</summary>
    [HttpPost("assessments")]
    public async Task<IActionResult> InsertAssessment([FromBody] StudentAssessmentDto dto)
    {
        try { return Ok(await _repository.InsertAssessmentAsync(dto)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>GET /api/clinical/assessments -> dbo.spStudentAssessment_Select</summary>
    [HttpGet("assessments")]
    public async Task<IActionResult> SelectAssessments([FromQuery] StudentAssessmentFilterDto filter)
    {
        try { return Ok(await _repository.SelectAssessmentsAsync(filter)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>POST /api/clinical/follow-ups -> dbo.spSessionFollowUp_Insert</summary>
    [HttpPost("follow-ups")]
    public async Task<IActionResult> InsertFollowUp([FromBody] SessionFollowUpDto dto)
    {
        try { return Ok(await _repository.InsertFollowUpAsync(dto)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>GET /api/clinical/follow-ups -> dbo.spSessionFollowUp_Select</summary>
    [HttpGet("follow-ups")]
    public async Task<IActionResult> SelectFollowUps([FromQuery] SessionFollowUpFilterDto filter)
    {
        try { return Ok(await _repository.SelectFollowUpsAsync(filter)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }
}
