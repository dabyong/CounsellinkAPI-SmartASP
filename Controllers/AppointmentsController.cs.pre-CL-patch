using CounselLink.API.DTOs;
using CounselLink.API.Repositories;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Controllers;

[ApiController]
[Route("api/appointments")]
public class AppointmentsController : ControllerBase
{
    private readonly IAppointmentRepository _repository;

    public AppointmentsController(IAppointmentRepository repository) => _repository = repository;

    /// <summary>GET /api/appointments -> dbo.spAppointment_Select (with query filters)</summary>
    [HttpGet]
    public async Task<IActionResult> Select([FromQuery] AppointmentFilterDto filter)
    {
        try { return Ok(await _repository.SelectAsync(filter)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>POST /api/appointments -> dbo.spAppointment_Insert</summary>
    [HttpPost]
    public async Task<IActionResult> Insert([FromBody] CreateAppointmentDto dto)
    {
        try { return Ok(await _repository.InsertAsync(dto)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>PUT /api/appointments/{id} -> dbo.spAppointment_Update</summary>
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateAppointmentDto dto)
    {
        try { return Ok(await _repository.UpdateAsync(id, dto)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>DELETE /api/appointments/{id} -> dbo.spAppointment_Delete</summary>
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        try { return Ok(await _repository.DeleteAsync(id)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>PUT /api/appointments/{id}/confirm -> dbo.spConfirmAppointment</summary>
    [HttpPut("{id:int}/confirm")]
    public async Task<IActionResult> Confirm(int id, [FromBody] ConfirmAppointmentDto dto)
    {
        try { return Ok(await _repository.ConfirmAsync(id, dto)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>PUT /api/appointments/{id}/student-confirm -> dbo.spStudentConfirmAppointment</summary>
    [HttpPut("{id:int}/student-confirm")]
    public async Task<IActionResult> StudentConfirm(int id, [FromBody] StudentIdNumberDto dto)
    {
        try { return Ok(await _repository.StudentConfirmAsync(id, dto.IDNumber)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>PUT /api/appointments/{id}/complete -> dbo.spCompleteAppointment</summary>
    [HttpPut("{id:int}/complete")]
    public async Task<IActionResult> Complete(int id)
    {
        try { return Ok(await _repository.CompleteAsync(id)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>POST /api/appointments/{id}/reschedule -> dbo.spRescheduleAppointment</summary>
    [HttpPost("{id:int}/reschedule")]
    public async Task<IActionResult> Reschedule(int id, [FromBody] RescheduleDto dto)
    {
        try { return Ok(await _repository.RescheduleAsync(id, dto)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>PUT /api/appointments/{id}/accept-reschedule -> dbo.spStudentAcceptReschedule</summary>
    [HttpPut("{id:int}/accept-reschedule")]
    public async Task<IActionResult> AcceptReschedule(int id, [FromBody] StudentIdNumberDto dto)
    {
        try { return Ok(await _repository.AcceptRescheduleAsync(id, dto.IDNumber)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>PUT /api/appointments/{id}/no-show -> dbo.spSetAppointmentNoShow</summary>
    [HttpPut("{id:int}/no-show")]
    public async Task<IActionResult> NoShow(int id)
    {
        try { return Ok(await _repository.SetNoShowAsync(id)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>GET /api/appointments/reschedule-history -> dbo.spGetCounselorRescheduleHistory</summary>
    [HttpGet("reschedule-history")]
    public async Task<IActionResult> RescheduleHistory([FromQuery] string? employeeId)
    {
        try { return Ok(await _repository.GetRescheduleHistoryAsync(employeeId)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }
}
