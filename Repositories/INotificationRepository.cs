using CounselLink.API.DTOs;

namespace CounselLink.API.Repositories;

public interface INotificationRepository
{
    Task<IEnumerable<dynamic>> SelectAsync(NotificationFilterDto filter);
    Task<WriteResult> InsertAsync(NotificationDto dto);
}
