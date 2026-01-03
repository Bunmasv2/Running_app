using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using server.DTO;
using server.Services.Interfaces;

namespace server.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize] 
public class DailyGoalController : ControllerBase
{
    private readonly IRunService _runService;
    private readonly IDailyGoalService _dailyGoalService;

    public DailyGoalController(IRunService runService)
    {
        _runService = runService;
    }

    [HttpPost("finish")]
    public async Task<IActionResult> FinishRun([FromBody] RunSessionDto.RunCreateDto request)
    {
        try
        {
            string? userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized("Không tìm thấy thông tin User");
            }

            RunSessionDto.RunResponseDto result = await _runService.ProcessRunSessionAsync(userId, request);

            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
    }
}