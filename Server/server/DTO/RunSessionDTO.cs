using System;
using System.ComponentModel.DataAnnotations;

namespace server.DTO
{
    public class RunSessionDto
    {
        // 1. DTO nhận dữ liệu khi client gửi lên (POST)
        public class RunCreateDto
        {
            [Required]
            public double DistanceKm { get; set; }

            [Required]
            public double DurationSeconds { get; set; }

            public DateTime StartTime { get; set; }
            public DateTime EndTime { get; set; }

            // Chuỗi JSON tọa độ để vẽ lại map
            public string RouteJson { get; set; } = string.Empty;
        }

        // 2. DTO trả về sau khi lưu thành công
        public class RunResponseDto
        {
            public int Id { get; set; }
            public double DistanceKm { get; set; }
            public double CaloriesBurned { get; set; }
            public string Message { get; set; } = string.Empty;
        }

        // 3. DTO cho item trong danh sách lịch sử (Gọn nhẹ, KHÔNG có RouteJson)
        public class RunHistoryItemDto
        {
            public int Id { get; set; }
            public DateTime StartTime { get; set; }
            public double DistanceKm { get; set; }
            public double DurationSeconds { get; set; }
            public double CaloriesBurned { get; set; }
        }

        // 4. DTO cho chi tiết 1 buổi chạy (Có đầy đủ RouteJson)
        public class RunDetailDto : RunHistoryItemDto
        {
            public string RouteJson { get; set; } = string.Empty;
        }

        // 5. DTO thống kê ngày hôm nay (Dashboard Home)
        public class DailyStatDto
        {
            public double TotalDistanceKm { get; set; }
            public double TotalCalories { get; set; }
            public double TargetDistanceKm { get; set; } // Mục tiêu đề ra
            public double ProgressPercent { get; set; } // Đã đạt bao nhiêu %
        }
    }
}