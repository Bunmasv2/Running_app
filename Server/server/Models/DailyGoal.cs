using System.ComponentModel.DataAnnotations.Schema;
namespace server.Models;

public partial class DailyGoal
{
    public int Id { get; set; }

    public string UserId { get; set; }
    [ForeignKey("UserId")]
    public AppUser User { get; set; }

    public DateTime Date { get; set; } // Ngày đặt mục tiêu (chỉ lấy phần Date)
    public double TargetDistanceKm { get; set; }
}