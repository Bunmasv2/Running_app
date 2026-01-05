using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using server.DTO;
using server.Services.Interfaces;

namespace server.Controllers
{
    [Route("[controller]")]
    [ApiController]
    // [Authorize]
    public class RunController : ControllerBase
    {
        private readonly IRun _runService;

        public RunController(IRun runService)
        {
            _runService = runService;
        }

        private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier);

        // POST: api/runs (Lưu bài chạy khi bấm Kết thúc)
        [HttpPost]
        public async Task<IActionResult> SaveRun([FromBody] RunSessionDto.RunCreateDto dto)
        {
            try
            {
                var result = await _runService.SaveRunSessionAsync(GetUserId(), dto);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { error = ex.Message });
            }
        }

        // GET: api/runs/history?pageIndex=1&pageSize=10
        [HttpGet("history")]
        public async Task<IActionResult> GetHistory([FromQuery] int pageIndex = 1, [FromQuery] int pageSize = 10)
        {
            var history = await _runService.GetRunHistoryAsync(GetUserId(), pageIndex, pageSize);
            return Ok(history);
        }

        // GET: api/runs/{id} (Xem chi tiết để vẽ Map)
        [HttpGet("{id}")]
        public async Task<IActionResult> GetRunDetail(int id)
        {
            try
            {
                var detail = await _runService.GetRunDetailAsync(id, GetUserId());
                return Ok(detail);
            }
            catch (KeyNotFoundException)
            {
                return NotFound("Không tìm thấy bài chạy này");
            }
        }

        // GET: api/runs/today-stats (Cho Widget trang chủ)
        [HttpGet("today-stats")]
        public async Task<IActionResult> GetTodayStats()
        {
            var stats = await _runService.GetTodayStatsAsync(GetUserId());
            return Ok(stats);
        }
    }
}