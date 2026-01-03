using System.ComponentModel.DataAnnotations.Schema;

namespace server.Models;

public partial class RunSession
{
    public int Id { get; set; }

    // Foreign Key trỏ về User
    public string UserId { get; set; }
    [ForeignKey("UserId")]
    public AppUser User { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public double DistanceKm { get; set; }
    public double DurationSeconds { get; set; } // Tổng giây chạy
    public double CaloriesBurned { get; set; }

    // Lưu json raw của mảng tọa độ
    public string RouteJson { get; set; }
}