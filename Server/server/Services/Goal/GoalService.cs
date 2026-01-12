using Microsoft.EntityFrameworkCore;
using server.DTO;
using server.Models;
using server.Services.Interfaces;

namespace server.Services
{
    public class GoalService : IGoalService
    {
        private readonly ApplicationDbContext _context;

        public GoalService(ApplicationDbContext context)
        {
            _context = context;
        }

        // 1. LẤY MỤC TIÊU HÔM NAY
        public async Task<GoalDto.DailyGoalResponseDto?> GetTodayGoalAsync(string userId)
        {
            var today = DateTime.Today; // 00:00:00 hôm nay

            // Tìm trong DB xem có dòng nào của user này và ngày == hôm nay không
            var goal = await _context.DailyGoals
                .OrderByDescending(g => g.Id)
                .FirstOrDefaultAsync(g => g.UserId == userId && g.Date.Date == today);

            if (goal == null) return null; // Chưa đặt mục tiêu

            return new GoalDto.DailyGoalResponseDto
            {
                Id = goal.Id,
                Date = goal.Date,
                TargetDistanceKm = goal.TargetDistanceKm,
                IsAchieved = false // (Logic tính đã đạt chưa sẽ làm ở phần thống kê sau)
            };
        }

        // 2. ĐẶT (HOẶC CẬP NHẬT) MỤC TIÊU HÔM NAY
        // public async Task<GoalDto.DailyGoalResponseDto> SetTodayGoalAsync(string userId, double targetKm)
        // {
        //     var today = DateTime.Today;

        //     // Kiểm tra xem đã có mục tiêu chưa
        //     var existingGoal = await _context.DailyGoals
        //         .FirstOrDefaultAsync(g => g.UserId == userId && g.Date.Date == today);

        //     if (existingGoal != null)
        //     {
        //         // TRƯỜNG HỢP 1: Đã có -> Cập nhật lại số Km
        //         existingGoal.TargetDistanceKm = targetKm;
        //         _context.DailyGoals.Update(existingGoal);
        //     }
        //     else
        //     {
        //         // TRƯỜNG HỢP 2: Chưa có -> Tạo mới
        //         existingGoal = new DailyGoal
        //         {
        //             UserId = userId,
        //             Date = today, // Lưu ngày giờ hiện tại (nhưng phần giờ là 00:00:00)
        //             TargetDistanceKm = targetKm
        //         };
        //         _context.DailyGoals.Add(existingGoal);
        //     }

        //     // Lưu vào DB
        //     await _context.SaveChangesAsync();

        //     return new GoalDto.DailyGoalResponseDto
        //     {
        //         Id = existingGoal.Id,
        //         Date = existingGoal.Date,
        //         TargetDistanceKm = existingGoal.TargetDistanceKm,
        //         IsAchieved = false
        //     };
        // }

        public async Task<GoalDto.DailyGoalResponseDto> SetTodayGoalAsync(string userId, double targetKm, string type)
        {
            if (type == "dailyGoal")
            {
                var today = DateTime.Now;

                var createGoalService = new DailyGoal
                {
                    UserId = userId,
                    Date = today,
                    TargetDistanceKm = targetKm
                };
                _context.DailyGoals.Add(createGoalService);

                await _context.SaveChangesAsync();

                return new GoalDto.DailyGoalResponseDto
                {
                    Id = createGoalService.Id,
                    Date = createGoalService.Date,
                    TargetDistanceKm = createGoalService.TargetDistanceKm,
                    IsAchieved = false
                };
            }
            else
            {
                return null;
            }
        }

        // public Task<GoalDto.DailyGoalResponseDto> SetTodayGoalAsync(string userId, double targetKm)
        // {
        //     throw new NotImplementedException();
        // }
    }
}