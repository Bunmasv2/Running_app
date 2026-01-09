using AutoMapper;
using server.DTO;
using server.Models;

namespace server.config
{
    public class AutoMapperConfig : Profile
    {
        public AutoMapperConfig()
        {
            CreateMap<AppUser, UserDTO.Profile>()
                .ForMember(dest => dest.AvatarUrl, opt => opt.MapFrom(
                    src => src.AvatarUrl == null ? null : $"{src.AvatarUrl}"
                ));

            CreateMap<Challenge, challengesDTO.Challenge>()
                .ForMember(dest => dest.TotalParticipants,
                    opt => opt.MapFrom(src => src.Participants.Count));
        }
    }
}