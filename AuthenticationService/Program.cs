using AuthenticationService.Data;
using AuthenticationService.Service;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
// builder.Services.AddOpenApi();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Configure Swagger with proper API info
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Authentication Service API",
        Version = "v1",
        Description = "Microservice for user authentication and management",
        Contact = new OpenApiContact
        {
            Name = "Development Team",
            Email = "dev@company.com"
        }
    });
    
    // Enable annotations
    c.EnableAnnotations();
    
    // Include XML documentation
    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        c.IncludeXmlComments(xmlPath);
    }
    
    // Add JWT Bearer authentication to Swagger
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Enter 'Bearer' [space] and then your token in the text input below.",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// Add health checks
builder.Services.AddHealthChecks();

// Configure DbContext
builder.Services.AddDbContext<AuthDbContext>(options => 
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"))
);

// add HttpClient for EmailService
builder.Services.AddHttpClient("EmailService", client => {
    var emailServiceUrl = builder.Configuration["Services:EmailService"] ?? "http://email-service:80";
    client.BaseAddress = new Uri(emailServiceUrl);
});

// add service
builder.Services.AddScoped<AuthService>();

// add Kafka producer service
builder.Services.AddSingleton<KafkaProducerService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
// Enable Swagger based on environment or ENABLE_SWAGGER environment variable
var enableSwagger = app.Environment.IsDevelopment() || 
                   bool.Parse(app.Configuration.GetValue<string>("ENABLE_SWAGGER") ?? "false");

if (enableSwagger)
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Add health check endpoint
app.MapHealthChecks("/health");

app.UseHttpsRedirection();
app.MapControllers();

app.Run();
