// ===== CONFIGURACIÓN DE LA API =====

using MentesConectadasAPI.Data;
using MentesConectadasAPI.Services;
using Microsoft.AspNetCore.RateLimiting;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "bearer",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Description = "Pega solo el token (sin la palabra Bearer)"
    });
    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

builder.Services.AddSingleton<AccesoSql>();

// ----- CORREOS -----
builder.Services.AddSingleton<EnvioCorreo>();

// ----- DONACIONES -----
builder.Services.AddHttpClient();
builder.Services.AddSingleton<PagosDonacion>();
builder.Services.AddHostedService<SincronizadorDonaciones>();

// ----- CHATBOT MENTYBOT -----
builder.Services.AddHttpClient<ChatbotIA>();
builder.Services.AddScoped<ChatbotIA>();

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    // Recuperar contraseña
    options.AddPolicy("recuperacion", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            httpContext.Connection.RemoteIpAddress?.ToString() ?? "desconocida",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 5,
                Window = TimeSpan.FromMinutes(10),
                QueueLimit = 0
            }));

    options.AddFixedWindowLimiter("chatbot", opt =>
    {
        opt.PermitLimit = 10;
        opt.Window = TimeSpan.FromMinutes(1);
        opt.QueueLimit = 0;
    });
});

builder.Services.AddCors(options =>
{
    options.AddPolicy("NuevaPolitica", app =>
    {
        app.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseDefaultFiles();
app.UseStaticFiles(new StaticFileOptions
{
    OnPrepareResponse = ctx =>
    {
        if (ctx.Context.Request.Path.StartsWithSegments("/assets"))
            ctx.Context.Response.Headers["Cache-Control"] = "public,max-age=604800";
    }
});

app.UseCors("NuevaPolitica");
app.UseRateLimiter();
app.UseAuthorization();

app.MapControllers();

app.Run();
