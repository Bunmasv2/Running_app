using System;
using System.ComponentModel.DataAnnotations;

namespace server.DTO
{
    public class GoalDto
    {
        // 1. DTO dùng khi client GỬI dữ liệu lên để đặt mục tiêu (POST)
        public class CreateGoalDto
        {
            [Required(ErrorMessage = "Vui lòng nhập số km mục tiêu")]
            [Range(0.1, 1000, ErrorMessage = "Mục tiêu phải lớn hơn 0km")]
            public double TargetDistanceKm { get; set; }
        }

        // 2. DTO dùng khi server TRẢ dữ liệu về (GET)
        public class DailyGoalResponseDto
        {
            public int Id { get; set; }
            public DateTime Date { get; set; } // Ngày đặt mục tiêu
            public double TargetDistanceKm { get; set; } // Số km user muốn chạy
            
            // Có thể thêm field này nếu muốn hiện trạng thái đã đạt được chưa ngay tại object này
            public bool IsAchieved { get; set; } = false; 
        }
    }
}