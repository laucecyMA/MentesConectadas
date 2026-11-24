# Mentes Conectadas

PWA con información y orientación práctica sobre neurodivergencia (Autismo, TDAH, Dislexia, Discalculia y Dispraxia) en el entorno universitario. Incluye guías con video, autoevaluaciones, favoritos, calificaciones y comentarios, panel del administrador, donaciones con Mercado Pago, asistente con IA (MentyBot) e idioma ES / EN.

## Tecnologías
- **Backend:** ASP.NET Core 8  + SQL Server 
- **Frontend:** HTML, CSS y JavaScript, PWA con Service Worker. El proyecto esta dentro de MentesConectadasAPI/wwwroot
- **Servicios externos:** Mercado Pago para donaciones, Gemini y Groq para el MentyBot

## Estructura

BaseDatos/
  Scripts.sql              Base de datos para SQL Server local
  Scripts_AzureSQL.sql     Misma base de datos para Azure SQL Database
MentesConectadasAPI/       API (Controllers, Services, Models, Helpers, Data)
  wwwroot/                 Frontend (index.html, js, css, content, assets)
MentesConectadasAPI.sln


## Requisitos
- Visual Studio 2022 con "ASP.NET y desarrollo web" (.NET 8)
- SQL Server 2016 o superior y SQL Server Management Studio

## Instalación
1. Base de datos: abre BaseDatos/Scripts.sql en SSMS y ejecútalo completo (F5). Crea MentesConectadasDB con tablas, stored procedure y datos.
2. Cadena de conexión: en MentesConectadasAPI/appsettings.json, llave ConnectionStrings:CadenaSQL:
   Server=localhost;Database=MentesConectadasDB;Trusted_Connection=True;TrustServerCertificate=True;
   
3. Llaves y secretos: Configúralos con User Secrets (clic derecho al proyecto > "Administrar secretos de usuario") o variables de entorno:
   json
   {
     "Admin": { "ClaveToken": "una-clave-larga-y-aleatoria" },
     "Chatbot": { "Gemini": { "ApiKey": "..." }, "Groq": { "ApiKey": "..." } },
     "MercadoPago": { "AccessToken": "...", "UrlPublica": "", "UrlNotificacion": "" }
   }
   
   Admin:ClaveToken es obligatoria para iniciar sesión. Sin las llaves de IA o de Mercado Pago, el resto de la app funciona.
4. Ejecutar: abre MentesConectadasAPI.sln y presiona F5. La app abre en http://localhost:61556 

## Credenciales de prueba
| Rol | Correo | Contraseña |
| Administrador | adminmentesconectadas@gmail.com | MentesConect123 |
| Estudiante | estudiante.prueba@correo.com | Estudiante123 |
| Docente | docente.prueba@correo.com | Docente123 |

## Videos de las guías
Cada guía lee su video desde la base de datos. Coloca los archivos .mp4 con estos nombres exactos:

| Carpeta MentesConectadasAPI/wwwroot/assets/videos/autismo/ | Carpeta .../tdah/ |
|---|---|
| autismo-sobrecarga.mp4 | tdah-sobrecarga.mp4 |
| autismo-comunicacion.mp4 | tdah-comunicacion.mp4 |
| autismo-trabajo-equipo.mp4 | tdah-trabajo-equipo.mp4 |
| autismo-examen.mp4 | tdah-examen.mp4 |
| autismo-cambios.mp4 | tdah-cambios.mp4 |
| autismo-participacion.mp4 | tdah-participacion.mp4 |
| autismo-retroalimentacion.mp4 | tdah-retroalimentacion.mp4 |
| autismo-correccion.mp4 | tdah-correccion.mp4 |

Si un video no existe, la guía se muestra sin él. 

## Publicación
Pasos para GitHub y Azure 

