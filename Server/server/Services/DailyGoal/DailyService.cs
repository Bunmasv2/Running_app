using Microsoft.EntityFrameworkCore;
using server.DTO;
using server.Models;
using server.Services.Interfaces;

namespace server.Services.Implements;

public class DailyGoalService : IDailyGoalService
{
    private readonly ApplicationDbContext _context;

    // Inject DbContext để thao tác với SQL
    public DailyGoalService(ApplicationDbContext context)
    {
        _context = context;
    }

}