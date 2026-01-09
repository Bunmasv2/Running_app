using server.DTO;

namespace server.Services.Interfaces;

public interface IChallengeService
{
    // Lấy danh sách tất cả thử thách đang mở
    Task<List<ChallengeDto>> GetAllActiveChallenges();

    // Lấy danh sách thử thách CỦA TÔI
    Task<List<UserChallengeProgressDto>> GetMyChallenges(string userId);

    // Tham gia thử thách
    Task<bool> JoinChallenge(string userId, int challengeId);
}