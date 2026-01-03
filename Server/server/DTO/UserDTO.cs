namespace server.DTO
{
    public class UserDTO
    {
        public class RegisterDto
        {
            public string UserName { get; set; }
            public string Email { get; set; }
            public string Password { get; set; }
            public double HeightCm { get; set; }
            public double WeightKg { get; set; }
        }

        public class DecodedToken
        {
            public string UserId { get; set; }
            public string Name { get; set; }
            public List<string> Roles { get; set; }
            public string Email { get; set; }
        }
    }
}
