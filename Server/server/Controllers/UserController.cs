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
public class UserController : ControllerBase
{
    private readonly IRun _runService;
    private readonly IDailyGoal _dailyGoalService;
        private readonly IConfiguration _configuration;

    public UserController(
        IRun runService, 
        IDailyGoal dailyService, 
        IConfiguration configuration)
    {
        _runService = runService;
        _dailyGoalService = dailyService;
        _configuration = configuration;
    }

    [HttpGet("signin-google")]
    public IActionResult SignGoogle(string returnUrl = "https://www.facebook.com/")
    {
        if (string.IsNullOrEmpty(returnUrl))
        {
            var configReturnUrl = _configuration["Authentication:Google:ReturnUrl"];
            returnUrl = configReturnUrl ?? "/";
        }

        var properties = new AuthenticationProperties
        {
            RedirectUri = Url.Action("GoogleCallback", "Auth", new { returnUrl }),
        };

        return Challenge(properties, GoogleDefaults.AuthenticationScheme);
    }

}