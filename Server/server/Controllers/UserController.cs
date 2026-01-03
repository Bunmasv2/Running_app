using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using server.DTO;
using server.Services.Interfaces;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Identity;
using server.Configs;

namespace server.Controllers;

[Route("[controller]")]
[ApiController]
public class UserController : ControllerBase
{
    private readonly IRun _runService;
    private readonly IUser _userServcie;
    private readonly IDailyGoal _dailyGoalService;
    private readonly IConfiguration _configuration;

    public UserController(
        IRun runService,
        IUser userServcie,
        IDailyGoal dailyService,
        IConfiguration configuration)
    {
        _runService = runService;
        _userServcie = userServcie;
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

    [HttpGet("profile")]
    [Authorize]
    public async Task<ActionResult> GetUserProfile()
    {
        string? userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        UserDTO.Profile user = await _userServcie.GetUserProfile("cc04e4e8-12bd-45e8-9ef5-808a2c16de5e");
        return Ok(user);
    }

    [HttpPut("update")]
    [Authorize]
    public async Task<ActionResult> UpdateProfile([FromBody] UserDTO.UpdateProfile dto)
    {
        string? userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        IdentityResult result = await _userServcie.UpdateProfile(userId, dto);

        if (!result.Succeeded)
            throw new ErrorException(400, "Update failed");

        return Ok(new { message = "Update successful" });
    }

    [HttpPost("avatar")]
    [Authorize]
    public async Task<ActionResult> UploadAvatar([FromForm] IFormFile avatar)
    {
        if (avatar == null || avatar.Length == 0)
            throw new ErrorException(400, "Image is required");

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var result = await _userServcie.UploadAvatar(userId, avatar);

        if (!result.Succeeded)
            throw new ErrorException(400, "Upload failed");

        return Ok(new{ message = "Upload avatar successful" });
    }

}