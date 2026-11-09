using CounselLink.API.DTOs;
using CounselLink.API.Repositories;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Controllers;

/// <summary>
/// CRUD for the constant lookup tables. {type} selects the stored-procedure
/// family: spConst{Type}_{Select|Insert|Update|Delete}. Supported types:
/// AppointmentType, ConcernType, AttendanceStatus, AppointmentStatus,
/// SessionType, SpecialistReferral.
/// </summary>
[ApiController]
[Route("api/constants")]
public class ConstantsController : ControllerBase
{
    private readonly IConstantRepository _repository;

    public ConstantsController(IConstantRepository repository) => _repository = repository;

    /// <summary>GET /api/constants/{type} -> spConst{Type}_Select</summary>
    [HttpGet("{type}")]
    public async Task<IActionResult> Select(string type)
    {
        if (!_repository.IsSupported(type))
            return NotFound(new { error = $"Unsupported constant type '{type}'." });

        try
        {
            return Ok(await _repository.SelectAsync(type));
        }
        catch (SqlException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>POST /api/constants/{type} -> spConst{Type}_Insert</summary>
    [HttpPost("{type}")]
    public async Task<IActionResult> Insert(string type, [FromBody] ConstantDto dto)
    {
        if (!_repository.IsSupported(type))
            return NotFound(new { error = $"Unsupported constant type '{type}'." });

        try
        {
            return Ok(await _repository.InsertAsync(type, dto));
        }
        catch (SqlException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>PUT /api/constants/{type} -> spConst{Type}_Update</summary>
    [HttpPut("{type}")]
    public async Task<IActionResult> Update(string type, [FromBody] ConstantDto dto)
    {
        if (!_repository.IsSupported(type))
            return NotFound(new { error = $"Unsupported constant type '{type}'." });

        try
        {
            return Ok(await _repository.UpdateAsync(type, dto));
        }
        catch (SqlException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>DELETE /api/constants/{type}/{id} -> spConst{Type}_Delete</summary>
    [HttpDelete("{type}/{id:int}")]
    public async Task<IActionResult> Delete(string type, int id)
    {
        if (!_repository.IsSupported(type))
            return NotFound(new { error = $"Unsupported constant type '{type}'." });

        try
        {
            return Ok(await _repository.DeleteAsync(type, id));
        }
        catch (SqlException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
