using System.Data;
using CounselLink.API.Data;
using CounselLink.API.DTOs;
using Dapper;

namespace CounselLink.API.Repositories;

/// <summary>Dapper implementation for spCounselor_* stored procedures.</summary>
public sealed class CounselorRepository : ICounselorRepository
{
    private readonly IDbConnectionFactory _factory;

    public CounselorRepository(IDbConnectionFactory factory) => _factory = factory;

    public async Task<IEnumerable<dynamic>> SelectAsync()
    {
        using var connection = _factory.CreateConnection();
        return await connection.QueryAsync(
            "dbo.spCounselor_Select",
            commandType: CommandType.StoredProcedure);
    }

    public async Task<WriteResult> InsertAsync(CounselorDto dto)
    {
        using var connection = _factory.CreateConnection();
        var parameters = BuildParameters(dto);
        parameters.AddMessageOutput();

        await connection.ExecuteAsync(
            "dbo.spCounselor_Insert",
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadMessageResult();
    }

    public async Task<WriteResult> UpdateAsync(CounselorDto dto)
    {
        using var connection = _factory.CreateConnection();
        var parameters = BuildParameters(dto);
        parameters.AddMessageOutput();

        await connection.ExecuteAsync(
            "dbo.spCounselor_Update",
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadMessageResult();
    }

    public async Task<WriteResult> DeleteAsync(string employeeId)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@EmployeeID", employeeId);
        parameters.AddMessageOutput();

        await connection.ExecuteAsync(
            "dbo.spCounselor_Delete",
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadMessageResult();
    }

    // spCounselor_Insert / _Update only declare these columns + @Message.
    private static DynamicParameters BuildParameters(CounselorDto dto)
    {
        var parameters = new DynamicParameters();
        parameters.Add("@EmployeeID", dto.EmployeeID);
        parameters.Add("@FirstName", dto.FirstName);
        parameters.Add("@LastName", dto.LastName);
        parameters.Add("@MiddleName", dto.MiddleName);
        return parameters;
    }
}

/// <summary>Dapper implementation for spCounselorAssignment_* stored procedures.</summary>
public sealed class CounselorAssignmentRepository : ICounselorAssignmentRepository
{
    private readonly IDbConnectionFactory _factory;

    public CounselorAssignmentRepository(IDbConnectionFactory factory) => _factory = factory;

    public async Task<IEnumerable<dynamic>> SelectAsync()
    {
        using var connection = _factory.CreateConnection();
        return await connection.QueryAsync(
            "dbo.spCounselorAssignment_Select",
            commandType: CommandType.StoredProcedure);
    }

    public async Task<WriteResult> InsertAsync(CounselorAssignmentDto dto)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@EmployeeID", dto.EmployeeID);
        parameters.Add("@DepartmentID", dto.DepartmentID);
        parameters.Add("@ProgramID", dto.ProgramID);
        parameters.Add("@YearOrGradeLevel", dto.YearOrGradeLevel);
        parameters.Add("@SchoolYear", dto.SchoolYear);
        parameters.AddStandardOutputs();

        await connection.ExecuteAsync(
            "dbo.spCounselorAssignment_Insert",
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadWriteResult();
    }
}
