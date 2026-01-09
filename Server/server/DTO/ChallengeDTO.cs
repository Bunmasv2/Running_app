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
    }
}