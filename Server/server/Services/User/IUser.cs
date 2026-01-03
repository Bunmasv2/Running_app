using server.DTO;
using server.Models;

namespace server.Services.Interfaces;

public interface IUser
{
    Task<AppUser> FindOrCreateUserByEmailAsync(string email, string name);
}