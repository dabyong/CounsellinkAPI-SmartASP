using System.ComponentModel.DataAnnotations;

namespace CounselLink.API.DTOs;

/// <summary>Notification record for spNotification_Insert.</summary>
public class NotificationDto
{
    /// <summary>Notification id (0 for new).</summary>
    /// <example>0</example>
    public int NotificationID { get; set; }

    /// <summary>Recipient student ID number.</summary>
    /// <example>2023001</example>
    [Required]
    public string IDNumber { get; set; } = string.Empty;

    /// <summary>Notification content.</summary>
    /// <example>Your appointment is confirmed.</example>
    public string? Content { get; set; }

    /// <summary>Read status (false = unread).</summary>
    /// <example>false</example>
    public bool NotificationStatus { get; set; }
}

/// <summary>Filters for spNotification_Select.</summary>
public class NotificationFilterDto
{
    /// <summary>@SearchNotificationID</summary>
    /// <example>7001</example>
    public int? SearchNotificationID { get; set; }

    /// <summary>@SearchIDNumber</summary>
    /// <example>2023001</example>
    public string? SearchIDNumber { get; set; }

    /// <summary>@SearchStatus (read status).</summary>
    /// <example>false</example>
    public bool? SearchStatus { get; set; }
}
