using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using server.DTO;
using server.Services.Interfaces;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Identity;
using server.Configs;
using System.Reflection.Metadata.Ecma335;
using server.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.SqlServer.Server;
using AutoMapper;
using AutoMapper.QueryableExtensions;
using Org.BouncyCastle.Tls;

namespace server.Controllers;

[Route("[controller]")]
[ApiController]
public class ChallengeController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly IChallengeService _challengeService;
    private readonly IMapper _mapper;

    public ChallengeController(
        IConfiguration configuration,
        IChallengeService challengeService,
        IMapper mapper)
    {
        _configuration = configuration;
        _challengeService = challengeService;
        _mapper = mapper;
    }


    [HttpGet("suggests")]
    public async Task<ActionResult> GetChallenges()
    {
        var challenges = await _challengeService.GetChallenges();

        if (challenges.Count == 0)
            return Ok();

        var challengesDTO = _mapper.Map<List<challengesDTO.Challenge>>(challenges);

        return Ok(new { data = challengesDTO });
    }

    // [HttpPost("{challengeId}/join")]
    // public async Task<ActionResult> JoinChallenge(int challengeId)
    // {
    //     // var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
    //     Challenge challenge = await _challengeService.FindChallengeById(challengeId)
    //         ?? throw new ErrorException(404, "Challenge not found");

    //     int result = await _challengeService.JoinChallenge(challengeId, "cc04e4e8-12bd-45e8-9ef5-808a2c16de5e");

    //     if (result <= 0)
    //         throw new ErrorException(400, "Joined challenge falied");

    //     return Ok(new { message = "Joined challenge successfully" });
    // }

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
        // var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        // if (userId == null) return Unauthorized();

        var success = await _challengeService.JoinChallenge("b1549d21-97ec-48a3-b2e1-31c8a59eefab", id);

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