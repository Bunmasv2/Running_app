using Microsoft.AspNetCore.Identity;
using server.DTO;
using server.Models;

namespace server.Services.Interfaces;

public interface IChallengeService
{
    Task<List<Challenge>> GetChallenges();
    Task<Challenge> FindChallengeById(int challengeId);
    Task<int> JoinChallenge(int challengeId, string userId);
    Task<List<ChallengeDto>> GetAllActiveChallenges();
    Task<List<UserChallengeProgressDto>> GetMyChallenges(string userId);
    Task<bool> JoinChallenge(string userId, int challengeId);
}