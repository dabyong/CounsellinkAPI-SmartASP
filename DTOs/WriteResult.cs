namespace CounselLink.API.DTOs;

/// <summary>
/// Standard response for write operations. Populated from the stored-procedure
/// output parameters @NewID and @Message. Serialized as { newId, message }.
/// </summary>
public class WriteResult
{
    public int? NewId { get; set; }
    public string? Message { get; set; }
}
