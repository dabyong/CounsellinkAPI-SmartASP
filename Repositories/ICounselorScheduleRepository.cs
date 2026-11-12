using CounselLink.API.DTOs;

namespace CounselLink.API.Repositories;

public interface ICounselorScheduleRepository
{
    Task<IEnumerable<CounselorAvailabilitySlotDto>> GetAvailabilityAsync(
        string employeeId, DateTime startDate, DateTime endDate);
}
