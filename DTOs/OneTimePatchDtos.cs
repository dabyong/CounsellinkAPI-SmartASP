using System.ComponentModel.DataAnnotations;

namespace CounselLink.API.DTOs;

public sealed class DraftAppointmentDto
{
    [Required, MaxLength(7)]
    public string IDNumber { get; set; } = "";
    public int? GradeOrYearLevel { get; set; }
    public string? ProgramOrCourse { get; set; }
    public string? EmployeeID { get; set; }
    public DateTime? AppointmentDate { get; set; }
    public TimeSpan? StartTime { get; set; }
    public TimeSpan? EndTime { get; set; }
    public int? AppointmentTypeID { get; set; }
    public int? ConcernTypeID { get; set; }
    public string? ConcernDescription { get; set; }
    public string? ReferredBy { get; set; }
    public DateTime? ReferralDate { get; set; }
}

public sealed class SubmitDraftDto
{
    [Required, MaxLength(7)] public string IDNumber { get; set; } = "";
}

public sealed class BlockSlotDto
{
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public bool IsAvailable { get; set; }
    public string? Reason { get; set; }
}

public sealed class UpdateBlockedSlotsDto
{
    [Required, MaxLength(7)] public string EmployeeId { get; set; } = "";
    public DateTime Date { get; set; }
    [Required] public List<BlockSlotDto> Slots { get; set; } = [];
}

public sealed class StudentProfileOverrideDto
{
    public string? FirstName { get; set; }
    public string? MiddleName { get; set; }
    public string? LastName { get; set; }
    [EmailAddress] public string? Email { get; set; }
    public string? ContactNumber { get; set; }
    public string? DepartmentID { get; set; }
    public string? ProgramID { get; set; }
    public string? ProgramOrCourse { get; set; }
    public int? GradeOrYearLevel { get; set; }
}

public sealed class CounselorAdminEditDto
{
    [Required, MaxLength(50)] public string FirstName { get; set; } = "";
    [Required, MaxLength(50)] public string LastName { get; set; } = "";
    public string? MiddleName { get; set; }
}

public sealed class CounselorAssignmentAdminDto
{
    public string? DepartmentID { get; set; }
    public string? ProgramID { get; set; }
    public int? YearOrGradeLevel { get; set; }
    public DateTime? SchoolYear { get; set; }
}
