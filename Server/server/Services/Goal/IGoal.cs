using server.DTO;

namespace server.Services.Interfaces;

public interface IGoalService
{
    Task<GoalDto.DailyGoalResponseDto?> GetTodayGoalAsync(string userId);
    
    Task<GoalDto.DailyGoalResponseDto> SetTodayGoalAsync(string userId, double targetKm);
}