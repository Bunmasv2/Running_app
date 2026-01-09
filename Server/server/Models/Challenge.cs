using System.ComponentModel.DataAnnotations.Schema;

namespace server.Models;

public class Challenge
{
    public int Id { get; set; }

    // Người tạo (Admin hoặc User)
    public string CreatorId { get; set; } = string.Empty;
    [ForeignKey("CreatorId")]
    public AppUser Creator { get; set; } = null!;

    // Thông tin hiển thị
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }

    // Mục tiêu
    public double TargetDistanceKm { get; set; } 
    
    // Null = Chạy theo StartDate/EndDate của giải. 
    // Có số = Chạy trong X ngày kể từ lúc bấm Join.
    public int? TargetDays { get; set; } 

    // Thời gian sự kiện
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Phần thưởng
    public string? RewardDescription { get; set; }
    public string? RewardFileUrl { get; set; }

    // Quản lý
    public ChallengeStatus Status { get; set; } = ChallengeStatus.Active;
    public int ParticipantCount { get; set; } = 0;

    // Danh sách người tham gia
    public ICollection<ChallengeParticipant> Participants { get; set; } = new List<ChallengeParticipant>();
}

public enum ChallengeStatus
{
    Draft = 0,      
    Active = 1,     
    Completed = 2,  
    Cancelled = 3   
}