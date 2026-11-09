using System.Data;
using CounselLink.API.DTOs;
using Dapper;

namespace CounselLink.API.Data;

/// <summary>
/// Helpers for the standard @Message / @NewID output-parameter convention used
/// by all INSERT/UPDATE/DELETE stored procedures.
/// </summary>
public static class OutputParameters
{
    /// <summary>Adds the standard @Message (VARCHAR(255)) and @NewID (INT) output parameters.</summary>
    public static void AddStandardOutputs(this DynamicParameters parameters)
    {
        parameters.Add("@Message", dbType: DbType.String, size: 255, direction: ParameterDirection.Output);
        parameters.Add("@NewID", dbType: DbType.Int32, direction: ParameterDirection.Output);
    }

    /// <summary>
    /// Adds only the @Message (VARCHAR(255)) output parameter, for procedures
    /// that do not declare @NewID (e.g. spAppointment_Update).
    /// </summary>
    public static void AddMessageOutput(this DynamicParameters parameters)
    {
        parameters.Add("@Message", dbType: DbType.String, size: 255, direction: ParameterDirection.Output);
    }

    /// <summary>Reads the standard outputs into a <see cref="WriteResult"/>.</summary>
    public static WriteResult ReadWriteResult(this DynamicParameters parameters) => new()
    {
        NewId = parameters.Get<int?>("@NewID"),
        Message = parameters.Get<string?>("@Message")
    };

    /// <summary>Reads only the @Message output into a <see cref="WriteResult"/> (NewId stays null).</summary>
    public static WriteResult ReadMessageResult(this DynamicParameters parameters) => new()
    {
        NewId = null,
        Message = parameters.Get<string?>("@Message")
    };
}
