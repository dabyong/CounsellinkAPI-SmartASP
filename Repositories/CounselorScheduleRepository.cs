using System.Data;
using CounselLink.API.Data;
using CounselLink.API.DTOs;
using Dapper;

namespace CounselLink.API.Repositories;

public sealed class CounselorScheduleRepository : ICounselorScheduleRepository
{
    private readonly IDbConnectionFactory _factory;

    public CounselorScheduleRepository(IDbConnectionFactory factory) => _factory = factory;

    public async Task<IEnumerable<CounselorAvailabilitySlotDto>> GetAvailabilityAsync(
        string employeeId, DateTime startDate, DateTime endDate)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@EmployeeID", employeeId, DbType.AnsiString, size: 7);
        parameters.Add("@StartDate", startDate.Date, DbType.Date);
        parameters.Add("@EndDate", endDate.Date, DbType.Date);

        return (await connection.QueryAsync<CounselorAvailabilitySlotDto>(
            "dbo.spCounselorAvailability_Select", parameters,
            commandType: CommandType.StoredProcedure)).ToList();
    }
}
