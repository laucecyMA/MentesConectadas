// ===== SINCRONIZACIÓN DE DONACIONES =====

using MentesConectadasAPI.Data;
using static MentesConectadasAPI.Data.AccesoSql;

namespace MentesConectadasAPI.Services
{
    public class SincronizadorDonaciones : BackgroundService
    {
        private static readonly TimeSpan Intervalo = TimeSpan.FromSeconds(20);
        private static readonly TimeSpan VentanaIntencion = TimeSpan.FromHours(6);
        private static readonly TimeSpan VentanaPendiente = TimeSpan.FromDays(3);
        private const int MaximoPorVuelta = 30;

        private readonly PagosDonacion _pagos;
        private readonly AccesoSql _sql;
        private readonly ILogger<SincronizadorDonaciones> _logger;

        public SincronizadorDonaciones(PagosDonacion pagos, AccesoSql sql, ILogger<SincronizadorDonaciones> logger)
        {
            _pagos = pagos;
            _sql = sql;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken detener)
        {
            try
            {
                await Task.Delay(TimeSpan.FromSeconds(10), detener);

                while (!detener.IsCancellationRequested)
                {
                    try
                    {
                        if (_pagos.Configurado) await RevisarAsync(detener);
                    }
                    catch (Exception ex) when (ex is not OperationCanceledException)
                    {
                        _logger.LogWarning(ex, "No se pudieron sincronizar las donaciones pendientes");
                    }

                    await Task.Delay(Intervalo, detener);
                }
            }
            catch (OperationCanceledException)
            {
            }
        }

        private async Task RevisarAsync(CancellationToken detener)
        {
            var lista = await _sql.ConsultarAsync("sp_adminListaDonaciones",
                l => new { Id = Convert.ToInt32(l["IdDonacion"]), Estado = (l["Estado"].ToString() ?? string.Empty).Trim(), Fecha = Convert.ToDateTime(l["Fecha"]) });

            var ahora = DateTime.Now;
            var porRevisar = lista
                .Where(d => (d.Estado == "intencion" && ahora - d.Fecha < VentanaIntencion)
                         || (d.Estado == "pendiente" && ahora - d.Fecha < VentanaPendiente))
                .Take(MaximoPorVuelta)
                .ToList();

            foreach (var d in porRevisar)
            {
                if (detener.IsCancellationRequested) return;
                await _pagos.SincronizarDonacionAsync(d.Id);
            }
        }
    }
}
