using System.Data;
using CounselLink.API.Data;
using CounselLink.API.DTOs;
using Dapper;

namespace CounselLink.API.Repositories;

public sealed class ReportRepository : IReportRepository
{
    private readonly IDbConnectionFactory _factory;

    public ReportRepository(IDbConnectionFactory factory) => _factory = factory;

    public Task<IEnumerable<dynamic>> CompletedAppointmentsAsync(MonthlyReportFilterDto filter)
        => MonthlyAsync("dbo.sp_GenerateMonthlyReport_CompletedAppointments", filter, includeEmployeeId: true);

    public Task<IEnumerable<dynamic>> ConcernFrequencyAsync(MonthlyReportFilterDto filter)
        => MonthlyAsync("dbo.sp_GenerateMonthlyReport_ConcernFrequency", filter);

    public Task<IEnumerable<dynamic>> SessionModesAsync(MonthlyReportFilterDto filter)
        => MonthlyAsync("dbo.sp_GenerateMonthlyReport_SessionModes", filter);

    public Task<IEnumerable<dynamic>> ExternalReferralsAsync(MonthlyReportFilterDto filter)
        => MonthlyAsync("dbo.sp_GenerateMonthlyReport_ExternalReferrals", filter);

    public async Task<IEnumerable<dynamic>> MasterlistAsync()
    {
        using var connection = _factory.CreateConnection();
        return await connection.QueryAsync(
            "dbo.sp_GetAppointmentMasterlist", commandType: CommandType.StoredProcedure);
    }

    private async Task<IEnumerable<dynamic>> MonthlyAsync(
        string storedProcedure, MonthlyReportFilterDto filter, bool includeEmployeeId = false)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SchoolYearStart", filter.SchoolYearStart);
        parameters.Add("@ReportMonth", filter.ReportMonth);

        // Only the CompletedAppointments procedure accepts @EmployeeID.
        if (includeEmployeeId)
            parameters.Add("@EmployeeID", filter.EmployeeID);

        return await connection.QueryAsync(
            storedProcedure, parameters, commandType: CommandType.StoredProcedure);
    }
}
