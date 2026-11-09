using System.Data;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Data;

/// <summary>
/// SQL Server implementation of <see cref="IDbConnectionFactory"/> reading the
/// "DefaultConnection" connection string from configuration.
/// </summary>
public sealed class SqlConnectionFactory : IDbConnectionFactory
{
    private readonly string _connectionString;

    public SqlConnectionFactory(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException(
                "Connection string 'DefaultConnection' was not found in configuration.");
    }

    public IDbConnection CreateConnection() => new SqlConnection(_connectionString);
}
