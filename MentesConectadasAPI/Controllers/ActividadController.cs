// ===== ACTIVIDAD DE LOS USUARIOS =====

using System.Data.SqlClient;
using Microsoft.AspNetCore.Mvc;
using MentesConectadasAPI.Data;
using MentesConectadasAPI.Helpers;
using MentesConectadasAPI.Models;
using static MentesConectadasAPI.Data.AccesoSql;

namespace MentesConectadasAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ActividadController : ControllerBase
    {
        private readonly AccesoSql _sql;
        private readonly IConfiguration _configuration;
        private readonly ILogger<ActividadController> _logger;

        public ActividadController(AccesoSql sql, IConfiguration configuration, ILogger<ActividadController> logger)
        {
            _sql = sql;
            _configuration = configuration;
            _logger = logger;
        }

        private int IdSesion => (int)HttpContext.Items["IdUsuario"]!;
        private bool EsAdmin => (HttpContext.Items["TipoUsuario"] as string) == "Administrador";

        // ----- VISTAS -----

        // POST registrarVista
        [HttpPost("vistas")]
        [SesionAuth]
        public async Task<IActionResult> RegistrarVista([FromBody] VistaGuiaRequest r)
        {
            if (EsAdmin) return SoloUsuarios();
            if (r.IdGuia < 1) return Invalido("La guía no es válida");

            return await Escribir("sp_registrarVista", null,
                Param("@IdUsuario", IdSesion), Param("@IdGuia", r.IdGuia));
        }

        // ----- FAVORITOS -----

        // GET listaFavoritos
        [HttpGet("favoritos")]
        [SesionAuth]
        public Task<IActionResult> ListaFavoritos() =>
            Consultar("sp_listaFavoritos", l => Convert.ToInt32(l["IdGuia"]), Param("@IdUsuario", IdSesion));

        // POST crearFavorito
        [HttpPost("favoritos")]
        [SesionAuth]
        public async Task<IActionResult> AgregarFavorito([FromBody] FavoritoNuevoRequest r)
        {
            if (EsAdmin) return SoloUsuarios();
            if (r.IdGuia < 1) return Invalido("La guía no es válida");

            return await Escribir("sp_crearFavorito", null,
                Param("@IdUsuario", IdSesion), Param("@IdGuia", r.IdGuia));
        }

        // DELETE eliminarFavorito
        [HttpDelete("favoritos/{idGuia:int}")]
        [SesionAuth]
        public async Task<IActionResult> QuitarFavorito(int idGuia)
        {
            if (EsAdmin) return SoloUsuarios();

            return await Escribir("sp_eliminarFavorito", null,
                Param("@IdUsuario", IdSesion), Param("@IdGuia", idGuia));
        }

        // ----- CALIFICACIONES -----

        // GET listaCalificaciones
        [HttpGet("calificaciones")]
        [SesionAuth]
        public Task<IActionResult> ListaCalificaciones()
        {
            int yo = IdSesion;
            return Consultar("sp_listaCalificaciones", l => new
            {
                idGuia = Convert.ToInt32(l["IdGuia"]),
                estrellas = Convert.ToInt32(l["Estrellas"]),
                fecha = Convert.ToDateTime(l["Fecha"]),
                esMia = Convert.ToInt32(l["IdUsuario"]) == yo
            });
        }

        // PUT guardarCalificacion
        [HttpPut("calificaciones/{idGuia:int}")]
        [SesionAuth]
        public async Task<IActionResult> Calificar(int idGuia, [FromBody] CalificacionGuardar r)
        {
            if (EsAdmin) return SoloUsuarios();
            if (idGuia < 1 || r.Estrellas < 1 || r.Estrellas > 5) return Invalido("La calificación debe ser de 1 a 5 estrellas");

            return await Escribir("sp_guardarCalificacion", null,
                Param("@IdUsuario", IdSesion), Param("@IdGuia", idGuia), Param("@Estrellas", (byte)r.Estrellas));
        }

        // ----- COMENTARIOS -----

        // GET listaComentarios
        [HttpGet("comentarios")]
        [SesionAuth]
        public Task<IActionResult> ListaComentarios()
        {
            int yo = IdSesion;
            return Consultar("sp_listaComentarios", l => new
            {
                idComentario = Convert.ToInt32(l["IdComentario"]),
                idGuia = Convert.ToInt32(l["IdGuia"]),
                nombre = l["Nombre"].ToString() ?? string.Empty,
                tipoUsuario = l["TipoUsuario"].ToString() ?? string.Empty,
                texto = l["Texto"].ToString() ?? string.Empty,
                fecha = Convert.ToDateTime(l["Fecha"]),
                estrellas = l["Estrellas"] is DBNull ? (int?)null : Convert.ToInt32(l["Estrellas"]),
                esMio = Convert.ToInt32(l["IdUsuario"]) == yo
            });
        }

        // POST crearComentario
        [HttpPost("comentarios")]
        [SesionAuth]
        public async Task<IActionResult> CrearComentario([FromBody] ComentarioNuevoRequest r)
        {
            if (EsAdmin) return SoloUsuarios();

            string texto = (r.Texto ?? string.Empty).Trim();
            if (r.IdGuia < 1 || texto.Length < 3 || texto.Length > 300)
                return Invalido("El comentario debe tener entre 3 y 300 caracteres");

            var pId = SalidaInt("@IdComentario");
            return await Escribir("sp_crearComentario", () => new { idComentario = Convert.ToInt32(pId.Value) },
                Param("@IdUsuario", IdSesion), Param("@IdGuia", r.IdGuia), Param("@Texto", texto), pId);
        }

        // DELETE eliminarComentario
        [HttpDelete("comentarios/{idComentario:int}")]
        [SesionAuth]
        public async Task<IActionResult> EliminarComentario(int idComentario)
        {
            if (EsAdmin) return SoloUsuarios();

            return await Escribir("sp_eliminarComentario", null,
                Param("@IdComentario", idComentario), Param("@IdUsuario", IdSesion));
        }

        // ----- RESULTADOS DE AUTOEVALUACIÓN -----

        // GET listaResultados
        [HttpGet("resultados")]
        [SesionAuth]
        public Task<IActionResult> ListaResultados() =>
            Consultar("sp_listaResultados", l => new
            {
                idResultado = Convert.ToInt32(l["IdResultado"]),
                idGuia = Convert.ToInt32(l["IdGuia"]),
                titulo = l["Titulo"].ToString() ?? string.Empty,
                aciertos = Convert.ToInt32(l["Aciertos"]),
                total = Convert.ToInt32(l["Total"]),
                fecha = Convert.ToDateTime(l["Fecha"])
            }, Param("@IdUsuario", IdSesion));

        // POST guardarResultado
        [HttpPost("resultados")]
        [SesionAuth]
        public async Task<IActionResult> GuardarResultado([FromBody] ResultadoNuevoRequest r)
        {
            if (EsAdmin) return SoloUsuarios();
            if (r.IdGuia < 1 || r.Total < 1 || r.Total > 100 || r.Aciertos < 0 || r.Aciertos > r.Total)
                return Invalido("El resultado de la autoevaluación no es válido");

            return await Escribir("sp_guardarResultado", null,
                Param("@IdUsuario", IdSesion), Param("@IdGuia", r.IdGuia),
                Param("@Aciertos", r.Aciertos), Param("@Total", r.Total));
        }

        // ----- DONACIONES -----

        // POST crearDonacion
        [HttpPost("donaciones")]
        public async Task<IActionResult> Donar([FromBody] DonacionNuevaRequest r)
        {
            if (r.Monto < 1 || r.Monto > 100000) return Invalido("El monto de la donación no es válido");

            return await Escribir("sp_crearDonacion", null,
                Param("@IdUsuario", IdUsuarioOpcional()), Param("@Monto", r.Monto), Param("@OtraCantidad", r.OtraCantidad));
        }

        // ----- AUXILIARES -----

        private int? IdUsuarioOpcional()
        {
            string cabecera = Request.Headers["Authorization"].ToString();
            if (!cabecera.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)) return null;

            DatosSesion? sesion = TokenSesion.Validar(cabecera.Substring(7).Trim(), _configuration["Admin:ClaveToken"] ?? string.Empty);
            return sesion?.IdUsuario;
        }

        private async Task<IActionResult> Consultar<T>(string procedimiento, Func<SqlDataReader, T> convertir, params SqlParameter[] parametros)
        {
            try
            {
                var lista = await _sql.ConsultarAsync(procedimiento, convertir, parametros);
                return Ok(Respuesta.Exito("Consulta correcta", lista));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al ejecutar {Procedimiento}", procedimiento);
                return StatusCode(500, Respuesta.Fallo(500, "No se pudo consultar la información. Inténtalo de nuevo en unos momentos."));
            }
        }

        private async Task<IActionResult> Escribir(string procedimiento, Func<object?>? datos, params SqlParameter[] parametros)
        {
            try
            {
                var pNumeroError = SalidaInt("@numeroError");
                var pRespuesta = SalidaTexto("@respuesta");

                await _sql.EjecutarAsync(procedimiento, parametros.Concat(new[] { pNumeroError, pRespuesta }).ToArray());

                int numeroError = Convert.ToInt32(pNumeroError.Value);
                string respuesta = Convert.ToString(pRespuesta.Value) ?? string.Empty;

                if (numeroError == 50034) return NotFound(Respuesta.Fallo(numeroError, respuesta));
                if (numeroError != 0) return BadRequest(Respuesta.Fallo(numeroError, respuesta));

                return Ok(Respuesta.Exito(respuesta, datos?.Invoke()));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al ejecutar {Procedimiento}", procedimiento);
                return StatusCode(500, Respuesta.Fallo(500, "No se pudo guardar la información. Inténtalo de nuevo en unos momentos."));
            }
        }

        private IActionResult Invalido(string mensaje) => BadRequest(Respuesta.Fallo(400, mensaje));

        private IActionResult SoloUsuarios() =>
            StatusCode(403, Respuesta.Fallo(403, "El administrador no genera actividad de usuario."));
    }
}