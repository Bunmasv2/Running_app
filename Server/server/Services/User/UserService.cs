using System.Text.RegularExpressions;
using AutoMapper;
using AutoMapper.QueryableExtensions;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using server.Configs;
using server.DTO;
using server.Models;
using server.Services.Interfaces;

namespace server.Services.Implements;

public class UserService : IUserService
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<AppUser> _userManager;
    private readonly IMapper _mapper;

    public UserService(
        ApplicationDbContext context,
        UserManager<AppUser> userManager,
        IMapper mapper)
    {
        _context = context;
        _userManager = userManager;
        _mapper = mapper;
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
        return await _context.Users
            .Where(u => u.Id == userId)
            .ProjectTo<UserDTO.Profile>(_mapper.ConfigurationProvider)
            .FirstOrDefaultAsync();
    }

    public async Task<IdentityResult> UpdateProfile(string userId, UserDTO.UpdateProfile dto)
    {
        var user = await _userManager.FindByIdAsync(userId)
            ?? throw new ErrorException("User not found");

        user.HeightCm = dto.HeightCm;
        user.WeightKg = dto.WeightKg;

        return await _userManager.UpdateAsync(user);
    }

    public async Task<IdentityResult> UploadAvatar(string userId, IFormFile avatar)
    {
        var user = await _userManager.FindByIdAsync(userId)
            ?? throw new ErrorException("User not found");

        using var memoryStream = new MemoryStream();
        await avatar.CopyToAsync(memoryStream);
        var imageData = memoryStream.ToArray();
        var base64 = Convert.ToBase64String(imageData);
        user.AvatarUrl = base64;

        return await _userManager.UpdateAsync(user);
    }
}