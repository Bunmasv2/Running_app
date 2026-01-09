using System.ComponentModel.DataAnnotations.Schema;

namespace server.Models;

public class ChallengeParticipant
{
    public int Id { get; set; }

    public int ChallengeId { get; set; }
    [ForeignKey("ChallengeId")]
    public Challenge Challenge { get; set; } = null!;

    public string UserId { get; set; } = string.Empty;
    [ForeignKey("UserId")]
    public AppUser User { get; set; } = null!;

    // Tiến độ
    public double CompletedDistanceKm { get; set; } = 0;
    public double ProgressPercent { get; set; } = 0;

    // Thời gian
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
    
    // Nếu Challenge là kiểu linh hoạt (TargetDays != null), Deadline sẽ được tính khi Join
    public DateTime? PersonalDeadline { get; set; } 
    
    public DateTime? CompletedAt { get; set; }

    public ParticipantStatus Status { get; set; } = ParticipantStatus.InProgress;
    public bool RewardClaimed { get; set; } = false;
}

public enum ParticipantStatus
{
    InProgress = 0, 
    Completed = 1,  
    Failed = 2,     
    Withdrawn = 3   
}