using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using server.Configs;
using server.DTO;
using server.Services.Interfaces;

namespace server.Controllers
{
    [Route("[controller]")]
    [ApiController]
    // [Authorize]
    public class RunController : ControllerBase
    {
        private readonly IRunService _runService;

        public RunController(IRunService runService)
        {
            _runService = runService;
        }

        // RunController.cs

        // 1. Sửa hàm lấy ID để debug xem nó lấy ra cái gì
        private string GetUserId()
        {
            var id = User.FindFirstValue(ClaimTypes.NameIdentifier);
            // [DEBUG QUAN TRỌNG] In ra màn hình đen (Console) của Server
            Console.WriteLine($"---> DEBUG TOKEN: ID trích xuất từ Token là: '{id}'");

            // Nếu ID null, thử tìm trong Claim khác xem sao
            if (string.IsNullOrEmpty(id))
            {
                var altId = User.FindFirstValue("id"); // Thử tìm claim tên là "id" thường
                Console.WriteLine($"---> DEBUG ALTERNATIVE: Thử tìm claim 'id' thường: '{altId}'");
                return altId;
            }
            return id;
        }

        [HttpPost]
        public async Task<IActionResult> SaveRun([FromBody] RunSessionDto.RunCreateDto dto)
        {
            try
            {
                var userId = GetUserId();
                Console.WriteLine($"---> DEBUG SAVE RUN: Đang tìm User trong DB với ID = {userId}");

                // Gọi Service
                var result = await _runService.SaveRunSessionAsync(userId, dto);
                return Ok(result);
            }
            catch (Exception ex)
            {
                // In lỗi chi tiết ra console server
                Console.WriteLine($"---> ERROR SERVER: {ex.Message}");
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

        [HttpGet("top-weekly")]
        public async Task<IActionResult> GetWeeklyRanking()
        {
            var result = await _runService.GetTop10WeeklyAsync();
            return Ok(new
            {
                title = "Ranking Runner",
                subtitle = "Những Chiến Binh Yêu Bản Thân – 7 Ngày Trong Tuần",
                data = result
            });
        }

        [HttpGet("monthly-sessions/{month}/{year}")]
        public async Task<IActionResult> GetMonthlyRunSessions(int month, int year)
        {
            var result = await _runService.GetMonthlyRunSessionsAsync(GetUserId(), month, year);
            return Ok(new { data = result });
        }

        [HttpGet("top2-sessions")]
        public async Task<IActionResult> GetTop2RunSessions()
        {
            var result = await _runService.GetTop2RunSessionsAsync(GetUserId());
            return Ok(new { data = result });
        }
        [HttpGet("weekly-sessions/{month}/{year}")]
        public async Task<IActionResult> GetWeeklyRunSessions(int month, int year)
        {
            var result = await _runService.GetWeeklyRunSessionsAsync(GetUserId(), month, year);
            return Ok(new { data = result });
        }

        [HttpGet("relative-effort")]
        public async Task<IActionResult> GetRelativeEffort()
        {
            var result = await _runService.GetRelativeEffortAsync(GetUserId());
            return Ok(new { data = result });
        }
    }
}