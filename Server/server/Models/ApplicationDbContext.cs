using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace server.Models;


public class ApplicationDbContext : IdentityDbContext<AppUser>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<RunSession> RunSessions { get; set; }
    public DbSet<DailyGoal> DailyGoals { get; set; }
    public DbSet<Challenge> Challenges { get; set; }
    public DbSet<ChallengeParticipant> ChallengeParticipants { get; set; }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        // 1. Cấu hình quan hệ: AppUser (Creator) -> Challenge
        // Khi xóa User, KHÔNG xóa Challenge do họ tạo (để giữ lịch sử cho người khác) hoặc set Null
        builder.Entity<Challenge>()
            .HasOne(c => c.Creator)
            .WithMany(u => u.CreatedChallenges)
            .HasForeignKey(c => c.CreatorId)
            .OnDelete(DeleteBehavior.Restrict); // Dùng Restrict để an toàn

        // 2. Cấu hình quan hệ: AppUser -> CurrentActiveChallenge
        // Quan hệ 1-Nhiều (hoặc 1-0..1) tùy chỉnh
        builder.Entity<AppUser>()
            .HasOne(u => u.CurrentActiveChallenge)
            .WithMany() // Challenge không cần list "CurrentUsers", chỉ cần User trỏ đến là đủ
            .HasForeignKey(u => u.CurrentActiveChallengeId)
            .OnDelete(DeleteBehavior.SetNull); // Nếu Challenge bị xóa, User trở thành rảnh (null)

        // 3. Cấu hình bảng trung gian ChallengeParticipant (Tránh xoá nhầm)
        builder.Entity<ChallengeParticipant>()
            .HasOne(cp => cp.Challenge)
            .WithMany(c => c.Participants)
            .HasForeignKey(cp => cp.ChallengeId)
            .OnDelete(DeleteBehavior.Cascade); // Xóa Challenge -> Xóa luôn danh sách tham gia

        builder.Entity<ChallengeParticipant>()
            .HasOne(cp => cp.User)
            .WithMany(u => u.ChallengeHistory)
            .HasForeignKey(cp => cp.UserId)
            .OnDelete(DeleteBehavior.Cascade); // Xóa User -> Xóa lịch sử tham gia

        builder.Entity<RunSession>()
            .HasOne(rs => rs.DailyGoal)
            .WithMany()
            .HasForeignKey(rs => rs.DailyGoalId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}