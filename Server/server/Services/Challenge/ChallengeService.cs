using AutoMapper;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using server.Models;
using server.Services.Interfaces;

namespace server.Services.Implements;

public class ChallengeService : IChallengeService
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<AppUser> _userManager;
    private readonly IMapper _mapper;
    private readonly IConfiguration _configuration;

    public ChallengeService(
        ApplicationDbContext context,
        UserManager<AppUser> userManager,
        IMapper mapper,
        IConfiguration configuration)
    {
        _context = context;
        _userManager = userManager;
        _mapper = mapper;
        _configuration = configuration;
    }

    public async Task<List<Challenge>> GetChallenges()
    {
        var challenges = await _context.Challenges
            .Include(c => c.Participants)
            .ToListAsync();

        return challenges;
    }
}