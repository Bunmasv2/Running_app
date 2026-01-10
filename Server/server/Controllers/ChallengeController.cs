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


    [HttpGet("")]
    public async Task<ActionResult> GetChallenges()
    {
        var challenges = await _challengeService.GetChallenges();

        if (challenges.Count == 0)
            return Ok();

        var challengesDTO = _mapper.Map<List<challengesDTO.Challenge>>(challenges);

        return Ok(new { data = challengesDTO });
    }

    [HttpPost("{challengeId}/join")]
    public async Task<ActionResult> JoinChallenge(int challengeId)
    {
        // var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        Challenge challenge = await _challengeService.FindChallengeById(challengeId)
            ?? throw new ErrorException(404, "Challenge not found");

        int result = await _challengeService.JoinChallenge(challengeId, "cc04e4e8-12bd-45e8-9ef5-808a2c16de5e");

        if (result <= 0)
            throw new ErrorException(400, "Joined challenge falied");

        return Ok(new { message = "Joined challenge successfully" });
    }
}