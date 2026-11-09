using CounselLink.API.DTOs;

namespace CounselLink.API.Repositories;

public interface IClinicalRepository
{
    Task<WriteResult> InsertSessionAsync(CounselingSessionDto dto);
    Task<IEnumerable<dynamic>> SelectSessionsAsync(CounselingSessionFilterDto filter);

    Task<WriteResult> InsertAssessmentAsync(StudentAssessmentDto dto);
    Task<IEnumerable<dynamic>> SelectAssessmentsAsync(StudentAssessmentFilterDto filter);

    Task<WriteResult> InsertFollowUpAsync(SessionFollowUpDto dto);
    Task<IEnumerable<dynamic>> SelectFollowUpsAsync(SessionFollowUpFilterDto filter);
}
