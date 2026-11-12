namespace CounselLink.API.DTOs;

/// <summary>Public, privacy-safe counselor time slot. Never includes student details.</summary>
public sealed class CounselorAvailabilitySlotDto
{
    public DateTime ScheduleDate { get; set; }
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public bool IsAvailable { get; set; }
    public string Status { get; set; } = "Unavailable";
}
