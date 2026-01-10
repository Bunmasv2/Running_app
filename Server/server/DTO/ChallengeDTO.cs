namespace server.DTO
{
    public class challengesDTO
    {
        public class Challenge
        {
            public int Id { get; set; }
            public string Name { get; set; } = string.Empty;
            public string Description { get; set; } = string.Empty;
            public double TargetDistanceKm { get; set; }
            public DateTime StartDate { get; set; }
            public DateTime EndDate { get; set; }
            public int TotalParticipants { get; set; }
        }

    public class ChallengeDto
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string? ImageUrl { get; set; }
        public double TargetDistanceKm { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int ParticipantCount { get; set; }
        public int Status { get; set; } // 0: Draft, 1: Active, ...
    }

    public class UserChallengeProgressDto
    {
        public int Id { get; set; } // Id của bảng Participant
        public int ChallengeId { get; set; }

        // Thông tin lồng của Challenge để hiển thị UI
        public ChallengeDto Challenge { get; set; } = null!;
        public double CompletedDistanceKm { get; set; }
        public double ProgressPercent { get; set; } // Tính toán sẵn %
        public int Status { get; set; } // 0: InProgress, 1: Completed...
        public bool RewardClaimed { get; set; }
    }
}