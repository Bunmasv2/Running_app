using server.DTO;

namespace server.Services.Interfaces;

public interface IRun
{
    // Hàm nhận vào UserId và DTO, trả về kết quả DTO
    Task<RunSessionDto.RunResponseDto> ProcessRunSessionAsync(string userId, RunSessionDto.RunCreateDto runDto);
    
    // Bạn có thể thêm các hàm khác sau này, ví dụ:
    // Task<List<RunResponseDto>> GetHistoryAsync(string userId);
}