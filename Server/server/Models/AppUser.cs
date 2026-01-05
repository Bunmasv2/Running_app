using Microsoft.AspNetCore.Identity;

namespace server.Models;


public class AppUser : IdentityUser
{
    public string? FullName { get; set; } = string.Empty;
    public double HeightCm { get; set; }
    public double WeightKg { get; set; }
    public double TotalDistanceKm { get; set; } = 0;
    public double TotalTimeSeconds { get; set; } = 0;
    public string? AvatarUrl { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Quan hệ 1-nhiều
    public ICollection<RunSession> RunSessions { get; set; } = new List<RunSession>();
    public ICollection<DailyGoal> DailyGoals { get; set; } = new List<DailyGoal>();
}