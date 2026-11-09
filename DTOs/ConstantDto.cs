using System.ComponentModel.DataAnnotations;

namespace CounselLink.API.DTOs;

/// <summary>
/// Shared shape for the constant lookup tables. Each table has an integer id
/// column (AppointmentTypeID, ConcernTypeID, AttendanceStatusID,
/// AppointmentStatusID, SessionTypeID, SpecialistReferralID) and a single
/// text column (the type/status name, or SpecialistRole). The repository maps
/// <see cref="Id"/> and <see cref="Value"/> onto the correct per-type
/// stored-procedure parameter names.
/// </summary>
public class ConstantDto
{
    /// <summary>Integer primary key for the constant row.</summary>
    /// <example>1</example>
    public int Id { get; set; }

    /// <summary>The text value (type/status name, or specialist role).</summary>
    /// <example>Student Initiated</example>
    [Required]
    public string Value { get; set; } = string.Empty;
}
