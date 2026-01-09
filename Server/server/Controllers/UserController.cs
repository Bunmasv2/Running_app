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
public class UserController : ControllerBase
{
    private readonly IRunService _runService;
    private readonly IUserService _userServcie;
    private readonly IDailyGoalService _dailyGoalService;
    private readonly IConfiguration _configuration;
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;

    public UserController(
        IRunService runService,
        IUserService userServcie,
        IDailyGoalService dailyService,
        IConfiguration configuration,
        ApplicationDbContext context,
        IMapper mapper)
    {
        _runService = runService;
        _userServcie = userServcie;
        _dailyGoalService = dailyService;
        _configuration = configuration;
        _context = context;
        _mapper = mapper;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] UserDTO.RegisterDto dto)
    {
        Console.WriteLine($"EMailll: {dto.Email}");
        Console.WriteLine($"Passss: {dto.Password}");

        var result = await _userServcie.Register(dto);

        if (!result)
            throw new ErrorException(400, "Đăng ký thất bại");

        return Ok(new
        {
            message = "Đăng ký thành công"
        });
    }



    [HttpPost("signin")]
    public async Task<IActionResult> SignIn([FromBody] UserDTO.SignIn signIn)
    {
        if (signIn == null)
        {
            throw new ErrorException(400, "Invalid sign-in data");
        }

        var result = await _userServcie.SignIn(signIn.Email, signIn.Password);
        return Ok(new { message = "Sign-in endpoint", data = result });
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
    // [Authorize]
    public async Task<ActionResult> GetUserProfile()
    {
        string? userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        UserDTO.Profile user = await _userServcie.GetUserProfile(userId);
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
        var result = await _userServcie.UpdateUserImage(avatar, userId);

        if (!result.Succeeded)
            throw new ErrorException(400, "Upload failed");

        // Console.WriteLine("AVAAAAAA: ", result.A);

        return Ok(new { message = "Upload avatar successful" });
    }

    [HttpGet("suggests")]
    public async Task<ActionResult> GetSuggestedUser()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var users = await _userServcie.GetSuggestedUser(userId);

        if (users.Count() <= 0)
            return Ok();

        var usersDTO = _mapper.Map<List<UserDTO.Profile>>(users);

        return Ok(usersDTO);
    }
}