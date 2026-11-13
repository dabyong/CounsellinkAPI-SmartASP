using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using CounselLink.API.Data;
using CounselLink.API.Repositories;
using CounselLink.API.Swagger;
using Dapper;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// Controllers and CORS: keep current Angular development ports.
builder.Services.AddControllers();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AngularDev", policy => policy
        .WithOrigins("http://localhost:4800", "http://localhost:4200")
        .AllowAnyHeader()
        .AllowAnyMethod());
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SchemaFilter<ExampleSchemaFilter>();
    var xmlFile = $"{typeof(Program).Assembly.GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath)) options.IncludeXmlComments(xmlPath);
});

builder.Services.AddScoped<IDbConnectionFactory, SqlConnectionFactory>();
builder.Services.AddScoped<IAppointmentRepository, AppointmentRepository>();
builder.Services.AddScoped<IClinicalRepository, ClinicalRepository>();
builder.Services.AddScoped<IConstantRepository, ConstantRepository>();
builder.Services.AddScoped<ICounselorRepository, CounselorRepository>();
builder.Services.AddScoped<ICounselorAssignmentRepository, CounselorAssignmentRepository>();
builder.Services.AddScoped<ICounselorScheduleRepository, CounselorScheduleRepository>();
builder.Services.AddScoped<INotificationRepository, NotificationRepository>();
builder.Services.AddScoped<IReportRepository, ReportRepository>();

// These classes should already be in your project from the earlier starter ZIP.
builder.Services.AddScoped<ICounselorScopedRepository, CounselorScopedRepository>();

// DEVELOPMENT ONLY: test tokens issued locally for pre-registered test accounts.
// Production/Staging still require verified school JWT validation configuration.
if (builder.Environment.IsDevelopment())
{
    var signingKeyBase64 = builder.Configuration["DevCounselorAuth:SigningKey"];
    byte[] keyBytes;
    try
    {
        keyBytes = Convert.FromBase64String(signingKeyBase64 ?? "");
    }
    catch (FormatException)
    {
        throw new InvalidOperationException(
            "DevCounselorAuth:SigningKey must be a base64-encoded random key. See SETUP_POWERSHELL.md.");
    }
    if (keyBytes.Length < 32)
        throw new InvalidOperationException(
            "Development signing key is missing/too short. Configure dotnet user-secrets first.");

    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.MapInboundClaims = false;
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = "CounselLink.LocalDevelopment",
                ValidateAudience = true,
                ValidAudience = "CounselLink.LocalTestClient",
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
                ValidateLifetime = true,
                RequireExpirationTime = true,
                RequireSignedTokens = true,
                ClockSkew = TimeSpan.FromSeconds(30),
                NameClaimType = "employee_id",
                RoleClaimType = "role"
            };
        });
}
else
{
    // DO NOT replace this branch with development test credentials.
    // The school must provide a verified issuer, audience, and API token contract
    // before staging/production starts.
    var portalAuth = builder.Configuration.GetSection("PortalAuth");
    var authority = portalAuth["Authority"];
    var audience = portalAuth["Audience"];
    var employeeIdClaim = portalAuth["EmployeeIdClaim"] ?? "employee_id";
    var roleClaim = portalAuth["RoleClaim"] ?? "role";
    if (string.IsNullOrWhiteSpace(authority) || string.IsNullOrWhiteSpace(audience))
        throw new InvalidOperationException(
            "PortalAuth:Authority and PortalAuth:Audience must be VERIFIED before non-development startup.");
    if (!Uri.TryCreate(authority, UriKind.Absolute, out var issuerUri)
        || issuerUri.Scheme != Uri.UriSchemeHttps)
        throw new InvalidOperationException("PortalAuth:Authority must be an HTTPS URL.");

    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.Authority = authority;
            options.Audience = audience;
            options.RequireHttpsMetadata = true;
            options.MapInboundClaims = false;
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                NameClaimType = employeeIdClaim,
                RoleClaimType = roleClaim
            };
        });
}

builder.Services.AddAuthorization(options =>
{
    // A token with the local/portal role is not enough to read records: the
    // counselor-records controller separately verifies the DB assignment.
    var role = builder.Environment.IsDevelopment()
        ? "Counselor"
        : builder.Configuration["PortalAuth:CounselorRoleValue"] ?? "Counselor";
    options.AddPolicy("VerifiedCounselor", policy =>
        policy.RequireAuthenticatedUser().RequireRole(role));
});

var app = builder.Build();

if (app.Environment.IsDevelopment() || app.Environment.IsStaging())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "CounselLink API" }));
if (app.Environment.IsDevelopment())
{
    app.MapGet("/health/db", (IDbConnectionFactory factory) =>
    {
        using var connection = factory.CreateConnection();
        connection.Open();
        return Results.Ok(new { status = "ok", database = connection.Database });
    });

    // ONLY for a development server bound to 127.0.0.1; never exposed in staging/production.
    // The password is read from dotnet user-secrets, NOT from a committed file.
    app.MapPost("/api/dev-auth/counselor-login", async (
        DevCounselorLogin login,
        IConfiguration configuration,
        IDbConnectionFactory factory,
        HttpContext context) =>
    {
        var ip = context.Connection.RemoteIpAddress;
        if (ip is null || !System.Net.IPAddress.IsLoopback(ip))
            return Results.NotFound();

        var employeeId = login.EmployeeID?.Trim().ToUpperInvariant();
        var providedPassword = login.Password;
        if (string.IsNullOrWhiteSpace(employeeId) || employeeId.Length > 7 ||
            string.IsNullOrWhiteSpace(providedPassword))
            return Results.Unauthorized();

        var expectedPassword = configuration[$"DevCounselorAuth:Accounts:{employeeId}"];
        if (string.IsNullOrWhiteSpace(expectedPassword))
            return Results.Unauthorized();

        // Fixed-time password comparison for local test credentials only.
        var providedHash = SHA256.HashData(Encoding.UTF8.GetBytes(providedPassword));
        var expectedHash = SHA256.HashData(Encoding.UTF8.GetBytes(expectedPassword));
        if (!CryptographicOperations.FixedTimeEquals(providedHash, expectedHash))
            return Results.Unauthorized();

        using var connection = factory.CreateConnection();
        var assigned = await connection.ExecuteScalarAsync<int>(
            "SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.CounselorAssignment " +
            "WHERE EmployeeID = @EmployeeID) THEN 1 ELSE 0 END",
            new { EmployeeID = employeeId });
        if (assigned != 1)
            return Results.Unauthorized();

        var keyBytes = Convert.FromBase64String(configuration["DevCounselorAuth:SigningKey"]!);
        var claims = new[]
        {
            new Claim("employee_id", employeeId),
            new Claim("role", "Counselor")
        };
        var expiresAt = DateTime.UtcNow.AddMinutes(30);
        var jwt = new JwtSecurityToken(
            issuer: "CounselLink.LocalDevelopment",
            audience: "CounselLink.LocalTestClient",
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: expiresAt,
            signingCredentials: new SigningCredentials(
                new SymmetricSecurityKey(keyBytes), SecurityAlgorithms.HmacSha256));
        var token = new JwtSecurityTokenHandler().WriteToken(jwt);

        return Results.Ok(new
        {
            accessToken = token,
            tokenType = "Bearer",
            expiresAtUtc = expiresAt,
            employeeID = employeeId
        });
    }).ExcludeFromDescription();
}

if (!app.Environment.IsDevelopment()) app.UseHttpsRedirection();
app.UseRouting();
app.UseCors("AngularDev");
app.UseAuthentication();
app.UseAuthorization();

// TEMPORARY FAIL-CLOSED ROUTE GUARD.
// There is NO trusted school-portal student identity in this test setup yet.
// Prevent anonymous access and counselor bypasses through legacy unscoped APIs.
// This is an interim access boundary, not a replacement for per-action,
// per-record authorization once real student authentication is available.
app.Use(async (context, next) =>
{
    var path = context.Request.Path;
    var method = context.Request.Method;
    var isApi = path.StartsWithSegments("/api", StringComparison.OrdinalIgnoreCase);

    if (!isApi)
    {
        await next();
        return;
    }

    // Authenticated, DB-scoped counselor endpoints. The controller already
    // enforces the VerifiedCounselor policy and checks assignments.
    var counselorScopedRead = HttpMethods.IsGet(method) &&
        path.StartsWithSegments("/api/counselor-records", StringComparison.OrdinalIgnoreCase);

    // Student-facing public metadata: lookups and availability only.
    // GET only: INSERT/UPDATE/DELETE operations remain blocked.
    var publicConstants = HttpMethods.IsGet(method) &&
        path.StartsWithSegments("/api/constants", StringComparison.OrdinalIgnoreCase);
    var publicAvailability = HttpMethods.IsGet(method) &&
        path.Value?.Equals("/api/counselor-schedules/availability",
            StringComparison.OrdinalIgnoreCase) == true;

    // Local loopback development testing only, NOT an authenticated student flow.
    // Replace this exception with verified student auth before public deployment.
    var isLoopback = context.Connection.RemoteIpAddress is { } ip &&
        System.Net.IPAddress.IsLoopback(ip);
    var devLogin = app.Environment.IsDevelopment() && isLoopback &&
        HttpMethods.IsPost(method) &&
        path.Value?.Equals("/api/dev-auth/counselor-login",
            StringComparison.OrdinalIgnoreCase) == true;
    var devStudentCreate = app.Environment.IsDevelopment() && isLoopback &&
        HttpMethods.IsPost(method) &&
        path.Value?.Equals("/api/appointments",
            StringComparison.OrdinalIgnoreCase) == true;

    if (counselorScopedRead || publicConstants || publicAvailability ||
        devLogin || devStudentCreate)
    {
        await next();
        return;
    }

    // The local counselor JWT must NOT grant access to legacy, unscoped APIs.
    // Anonymous: 401. Authenticated but not allowed: 403.
    context.Response.StatusCode = context.User.Identity?.IsAuthenticated == true
        ? StatusCodes.Status403Forbidden
        : StatusCodes.Status401Unauthorized;
    await context.Response.WriteAsJsonAsync(new
    {
        error = "Legacy endpoint disabled until caller-specific authorization is implemented."
    });
});

app.MapControllers();
app.Run();

internal sealed record DevCounselorLogin(string EmployeeID, string Password);
