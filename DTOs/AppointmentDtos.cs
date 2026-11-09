using System.ComponentModel.DataAnnotations;

namespace CounselLink.API.DTOs;

/// <summary>
/// Request payload for PUT /api/appointments/{id}. Property names match the
/// dbo.spAppointment_Update parameters exactly (the appointment id comes from
/// the route and is supplied as @AppointmentID by the repository).
/// </summary>
public class UpdateAppointmentDto
{
    /// <summary>Appointment status id.</summary>
    /// <example>2</example>
    public int AppointmentStatusID { get; set; }

    /// <summary>Attendance status id.</summary>
    /// <example>1</example>
    public int AttendanceStatusID { get; set; }

    /// <summary>Optional reschedule note.</summary>
    /// <example>Moved to a later slot at the student's request.</example>
    public string? RescheduleNote { get; set; }

    /// <summary>Primary concern description.</summary>
    /// <example>Academic stress and time management</example>
    public string? ConcernDescription { get; set; }

    /// <summary>Free-text detail when the concern type is "Other".</summary>
    /// <example>Difficulty balancing part-time work and studies</example>
    public string? OtherConcernDetail { get; set; }
}

/// <summary>
/// Request payload for POST /api/appointments. Property names match the
/// dbo.spAppointment_Insert parameters exactly.
/// </summary>
public class CreateAppointmentDto
{
    /// <summary>Student ID number.</summary>
    /// <example>2023001</example>
    [Required]
    public string IDNumber { get; set; } = string.Empty;

    /// <summary>Grade or year level.</summary>
    /// <example>4</example>
    public int? GradeOrYearLevel { get; set; }

    /// <summary>Program or course.</summary>
    /// <example>BS Information Technology</example>
    public string? ProgramOrCourse { get; set; }

    /// <summary>Assigned counselor employee id.</summary>
    /// <example>EMP-1001</example>
    public string? EmployeeID { get; set; }

    /// <summary>Appointment date (YYYY-MM-DD).</summary>
    /// <example>2026-10-26</example>
    public DateTime? AppointmentDate { get; set; }

    /// <summary>Appointment time (HH:mm:ss).</summary>
    /// <example>08:30:00</example>
    public TimeSpan? AppointmentTime { get; set; }

    /// <summary>Appointment type id.</summary>
    /// <example>1</example>
    public int? AppointmentTypeID { get; set; }

    /// <summary>Appointment status id.</summary>
    /// <example>1</example>
    public int? AppointmentStatusID { get; set; }

    /// <summary>Attendance status id.</summary>
    /// <example>1</example>
    public int? AttendanceStatusID { get; set; }

    /// <summary>Primary concern description.</summary>
    /// <example>Academic stress and time management</example>
    public string? ConcernDescription { get; set; }

    /// <summary>Free-text detail when the concern type is "Other".</summary>
    /// <example>Difficulty balancing part-time work and studies</example>
    public string? OtherConcernDetail { get; set; }

    /// <summary>Who referred the student, if applicable.</summary>
    /// <example>Prof. Dela Cruz</example>
    public string? ReferredBy { get; set; }

    /// <summary>Referral date (YYYY-MM-DD), if applicable.</summary>
    /// <example>2026-10-20</example>
    public DateTime? ReferralDate { get; set; }
}

/// <summary>
/// Query filters for spAppointment_Select. Property names map to the exact
/// @Search* stored-procedure parameters.
/// </summary>
public class AppointmentFilterDto
{
    /// <summary>@SearchAppointmentID</summary>
    /// <example>1001</example>
    public int? SearchAppointmentID { get; set; }

    /// <summary>@SearchIDNumber</summary>
    /// <example>2023001</example>
    public string? SearchIDNumber { get; set; }

    /// <summary>@SearchGradeOrYear</summary>
    /// <example>4</example>
    public int? SearchGradeOrYear { get; set; }

    /// <summary>@SearchProgram</summary>
    /// <example>BS Information Technology</example>
    public string? SearchProgram { get; set; }

    /// <summary>@SearchEmployeeID</summary>
    /// <example>EMP-1001</example>
    public string? SearchEmployeeID { get; set; }

    /// <summary>@SearchStartDate (YYYY-MM-DD)</summary>
    /// <example>2026-10-01</example>
    public DateTime? SearchStartDate { get; set; }

    /// <summary>@SearchEndDate (YYYY-MM-DD)</summary>
    /// <example>2026-10-31</example>
    public DateTime? SearchEndDate { get; set; }

    /// <summary>@SearchAppointmentTime (HH:mm:ss)</summary>
    /// <example>08:30:00</example>
    public TimeSpan? SearchAppointmentTime { get; set; }

    /// <summary>@SearchAppointmentTypeID</summary>
    /// <example>1</example>
    public int? SearchAppointmentTypeID { get; set; }

    /// <summary>@SearchConcernTypeID</summary>
    /// <example>2</example>
    public int? SearchConcernTypeID { get; set; }

    /// <summary>@SearchStatusID</summary>
    /// <example>1</example>
    public int? SearchStatusID { get; set; }

    /// <summary>@SearchAttendanceID</summary>
    /// <example>1</example>
    public int? SearchAttendanceID { get; set; }

    /// <summary>@SearchReferredBy</summary>
    /// <example>Prof. Dela Cruz</example>
    public string? SearchReferredBy { get; set; }

    /// <summary>@SearchReferralStart (YYYY-MM-DD)</summary>
    /// <example>2026-10-01</example>
    public DateTime? SearchReferralStart { get; set; }

    /// <summary>@SearchReferralEnd (YYYY-MM-DD)</summary>
    /// <example>2026-10-31</example>
    public DateTime? SearchReferralEnd { get; set; }
}

/// <summary>Input for spConfirmAppointment.</summary>
public class ConfirmAppointmentDto
{
    /// <summary>Confirming counselor employee id.</summary>
    /// <example>EMP-1001</example>
    [Required]
    public string EmployeeID { get; set; } = string.Empty;

    /// <summary>Confirmed date (YYYY-MM-DD).</summary>
    /// <example>2026-10-26</example>
    public DateTime? ConfirmedDate { get; set; }

    /// <summary>Confirmed time (HH:mm:ss).</summary>
    /// <example>08:30:00</example>
    public TimeSpan? ConfirmedTime { get; set; }
}

/// <summary>Input for spStudentConfirmAppointment and spStudentAcceptReschedule.</summary>
public class StudentIdNumberDto
{
    /// <summary>Student ID number.</summary>
    /// <example>2023001</example>
    [Required]
    public string IDNumber { get; set; } = string.Empty;
}

/// <summary>Input for spRescheduleAppointment.</summary>
public class RescheduleDto
{
    /// <summary>New start date/time (ISO 8601).</summary>
    /// <example>2026-11-02T08:30:00</example>
    [Required]
    public DateTime NewStartDate { get; set; }

    /// <summary>New end date/time (ISO 8601).</summary>
    /// <example>2026-11-02T09:15:00</example>
    [Required]
    public DateTime NewEndDate { get; set; }

    /// <summary>Reschedule note (required by the procedure).</summary>
    /// <example>Counselor unavailable on the original date.</example>
    [Required]
    public string RescheduleNote { get; set; } = string.Empty;
}
