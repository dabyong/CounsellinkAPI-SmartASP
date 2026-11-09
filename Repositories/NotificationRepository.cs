using System.Data;
using CounselLink.API.Data;
using CounselLink.API.DTOs;
using Dapper;

namespace CounselLink.API.Repositories;

public sealed class NotificationRepository : INotificationRepository
{
    private readonly IDbConnectionFactory _factory;

    public NotificationRepository(IDbConnectionFactory factory) => _factory = factory;

    public async Task<IEnumerable<dynamic>> SelectAsync(NotificationFilterDto filter)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchNotificationID", filter.SearchNotificationID);
        parameters.Add("@SearchIDNumber", filter.SearchIDNumber);
        parameters.Add("@SearchStatus", filter.SearchStatus);

        return await connection.QueryAsync(
            "dbo.spNotification_Select", parameters, commandType: CommandType.StoredProcedure);
    }

    public async Task<WriteResult> InsertAsync(NotificationDto dto)
    {
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@IDNumber", dto.IDNumber);
        parameters.Add("@Content", dto.Content);
        parameters.Add("@NotificationStatus", dto.NotificationStatus);
        parameters.AddStandardOutputs();

        await connection.ExecuteAsync(
            "dbo.spNotification_Insert", parameters, commandType: CommandType.StoredProcedure);

        return parameters.ReadWriteResult();
    }
}
