using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using server.DTO;
using server.Services.Interfaces;

namespace server.Controllers
{
    [Route("[controller]")]
    [ApiController]
    [Authorize]
    public class GoalController : ControllerBase
    {
        private readonly IGoalService _goalService;

        public GoalController(IGoalService goalService)
        {
            _goalService = goalService;
        }

        private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier);

        // GET: api/goals/today (Kiểm tra xem hôm nay đặt mục tiêu chưa)
        [HttpGet("today")]
        public async Task<IActionResult> GetTodayGoal()
        {
            var goal = await _goalService.GetTodayGoalAsync(GetUserId());
            if (goal == null) return Ok(null); // Trả về null để FE hiện nút "+"
            return Ok(goal);
        }

        // POST: api/goals (Đặt mục tiêu mới)
        [HttpPost]
        public async Task<IActionResult> SetGoal([FromBody] GoalDto.CreateGoalDto dto)
        {
            try
            {
                var result = await _goalService.SetTodayGoalAsync(GetUserId(), dto.TargetDistanceKm);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { error = ex.Message });
            }
        }
    }
}