// ===== PAGOS DE DONACIONES MERCADO PAGO =====

using System.Data;
using System.Data.SqlClient;
using System.Net.Http.Headers;
using System.Text.Json;
using MentesConectadasAPI.Data;
using static MentesConectadasAPI.Data.AccesoSql;

namespace MentesConectadasAPI.Services
{
    public class PagosDonacion
    {
        private const string UrlMercadoPago = "https://api.mercadopago.com";

        private readonly AccesoSql _sql;
        private readonly IConfiguration _configuration;
        private readonly IHttpClientFactory _httpFactory;
        private readonly ILogger<PagosDonacion> _logger;

        public PagosDonacion(AccesoSql sql, IConfiguration configuration, IHttpClientFactory httpFactory, ILogger<PagosDonacion> logger)
        {
            _sql = sql;
            _configuration = configuration;
            _httpFactory = httpFactory;
            _logger = logger;
        }

        private string AccessToken => _configuration["MercadoPago:AccessToken"] ?? string.Empty;

        public bool Configurado => AccessToken.Length >= 20;

        public async Task<string?> VerificarPagoAsync(string idPago)
        {
            if (idPago.Length is 0 or > 20 || !idPago.All(char.IsDigit) || !Configurado) return null;

            try
            {
                string? texto = await ConsultarAsync("/v1/payments/" + idPago);
                if (texto == null) return null;

                using var doc = JsonDocument.Parse(texto);
                return await ProcesarPagoAsync(doc.RootElement, idPago);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al verificar el pago {Pago}", idPago);
                return null;
            }
        }

        public async Task<string?> SincronizarDonacionAsync(int idDonacion)
        {
            if (!Configurado) return null;

            try
            {
                string? texto = await ConsultarAsync($"/v1/payments/search?external_reference={idDonacion}&sort=date_created&criteria=desc&limit=10");
                if (texto == null) return null;

                using var doc = JsonDocument.Parse(texto);
                if (!doc.RootElement.TryGetProperty("results", out var resultados) || resultados.ValueKind != JsonValueKind.Array || resultados.GetArrayLength() == 0)
                    return null;

                JsonElement? elegido = null;
                foreach (var pago in resultados.EnumerateArray())
                {
                    elegido ??= pago;
                    if (Texto(pago, "status") == "approved") { elegido = pago; break; }
                }

                string idPago = Texto(elegido!.Value, "id");
                if (idPago.Length == 0) return null;

                return await ProcesarPagoAsync(elegido.Value, idPago);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al sincronizar la donación {Donacion}", idDonacion);
                return null;
            }
        }

        private async Task<string?> ProcesarPagoAsync(JsonElement pago, string idPago)
        {
            string status = Texto(pago, "status");
            string detalle = Texto(pago, "status_detail");
            string metodo = Texto(pago, "payment_method_id");
            string moneda = Texto(pago, "currency_id");
            decimal montoPagado = pago.TryGetProperty("transaction_amount", out var m) && m.ValueKind == JsonValueKind.Number ? m.GetDecimal() : 0m;

            DateTime? fechaAprobado = null;
            if (DateTimeOffset.TryParse(Texto(pago, "date_approved"), out var fecha)) fechaAprobado = fecha.LocalDateTime;

            if (!int.TryParse(Texto(pago, "external_reference"), out int idDonacion)) return null;

            var guardada = (await _sql.ConsultarAsync("sp_obtenerDonacion",
                l => new { Monto = Convert.ToDecimal(l["Monto"]), Moneda = (l["Moneda"].ToString() ?? "MXN").Trim() },
                Param("@IdDonacion", idDonacion))).FirstOrDefault();

            if (guardada == null) return null;
            if (guardada.Monto != montoPagado || (moneda.Length > 0 && !string.Equals(guardada.Moneda, moneda, StringComparison.OrdinalIgnoreCase)))
            {
                _logger.LogWarning("El pago {Pago} no coincide con la donación {Donacion} (pagado {Pagado} {Moneda}, esperado {Esperado})",
                    idPago, idDonacion, montoPagado, moneda, guardada.Monto);
                return null;
            }

            string estado = status switch
            {
                "approved" => "confirmada",
                "rejected" or "cancelled" => "rechazada",
                "refunded" or "charged_back" => "reembolsada",
                _ => "pendiente"
            };

            var pNumeroError = SalidaInt("@numeroError");
            var pRespuesta = SalidaTexto("@respuesta");
            await _sql.EjecutarAsync("sp_registrarPagoDonacion",
                Param("@IdDonacion", idDonacion),
                Param("@Estado", estado),
                Param("@IdPagoProveedor", idPago),
                Param("@MetodoPago", Recortar(metodo, 40)),
                Param("@DetalleEstado", Recortar(detalle, 60)),
                Param("@FechaPago", fechaAprobado),
                pNumeroError, pRespuesta);

            if (Convert.ToInt32(pNumeroError.Value) != 0)
            {
                _logger.LogWarning("sp_registrarPagoDonacion: {Respuesta}", Convert.ToString(pRespuesta.Value));
                return null;
            }

            var final = await _sql.ConsultarAsync("sp_obtenerDonacion", l => (l["Estado"].ToString() ?? estado).Trim(), Param("@IdDonacion", idDonacion));
            string resultado = final.FirstOrDefault() ?? estado;
            _logger.LogInformation("Donación {Donacion}: pago {Pago} -> {Estado}", idDonacion, idPago, resultado);
            return resultado;
        }

        private async Task<string?> ConsultarAsync(string ruta)
        {
            using var peticion = new HttpRequestMessage(HttpMethod.Get, UrlMercadoPago + ruta);
            peticion.Headers.Authorization = new AuthenticationHeaderValue("Bearer", AccessToken);

            using var respuesta = await _httpFactory.CreateClient().SendAsync(peticion);
            string texto = await respuesta.Content.ReadAsStringAsync();

            if (!respuesta.IsSuccessStatusCode)
            {
                _logger.LogWarning("Mercado Pago respondió {Codigo} a {Ruta}: {Texto}", (int)respuesta.StatusCode, ruta, texto);
                return null;
            }
            return texto;
        }

        private static string Texto(JsonElement el, string propiedad) =>
            el.TryGetProperty(propiedad, out var v) && v.ValueKind != JsonValueKind.Null ? v.ToString() : string.Empty;

        private static string? Recortar(string valor, int maximo) =>
            valor.Length == 0 ? null : (valor.Length <= maximo ? valor : valor.Substring(0, maximo));
    }
}
