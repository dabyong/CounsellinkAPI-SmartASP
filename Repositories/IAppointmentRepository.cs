using CounselLink.API.DTOs;

namespace CounselLink.API.Repositories;

public interface IAppointmentRepository
{
    Task<IEnumerable<dynamic>> SelectAsync(AppointmentFilterDto filter);
    Task<WriteResult> InsertAsync(CreateAppointmentDto dto);
    Task<WriteResult> UpdateAsync(int id, UpdateAppointmentDto dto);
    Task<WriteResult> DeleteAsync(int id);

    Task<WriteResult> ConfirmAsync(int id, ConfirmAppointmentDto dto);
    Task<WriteResult> StudentConfirmAsync(int id, string idNumber);
    Task<WriteResult> CompleteAsync(int id);
    Task<WriteResult> RescheduleAsync(int id, RescheduleDto dto);
    Task<WriteResult> AcceptRescheduleAsync(int id, string idNumber);
    Task<WriteResult> SetNoShowAsync(int id);

    Task<IEnumerable<dynamic>> GetRescheduleHistoryAsync(string? employeeId);
}
