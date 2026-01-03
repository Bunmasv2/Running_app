using Microsoft.EntityFrameworkCore;
using server.DTO;
using server.Models;
using server.Services.Interfaces;

namespace server.Services.Implements;

public class RunService : IRunService
{
    private readonly ApplicationDbContext _context;

    // Inject DbContext để thao tác với SQL
    public RunService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<RunSessionDto.RunResponseDto> ProcessRunSessionAsync(string userId, RunSessionDto.RunCreateDto dto)
    {
        // 1. Tìm User để lấy cân nặng (Weight)
        AppUser? user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null)
        {
            throw new Exception("User not found"); // Controller sẽ bắt lỗi này
        }

        // 2. Logic tính Calo: (Cân nặng x Distance x 1.036)
        double calories = user.WeightKg * dto.DistanceKm * 1.036;

        // 3. Map từ DTO sang Entity để lưu xuống DB
        RunSession session = new RunSession
        {
            UserId = userId,
            DistanceKm = dto.DistanceKm,
            DurationSeconds = dto.DurationSeconds,
            StartTime = dto.StartTime,
            EndTime = dto.EndTime,
            RouteJson = dto.RouteJson,
            CaloriesBurned = calories
        };

        // 4. Lưu vào Database
        _context.RunSessions.Add(session);
        await _context.SaveChangesAsync();

        // 5. Trả về kết quả cho Controller
        return new RunSessionDto.RunResponseDto
        {
            Id = session.Id,
            DistanceKm = session.DistanceKm,
            DurationSeconds = session.DurationSeconds,
            CaloriesBurned = calories,
            StartTime = session.StartTime,
            RouteJson = session.RouteJson,
            Message = "Lưu thành công!"
        };
    }
}