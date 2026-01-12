using System.Data;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;
using server.DTO;
using server.Models;
using server.Services;
using server.Util;

namespace server.Configs
{
    public static class JWTConfigs
    {
        public static AuthenticationBuilder AddJWT(this AuthenticationBuilder builder, IConfiguration configuration)
        {
            return builder.AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = configuration["JWT:ISSUSER"],
                    ValidAudience = configuration["JWT:AUDIENCE"],
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(configuration["JWT:KEY"])),
                    // ClockSkew = TimeSpan.FromMinutes(5)
                    ClockSkew = TimeSpan.Zero
                };

                options.Events = new JwtBearerEvents
                {
                    OnMessageReceived = context =>
                    {
                        // 1. Lấy token từ Header (Cách chuẩn cho Flutter/Mobile App)
                        string authorization = context.Request.Headers["Authorization"];

                        // Nếu Header có dạng "Bearer xxxxx..."
                        if (!string.IsNullOrEmpty(authorization) && authorization.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
                        {
                            // Cắt bỏ chữ "Bearer " để lấy token
                            context.Token = authorization.Substring("Bearer ".Length).Trim();
                            Console.WriteLine($"✅ LOG: Tìm thấy Token trong Header: {context.Token.Substring(0, 10)}...");
                        }
                        // 2. Nếu không có trong Header, mới tìm trong Cookie (Fallback cho Web)
                        else if (context.Request.Cookies.ContainsKey("token"))
                        {
                            context.Token = context.Request.Cookies["token"];
                            Console.WriteLine($"✅ LOG: Tìm thấy Token trong Cookie: {context.Token?.Substring(0, 10)}...");
                        }
                        else
                        {
                            Console.WriteLine("⚠️ LOG: Không tìm thấy Token trong cả Header và Cookie");
                        }

                        return Task.CompletedTask;
                    },
                    OnTokenValidated = async context =>
                    {
                        Console.WriteLine("✅ OnTokenValidated triggered");
                    },
                    OnForbidden = async context =>
                    {
                        Console.WriteLine("⛔ OnForbidden triggered");
                        context.Response.StatusCode = 403;
                        context.Response.ContentType = "application/json";

                        var message = "Only members have access!";
                        var response = new { ErrorMessage = message };

                        if (context.HttpContext.Items.TryGetValue("AuthorizeErrorMessage", out var messageObj))
                        {
                            message = messageObj?.ToString();
                            response = new { ErrorMessage = message };
                        }

                        await context.Response.WriteAsync(JsonSerializer.Serialize(response));
                    },
                    OnChallenge = async context =>
                    {
                        Console.WriteLine("⚠️ OnChallenge triggered");
                        context.HandleResponse();
                        context.Response.StatusCode = 401;
                        context.Response.ContentType = "application/json";

                        var token = context.Request.Cookies["token"];
                        var errorMessage = string.IsNullOrEmpty(token) ? "Please login to continue!" : "Your session has expired. Please log in again.";

                        await context.Response.WriteAsync(JsonSerializer.Serialize(new { ErrorMessage = errorMessage }));
                    },
                };
            });
        }
    }
}