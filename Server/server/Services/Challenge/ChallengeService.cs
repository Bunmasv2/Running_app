using AutoMapper;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using server.Configs;
using server.DTO;
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

    public async Task<List<challengesDTO.ChallengeDto>> GetAllActiveChallenges()
    {
        // Lấy các challenge đang Active (Status = 1)
        var challenges = await _context.Challenges
            .Where(c => c.Status == ChallengeStatus.Active)
            .OrderByDescending(c => c.StartDate)
            .ToListAsync();

        // Map sang DTO
        return challenges.Select(c => new challengesDTO.ChallengeDto
        {
            Id = c.Id,
            Title = c.Title,
            Description = c.Description,
            ImageUrl = c.ImageUrl,
            TargetDistanceKm = c.TargetDistanceKm,
            StartDate = c.StartDate,
            EndDate = c.EndDate,
            ParticipantCount = c.ParticipantCount,
            Status = (int)c.Status
        }).ToList();
    }

    public async Task<List<challengesDTO.UserChallengeProgressDto>> GetMyChallenges(string userId)
    {
        // Lấy bảng trung gian (Participant) kèm thông tin Challenge
        var participants = await _context.ChallengeParticipants
            .Include(cp => cp.Challenge)
            .Where(cp => cp.UserId == userId)
            .OrderByDescending(cp => cp.JoinedAt)
            .ToListAsync();

        return participants.Select(p => new challengesDTO.UserChallengeProgressDto
        {
            Id = p.Id,
            ChallengeId = p.ChallengeId,
            CompletedDistanceKm = p.CompletedDistanceKm,
            Status = (int)p.Status,
            RewardClaimed = p.RewardClaimed,

            // Tính toán % tiến độ tại đây để FE đỡ phải tính
            ProgressPercent = (p.Challenge.TargetDistanceKm > 0)
                ? (p.CompletedDistanceKm / p.Challenge.TargetDistanceKm) * 100
                : 0,

            // Map lồng ChallengeDto
            Challenge = new challengesDTO.ChallengeDto
            {
                Id = p.Challenge.Id,
                Title = p.Challenge.Title,
                Description = p.Challenge.Description,
                ImageUrl = p.Challenge.ImageUrl,
                TargetDistanceKm = p.Challenge.TargetDistanceKm,
                StartDate = p.Challenge.StartDate,
                EndDate = p.Challenge.EndDate,
                Status = (int)p.Challenge.Status
            }
        }).ToList();
    }

    public async Task<bool> JoinChallenge(string userId, int challengeId)
    {
        // 1. Kiểm tra Challenge có tồn tại và đang mở không
        var challenge = await _context.Challenges.FindAsync(challengeId);

        if (challenge == null || challenge.Status != ChallengeStatus.Active)
        {
            return false; // Không tìm thấy hoặc đã đóng
        }

        // 2. Kiểm tra xem User đã tham gia chưa
        var existing = await _context.ChallengeParticipants
            .FirstOrDefaultAsync(cp => cp.UserId == userId && cp.ChallengeId == challengeId);

        if (existing != null)
        {
            return false; // Đã tham gia rồi
        }

        // 3. Tạo mới Participant
        var newParticipant = new ChallengeParticipant
        {
            UserId = userId,
            ChallengeId = challengeId,
            JoinedAt = DateTime.UtcNow,
            Status = ParticipantStatus.InProgress,
            CompletedDistanceKm = 0,
            ProgressPercent = 0
        };

        _context.ChallengeParticipants.Add(newParticipant);

        // 4. Tăng số lượng người tham gia trong bảng Challenge
        challenge.ParticipantCount += 1;
        _context.Challenges.Update(challenge);

        // 5. Cập nhật "Thử thách hiện tại" cho User (nếu cần Logic này)
        // var user = await _context.Users.FindAsync(userId);
        // if (user != null) user.CurrentActiveChallengeId = challengeId;

        return await _context.SaveChangesAsync() > 0;
    }
}