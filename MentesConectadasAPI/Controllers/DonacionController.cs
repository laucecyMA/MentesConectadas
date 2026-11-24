// ===== DONACIONES MERCADO PAGO =====

using System.Data;
using System.Data.SqlClient;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Mvc;
using MentesConectadasAPI.Data;
using MentesConectadasAPI.Helpers;
using MentesConectadasAPI.Models;
using MentesConectadasAPI.Services;
using static MentesConectadasAPI.Data.AccesoSql;

namespace MentesConectadasAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DonacionController : ControllerBase
    {
        private const string UrlMercadoPago = "https://api.mercadopago.com";
        private const decimal MontoMinimo = 10m;
        private const decimal MontoMaximo = 100000m;

        private readonly AccesoSql _sql;
        private readonly IConfiguration _configuration;
        private readonly IHttpClientFactory _httpFactory;
        private readonly ILogger<DonacionController> _logger;
        private readonly PagosDonacion _pagos;

        public DonacionController(AccesoSql sql, IConfiguration configuration, IHttpClientFactory httpFactory, ILogger<DonacionController> logger, PagosDonacion pagos)
        {
            _sql = sql;
            _configuration = configuration;
            _httpFactory = httpFactory;
            _logger = logger;
            _pagos = pagos;
        }

        
        private string AccessToken => _configuration["MercadoPago:AccessToken"] ?? string.Empty;

        // ----- INICIAR LA DONACIÓN -----

        // POST iniciar, iniciarDonacion y asignarPreferenciaDonacion
        [HttpPost("iniciar")]
        public async Task<IActionResult> Iniciar([FromBody] DonacionIniciarRequest r)
        {
            if (AccessToken.Length < 20)
                return StatusCode(503, Respuesta.Fallo(503, "El pago en línea todavía no está configurado en el servidor."));

            decimal monto = Math.Round(r.Monto, 2);
            string nombre = (r.Nombre ?? string.Empty).Trim();
            string correo = Validar.Correo(r.Correo);
            string mensaje = (r.Mensaje ?? string.Empty).Trim();

            if (monto < MontoMinimo || monto > MontoMaximo) return Invalido("El monto de la donación debe ser de $10 a $100,000");
            if (nombre.Length == 0 || nombre.Length > 100) return Invalido("Escribe tu nombre (máximo 100 caracteres)");
            if (!Validar.CorreoValido(correo)) return Invalido("Escribe un correo electrónico válido");
            if (mensaje.Length > 200) return Invalido("El mensaje puede tener máximo 200 caracteres");

            try
            {
                var pIdDonacion = SalidaInt("@IdDonacion");
                var pNumeroError = SalidaInt("@numeroError");
                var pRespuesta = SalidaTexto("@respuesta");

                await _sql.EjecutarAsync("sp_iniciarDonacion",
                    Param("@IdUsuario", IdUsuarioOpcional()),
                    Param("@NombreDonante", nombre),
                    Param("@CorreoDonante", correo),
                    ParamMonto(monto),
                    Param("@OtraCantidad", r.OtraCantidad),
                    Param("@Mensaje", mensaje.Length == 0 ? null : mensaje),
                    pIdDonacion, pNumeroError, pRespuesta);

                int numeroError = Convert.ToInt32(pNumeroError.Value);
                if (numeroError != 0) return BadRequest(Respuesta.Fallo(numeroError, Convert.ToString(pRespuesta.Value) ?? string.Empty));

                int idDonacion = Convert.ToInt32(pIdDonacion.Value);

                string baseUrl = BaseUrlPublica();
                string retorno = baseUrl + "/api/Donacion/retorno";
                string? notificacion = _configuration["MercadoPago:UrlNotificacion"];

                bool ingles = string.Equals(r.Idioma, "en", StringComparison.OrdinalIgnoreCase);

                var cuerpo = new
                {
                    items = new[]
                    {
                        new
                        {
                            id = "donacion-" + idDonacion,
                            title = ingles ? "Donation to Mentes Conectadas" : "Donación a Mentes Conectadas",
                            description = ingles ? "Voluntary contribution" : "Aportación voluntaria",
                            quantity = 1,
                            currency_id = "MXN",
                            unit_price = monto
                        }
                    },
                    payer = new { name = nombre, email = correo },
                    external_reference = idDonacion.ToString(),
                    back_urls = new { success = retorno, pending = retorno, failure = retorno },
                    auto_return = baseUrl.StartsWith("https://") ? "approved" : null,
                    statement_descriptor = "MENTESCONECTADAS",
                    notification_url = string.IsNullOrWhiteSpace(notificacion) ? null : notificacion.Trim()
                };

                var opciones = new JsonSerializerOptions { DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull };
                using var peticion = new HttpRequestMessage(HttpMethod.Post, UrlMercadoPago + "/checkout/preferences");
                peticion.Headers.Authorization = new AuthenticationHeaderValue("Bearer", AccessToken);
                peticion.Content = new StringContent(JsonSerializer.Serialize(cuerpo, opciones), Encoding.UTF8, "application/json");

                using var respuestaMp = await _httpFactory.CreateClient().SendAsync(peticion);
                string texto = await respuestaMp.Content.ReadAsStringAsync();

                if (!respuestaMp.IsSuccessStatusCode)
                {
                    _logger.LogError("Mercado Pago rechazó crear la preferencia ({Codigo}): {Texto}", (int)respuestaMp.StatusCode, texto);
                    return StatusCode(502, Respuesta.Fallo(502, "No se pudo iniciar el pago con Mercado Pago. Intenta de nuevo en un momento."));
                }

                using var doc = JsonDocument.Parse(texto);
                string idPreferencia = doc.RootElement.TryGetProperty("id", out var idEl) ? idEl.GetString() ?? string.Empty : string.Empty;

                bool sandbox = _configuration.GetValue<bool>("MercadoPago:UsarSandboxInitPoint");
                string campoUrl = sandbox ? "sandbox_init_point" : "init_point";
                string urlPago = doc.RootElement.TryGetProperty(campoUrl, out var urlEl) ? urlEl.GetString() ?? string.Empty : string.Empty;

                if (idPreferencia.Length == 0 || !urlPago.StartsWith("https://"))
                {
                    _logger.LogError("Respuesta inesperada de Mercado Pago: {Texto}", texto);
                    return StatusCode(502, Respuesta.Fallo(502, "Mercado Pago respondió algo inesperado. Intenta de nuevo."));
                }

                var pNum2 = SalidaInt("@numeroError");
                var pResp2 = SalidaTexto("@respuesta");
                await _sql.EjecutarAsync("sp_asignarPreferenciaDonacion",
                    Param("@IdDonacion", idDonacion), Param("@IdPreferencia", Recortar(idPreferencia, 100)), pNum2, pResp2);

                return Ok(Respuesta.Exito("Donación creada", new { idDonacion, urlPago, clave = Firmar(idDonacion) }));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al iniciar la donación");
                return StatusCode(500, Respuesta.Fallo(500, "No se pudo iniciar la donación."));
            }
        }

        // ----- REGRESO DESDE MERCADO PAGO -----

        // GET retorno
        [HttpGet("retorno")]
        public async Task<IActionResult> Retorno(
            [FromQuery(Name = "payment_id")] string? paymentId,
            [FromQuery(Name = "collection_id")] string? collectionId,
            [FromQuery(Name = "external_reference")] string? referencia)
        {
            string? idPago = new[] { paymentId, collectionId }.FirstOrDefault(v => !string.IsNullOrWhiteSpace(v) && v != "null");

            string estado = "cancelada";
            if (idPago != null)
                estado = await _pagos.VerificarPagoAsync(idPago.Trim()) ?? "error";
            else if (int.TryParse(referencia, out int idDonacion))
                estado = await _pagos.SincronizarDonacionAsync(idDonacion) ?? "cancelada";

            return Redirect("/donacion/resultado.html?estado=" + Uri.EscapeDataString(estado));
        }

        // ----- ESTADO -----

        // GET estado
        [HttpGet("estado")]
        public async Task<IActionResult> Estado([FromQuery] int id, [FromQuery] string? clave)
        {
            if (id <= 0 || !ClaveValida(id, clave)) return BadRequest(Respuesta.Fallo(400, "Solicitud no válida"));

            try
            {
                var d = await LeerEstadoAsync(id);
                if (d == null) return NotFound(Respuesta.Fallo(404, "No se encontró la donación"));

                if (d.Estado is "intencion" or "pendiente")
                {
                    await _pagos.SincronizarDonacionAsync(id);
                    d = await LeerEstadoAsync(id) ?? d;
                }

                return Ok(Respuesta.Exito("OK", new { estado = d.Estado, monto = d.Monto, moneda = d.Moneda, idPago = d.IdPago }));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al consultar el estado de la donación {Donacion}", id);
                return StatusCode(500, Respuesta.Fallo(500, "No se pudo consultar la donación."));
            }
        }

        // ----- AVISO AUTOMÁTICO -----

        // POST webhook
        [HttpPost("webhook")]
        public async Task<IActionResult> Webhook()
        {
            try
            {
                string? tipo = Request.Query["type"].FirstOrDefault() ?? Request.Query["topic"].FirstOrDefault();
                string? id = Request.Query["data.id"].FirstOrDefault() ?? Request.Query["id"].FirstOrDefault();

                if (string.IsNullOrEmpty(id))
                {
                    using var lector = new StreamReader(Request.Body);
                    string cuerpo = await lector.ReadToEndAsync();
                    if (!string.IsNullOrWhiteSpace(cuerpo))
                    {
                        using var doc = JsonDocument.Parse(cuerpo);
                        var raiz = doc.RootElement;
                        if (tipo == null && raiz.TryGetProperty("type", out var t)) tipo = t.GetString();
                        if (raiz.TryGetProperty("data", out var data) && data.TryGetProperty("id", out var idEl)) id = idEl.ToString();
                    }
                }

                if (tipo == "payment" && !string.IsNullOrWhiteSpace(id)) await _pagos.VerificarPagoAsync(id.Trim());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al procesar el webhook de Mercado Pago");
            }

            return Ok();
        }

        // ----- AUXILIARES -----

        private sealed record DonacionEstado(string Estado, decimal Monto, string Moneda, string IdPago);

        private async Task<DonacionEstado?> LeerEstadoAsync(int id) =>
            (await _sql.ConsultarAsync("sp_obtenerDonacion",
                l => new DonacionEstado((l["Estado"].ToString() ?? string.Empty).Trim(), Convert.ToDecimal(l["Monto"]), (l["Moneda"].ToString() ?? "MXN").Trim(), l["IdPagoProveedor"] as string ?? string.Empty),
                Param("@IdDonacion", id))).FirstOrDefault();

        private string Firmar(int idDonacion)
        {
            string secreto = _configuration["Admin:ClaveToken"] ?? string.Empty;
            if (secreto.Length == 0) secreto = AccessToken;
            using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secreto));
            return Convert.ToHexString(hmac.ComputeHash(Encoding.UTF8.GetBytes("donacion:" + idDonacion))).Substring(0, 32).ToLowerInvariant();
        }

        private bool ClaveValida(int idDonacion, string? clave) =>
            !string.IsNullOrEmpty(clave) && CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(Firmar(idDonacion)), Encoding.UTF8.GetBytes(clave));

        private string BaseUrlPublica()
        {
            string? configurada = _configuration["MercadoPago:UrlPublica"];
            return !string.IsNullOrWhiteSpace(configurada) ? configurada.Trim().TrimEnd('/') : $"{Request.Scheme}://{Request.Host}";
        }

        private int? IdUsuarioOpcional()
        {
            string cabecera = Request.Headers["Authorization"].ToString();
            if (!cabecera.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)) return null;

            DatosSesion? sesion = TokenSesion.Validar(cabecera.Substring(7).Trim(), _configuration["Admin:ClaveToken"] ?? string.Empty);
            return sesion?.IdUsuario;
        }

        private static SqlParameter ParamMonto(decimal monto) =>
            new SqlParameter("@Monto", SqlDbType.Decimal) { Precision = 10, Scale = 2, Value = monto };

        private static string Texto(JsonElement el, string propiedad) =>
            el.TryGetProperty(propiedad, out var v) && v.ValueKind != JsonValueKind.Null ? v.ToString() : string.Empty;

        private static string? Recortar(string valor, int maximo) =>
            valor.Length == 0 ? null : (valor.Length <= maximo ? valor : valor.Substring(0, maximo));

        private IActionResult Invalido(string mensaje) => BadRequest(Respuesta.Fallo(400, mensaje));
    }
}
