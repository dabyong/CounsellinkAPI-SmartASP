using CounselLink.API.Data;
using CounselLink.API.Repositories;
using CounselLink.API.Swagger;

// TEMPORARY SYNTHETIC-TEST API CONFIGURATION.
// No API credential checks, tokens, JWT, login, or required identity.
// Replace this test configuration before storing real student or clinical information.
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddCors(options => options.AddPolicy("OpenTest", policy =>
    policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SchemaFilter<ExampleSchemaFilter>();
    var xmlFile = $"{typeof(Program).Assembly.GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath)) options.IncludeXmlComments(xmlPath);
});

// Preserve the services expected by the current CounselLink controllers.
builder.Services.AddScoped<IDbConnectionFactory, SqlConnectionFactory>();
builder.Services.AddScoped<IAppointmentRepository, AppointmentRepository>();
builder.Services.AddScoped<IClinicalRepository, ClinicalRepository>();
builder.Services.AddScoped<IConstantRepository, ConstantRepository>();
builder.Services.AddScoped<ICounselorRepository, CounselorRepository>();
builder.Services.AddScoped<ICounselorAssignmentRepository, CounselorAssignmentRepository>();
builder.Services.AddScoped<ICounselorScheduleRepository, CounselorScheduleRepository>();
builder.Services.AddScoped<INotificationRepository, NotificationRepository>();
builder.Services.AddScoped<IReportRepository, ReportRepository>();
builder.Services.AddScoped<ICounselorScopedRepository, CounselorScopedRepository>();

// ASP.NET Core infrastructure for endpoints that still contain [Authorize] metadata.
// All controller endpoints receive [AllowAnonymous] below, so no authorization check
// is applied. This registers no identity provider and no authentication scheme.
builder.Services.AddAuthorization(options =>
{
    // Legacy controller metadata may name this policy. Define it without
    // requiring identity so endpoint discovery never fails; AllowAnonymous
    // below bypasses all authorization checks for synthetic testing.
    options.AddPolicy("VerifiedCounselor", policy => policy.RequireAssertion(_ => true));
});

var app = builder.Build();

// Keep Swagger accessible on the SmarterASP test site, including Production environment.
app.UseSwagger();
app.UseSwaggerUI();

app.MapGet("/health", () => Results.Ok(new
{
    status = "ok",
    service = "CounselLink API",
    deploymentBuild = "no-key-no-auth-v4-2026-11-13"
}));

app.UseHttpsRedirection();
app.UseRouting();
app.UseCors("OpenTest");
app.UseAuthorization();

// Skip any leftover authorization attributes for this synthetic-data test build.
app.MapControllers().AllowAnonymous();

app.Run();
