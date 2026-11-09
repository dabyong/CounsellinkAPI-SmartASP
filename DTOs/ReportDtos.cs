using System.ComponentModel.DataAnnotations;

namespace CounselLink.API.DTOs;

/// <summary>
/// Shared filter for the monthly report procedures. Maps to the
/// @SchoolYearStart, @ReportMonth, and optional @EmployeeID parameters.
/// </summary>
public class MonthlyReportFilterDto
{
    /// <summary>School year start (year).</summary>
    /// <example>2026</example>
    [Required]
    public int SchoolYearStart { get; set; }

    /// <summary>Report month (1-12).</summary>
    /// <example>9</example>
    [Required]
    [Range(1, 12)]
    public int ReportMonth { get; set; }

    /// <summary>Optional counselor employee id to scope the report.</summary>
    /// <example>EMP0001</example>
    public string? EmployeeID { get; set; }
}
