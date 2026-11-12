
using CounselLink.API.Data;
using CounselLink.API.Repositories;
using CounselLink.API.Swagger;

var builder = WebApplication.CreateBuilder(args);

// ==========================================
// CONTROLLERS
// ==========================================
builder.Services.AddControllers();

// ==========================================
// CORS - ANGULAR FRONTEND
// ==========================================
builder.Services.AddCors(options =>
{
    options.AddPolicy("AngularDev", policy =>
    {
        policy.WithOrigins(
                "http://localhost:4800",
                "http://localhost:4200"
            )
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

// ==========================================
// SWAGGER / OPENAPI
// ==========================================
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(options =>
{
    options.SchemaFilter<ExampleSchemaFilter>();

    var xmlFile =
        $"{typeof(Program).Assembly.GetName().Name}.xml";

    var xmlPath =
        Path.Combine(AppContext.BaseDirectory, xmlFile);

    if (File.Exists(xmlPath))
    {
        options.IncludeXmlComments(xmlPath);
    }
});

// ==========================================
// DATABASE CONNECTION
// ==========================================
builder.Services.AddScoped<
    IDbConnectionFactory,
    SqlConnectionFactory>();

// ==========================================
// REPOSITORIES
// ==========================================

// Appointment Repository
builder.Services.AddScoped<
    IAppointmentRepository,
    AppointmentRepository>();

// Clinical Repository
builder.Services.AddScoped<
    IClinicalRepository,
    ClinicalRepository>();

// Constants Repository
builder.Services.AddScoped<
    IConstantRepository,
    ConstantRepository>();

// Counselor Repository
builder.Services.AddScoped<
    ICounselorRepository,
    CounselorRepository>();

// Counselor Assignment Repository
builder.Services.AddScoped<
    ICounselorAssignmentRepository,
    CounselorAssignmentRepository>();

// NEW: Counselor Schedule Repository
builder.Services.AddScoped<
    ICounselorScheduleRepository,
    CounselorScheduleRepository>();

// Notification Repository
builder.Services.AddScoped<
    INotificationRepository,
    NotificationRepository>();

// Report Repository
builder.Services.AddScoped<
    IReportRepository,
    ReportRepository>();

// ==========================================
// BUILD APPLICATION
// ==========================================
var app = builder.Build();

// ==========================================
// SWAGGER
// ==========================================
// Enable Swagger in development/staging.
if (app.Environment.IsDevelopment() ||
    app.Environment.IsStaging())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// ==========================================
// HEALTH CHECK
// ==========================================
app.MapGet("/health", () =>
    Results.Ok(new
    {
        status = "ok",
        service = "CounselLink API"
    })
);

// ==========================================
// DATABASE HEALTH CHECK
// ==========================================
if (app.Environment.IsDevelopment())
{
    app.MapGet("/health/db",
        (IDbConnectionFactory factory) =>
    {
        using var connection =
            factory.CreateConnection();

        connection.Open();

        return Results.Ok(new
        {
            status = "ok",
            database = connection.Database
        });
    });
}

// ==========================================
// HTTPS REDIRECTION
// ==========================================
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

// ==========================================
// ROUTING AND CORS
// ==========================================
app.UseRouting();

app.UseCors("AngularDev");

// ==========================================
// MAP API CONTROLLERS
// ==========================================
app.MapControllers();

// ==========================================
// RUN APPLICATION
// ==========================================
app.Run();
