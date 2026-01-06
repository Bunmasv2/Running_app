using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using server.config;
using server.Configs;
using server.Models;
using server.Services;
using server.Services.Implements;
using server.Services.Interfaces;

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
builder.Services.AddIdentity<AppUser, IdentityRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders();

builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IRunService, RunService>();
// builder.Services.AddScoped<IRun, RunService>();
builder.Services.AddScoped<IDailyGoalService, DailyGoalService>();
// Add services to the container.
builder.Services.AddAutoMapper(typeof(AutoMapperConfig).Assembly);
builder.Services.AddControllers();
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddGoogleAuth(builder.Configuration)
.AddJWT(builder.Configuration);
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
    ForwardedHeaders = ForwardedHeaders.XForwardedProto
});

//app.UseHttpsRedirection();

app.UseMiddleware<ErrorHandlingMiddleware>();

app.UseRouting();

app.UseCors("_allowSpecificOrigins");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();