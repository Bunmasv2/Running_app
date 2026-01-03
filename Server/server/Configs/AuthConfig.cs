using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using server.Models;
using server.Services.Interfaces;
using server.Util;

namespace server.Configs
{
    public static class AuthConfig
    {
        public static AuthenticationBuilder AddGoogleAuth(this AuthenticationBuilder builder, IConfiguration configuration)
        {
            builder.AddGoogle(options =>
            {
                options.ClientId = configuration["Authentication:Google:ClientId"];
                options.ClientSecret = configuration["Authentication:Google:ClientSecret"];
                options.CallbackPath = configuration["Authentication:Google:CallBack"];

                options.SaveTokens = true;
                options.AccessType = "offline";

                options.Events.OnTicketReceived = async context =>
                {
                    var email = context.Principal.FindFirstValue(ClaimTypes.Email);
                    var name = context.Principal.FindFirstValue(ClaimTypes.Name);

                    var userService = context.HttpContext.RequestServices.GetRequiredService<IUser>();
                    var userManager = context.HttpContext.RequestServices.GetRequiredService<UserManager<AppUser>>();
                    var db = context.HttpContext.RequestServices.GetRequiredService<ApplicationDbContext>();

                    var user = await userService.FindOrCreateUserByEmailAsync(email, name);
                    var roles = await userManager.GetRolesAsync(user);

                    var accessToken = JwtUtils.GenerateToken(user, roles, 1, configuration);

                    context.Response.Redirect("http://localhost:3000/project?success=true");
                    context.HandleResponse();
                };

                options.Events.OnRemoteFailure = context =>
                {
                    context.Response.Redirect("http://localhost:3000/project?success=false");
                    context.HandleResponse();
                    return System.Threading.Tasks.Task.CompletedTask;
                };
            });

            return builder;
        }
    }
}
