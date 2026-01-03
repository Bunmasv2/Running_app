using Microsoft.AspNetCore.Identity;

namespace server.Models;


public class AppUser : IdentityUser
{
    // Thêm các field riêng cho app chạy bộ
    public double HeightCm { get; set; }
    public double WeightKg { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Quan hệ 1-nhiều
    public ICollection<RunSession> RunSessions { get; set; } = new List<RunSession>();
    public ICollection<DailyGoal> DailyGoals { get; set; } = new List<DailyGoal>();
}