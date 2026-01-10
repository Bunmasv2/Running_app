using server.DTO;

namespace server.Services.Interfaces;

public interface IRunService
{
    Task<RunSessionDto.RunResponseDto> SaveRunSessionAsync(string userId, RunSessionDto.RunCreateDto dto);
    Task<List<RunSessionDto.RunHistoryItemDto>> GetRunHistoryAsync(string userId, int pageIndex, int pageSize);
    Task<RunSessionDto.RunDetailDto> GetRunDetailAsync(int runId, string userId);
    Task<RunSessionDto.DailyStatDto> GetTodayStatsAsync(string userId);
    Task<List<UserDTO.userRanking>> GetTop10WeeklyAsync();
    Task<List<RunSessionDto.RunHistoryItemDto>> GetMonthlyRunSessionsAsync(string userId, int month, int year);
    Task<List<RunSessionDto.RunHistoryItemDto>> GetTop2RunSessionsAsync(string userId);
    Task<List<RunSessionDto.RunHistoryItemDto>> GetWeeklyRunSessionsAsync(string userId);
}