using System.Data;
using CounselLink.API.Data;
using CounselLink.API.DTOs;
using Dapper;

namespace CounselLink.API.Repositories;

/// <summary>
/// Dapper implementation for clinical sessions, assessments, and follow-ups.
/// Parameter names match the CounselLinkDB stored-procedure signatures exactly.
/// </summary>
public sealed class ClinicalRepository : IClinicalRepository
{
    private readonly IDbConnectionFactory _factory;

    public ClinicalRepository(IDbConnectionFactory factory) => _factory = factory;

    public async Task<WriteResult> InsertSessionAsync(CounselingSessionDto dto)
    {
        using var connection = _factory.CreateConnection();
        // spCounselingSession_Insert: @AppointmentID, @IDNumber, @GradeOrYearLevel,
        // @EmployeeID, @ProgramOrCourse, @AppointmentStatusID(=4), @SessionDate,
        // @SessionTypeID, @GeneralNotes, @SessionStartTime, @SessionEndTime,
        // @NewID OUT, @Message OUT. (No @Mode / @AttendanceStatusID.)
        var parameters = new DynamicParameters();
        parameters.Add("@AppointmentID", dto.AppointmentID);
        parameters.Add("@IDNumber", dto.IDNumber);
        parameters.Add("@EmployeeID", dto.EmployeeID);
        parameters.Add("@SessionDate", dto.SessionDate);
        parameters.Add("@SessionTypeID", dto.SessionTypeID);
        parameters.Add("@GeneralNotes", dto.GeneralNotes);
        parameters.Add("@SessionStartTime", dto.SessionStartTime);
        parameters.Add("@SessionEndTime", dto.SessionEndTime);
        parameters.AddStandardOutputs();

        await connection.ExecuteAsync(
            "dbo.spCounselingSession_Insert",
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadWriteResult();
    }

    public async Task<IEnumerable<dynamic>> SelectSessionsAsync(CounselingSessionFilterDto filter)
    {
        using var connection = _factory.CreateConnection();
        // spCounselingSession_Select: @SearchSessionID, @SearchAppointmentID,
        // @SearchIDNumber, @SearchEmployeeID (all optional).
        var parameters = new DynamicParameters();
        parameters.Add("@SearchAppointmentID", filter.SearchAppointmentID);
        parameters.Add("@SearchIDNumber", filter.SearchIDNumber);
        parameters.Add("@SearchEmployeeID", filter.SearchEmployeeID);

        return await connection.QueryAsync(
            "dbo.spCounselingSession_Select",
            parameters,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<WriteResult> InsertAssessmentAsync(StudentAssessmentDto dto)
    {
        using var connection = _factory.CreateConnection();
        // spStudentAssessment_Insert: @SessionID, @ProgressNotes, @IsFollowUpNeeded,
        // @IsForMonitoring, @SpecialistReferralID, @NewID OUT, @Message OUT.
        var parameters = new DynamicParameters();
        parameters.Add("@SessionID", dto.SessionID);
        parameters.Add("@ProgressNotes", dto.ProgressNotes);
        parameters.Add("@IsFollowUpNeeded", dto.IsFollowUpNeeded);
        parameters.Add("@IsForMonitoring", dto.IsForMonitoring);
        parameters.Add("@SpecialistReferralID", dto.SpecialistReferralID);
        parameters.AddStandardOutputs();

        await connection.ExecuteAsync(
            "dbo.spStudentAssessment_Insert",
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadWriteResult();
    }

    public async Task<IEnumerable<dynamic>> SelectAssessmentsAsync(StudentAssessmentFilterDto filter)
    {
        using var connection = _factory.CreateConnection();
        // spStudentAssessment_Select: @SearchAssessmentID, @SearchSessionID.
        var parameters = new DynamicParameters();
        parameters.Add("@SearchAssessmentID", filter.SearchAssessmentID);
        parameters.Add("@SearchSessionID", filter.SearchSessionID);

        return await connection.QueryAsync(
            "dbo.spStudentAssessment_Select",
            parameters,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<WriteResult> InsertFollowUpAsync(SessionFollowUpDto dto)
    {
        using var connection = _factory.CreateConnection();
        // spSessionFollowUp_Insert: @AssessmentID, @TargetDate, @FollowUpStatus(='Pending'),
        // @ActionRequired, @ResolutionNotes, @NewID OUT, @Message OUT.
        var parameters = new DynamicParameters();
        parameters.Add("@AssessmentID", dto.AssessmentID);
        parameters.Add("@TargetDate", dto.TargetDate);
        parameters.Add("@FollowUpStatus", dto.FollowUpStatus);
        parameters.Add("@ActionRequired", dto.ActionRequired);
        parameters.Add("@ResolutionNotes", dto.ResolutionNotes);
        parameters.AddStandardOutputs();

        await connection.ExecuteAsync(
            "dbo.spSessionFollowUp_Insert",
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadWriteResult();
    }

    public async Task<IEnumerable<dynamic>> SelectFollowUpsAsync(SessionFollowUpFilterDto filter)
    {
        using var connection = _factory.CreateConnection();
        // spSessionFollowUp_Select: @SearchFollowUpID, @SearchAssessmentID, @SearchStatus.
        var parameters = new DynamicParameters();
        parameters.Add("@SearchAssessmentID", filter.SearchAssessmentID);
        parameters.Add("@SearchStatus", filter.SearchStatus);

        return await connection.QueryAsync(
            "dbo.spSessionFollowUp_Select",
            parameters,
            commandType: CommandType.StoredProcedure);
    }
}
