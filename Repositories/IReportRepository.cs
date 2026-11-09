using CounselLink.API.DTOs;

namespace CounselLink.API.Repositories;

public interface IReportRepository
{
    Task<IEnumerable<dynamic>> CompletedAppointmentsAsync(MonthlyReportFilterDto filter);
    Task<IEnumerable<dynamic>> ConcernFrequencyAsync(MonthlyReportFilterDto filter);
    Task<IEnumerable<dynamic>> SessionModesAsync(MonthlyReportFilterDto filter);
    Task<IEnumerable<dynamic>> ExternalReferralsAsync(MonthlyReportFilterDto filter);
    Task<IEnumerable<dynamic>> MasterlistAsync();
}
