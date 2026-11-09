using CounselLink.API.Data;
using CounselLink.API.Repositories;
using CounselLink.API.Swagger;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SchemaFilter<ExampleSchemaFilter>();

    var xmlFile = $"{typeof(Program).Assembly.GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        options.IncludeXmlComments(xmlPath);
    }
});

builder.Services.AddScoped<IDbConnectionFactory, SqlConnectionFactory>();
builder.Services.AddScoped<IAppointmentRepository, AppointmentRepository>();
builder.Services.AddScoped<IClinicalRepository, ClinicalRepository>();
builder.Services.AddScoped<IConstantRepository, ConstantRepository>();
builder.Services.AddScoped<ICounselorRepository, CounselorRepository>();
builder.Services.AddScoped<ICounselorAssignmentRepository, CounselorAssignmentRepository>();
builder.Services.AddScoped<INotificationRepository, NotificationRepository>();
builder.Services.AddScoped<IReportRepository, ReportRepository>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();

    // DEVELOPMENT ONLY: distinguish 'API is listening' from 'SQL is reachable'.
    app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "CounselLink API" }));
    app.MapGet("/health/db", (IDbConnectionFactory factory) =>
    {
        using var connection = factory.CreateConnection();
        connection.Open();
        return Results.Ok(new { status = "ok", database = connection.Database });
    });
}
else
{
    app.UseHttpsRedirection();
}

// No CORS/authentication is configured in this recovery scaffold.
// DO NOT deploy or expose it publicly before adding authentication,
// authorization, precise CORS origins, safe error handling, and HTTPS.
app.MapControllers();
app.Run();
