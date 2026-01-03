using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using server.DTO;
using server.Services.Interfaces;

namespace server.Controllers;

[Route("[controller]")]
[ApiController]
[Authorize] // Yêu cầu phải có Token đăng nhập
public class RunController : ControllerBase
{
    private readonly IRun _runService;

    // Inject Interface vào Controller
    public RunController(IRun runService)
    {
        _runService = runService;
    }

    [HttpPost("finish")]
    public async Task<IActionResult> FinishRun([FromBody] RunSessionDto.RunCreateDto request)
    {
        try
        {
            // Lấy UserId từ Token (Claims)
            string? userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized("Không tìm thấy thông tin User");
            }

            // Gọi Service để xử lý logic
            RunSessionDto.RunResponseDto result = await _runService.ProcessRunSessionAsync(userId, request);

            return Ok(result);
        }
        catch (Exception ex)
        {
            // Xử lý lỗi nếu Service ném ra
            return BadRequest(new { Error = ex.Message });
        }
    }
}