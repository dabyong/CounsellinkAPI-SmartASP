using CounselLink.API.DTOs;

namespace CounselLink.API.Repositories;

public interface ICounselorRepository
{
    Task<IEnumerable<dynamic>> SelectAsync();
    Task<WriteResult> InsertAsync(CounselorDto dto);
    Task<WriteResult> UpdateAsync(CounselorDto dto);
    Task<WriteResult> DeleteAsync(string employeeId);
}

public interface ICounselorAssignmentRepository
{
    Task<IEnumerable<dynamic>> SelectAsync();
    Task<WriteResult> InsertAsync(CounselorAssignmentDto dto);
}
