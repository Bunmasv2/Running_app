using Microsoft.AspNetCore.Identity;
using server.DTO;
using server.Models;

namespace server.Services.Interfaces;

public interface IUserService
{
    Task<AppUser> FindOrCreateUserByEmailAsync(string email, string name);
    Task<UserDTO.Profile> GetUserProfile(string userId);
    Task<IdentityResult> UpdateProfile(string userId, UserDTO.UpdateProfile dto);
    Task<UserDTO.SignInResponse> SignIn(string email, string password);
    Task<IdentityResult> UpdateUserImage(IFormFile file, string userId);
    Task<bool> Register(UserDTO.RegisterDto registerDto);
    Task<List<AppUser>> GetSuggestedUser(string userId);

}