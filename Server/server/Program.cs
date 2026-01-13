using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using server.config;
using server.Services;
using server.Services.Interfaces;
using server.Configs;
using server.Models;
using server.Services.Implements;

var builder = WebApplication.CreateBuilder(args);

//MySQL Connection
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseMySql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        ServerVersion.AutoDetect(
            builder.Configuration.GetConnectionString("DefaultConnection")
        )
    )
);

// // Đăng ký Identity
builder.Services.AddCloudinary(builder.Configuration);
builder.Services.AddIdentity<AppUser, IdentityRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders();

builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IRunService, RunService>();
builder.Services.AddScoped<IChallengeService, ChallengeService>();
builder.Services.AddScoped<IDailyGoalService, DailyGoalService>();
builder.Services.AddScoped<IGoalService, GoalService>();
builder.Services.AddScoped<IChallengeService, ChallengeService>();
// Add services to the container.
builder.Services.AddAutoMapper(typeof(AutoMapperConfig).Assembly);
builder.Services.AddControllers();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJWT(builder.Configuration)          // ⬅️ JWT ƯU TIÊN
    .AddGoogleAuth(builder.Configuration);  // ⬅️ Sau cùng

builder.Services.AddAuthorization();

// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders =
        ForwardedHeaders.XForwardedFor |
        ForwardedHeaders.XForwardedProto
});

//app.UseHttpsRedirection();

app.UseMiddleware<ErrorHandlingMiddleware>();

app.UseRouting();

app.UseCors("_allowSpecificOrigins");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();