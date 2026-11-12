using System.Data;
using CounselLink.API.Data;
using CounselLink.API.DTOs;
using Dapper;

namespace CounselLink.API.Repositories;

/// <summary>
/// Dapper implementation for appointment CRUD and lifecycle stored procedures.
/// </summary>
public sealed class AppointmentRepository : IAppointmentRepository
{
    private readonly IDbConnectionFactory _factory;

    public AppointmentRepository(IDbConnectionFactory factory) => _factory = factory;

    public async Task<IEnumerable<dynamic>> SelectAsync(AppointmentFilterDto filter)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchAppointmentID", filter.SearchAppointmentID);
        parameters.Add("@SearchIDNumber", filter.SearchIDNumber);
        parameters.Add("@SearchGradeOrYear", filter.SearchGradeOrYear);
        parameters.Add("@SearchProgram", filter.SearchProgram);
        parameters.Add("@SearchEmployeeID", filter.SearchEmployeeID);
        parameters.Add("@SearchStartDate", filter.SearchStartDate);
        parameters.Add("@SearchEndDate", filter.SearchEndDate);
        parameters.Add("@SearchAppointmentTime", filter.SearchAppointmentTime);
        parameters.Add("@SearchAppointmentTypeID", filter.SearchAppointmentTypeID);
        parameters.Add("@SearchConcernTypeID", filter.SearchConcernTypeID);
        parameters.Add("@SearchStatusID", filter.SearchStatusID);
        parameters.Add("@SearchAttendanceID", filter.SearchAttendanceID);
        parameters.Add("@SearchReferredBy", filter.SearchReferredBy);
        parameters.Add("@SearchReferralStart", filter.SearchReferralStart);
        parameters.Add("@SearchReferralEnd", filter.SearchReferralEnd);

        return await connection.QueryAsync(
            "dbo.spAppointment_Select",
            parameters,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<WriteResult> InsertAsync(CreateAppointmentDto dto)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@IDNumber", dto.IDNumber);
        parameters.Add("@GradeOrYearLevel", dto.GradeOrYearLevel);
        parameters.Add("@ProgramOrCourse", dto.ProgramOrCourse);
        parameters.Add("@EmployeeID", dto.EmployeeID);
        parameters.Add("@AppointmentDate", dto.AppointmentDate);
        parameters.Add("@AppointmentTime", dto.AppointmentTime);
        parameters.Add("@AppointmentTypeID", dto.AppointmentTypeID);
        // Included by the non-destructive spAppointment_Insert migration.
        // Must be installed in the database before deploying this repository change.
        parameters.Add("@ConcernTypeID", dto.ConcernTypeID, DbType.Int32);
        // Student-created appointments always start Requested (1), attendance Pending (1).
        // Never trust caller-supplied lifecycle status IDs during creation.
        parameters.Add("@AppointmentStatusID", 1, DbType.Int32);
        parameters.Add("@AttendanceStatusID", 1, DbType.Int32);
        parameters.Add("@ConcernDescription", dto.ConcernDescription);
        parameters.Add("@ReferredBy", dto.ReferredBy);
        parameters.Add("@ReferralDate", dto.ReferralDate);
        parameters.AddStandardOutputs();

        await connection.ExecuteAsync(
            "dbo.spAppointment_Insert",
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadWriteResult();
    }

    public async Task<WriteResult> UpdateAsync(int id, UpdateAppointmentDto dto)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@AppointmentID", id);
        parameters.Add("@AppointmentStatusID", dto.AppointmentStatusID);
        parameters.Add("@AttendanceStatusID", dto.AttendanceStatusID);
        parameters.Add("@RescheduleNote", dto.RescheduleNote);
        parameters.Add("@ConcernDescription", dto.ConcernDescription);
        parameters.Add("@ConcernTypeID", dto.ConcernTypeID, DbType.Int32);
        // spAppointment_Update declares only @Message OUTPUT (no @NewID).
        parameters.AddMessageOutput();

        await connection.ExecuteAsync(
            "dbo.spAppointment_Update",
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadMessageResult();
    }

    public async Task<WriteResult> DeleteAsync(int id)
    {
        using var connection = _factory.CreateConnection();
        // spAppointment_Delete binds only @AppointmentID and @Message (OUTPUT).
        var parameters = new DynamicParameters();
        parameters.Add("@AppointmentID", id, DbType.Int32);
        parameters.Add("@Message", dbType: DbType.String, direction: ParameterDirection.Output, size: 255);

        await connection.ExecuteAsync(
            "dbo.spAppointment_Delete",
            parameters,
            commandType: CommandType.StoredProcedure);

        return new WriteResult { Message = parameters.Get<string>("@Message") };
    }

    public async Task<WriteResult> ConfirmAsync(int id, ConfirmAppointmentDto dto)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@AppointmentID", id);
        parameters.Add("@EmployeeID", dto.EmployeeID);
        parameters.Add("@ConfirmedDate", dto.ConfirmedDate);
        parameters.Add("@ConfirmedTime", dto.ConfirmedTime);
        // spConfirmAppointment declares only @Message OUTPUT (no @NewID).
        parameters.Add("@Message", dbType: DbType.String, direction: ParameterDirection.Output, size: 255);

        await connection.ExecuteAsync(
            "dbo.spConfirmAppointment",
            parameters,
            commandType: CommandType.StoredProcedure);

        return new WriteResult { Message = parameters.Get<string>("@Message") };
    }

    public async Task<WriteResult> StudentConfirmAsync(int id, string idNumber)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@AppointmentID", id, DbType.Int32);
        parameters.Add("@IDNumber", idNumber);
        parameters.AddMessageOutput();

        await connection.ExecuteAsync(
            "dbo.spStudentConfirmAppointment",
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadMessageResult();
    }

    public async Task<WriteResult> CompleteAsync(int id)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@AppointmentID", id, DbType.Int32);
        parameters.AddMessageOutput();

        await connection.ExecuteAsync(
            "dbo.spCompleteAppointment",
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadMessageResult();
    }

    public async Task<WriteResult> RescheduleAsync(int id, RescheduleDto dto)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        // spRescheduleAppointment: @AppointmentID, @NewStartDate, @NewEndDate, @RescheduleNote, @Message.
        parameters.Add("@AppointmentID", id, DbType.Int32);
        parameters.Add("@NewStartDate", dto.NewStartDate);
        parameters.Add("@NewEndDate", dto.NewEndDate);
        parameters.Add("@RescheduleNote", dto.RescheduleNote);
        parameters.AddMessageOutput();

        await connection.ExecuteAsync(
            "dbo.spRescheduleAppointment",
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadMessageResult();
    }

    public async Task<WriteResult> AcceptRescheduleAsync(int id, string idNumber)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@AppointmentID", id, DbType.Int32);
        parameters.Add("@IDNumber", idNumber);
        parameters.AddMessageOutput();

        await connection.ExecuteAsync(
            "dbo.spStudentAcceptReschedule",
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadMessageResult();
    }

    public async Task<WriteResult> SetNoShowAsync(int id)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@AppointmentID", id, DbType.Int32);
        parameters.AddMessageOutput();

        await connection.ExecuteAsync(
            "dbo.spSetAppointmentNoShow",
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadMessageResult();
    }

    public async Task<IEnumerable<dynamic>> GetRescheduleHistoryAsync(string? employeeId)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@EmployeeID", employeeId);

        return await connection.QueryAsync(
            "dbo.spGetCounselorRescheduleHistory",
            parameters,
            commandType: CommandType.StoredProcedure);
    }

}
