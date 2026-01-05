using server.DTO;

namespace server.Services.Interfaces;

public interface IRunService
{
    Task<RunSessionDto.RunResponseDto> SaveRunSessionAsync(string userId, RunSessionDto.RunCreateDto dto);
    Task<List<RunSessionDto.RunHistoryItemDto>> GetRunHistoryAsync(string userId, int pageIndex, int pageSize);
    Task<RunSessionDto.RunDetailDto> GetRunDetailAsync(int runId, string userId);
    Task<RunSessionDto.DailyStatDto> GetTodayStatsAsync(string userId);
}