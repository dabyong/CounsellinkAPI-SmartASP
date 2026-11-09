using System.ComponentModel.DataAnnotations;

namespace CounselLink.API.DTOs;

/// <summary>Input for spCounselingSession_Insert.</summary>
public class CounselingSessionDto
{
    /// <summary>Session id (0 for new).</summary>
    /// <example>0</example>
    public int SessionID { get; set; }

    /// <summary>Related appointment id.</summary>
    /// <example>1001</example>
    [Required]
    public int AppointmentID { get; set; }

    /// <summary>Counselor employee id (derived from the appointment if omitted).</summary>
    /// <example>EMP0001</example>
    public string? EmployeeID { get; set; }

    /// <summary>Student ID number (derived from the appointment if omitted).</summary>
    /// <example>2023001</example>
    public string? IDNumber { get; set; }

    /// <summary>Session type id.</summary>
    /// <example>1</example>
    public int? SessionTypeID { get; set; }

    /// <summary>Session date (ISO 8601 UTC).</summary>
    /// <example>2026-10-26T08:30:00Z</example>
    [Required]
    public DateTime SessionDate { get; set; }

    /// <summary>Session start time (ISO 8601 UTC).</summary>
    /// <example>2026-10-26T08:30:00Z</example>
    [Required]
    public DateTime SessionStartTime { get; set; }

    /// <summary>Session end time (ISO 8601 UTC).</summary>
    /// <example>2026-10-26T09:15:00Z</example>
    public DateTime? SessionEndTime { get; set; }

    /// <summary>General session notes (required by the procedure).</summary>
    /// <example>Discussed academic goals</example>
    [Required]
    public string GeneralNotes { get; set; } = string.Empty;
}

/// <summary>Filters for spCounselingSession_Select.</summary>
public class CounselingSessionFilterDto
{
    /// <summary>@SearchIDNumber</summary>
    /// <example>2023001</example>
    public string? SearchIDNumber { get; set; }

    /// <summary>@SearchEmployeeID</summary>
    /// <example>EMP0001</example>
    public string? SearchEmployeeID { get; set; }

    /// <summary>@SearchAppointmentID</summary>
    /// <example>1001</example>
    public int? SearchAppointmentID { get; set; }
}

/// <summary>Input for spStudentAssessment_Insert.</summary>
public class StudentAssessmentDto
{
    /// <summary>Assessment id (0 for new).</summary>
    /// <example>0</example>
    public int AssessmentID { get; set; }

    /// <summary>Related session id.</summary>
    /// <example>5001</example>
    [Required]
    public int SessionID { get; set; }

    /// <summary>Progress notes.</summary>
    /// <example>Client showing progress</example>
    public string? ProgressNotes { get; set; }

    /// <summary>Whether a follow-up is needed.</summary>
    /// <example>true</example>
    public bool IsFollowUpNeeded { get; set; }

    /// <summary>Whether the student is flagged for monitoring.</summary>
    /// <example>false</example>
    public bool IsForMonitoring { get; set; }

    /// <summary>Specialist referral id, if any.</summary>
    /// <example>1</example>
    public int? SpecialistReferralID { get; set; }
}

/// <summary>Filters for spStudentAssessment_Select.</summary>
public class StudentAssessmentFilterDto
{
    /// <summary>@SearchAssessmentID</summary>
    /// <example>6001</example>
    public int? SearchAssessmentID { get; set; }

    /// <summary>@SearchSessionID</summary>
    /// <example>5001</example>
    public int? SearchSessionID { get; set; }
}

/// <summary>Input for spSessionFollowUp_Insert.</summary>
public class SessionFollowUpDto
{
    /// <summary>Follow-up id (0 for new).</summary>
    /// <example>0</example>
    public int FollowUpID { get; set; }

    /// <summary>Related assessment id.</summary>
    /// <example>6001</example>
    [Required]
    public int AssessmentID { get; set; }

    /// <summary>Target date (YYYY-MM-DD).</summary>
    /// <example>2026-11-01</example>
    [Required]
    public DateTime TargetDate { get; set; }

    /// <summary>Follow-up status (Pending, Completed, or Cancelled).</summary>
    /// <example>Pending</example>
    public string? FollowUpStatus { get; set; }

    /// <summary>Action required (required by the procedure).</summary>
    /// <example>Check grade report</example>
    [Required]
    public string ActionRequired { get; set; } = string.Empty;

    /// <summary>Resolution notes, if any.</summary>
    /// <example>Reviewed updated grades with the student.</example>
    public string? ResolutionNotes { get; set; }
}

/// <summary>Filters for spSessionFollowUp_Select.</summary>
public class SessionFollowUpFilterDto
{
    /// <summary>@SearchAssessmentID</summary>
    /// <example>6001</example>
    public int? SearchAssessmentID { get; set; }

    /// <summary>@SearchStatus (Pending, Completed, Cancelled).</summary>
    /// <example>Pending</example>
    public string? SearchStatus { get; set; }
}
