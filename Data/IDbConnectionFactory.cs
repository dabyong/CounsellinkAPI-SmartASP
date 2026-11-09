using System.Data;

namespace CounselLink.API.Data;

/// <summary>
/// Creates database connections for repositories, centralizing connection-string
/// resolution so repositories never build connection strings themselves.
/// </summary>
public interface IDbConnectionFactory
{
    /// <summary>Creates a new, unopened connection to CounselLinkDB.</summary>
    IDbConnection CreateConnection();
}
