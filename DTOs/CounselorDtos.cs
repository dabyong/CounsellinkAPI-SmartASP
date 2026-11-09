using System.ComponentModel.DataAnnotations;

namespace CounselLink.API.DTOs;

/// <summary>Counselor record for spCounselor_* procedures.</summary>
public class CounselorDto
{
    /// <summary>Counselor employee id.</summary>
    /// <example>EMP0001</example>
    [Required]
    public string EmployeeID { get; set; } = string.Empty;

    /// <summary>First name.</summary>
    /// <example>Maria</example>
    public string? FirstName { get; set; }

    /// <summary>Last name.</summary>
    /// <example>Santos</example>
    public string? LastName { get; set; }

    /// <summary>Middle name.</summary>
    /// <example>Reyes</example>
    public string? MiddleName { get; set; }
}

/// <summary>Counselor-to-scope assignment for spCounselorAssignment_* procedures.</summary>
public class CounselorAssignmentDto
{
    /// <summary>Assignment id (0 for new).</summary>
    /// <example>0</example>
    public int AssignmentID { get; set; }

    /// <summary>Counselor employee id.</summary>
    /// <example>EMP0001</example>
    [Required]
    public string EmployeeID { get; set; } = string.Empty;

    /// <summary>Department id/code.</summary>
    /// <example>SACE</example>
    public string? DepartmentID { get; set; }

    /// <summary>Program id/code.</summary>
    /// <example>BSIT</example>
    public string? ProgramID { get; set; }

    /// <summary>Year or grade level.</summary>
    /// <example>4</example>
    public int? YearOrGradeLevel { get; set; }

    /// <summary>School year (YYYY-MM-DD, start date).</summary>
    /// <example>2026-08-01</example>
    public DateTime? SchoolYear { get; set; }
}
