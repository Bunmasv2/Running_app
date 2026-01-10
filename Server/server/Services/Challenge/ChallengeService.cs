using AutoMapper;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using server.Configs;
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

    public async Task<Challenge> FindChallengeById(int challengeId)
    {
        return await _context.Challenges.FirstOrDefaultAsync(c => c.Id == challengeId);
    }

    public async Task<List<Challenge>> GetChallenges()
    {
        var challenges = await _context.Challenges
            .Include(c => c.Participants)
            .ToListAsync();

        return challenges;
    }

    public async Task<int> JoinChallenge(int challengeId, string userId)
    {
        ChallengeParticipant isJoined = await _context.ChallengeParticipants
            .FirstOrDefaultAsync(cp => cp.UserId == userId && cp.ChallengeId == challengeId);

        if (isJoined.UserId == userId)
        {
            throw new ErrorException(400, "You are participating in this challenge");
        }

        ChallengeParticipant challengeParticipant = new ChallengeParticipant
        {
            ChallengeId = challengeId,
            UserId = userId,
        };

        await _context.ChallengeParticipants.AddAsync(challengeParticipant);
        return await _context.SaveChangesAsync();
    }
}