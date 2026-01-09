using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using server.Services.Interfaces;
using server.DTO;

namespace server.Controllers
{
    [Route("[controller]")]
    [ApiController]
    // [Authorize] // Bắt buộc phải đăng nhập mới dùng được
    public class ChallengeController : ControllerBase
    {
        private readonly IChallengeService _challengeService;

        public ChallengeController(IChallengeService challengeService)
        {
            _challengeService = challengeService;
        }

        // GET: /Challenge
        // Lấy danh sách tất cả (Tab "Danh sách")
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var result = await _challengeService.GetAllActiveChallenges();
            return Ok(new { data = result });
        }

        // GET: /Challenge/my-challenges
        // Lấy danh sách của tôi (Tab "Của bạn")
        [HttpGet("my-challenges")]
        public async Task<IActionResult> GetMyChallenges()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (userId == null) return Unauthorized();

            var result = await _challengeService.GetMyChallenges(userId);
            return Ok(new { data = result });
        }

        // POST: /Challenge/join/5
        // Tham gia thử thách
        [HttpPost("join/{id}")]
        public async Task<IActionResult> JoinChallenge(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (userId == null) return Unauthorized();

            var success = await _challengeService.JoinChallenge(userId, id);

            if (success)
            {
                return Ok(new { message = "Tham gia thử thách thành công!" });
            }
            else
            {
                return BadRequest(new { message = "Không thể tham gia (Thử thách không tồn tại hoặc bạn đã tham gia rồi)." });
            }
        }
    }
}