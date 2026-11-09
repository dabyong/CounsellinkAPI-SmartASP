using CounselLink.API.DTOs;
using CounselLink.API.Repositories;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Controllers;

[ApiController]
[Route("api/notifications")]
public class NotificationsController : ControllerBase
{
    private readonly INotificationRepository _repository;

    public NotificationsController(INotificationRepository repository) => _repository = repository;

    /// <summary>GET /api/notifications -> dbo.spNotification_Select</summary>
    [HttpGet]
    public async Task<IActionResult> Select([FromQuery] NotificationFilterDto filter)
    {
        try { return Ok(await _repository.SelectAsync(filter)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }

    /// <summary>POST /api/notifications -> dbo.spNotification_Insert</summary>
    [HttpPost]
    public async Task<IActionResult> Insert([FromBody] NotificationDto dto)
    {
        try { return Ok(await _repository.InsertAsync(dto)); }
        catch (SqlException ex) { return BadRequest(new { error = ex.Message }); }
    }
}
