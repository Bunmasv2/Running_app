using System.Text.RegularExpressions;
using AutoMapper;
using AutoMapper.QueryableExtensions;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using server.Configs;
using server.DTO;
using server.Models;
using server.Services.Interfaces;
using server.Util;
using CloudinaryDotNet;
using CloudinaryDotNet.Actions;

namespace server.Services.Implements;

public class UserService : IUserService
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<AppUser> _userManager;
    private readonly IMapper _mapper;
    private readonly IConfiguration _configuration;
    private readonly Cloudinary _cloudinary;

    public UserService(
        ApplicationDbContext context,
        UserManager<AppUser> userManager,
        IMapper mapper,
        IConfiguration configuration,
        Cloudinary cloudinary)
    {
        _context = context;
        _userManager = userManager;
        _mapper = mapper;
        _configuration = configuration;
        _cloudinary = cloudinary;
    }

    public async Task<AppUser> FindOrCreateUserByEmailAsync(string email, string name)
    {
        if (string.IsNullOrEmpty(email))
            throw new ErrorException(400, "Email is required");

        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Email == email);

        string baseUserName = Regex.Replace(name ?? email.Split('@')[0], @"[^a-zA-Z0-9]", "").ToLower();
        string finalUserName = baseUserName;
        int suffix = 1;

        while (await _userManager.FindByNameAsync(finalUserName) != null)
        {
            finalUserName = $"{baseUserName}{suffix}";
            suffix++;
        }

        if (user == null)
        {
            user = new AppUser
            {
                Email = email,
                UserName = finalUserName
            };

            var result = await _userManager.CreateAsync(user);

            if (!result.Succeeded)
            {
                var messages = string.Join(" | ", result.Errors.Select(e => $"{e.Code}: {e.Description}"));
                throw new ErrorException(400, "Failed to create user: " + messages);
            }

            var roleResult = await _userManager.AddToRoleAsync(user, "User");
            if (!roleResult.Succeeded)
            {
                var messages = string.Join(" | ", roleResult.Errors.Select(e => $"{e.Code}: {e.Description}"));
                throw new ErrorException(400, "Failed to add role: " + messages);
            }
        }

        return user;
    }

    public async Task<UserDTO.Profile?> GetUserProfile(string userId)
    {

        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Id == userId);
        return _mapper.Map<UserDTO.Profile>(user);
        // return await _context.Users
        //     .Where(u => u.Id == userId)
        //     .ProjectTo<UserDTO.Profile>(_mapper.ConfigurationProvider)
        //     .FirstOrDefaultAsync();
    }

    public async Task<IdentityResult> UpdateProfile(string userId, UserDTO.UpdateProfile dto)
    {
        var user = await _userManager.FindByIdAsync(userId)
            ?? throw new ErrorException("User not found");

        user.HeightCm = dto.HeightCm;
        user.WeightKg = dto.WeightKg;

        return await _userManager.UpdateAsync(user);
    }

    // public async Task<IdentityResult> UploadAvatar(string userId, IFormFile avatar)
    // {
    //     var user = await _userManager.FindByIdAsync(userId)
    //         ?? throw new ErrorException("User not found");

    //     using var memoryStream = new MemoryStream();
    //     await avatar.CopyToAsync(memoryStream);
    //     var imageData = memoryStream.ToArray();
    //     var base64 = Convert.ToBase64String(imageData);
    //     user.AvatarUrl = base64;

    //     return await _userManager.UpdateAsync(user);
    // }

    public async Task<IdentityResult> UpdateUserImage(IFormFile file, string userId)
    {
        var user = _context.Users.FirstOrDefault(u => u.Id == userId);
        if (user == null)
            return null;

        if (file == null || file.Length == 0)
            throw new ArgumentException("No file uploaded");

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        ImageUploadResult imageResult = null;
        Console.WriteLine($"[UPLOAD DEBUG] FileName: {file.FileName}, Extension: {ext}");

        if (new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg" }.Contains(ext))
        {
            var uploadParams = new ImageUploadParams
            {
                File = new FileDescription(file.FileName, file.OpenReadStream()),
                Folder = "ProjectManagement/Tasks",
                PublicId = $"{userId}_{Guid.NewGuid()}"
            };
            imageResult = await _cloudinary.UploadAsync(uploadParams);
        }

        Console.WriteLine("Upload result: " + imageResult.ToString());
        var fileUrl = imageResult?.SecureUrl?.ToString();
        Console.WriteLine("Uploaded file URL: " + fileUrl);

        if (string.IsNullOrEmpty(fileUrl))
            throw new Exception("Upload failed or URL missing.");

        user.AvatarUrl = fileUrl;
        Console.WriteLine("AVAAAAAA: ", user.AvatarUrl);


        return await _userManager.UpdateAsync(user);
    }

    public async Task<UserDTO.SignInResponse> SignIn(string email, string password)
    {
        var user = await _userManager.FindByEmailAsync(email);
        if (user == null || !await _userManager.CheckPasswordAsync(user, password))
        {
            throw new ErrorException(400, "Invalid email or password");
        }
        var roles = await _userManager.GetRolesAsync(user);
        var token = JwtUtils.GenerateToken(user, roles, 1, _configuration);
        var refreshToken = JwtUtils.GenerateToken(user, roles, 8, _configuration);

        // CookieUtils.SetCookie(Response, "token", token, 8);

        // await _ .SaveRefreshToken(user, refreshToken);

        return new UserDTO.SignInResponse
        {
            Email = user.Email,
            Token = token
        };
    }

    public async Task<bool> Register(UserDTO.RegisterDto registerDto)
    {
        if (registerDto.Password != registerDto.ConfirmPass)
        {
            throw new ErrorException(400, "Mật khẩu xác nhận không khớp");
        }

        // 2. Check email đã tồn tại
        var existingUser = await _userManager.FindByEmailAsync(registerDto.Email);
        if (existingUser != null)
        {
            throw new ErrorException(400, "Email đã được sử dụng");
        }

        // 3. Tạo user
        var user = new AppUser
        {
            UserName = registerDto.UserName,
            Email = registerDto.Email,
            HeightCm = registerDto.HeightCm,
            WeightKg = registerDto.WeightKg,
            CreatedAt = DateTime.UtcNow,
            EmailConfirmed = true
        };

        // 4. Tạo user + hash password
        var result = await _userManager.CreateAsync(user, registerDto.Password);
        if (!result.Succeeded)
        {
            foreach (var error in result.Errors)
            {
                Console.WriteLine($"Identity error: {error.Code} - {error.Description}");
            }
            return false;
        }
        return true;
    }

    public async Task<List<AppUser>> GetSuggestedUser(string userId)
    {
        var users = await _context.Users
            .Where(u => u.Id != userId)
            .OrderBy(u => Guid.NewGuid())
            .Take(10)
            .ToListAsync();

        return users;
    }
}