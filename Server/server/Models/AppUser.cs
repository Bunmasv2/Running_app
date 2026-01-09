using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Identity;
using Org.BouncyCastle.Asn1.Cmp;

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
    public int? CurrentActiveChallengeId { get; set; }

    [ForeignKey("CurrentActiveChallengeId")]
    public Challenge? CurrentActiveChallenge { get; set; }

    // Quan hệ 1-nhiều
    public ICollection<RunSession> RunSessions { get; set; } = new List<RunSession>();
    public ICollection<DailyGoal> DailyGoals { get; set; } = new List<DailyGoal>();
    // Lịch sử tham gia thử thách (Bao gồm cả cái đang tham gia và cái đã xong)
    [InverseProperty("User")] 
    public ICollection<ChallengeParticipant> ChallengeHistory { get; set; } = new List<ChallengeParticipant>();
    
    // Các thử thách do người này TẠO ra (Với tư cách là Creator)
    [InverseProperty("Creator")]
    public ICollection<Challenge> CreatedChallenges { get; set; } = new List<Challenge>();
}