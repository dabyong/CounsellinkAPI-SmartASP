
using CounselLink.API.Data;
using CounselLink.API.Repositories;
using CounselLink.API.Swagger;

var builder = WebApplication.CreateBuilder(args);

// Controllers
builder.Services.AddControllers();

// CORS for Angular 8 development frontends
builder.Services.AddCors(options =>
{
    options.AddPolicy("AngularDev", policy =>
    {
        policy.WithOrigins("http://localhost:4200")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Swagger / OpenAPI
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

// Database connection
builder.Services.AddScoped<IDbConnectionFactory, SqlConnectionFactory>();

// Repositories
builder.Services.AddScoped<IAppointmentRepository, AppointmentRepository>();
builder.Services.AddScoped<IClinicalRepository, ClinicalRepository>();
builder.Services.AddScoped<IConstantRepository, ConstantRepository>();
builder.Services.AddScoped<ICounselorRepository, CounselorRepository>();
builder.Services.AddScoped<ICounselorAssignmentRepository, CounselorAssignmentRepository>();
builder.Services.AddScoped<INotificationRepository, NotificationRepository>();
builder.Services.AddScoped<IReportRepository, ReportRepository>();

var app = builder.Build();

// Swagger available for local development and staging
if (app.Environment.IsDevelopment() || app.Environment.IsStaging())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Basic health check
app.MapGet("/health", () =>
    Results.Ok(new
    {
        status = "ok",
        service = "CounselLink API"
    })
);

// Database health check - local development only
if (app.Environment.IsDevelopment())
{
    app.MapGet("/health/db", (IDbConnectionFactory factory) =>
    {
        using var connection = factory.CreateConnection();
        connection.Open();

        return Results.Ok(new
        {
            status = "ok",
            database = connection.Database
        });
    });
}

// HTTPS for hosted environments
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

// Routing and Angular CORS
app.UseRouting();
app.UseCors("AngularDev");

// Controller endpoints
app.MapControllers();

app.Run();
