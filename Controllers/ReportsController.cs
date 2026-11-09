using CounselLink.API.DTOs;
using CounselLink.API.Repositories;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Controllers;

[ApiController]
[Route("api/reports")]
public class ReportsController : ControllerBase
{
    private readonly IReportRepository _repository;

    public ReportsController(IReportRepository repository) => _repository = repository;

    /// <summary>GET /api/reports/monthly/completed -> dbo.sp_GenerateMonthlyReport_CompletedAppointments</summary>
    [HttpGet("monthly/completed")]
    public async Task<IActionResult> Completed([FromQuery] MonthlyReportFilterDto filter)
    {
        try { return Ok(await _repository.CompletedAppointmentsAsync(filter)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>GET /api/reports/monthly/concerns -> dbo.sp_GenerateMonthlyReport_ConcernFrequency</summary>
    [HttpGet("monthly/concerns")]
    public async Task<IActionResult> Concerns([FromQuery] MonthlyReportFilterDto filter)
    {
        try { return Ok(await _repository.ConcernFrequencyAsync(filter)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>GET /api/reports/monthly/modes -> dbo.sp_GenerateMonthlyReport_SessionModes</summary>
    [HttpGet("monthly/modes")]
    public async Task<IActionResult> Modes([FromQuery] MonthlyReportFilterDto filter)
    {
        try { return Ok(await _repository.SessionModesAsync(filter)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>GET /api/reports/monthly/referrals -> dbo.sp_GenerateMonthlyReport_ExternalReferrals</summary>
    [HttpGet("monthly/referrals")]
    public async Task<IActionResult> Referrals([FromQuery] MonthlyReportFilterDto filter)
    {
        try { return Ok(await _repository.ExternalReferralsAsync(filter)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>GET /api/reports/masterlist -> dbo.sp_GetAppointmentMasterlist</summary>
    [HttpGet("masterlist")]
    public async Task<IActionResult> Masterlist()
    {
        try { return Ok(await _repository.MasterlistAsync()); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }
}
