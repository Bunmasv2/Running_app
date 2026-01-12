using Microsoft.EntityFrameworkCore;
using server.DTO;
using server.Models;
using server.Services.Interfaces;
using AutoMapper;

namespace server.Services
{
    public class RunService : IRunService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public RunService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        // --- 1. LƯU BUỔI CHẠY ---
        // Trong RunService.cs (Server)

        public async Task<RunSessionDto.RunResponseDto> SaveRunSessionAsync(string userId, RunSessionDto.RunCreateDto dto)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            var DailyGoal = await _context.DailyGoals
                .OrderByDescending(g => g.Id)
                .FirstOrDefaultAsync(g => g.UserId == userId);
            int? DailyGoalId = null;

            if (DailyGoal != null && DailyGoal.Date.Date == dto.StartTime.Date)
            {
                DailyGoalId = DailyGoal.Id;
            }

            if (user == null) throw new Exception("User not found");

            double weight = user.WeightKg > 0 ? user.WeightKg : 65.0;
            double calories = weight * dto.DistanceKm * 1.036;

            var runSession = new RunSession
            {
                UserId = userId,
                DistanceKm = dto.DistanceKm,
                DurationSeconds = dto.DurationSeconds,
                StartTime = dto.StartTime,
                EndTime = dto.EndTime,
                RouteJson = dto.RouteJson,
                CaloriesBurned = calories,
                DailyGoalId = DailyGoalId
            };

            // --- [SỬA LỖI TẠI ĐÂY] ---
            // Cũ: user.TotalDistanceKm += 10;  <-- SAI (Hardcode)
            // Mới:
            user.TotalDistanceKm += dto.DistanceKm;

            user.TotalTimeSeconds += dto.DurationSeconds;

            _context.RunSessions.Add(runSession);
            _context.Users.Update(user);
            await _context.SaveChangesAsync();

            return new RunSessionDto.RunResponseDto
            {
                Id = runSession.Id,
                DistanceKm = runSession.DistanceKm,
                CaloriesBurned = Math.Round(calories, 1),
                Message = "Saved run session successfully"
            };
        }

        // --- 2. LẤY LỊCH SỬ CHẠY (PHÂN TRANG) ---
        public async Task<List<RunSessionDto.RunHistoryItemDto>> GetRunHistoryAsync(string userId, int pageIndex, int pageSize)
        {
            // Query dữ liệu
            var query = _context.RunSessions
                .Where(r => r.UserId == userId)
                .OrderByDescending(r => r.StartTime); // Mới nhất lên đầu

            // Phân trang (Skip & Take) và Map sang DTO
            var historyList = await query
                .Skip((pageIndex - 1) * pageSize)
                .Take(pageSize)
                .Select(r => new RunSessionDto.RunHistoryItemDto
                {
                    Id = r.Id,
                    StartTime = r.StartTime,
                    EndTime = r.EndTime,
                    DistanceKm = r.DistanceKm,
                    DurationSeconds = r.DurationSeconds,
                    CaloriesBurned = r.CaloriesBurned
                    // Lưu ý: KHÔNG lấy RouteJson ở đây để danh sách nhẹ
                })
                .ToListAsync();

            return historyList;
        }

        // --- 3. LẤY CHI TIẾT 1 BUỔI CHẠY ---
        public async Task<RunSessionDto.RunDetailDto> GetRunDetailAsync(int runId, string userId)
        {
            var run = await _context.RunSessions
                .FirstOrDefaultAsync(r => r.Id == runId && r.UserId == userId);

            if (run == null) throw new KeyNotFoundException("Run session not found or access denied");

            return new RunSessionDto.RunDetailDto
            {
                Id = run.Id,
                StartTime = run.StartTime,
                DistanceKm = run.DistanceKm,
                DurationSeconds = run.DurationSeconds,
                CaloriesBurned = run.CaloriesBurned,
                RouteJson = run.RouteJson // Trả về JSON để FE vẽ map
            };
        }

        // --- 4. LẤY THỐNG KÊ HÔM NAY ---
        public async Task<RunSessionDto.DailyStatDto> GetTodayStatsAsync(string userId)
        {
            // Xác định khoảng thời gian "Hôm nay" (Theo Server Time)
            var today = DateTime.Today; // 00:00:00 hôm nay
            var tomorrow = today.AddDays(1);

            // 1. Tính tổng Km và Calo đã chạy hôm nay
            var todayRuns = await _context.RunSessions
                .Where(r => r.UserId == userId && r.StartTime >= today && r.StartTime < tomorrow)
                .ToListAsync(); // Lấy về RAM để tính toán cho nhanh nếu data ít

            double totalDist = todayRuns.Sum(r => r.DistanceKm);
            double totalCal = todayRuns.Sum(r => r.CaloriesBurned);

            // 2. Lấy Mục tiêu (Goal) hôm nay
            var goal = await _context.DailyGoals
                .FirstOrDefaultAsync(g => g.UserId == userId && g.Date.Date == today);
            double target = goal != null ? goal.TargetDistanceKm : 0;

            // 3. Tính % hoàn thành
            double progress = 0;

            if (target > 0)
            {
                progress = (totalDist / target) * 100;
                if (progress > 100) progress = 100; // Max là 100%
            }

            return new RunSessionDto.DailyStatDto
            {
                TotalDistanceKm = Math.Round(totalDist, 2),
                TotalCalories = Math.Round(totalCal, 1),
                TargetDistanceKm = target,
                ProgressPercent = Math.Round(progress, 1)
            };
        }

        public async Task<List<UserDTO.userRanking>> GetTop10WeeklyAsync()
        {
            var today = DateTime.UtcNow.Date;

            int diff = (7 + (today.DayOfWeek - DayOfWeek.Monday)) % 7;
            var weekStart = today.AddDays(-diff);
            var weekEnd = weekStart.AddDays(7).AddTicks(-1);

            var result = await _context.RunSessions
                .Include(r => r.User)
                .Where(r => r.EndTime >= weekStart && r.EndTime <= weekEnd)
                .GroupBy(r => new
                {
                    r.UserId,
                    r.User.UserName,
                    r.User.AvatarUrl
                })
                .Select(g => new UserDTO.userRanking
                {
                    Username = g.Key.UserName,
                    AvatarUrl = g.Key.AvatarUrl == null
                        ? null
                        : $"{g.Key.AvatarUrl}",

                    TotalDistanceKm = Math.Round(g.Sum(x => x.DistanceKm), 2),

                    TotalDurationSeconds = g.Sum(x => x.DurationSeconds),

                    TotalTime = TimeSpan
                        .FromSeconds(g.Sum(x => x.DurationSeconds))
                        .ToString(@"hh\:mm\:ss")
                })
                .OrderByDescending(x => x.TotalDistanceKm)
                .ThenBy(x => x.TotalDurationSeconds)
                .Take(10)
                .ToListAsync();

            return result;
        }

        public async Task<List<RunSessionDto.RunHistoryItemDto>> GetMonthlyRunSessionsAsync(string userId, int month, int year)
        {
            var result = await _context.RunSessions
                .Where(r =>
                    r.UserId == userId &&
                    r.EndTime.Month == month &&
                    r.EndTime.Year == year)
                .GroupBy(r => r.EndTime.Date)
                .Select(g => new RunSessionDto.RunHistoryItemDto
                {
                    Id = g.First().Id,
                    StartTime = g.Min(x => x.StartTime),
                    EndTime = g.Max(x => x.EndTime),
                    DistanceKm = g.Sum(x => x.DistanceKm),
                    DurationSeconds = g.Sum(x => x.DurationSeconds),
                    CaloriesBurned = g.Sum(x => x.CaloriesBurned),
                })
                .OrderBy(x => x.EndTime)
                .ToListAsync();

            return result;
        }

        public async Task<List<RunSessionDto.RunHistoryItemDto>> GetTop2RunSessionsAsync(string userId)
        {
            var top2Runs = await _context.RunSessions
                .Where(r => r.UserId == userId)
                .OrderByDescending(r => r.DistanceKm)
                .Take(2)
                .ToListAsync();

            var top2RunDtos = _mapper.Map<List<RunSessionDto.RunHistoryItemDto>>(top2Runs);
            return top2RunDtos;
        }
        public async Task<List<RunSessionDto.RunHistoryItemDto>> GetWeeklyRunSessionsAsync(string userId, int month, int year)
        {
            return await _context.RunSessions
                .Where(r =>
                    r.UserId == userId &&
                    r.EndTime.Month == month &&
                    r.EndTime.Year == year)
                .OrderBy(r => r.EndTime)
                .Select(r => new RunSessionDto.RunHistoryItemDto
                {
                    Id = r.Id,
                    StartTime = r.StartTime,
                    EndTime = r.EndTime,
                    DistanceKm = r.DistanceKm,
                    DurationSeconds = r.DurationSeconds,
                    CaloriesBurned = r.CaloriesBurned
                })
                .ToListAsync();
        }

        public async Task<List<RunSessionDto.RealativeEffort>> GetRelativeEffortAsync(string userId)
        {
            var runs = await _context.RunSessions
                .Include(r => r.DailyGoal)
                .Where(r => r.UserId == userId)
                .OrderByDescending(r => r.StartTime)
                .ToListAsync();

            var relativeEfforts = runs.Select(r => new RunSessionDto.RealativeEffort
            {
                Id = r.Id,
                StartTime = r.StartTime,
                EndTime = r.EndTime,
                DistanceKm = r.DistanceKm,
                DurationSeconds = r.DurationSeconds,
                CaloriesBurned = r.CaloriesBurned,
                TargetDistanceKm = r.DailyGoal?.TargetDistanceKm ?? 0,
                ProgressPercent = r.DailyGoal != null && r.DailyGoal.TargetDistanceKm > 0
                    ? Math.Min((r.DistanceKm / r.DailyGoal.TargetDistanceKm) * 100, 100)
                    : 0
            }).ToList();

            return relativeEfforts;
        }
    }
}