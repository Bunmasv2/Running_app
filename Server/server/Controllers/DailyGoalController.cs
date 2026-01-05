using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using server.DTO;
using server.Services.Interfaces;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Google;

namespace server.Controllers;

[Route("[controller]")]
[ApiController]
[Authorize]
public class DailyGoalController : ControllerBase
{
    private readonly IRun _runService;
    private readonly IDailyGoal _dailyGoalService;
    private readonly IConfiguration _configuration;

    public DailyGoalController(
        IRun runService, 
        IDailyGoal dailyService, 
        IConfiguration configuration)
    {
        _runService = runService;
        _dailyGoalService = dailyService;
        _configuration = configuration;
    }
}