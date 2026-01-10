using Microsoft.AspNetCore.Identity;
using server.DTO;
using server.Models;

namespace server.Services.Interfaces;

public interface IChallengeService
{
    Task<List<Challenge>> GetChallenges();
    Task<Challenge> FindChallengeById(int challengeId);
    Task<int> JoinChallenge(int challengeId, string userId);
    Task<List<challengesDTO.ChallengeDto>> GetAllActiveChallenges();
    Task<List<challengesDTO.UserChallengeProgressDto>> GetMyChallenges(string userId);
    Task<bool> JoinChallenge(string userId, int challengeId);
}