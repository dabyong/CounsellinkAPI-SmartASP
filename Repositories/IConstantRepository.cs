using CounselLink.API.DTOs;

namespace CounselLink.API.Repositories;

/// <summary>
/// CRUD over constant lookup tables. The concrete procedure name is computed as
/// "spConst{Type}_{Action}" where {Type} is one of the supported lookup types.
/// </summary>
public interface IConstantRepository
{
    /// <summary>Returns true if the supplied type is a supported constant type.</summary>
    bool IsSupported(string type);

    Task<IEnumerable<dynamic>> SelectAsync(string type);
    Task<WriteResult> InsertAsync(string type, ConstantDto dto);
    Task<WriteResult> UpdateAsync(string type, ConstantDto dto);
    Task<WriteResult> DeleteAsync(string type, int id);
}
