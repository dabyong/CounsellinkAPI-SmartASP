using System.Data;
using CounselLink.API.Data;
using Dapper;

namespace CounselLink.API.Repositories;

/// <summary>
/// Scoped SQL access to the five procedures installed by 01_INSTALL_SCOPE_SQL.sql.
/// This repository does not authenticate users. The controller must supply the
/// EmployeeID taken from the validated portal identity (never from query/body).
/// </summary>
public sealed class CounselorScopedRepository : ICounselorScopedRepository
{
    private readonly IDbConnectionFactory _factory;

    public CounselorScopedRepository(IDbConnectionFactory factory) => _factory = factory;

    public async Task<IReadOnlyList<CounselorScopeAssignment>> GetAssignmentsAsync(
        string employeeId, DateTime schoolYear)
    {
        using var connection = _factory.CreateConnection();
        var result = await connection.QueryAsync<CounselorScopeAssignment>(
            """
            SELECT EmployeeID, DepartmentID, ProgramID, YearOrGradeLevel, SchoolYear
            FROM dbo.CounselorAssignment
            WHERE EmployeeID = @EmployeeID AND SchoolYear = @SchoolYear
            ORDER BY DepartmentID, YearOrGradeLevel
            """,
            new { EmployeeID = employeeId, SchoolYear = schoolYear.Date });
        return result.ToList();
    }

    public Task<IEnumerable<dynamic>> GetAppointmentsAsync(
        string employeeId, DateTime schoolYear, string? studentId)
        => QueryScopedAsync(
            "dbo.spCounselorAppointments_SelectScoped", employeeId, schoolYear,
            includeStudentId: true, studentId: studentId);

    public Task<IEnumerable<dynamic>> GetSessionsAsync(string employeeId, DateTime schoolYear)
        => QueryScopedAsync("dbo.spCounselorSessions_SelectScoped", employeeId, schoolYear);

    public Task<IEnumerable<dynamic>> GetAssessmentsAsync(string employeeId, DateTime schoolYear)
        => QueryScopedAsync("dbo.spCounselorAssessments_SelectScoped", employeeId, schoolYear);

    public Task<IEnumerable<dynamic>> GetFollowUpsAsync(string employeeId, DateTime schoolYear)
        => QueryScopedAsync("dbo.spCounselorFollowUps_SelectScoped", employeeId, schoolYear);

    public Task<IEnumerable<dynamic>> GetMasterlistAsync(string employeeId, DateTime schoolYear)
        => QueryScopedAsync("dbo.spCounselorMasterlist_SelectScoped", employeeId, schoolYear);

    private async Task<IEnumerable<dynamic>> QueryScopedAsync(
        string procedure, string employeeId, DateTime schoolYear,
        bool includeStudentId = false, string? studentId = null)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@EmployeeID", employeeId, DbType.AnsiString, size: 7);
        parameters.Add("@SchoolYear", schoolYear.Date, DbType.Date);
        if (includeStudentId)
            parameters.Add("@SearchIDNumber", studentId, DbType.AnsiString, size: 7);

        return await connection.QueryAsync(
            procedure, parameters, commandType: CommandType.StoredProcedure);
    }
}
