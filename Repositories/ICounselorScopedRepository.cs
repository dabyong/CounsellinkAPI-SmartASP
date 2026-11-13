namespace CounselLink.API.Repositories;

public sealed class CounselorScopeAssignment
{
    public string EmployeeID { get; set; } = string.Empty;
    public string DepartmentID { get; set; } = string.Empty;
    public string? ProgramID { get; set; }
    public int? YearOrGradeLevel { get; set; }
    public DateTime SchoolYear { get; set; }
}

public interface ICounselorScopedRepository
{
    Task<IReadOnlyList<CounselorScopeAssignment>> GetAssignmentsAsync(
        string employeeId, DateTime schoolYear);

    Task<IEnumerable<dynamic>> GetAppointmentsAsync(
        string employeeId, DateTime schoolYear, string? studentId);

    Task<IEnumerable<dynamic>> GetSessionsAsync(
        string employeeId, DateTime schoolYear);

    Task<IEnumerable<dynamic>> GetAssessmentsAsync(
        string employeeId, DateTime schoolYear);

    Task<IEnumerable<dynamic>> GetFollowUpsAsync(
        string employeeId, DateTime schoolYear);

    Task<IEnumerable<dynamic>> GetMasterlistAsync(
        string employeeId, DateTime schoolYear);
}
