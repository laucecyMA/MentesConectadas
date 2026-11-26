// ===== ENVÍO DE CORREOS =====

using System.Net;
using System.Net.Mail;
using System.Net.Mime;
using System.Text;

namespace MentesConectadasAPI.Services
{
    public class EnvioCorreo
    {
        private const string IdBanner = "banner-mc";
        private const string RutaBanner = "assets/img/banner-correo.png";

        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _entorno;
        private readonly ILogger<EnvioCorreo> _logger;
        private byte[]? _banner;
        private bool _bannerLeido;

        public EnvioCorreo(IConfiguration configuration, IWebHostEnvironment entorno, ILogger<EnvioCorreo> logger)
        {
            _configuration = configuration;
            _entorno = entorno;
            _logger = logger;
        }

        private string Host
        {
            get
            {
                string h = (_configuration["Correo:Host"] ?? string.Empty).Trim();
                return h.Length > 0 ? h : "smtp.gmail.com";
            }
        }
        private int Puerto => int.TryParse(_configuration["Correo:Puerto"], out int p) && p > 0 ? p : 587;
        private string Usuario => (_configuration["Correo:Usuario"] ?? string.Empty).Trim();
        
        private string Clave => (_configuration["Correo:Clave"] ?? string.Empty).Replace(" ", string.Empty).Trim();
        private string Remitente
        {
            get
            {
                string r = (_configuration["Correo:Remitente"] ?? string.Empty).Trim();
                return r.Length > 0 ? r : Usuario;
            }
        }

        public bool Configurado => Usuario.Length > 0 && Clave.Length > 0;


        public string? UrlSitio(HttpRequest peticion)
        {
            string? url = _configuration["Correo:UrlSitio"];
            if (string.IsNullOrWhiteSpace(url)) url = _configuration["MercadoPago:UrlPublica"];

            if (string.IsNullOrWhiteSpace(url))
            {
                string? sitioAzure = Environment.GetEnvironmentVariable("WEBSITE_HOSTNAME");
                if (!string.IsNullOrWhiteSpace(sitioAzure)) url = "https://" + sitioAzure.Trim();
            }

            if (string.IsNullOrWhiteSpace(url) && _entorno.IsDevelopment())
                url = $"{peticion.Scheme}://{peticion.Host}";

            if (string.IsNullOrWhiteSpace(url)) return null;

            url = url.Trim().TrimEnd('/');
            bool valida = url.StartsWith("https://", StringComparison.OrdinalIgnoreCase)
                       || url.StartsWith("http://", StringComparison.OrdinalIgnoreCase);
            return valida ? url : null;
        }

        
        public void EnSegundoPlano(string descripcion, Func<Task> envio)
        {
            _ = Task.Run(async () =>
            {
                try { await envio(); }
                catch (Exception ex) { _logger.LogError(ex, "No se pudo enviar el correo ({Descripcion})", descripcion); }
            });
        }

        // ----- BIENVENIDA -----
        public Task EnviarBienvenidaAsync(string para, string nombre, string tipo, string urlSitio)
        {
            string primerNombre = nombre.Split(' ', StringSplitOptions.RemoveEmptyEntries).FirstOrDefault() ?? nombre;
            string enlaceLogin = urlSitio + "/#dashboard";

            string cuerpo =
                $"<h1 style=\"margin:0 0 12px;font-size:24px;line-height:1.25;color:#1b2442\">¡Hola, {H(primerNombre)}!</h1>" +
                $"<p style=\"margin:0 0 12px\">Tu cuenta como <strong>{H(tipo)}</strong> en Mentes Conectadas se creó correctamente. Ya puedes iniciar sesión y empezar a usar la plataforma.</p>" +
                "<ul style=\"margin:0 0 4px;padding-left:20px;color:#1b2442\">" +
                "<li style=\"margin-bottom:6px\"><strong>Guías prácticas</strong> para situaciones del aula y otros espacios universitarios.</li>" +
                "<li style=\"margin-bottom:6px\"><strong>Autoevaluaciones</strong> para comprobar lo que aprendiste de cada guía.</li>" +
                "<li><strong>Información</strong> sobre neurodivergencia en el contexto universitario.</li></ul>" +
                Boton(enlaceLogin, "Ir a Mentes Conectadas") +
                "<table role=\"presentation\" width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\" bgcolor=\"#efeafb\" style=\"background:#efeafb;border-radius:14px\"><tr><td style=\"padding:18px 20px\">" +
                "<div style=\"font-size:11px;font-weight:bold;letter-spacing:1px;color:#5a47b0\">ASISTENTE VIRTUAL</div>" +
                "<div style=\"font-size:18px;font-weight:bold;line-height:1.3;margin:6px 0;color:#1b2442\">¿Tienes dudas sobre neurodivergencia? Pregúntale a MentyBot.</div>" +
                "<div style=\"font-size:14px;line-height:1.5;color:#4a5678\">Haz tus preguntas y encuentra información y guías para comprender mejor. Inicia sesión y chatea con MentyBot desde la página.</div>" +
                $"<a href=\"{H(enlaceLogin)}\" target=\"_blank\" style=\"display:inline-block;margin-top:12px;font-size:14px;font-weight:bold;color:#5a47b0;text-decoration:none\">Conocer a MentyBot &rarr;</a>" +
                "<div style=\"font-size:12px;line-height:1.5;color:#6b7592;margin-top:12px\">Importante: MentyBot no sustituye a un psicólogo. Para más información, acude a un especialista o profesional del área.</div>" +
                "</td></tr></table>";

            string pie = "Recibiste este correo porque se creó una cuenta con esta dirección en Mentes Conectadas. Si no fuiste tú, puedes ignorar este mensaje.";

            string texto =
                $"¡Hola, {primerNombre}!\n\n" +
                $"Tu cuenta como {tipo} en Mentes Conectadas se creó correctamente. Ya puedes iniciar sesión:\n{enlaceLogin}\n\n" +
                "¿Tienes dudas sobre neurodivergencia? Pregúntale a MentyBot dentro de la página.\n" +
                "MentyBot no sustituye a un psicólogo.\n\n" + pie;

            return EnviarAsync(para, "¡Tu cuenta en Mentes Conectadas está lista!", Plantilla("Bienvenido/a a Mentes Conectadas", cuerpo, pie, urlSitio), texto);
        }

        // ----- RECUPERAR CONTRASEÑA -----
        public Task EnviarRecuperacionAsync(string para, string nombre, string enlace, int minutosVigencia, string urlSitio)
        {
            string primerNombre = nombre.Split(' ', StringSplitOptions.RemoveEmptyEntries).FirstOrDefault() ?? nombre;

            string cuerpo =
                $"<h1 style=\"margin:0 0 12px;font-size:24px;line-height:1.25;color:#1b2442\">Hola, {H(primerNombre)}</h1>" +
                "<p style=\"margin:0 0 12px\">Recibimos una solicitud para cambiar la contraseña de tu cuenta en Mentes Conectadas. Presiona el botón para crear una nueva.</p>" +
                Boton(enlace, "Crear nueva contraseña") +
                $"<p style=\"margin:0 0 12px;font-size:14px;color:#4a5678\">Este enlace funciona durante <strong>{minutosVigencia} minutos</strong> y solo se puede usar una vez.</p>" +
                "<p style=\"margin:0 0 4px;font-size:13px;color:#6b7592\">Si el botón no funciona, copia y pega esta dirección en tu navegador:</p>" +
                $"<p style=\"margin:0 0 12px;font-size:12px;line-height:1.5;word-break:break-all;color:#5a47b0\">{H(enlace)}</p>";

            string pie = "Si tú no pediste este cambio, ignora este mensaje: tu contraseña actual sigue funcionando y nadie puede cambiarla sin este enlace.";

            string texto =
                $"Hola, {primerNombre}\n\n" +
                "Recibimos una solicitud para cambiar la contraseña de tu cuenta en Mentes Conectadas.\n" +
                $"Crea una nueva contraseña aquí (el enlace dura {minutosVigencia} minutos y solo se usa una vez):\n{enlace}\n\n" + pie;

            return EnviarAsync(para, "Restablece tu contraseña de Mentes Conectadas", Plantilla("Restablecer contraseña", cuerpo, pie, urlSitio), texto);
        }

        // ----- AVISO DE CONTRASEÑA CAMBIADA -----
        public Task EnviarContrasenaCambiadaAsync(string para, string nombre, string urlSitio)
        {
            string primerNombre = nombre.Split(' ', StringSplitOptions.RemoveEmptyEntries).FirstOrDefault() ?? nombre;
            string enlaceLogin = urlSitio + "/#login";

            string cuerpo =
                $"<h1 style=\"margin:0 0 12px;font-size:24px;line-height:1.25;color:#1b2442\">Tu contraseña se cambió, {H(primerNombre)}</h1>" +
                "<p style=\"margin:0 0 12px\">La contraseña de tu cuenta en Mentes Conectadas se actualizó correctamente. Ya puedes iniciar sesión con la nueva.</p>" +
                Boton(enlaceLogin, "Iniciar sesión") +
                "<p style=\"margin:0 0 12px;font-size:14px;color:#4a5678\">Si no fuiste tú, solicita otro cambio de contraseña desde la página lo antes posible.</p>";

            string pie = "Este aviso se envía cada vez que cambia la contraseña de una cuenta.";

            string texto =
                $"Hola, {primerNombre}\n\nLa contraseña de tu cuenta en Mentes Conectadas se actualizó correctamente.\n" +
                $"Inicia sesión aquí: {enlaceLogin}\n\nSi no fuiste tú, solicita otro cambio de contraseña desde la página lo antes posible.\n\n" + pie;

            return EnviarAsync(para, "Tu contraseña de Mentes Conectadas se cambió", Plantilla("Contraseña actualizada", cuerpo, pie, urlSitio), texto);
        }

        // ----- ENVÍO -----
        private async Task EnviarAsync(string para, string asunto, string html, string texto)
        {
            if (!Configurado)
            {
                _logger.LogWarning("Correo no enviado ({Asunto}): falta configurar Correo:Usuario y Correo:Clave.", asunto);
                return;
            }

            using var mensaje = new MailMessage
            {
                From = new MailAddress(Remitente, "Mentes Conectadas", Encoding.UTF8),
                Subject = asunto,
                SubjectEncoding = Encoding.UTF8,
                BodyEncoding = Encoding.UTF8,
                IsBodyHtml = true
            };
            mensaje.To.Add(new MailAddress(para));

            
            mensaje.AlternateViews.Add(AlternateView.CreateAlternateViewFromString(texto, Encoding.UTF8, MediaTypeNames.Text.Plain));

            var vistaHtml = AlternateView.CreateAlternateViewFromString(html, Encoding.UTF8, MediaTypeNames.Text.Html);
            byte[]? banner = LeerBanner();
            if (banner != null)
            {
                vistaHtml.LinkedResources.Add(new LinkedResource(new MemoryStream(banner), "image/png")
                {
                    ContentId = IdBanner,
                    TransferEncoding = TransferEncoding.Base64
                });
            }
            mensaje.AlternateViews.Add(vistaHtml);

            using var smtp = new SmtpClient(Host, Puerto)
            {
                EnableSsl = true,
                DeliveryMethod = SmtpDeliveryMethod.Network,
                UseDefaultCredentials = false,
                Credentials = new NetworkCredential(Usuario, Clave),
                Timeout = 20000
            };
            await smtp.SendMailAsync(mensaje);
            _logger.LogInformation("Correo enviado: {Asunto}", asunto);
        }

        private byte[]? LeerBanner()
        {
            if (_bannerLeido) return _banner;
            _bannerLeido = true;
            try
            {
                string ruta = Path.Combine(_entorno.WebRootPath ?? string.Empty, RutaBanner.Replace('/', Path.DirectorySeparatorChar));
                if (File.Exists(ruta)) _banner = File.ReadAllBytes(ruta);
                else _logger.LogWarning("No se encontró el banner del correo en {Ruta}", ruta);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "No se pudo leer el banner del correo");
            }
            return _banner;
        }

        
        private string Plantilla(string titulo, string cuerpo, string pie, string urlSitio)
        {
            string encabezado = LeerBanner() != null
                ? $"<a href=\"{H(urlSitio)}/\" target=\"_blank\" style=\"text-decoration:none\"><img src=\"cid:{IdBanner}\" width=\"600\" alt=\"Mentes Conectadas: inclusión y aprendizaje\" style=\"display:block;width:100%;max-width:600px;height:auto;border:0;border-radius:16px 16px 0 0\"></a>"
                : "<div style=\"background:#172333;color:#ffffff;padding:28px 32px;font-size:24px;font-weight:bold;border-radius:16px 16px 0 0\">Mentes Conectadas</div>";

            return
                "<!DOCTYPE html><html lang=\"es\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">" +
                $"<title>{H(titulo)}</title></head>" +
                "<body style=\"margin:0;padding:0;background:#e4ebfb\">" +
                "<table role=\"presentation\" width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\" bgcolor=\"#e4ebfb\" style=\"background:#e4ebfb\"><tr><td align=\"center\" style=\"padding:24px 12px\">" +
                "<table role=\"presentation\" width=\"600\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\" bgcolor=\"#ffffff\" style=\"width:100%;max-width:600px;background:#ffffff;border-radius:16px;font-family:Arial,Helvetica,sans-serif;color:#1b2442\">" +
                $"<tr><td>{encabezado}</td></tr>" +
                $"<tr><td style=\"padding:28px 32px 12px 32px;font-family:Arial,Helvetica,sans-serif;font-size:15px;line-height:1.6;color:#1b2442\">{cuerpo}</td></tr>" +
                $"<tr><td style=\"padding:16px 32px 28px 32px;font-family:Arial,Helvetica,sans-serif;font-size:12px;line-height:1.5;color:#6b7592\">{H(pie)}<br><br>Mentes Conectadas &middot; Inclusión y aprendizaje<br>Este es un mensaje automático, por favor no respondas a este correo.</td></tr>" +
                "</table></td></tr></table></body></html>";
        }

        private static string Boton(string url, string texto) =>
            "<table role=\"presentation\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\" style=\"margin:22px 0\"><tr>" +
            "<td bgcolor=\"#5a47b0\" style=\"background:#5a47b0;border-radius:999px\">" +
            $"<a href=\"{H(url)}\" target=\"_blank\" style=\"display:inline-block;padding:14px 28px;font-family:Arial,Helvetica,sans-serif;font-size:15px;font-weight:bold;color:#ffffff;text-decoration:none;border-radius:999px\">{H(texto)}</a>" +
            "</td></tr></table>";

        private static string H(string texto) => WebUtility.HtmlEncode(texto);
    }
}
