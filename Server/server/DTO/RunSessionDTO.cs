namespace server.DTO
{
    public class RunSessionDto
    {
        public class RunCreateDto
        {
            public double DistanceKm { get; set; }
            public double DurationSeconds { get; set; }
            public DateTime StartTime { get; set; }
            public DateTime EndTime { get; set; }
            public string RouteJson { get; set; } = string.Empty; // Mặc định chuỗi rỗng để tránh null
        }

        public class RunResponseDto
        {
            public int Id { get; set; }
            public double DistanceKm { get; set; }
            public double DurationSeconds { get; set; }
            public double CaloriesBurned { get; set; }
            public DateTime StartTime { get; set; }

            // Trả về nguyên chuỗi JSON tọa độ để FE tự parse
            public string RouteJson { get; set; } = string.Empty;
            public string Message { get; set; } = string.Empty;
        }
    }
}