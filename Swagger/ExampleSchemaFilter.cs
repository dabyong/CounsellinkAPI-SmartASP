using System.Xml.XPath;
using Microsoft.OpenApi;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace CounselLink.API.Swagger;

/// <summary>
/// Populates Swagger schema examples for DTO properties so the "Try it out"
/// editor pre-fills valid, CounselLinkDB-shaped test data instead of the
/// generic "string" / 0 placeholders.
///
/// Resolution order per property:
///   1. The property's XML &lt;example&gt; doc comment (authored on the DTO), if present.
///   2. A type-based fallback (dates as YYYY-MM-DD, times as HH:mm:ss, etc.).
/// </summary>
public sealed class ExampleSchemaFilter : ISchemaFilter
{
    private readonly XPathNavigator? _xml;

    public ExampleSchemaFilter()
    {
        var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
        var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
        if (File.Exists(xmlPath))
        {
            _xml = new XPathDocument(xmlPath).CreateNavigator();
        }
    }

    public void Apply(IOpenApiSchema schema, SchemaFilterContext context)
    {
        if (schema is not OpenApiSchema concrete || concrete.Properties is null)
            return;

        var members = context.Type.GetProperties();

        foreach (var member in members)
        {
            // OpenAPI property keys are camelCased by default.
            var key = concrete.Properties.Keys.FirstOrDefault(
                k => string.Equals(k, member.Name, StringComparison.OrdinalIgnoreCase));
            if (key is null || concrete.Properties[key] is not OpenApiSchema propSchema)
                continue;

            if (propSchema.Example is not null)
                continue;

            var example = ResolveXmlExample(context.Type, member.Name)
                          ?? FallbackExample(member.PropertyType);

            if (example is not null)
                propSchema.Example = JsonNodeFactory.Create(example);
        }
    }

    private string? ResolveXmlExample(Type declaringType, string propertyName)
    {
        if (_xml is null)
            return null;

        // Doc member name for a property: P:Namespace.Type.Property
        var memberName = $"P:{declaringType.FullName}.{propertyName}";
        var node = _xml.SelectSingleNode($"/doc/members/member[@name='{memberName}']/example");
        return node?.Value?.Trim();
    }

    private static string? FallbackExample(Type type)
    {
        var t = Nullable.GetUnderlyingType(type) ?? type;

        if (t == typeof(DateTime)) return "2026-10-26";
        if (t == typeof(TimeSpan)) return "08:30:00";
        if (t == typeof(bool)) return "false";
        if (t == typeof(int) || t == typeof(long) || t == typeof(short)) return "1";
        if (t == typeof(string)) return "sample";
        return null;
    }
}

/// <summary>Builds an OpenAPI example node from a raw string, typed per schema needs.</summary>
internal static class JsonNodeFactory
{
    public static System.Text.Json.Nodes.JsonNode Create(string raw)
    {
        // Numbers and booleans should not be quoted in the example.
        if (bool.TryParse(raw, out var b))
            return System.Text.Json.Nodes.JsonValue.Create(b);
        if (long.TryParse(raw, out var l))
            return System.Text.Json.Nodes.JsonValue.Create(l);
        return System.Text.Json.Nodes.JsonValue.Create(raw)!;
    }
}
