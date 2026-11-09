using System.Data;
using CounselLink.API.Data;
using CounselLink.API.DTOs;
using Dapper;

namespace CounselLink.API.Repositories;

/// <summary>
/// Dapper implementation for the constant lookup tables. Each supported type
/// maps to a procedure family "spConst{Type}_{Action}" and a pair of column
/// parameter names: an integer id (@{Type}ID) and a text value (@{Type} or,
/// for SpecialistReferral, @SpecialistRole). All write procedures use a single
/// @Message OUTPUT (no @NewID).
/// </summary>
public sealed class ConstantRepository : IConstantRepository
{
    /// <summary>
    /// Maps each supported route type to (proc infix, id-param, value-param).
    /// </summary>
    private static readonly IReadOnlyDictionary<string, (string Infix, string IdParam, string ValueParam)> Map =
        new Dictionary<string, (string, string, string)>(StringComparer.OrdinalIgnoreCase)
        {
            ["AppointmentType"]    = ("AppointmentType",    "@AppointmentTypeID",    "@AppointmentType"),
            ["ConcernType"]        = ("ConcernType",        "@ConcernTypeID",        "@ConcernType"),
            ["AttendanceStatus"]   = ("AttendanceStatus",   "@AttendanceStatusID",   "@AttendanceStatus"),
            ["AppointmentStatus"]  = ("AppointmentStatus",  "@AppointmentStatusID",  "@AppointmentStatus"),
            ["SessionType"]        = ("SessionType",        "@SessionTypeID",        "@SessionType"),
            ["SpecialistReferral"] = ("SpecialistReferral", "@SpecialistReferralID", "@SpecialistRole"),
        };

    private readonly IDbConnectionFactory _factory;

    public ConstantRepository(IDbConnectionFactory factory) => _factory = factory;

    public bool IsSupported(string type) => Map.ContainsKey(type);

    private static (string Infix, string IdParam, string ValueParam) Meta(string type) => Map[type];

    private string Proc(string type, string action) => $"dbo.spConst{Meta(type).Infix}_{action}";

    public async Task<IEnumerable<dynamic>> SelectAsync(string type)
    {
        using var connection = _factory.CreateConnection();
        // Every *_Select proc accepts optional @SearchID (+ a text filter) that
        // default to NULL, so passing none returns all rows.
        return await connection.QueryAsync(
            Proc(type, "Select"),
            commandType: CommandType.StoredProcedure);
    }

    public async Task<WriteResult> InsertAsync(string type, ConstantDto dto)
    {
        var meta = Meta(type);
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add(meta.IdParam, dto.Id);
        parameters.Add(meta.ValueParam, dto.Value);
        parameters.AddMessageOutput();

        await connection.ExecuteAsync(
            Proc(type, "Insert"),
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadMessageResult();
    }

    public async Task<WriteResult> UpdateAsync(string type, ConstantDto dto)
    {
        var meta = Meta(type);
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add(meta.IdParam, dto.Id);
        parameters.Add(meta.ValueParam, dto.Value);
        parameters.AddMessageOutput();

        await connection.ExecuteAsync(
            Proc(type, "Update"),
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadMessageResult();
    }

    public async Task<WriteResult> DeleteAsync(string type, int id)
    {
        var meta = Meta(type);
        using var connection = _factory.CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add(meta.IdParam, id);
        parameters.AddMessageOutput();

        await connection.ExecuteAsync(
            Proc(type, "Delete"),
            parameters,
            commandType: CommandType.StoredProcedure);

        return parameters.ReadMessageResult();
    }
}
