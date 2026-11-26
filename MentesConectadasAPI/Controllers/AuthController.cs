// ===== INICIO DE SESIÓN, REGISTRO Y PERFIL =====

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using MentesConectadasAPI.Data;
using MentesConectadasAPI.Helpers;
using MentesConectadasAPI.Models;
using MentesConectadasAPI.Services;
using static MentesConectadasAPI.Data.AccesoSql;

namespace MentesConectadasAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private static readonly TimeSpan DuracionToken = TimeSpan.FromHours(8);
        private static readonly TimeSpan DuracionRecuperacion = TimeSpan.FromMinutes(30);
        private readonly AccesoSql _sql;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AuthController> _logger;
        private readonly EnvioCorreo _correo;

        public AuthController(AccesoSql sql, IConfiguration configuration, ILogger<AuthController> logger, EnvioCorreo correo)
        {
            _sql = sql;
            _configuration = configuration;
            _logger = logger;
            _correo = correo;
        }

        private string Clave => _configuration["Admin:ClaveToken"] ?? string.Empty;
        private int IdSesion => (int)HttpContext.Items["IdUsuario"]!;

        // POST crearUsuario
        [HttpPost("registro")]
        public async Task<IActionResult> Registro([FromBody] RegistroRequest r)
        {
            string nombre = (r.NombreCompleto ?? string.Empty).Trim();
            string correo = Validar.Correo(r.Correo);
            string password = r.Password ?? string.Empty;
            string tipo = (r.TipoUsuario ?? string.Empty).Trim();

            if (nombre.Length == 0 || nombre.Length > 100) return Invalido("Escribe tu nombre completo (máximo 100 caracteres)");
            if (!Validar.CorreoValido(correo)) return Invalido("Escribe un correo electrónico válido");
            if (password.Length < 6 || password.Length > 100) return Invalido("La contraseña debe tener entre 6 y 100 caracteres");
            if (!Validar.TipoValido(tipo)) return Invalido("Elige si eres Estudiante o Docente");
            if (Clave.Length < 32) return StatusCode(500, Respuesta.Fallo(500, "Falta configurar la clave del token en el servidor."));

            try
            {
                var pIdUsuario = SalidaInt("@IdUsuario");
                var pNumeroError = SalidaInt("@numeroError");
                var pRespuesta = SalidaTexto("@respuesta");

                await _sql.EjecutarAsync("sp_crearUsuario",
                    Param("@NombreCompleto", nombre),
                    Param("@Correo", correo),
                    Param("@Contrasena", HashContrasena.Hashear(password)),
                    Param("@TipoUsuario", tipo),
                    pIdUsuario, pNumeroError, pRespuesta);

                int numeroError = Convert.ToInt32(pNumeroError.Value);
                string respuesta = Convert.ToString(pRespuesta.Value) ?? string.Empty;
                if (numeroError == 50021) respuesta = "Ya existe una cuenta con ese correo. Inicia sesión o usa otro correo.";
                if (numeroError != 0) return BadRequest(Respuesta.Fallo(numeroError, respuesta));

                // Correo de bienvenida 
                string? urlSitio = _correo.UrlSitio(Request);
                if (urlSitio != null)
                    _correo.EnSegundoPlano("bienvenida", () => _correo.EnviarBienvenidaAsync(correo, nombre, tipo, urlSitio));
                else
                    _logger.LogWarning("No se envió el correo de bienvenida: configura Correo:UrlSitio con la dirección pública de la página.");

                return Ok(RespuestaSesion(respuesta, Convert.ToInt32(pIdUsuario.Value), nombre, correo, tipo));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al ejecutar sp_crearUsuario");
                return StatusCode(500, Respuesta.Fallo(500, "No se pudo crear la cuenta. Revisa los datos e inténtalo nuevamente."));
            }
        }

        // POST obtenerUsuario y registrarAcceso
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest r)
        {
            string correo = Validar.Correo(r.Correo);
            string password = r.Password ?? string.Empty;
            if (Clave.Length < 32) return StatusCode(500, Respuesta.Fallo(500, "Falta configurar la clave del token en el servidor."));

            try
            {
                var usuario = correo.Length == 0 ? null : await BuscarUsuarioAsync(null, correo);

                if (usuario == null || !usuario.Activo || !HashContrasena.Verificar(password, usuario.Contrasena))
                    return Unauthorized(Respuesta.Fallo(401, "Correo o contraseña incorrectos"));

                await _sql.EjecutarAsync("sp_registrarAcceso",
                    Param("@IdUsuario", usuario.IdUsuario), SalidaInt("@numeroError"), SalidaTexto("@respuesta"));

                return Ok(RespuestaSesion("Inicio de sesión correcto", usuario.IdUsuario, usuario.NombreCompleto, usuario.Correo, usuario.TipoUsuario));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al iniciar sesión");
                return StatusCode(500, Respuesta.Fallo(500, "No se pudo iniciar sesión. Intenta de nuevo."));
            }
        }

        // GET perfil
        [HttpGet("perfil")]
        [SesionAuth]
        public async Task<IActionResult> ObtenerPerfil()
        {
            try
            {
                var usuario = await BuscarUsuarioAsync(IdSesion, null);
                if (usuario == null || !usuario.Activo) return Unauthorized(Respuesta.Fallo(401, "La sesión ya no es válida."));

                return Ok(Respuesta.Exito("Consulta correcta",
                    new { id = usuario.IdUsuario, nombre = usuario.NombreCompleto, correo = usuario.Correo, tipo = usuario.TipoUsuario }));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al consultar el perfil");
                return StatusCode(500, Respuesta.Fallo(500, "No se pudo consultar el perfil. Inténtalo de nuevo en unos momentos."));
            }
        }

        // PUT editarUsuario
        [HttpPut("perfil")]
        [SesionAuth]
        public async Task<IActionResult> EditarPerfil([FromBody] PerfilRequest r)
        {
            string nombre = (r.NombreCompleto ?? string.Empty).Trim();
            string correo = Validar.Correo(r.Correo);
            string actual = r.PasswordActual ?? string.Empty;
            string nueva = r.PasswordNueva ?? string.Empty;
            bool cambiaPassword = actual.Length > 0 || nueva.Length > 0;

            if (nombre.Length == 0 || nombre.Length > 100) return Invalido("Escribe tu nombre completo (máximo 100 caracteres)");
            if (!Validar.CorreoValido(correo)) return Invalido("Escribe un correo electrónico válido");
            if (cambiaPassword && actual.Length == 0) return Invalido("Escribe tu contraseña actual para cambiarla");
            if (cambiaPassword && (nueva.Length < 6 || nueva.Length > 100)) return Invalido("La nueva contraseña debe tener entre 6 y 100 caracteres");

            try
            {
                var usuario = await BuscarUsuarioAsync(IdSesion, null);
                if (usuario == null || !usuario.Activo) return Unauthorized(Respuesta.Fallo(401, "La sesión ya no es válida."));

                string? hashNuevo = null;
                if (cambiaPassword)
                {
                    if (!HashContrasena.Verificar(actual, usuario.Contrasena))
                        return BadRequest(Respuesta.Fallo(50023, "La contraseña actual no es correcta"));
                    hashNuevo = HashContrasena.Hashear(nueva);
                }

                var pNumeroError = SalidaInt("@numeroError");
                var pRespuesta = SalidaTexto("@respuesta");

                await _sql.EjecutarAsync("sp_editarUsuario",
                    Param("@IdUsuario", usuario.IdUsuario),
                    Param("@NombreCompleto", nombre),
                    Param("@Correo", correo),
                    Param("@Contrasena", hashNuevo),
                    pNumeroError, pRespuesta);

                int numeroError = Convert.ToInt32(pNumeroError.Value);
                string respuesta = Convert.ToString(pRespuesta.Value) ?? string.Empty;
                if (numeroError == 50021) respuesta = "Ese correo ya está registrado en otra cuenta. Usa uno distinto.";
                if (numeroError != 0) return BadRequest(Respuesta.Fallo(numeroError, respuesta));

                return Ok(Respuesta.Exito(respuesta,
                    new { id = usuario.IdUsuario, nombre, correo, tipo = usuario.TipoUsuario }));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al ejecutar sp_editarUsuario");
                return StatusCode(500, Respuesta.Fallo(500, "No se pudo actualizar el perfil. Revisa los datos e inténtalo nuevamente."));
            }
        }

        // POST olvide-contraseña
        [HttpPost("olvide-contrasena")]
        [EnableRateLimiting("recuperacion")]
        public async Task<IActionResult> OlvideContrasena([FromBody] OlvideContrasenaRequest r)
        {
            string correo = Validar.Correo(r.Correo);
            if (!Validar.CorreoValido(correo)) return Invalido("Escribe un correo electrónico válido");
            if (Clave.Length < 32) return StatusCode(500, Respuesta.Fallo(500, "Falta configurar la clave del token en el servidor."));
            if (!_correo.Configurado)
                return StatusCode(503, Respuesta.Fallo(503, "El envío de correos no está disponible por el momento. Inténtalo más tarde."));

            string? urlSitio = _correo.UrlSitio(Request);
            if (urlSitio == null)
            {
                _logger.LogError("No se puede armar el enlace de recuperación: configura Correo:UrlSitio con la dirección pública de la página.");
                return StatusCode(503, Respuesta.Fallo(503, "El envío de correos no está disponible por el momento. Inténtalo más tarde."));
            }

            const string mensaje = "Si el correo está registrado, te enviamos un mensaje con las instrucciones para cambiar tu contraseña. Revisa también tu carpeta de spam.";

            try
            {
                var usuario = await BuscarUsuarioAsync(null, correo);
                if (usuario != null && usuario.Activo)
                {
                    string token = TokenRecuperacion.Crear(usuario.IdUsuario, usuario.Contrasena, Clave, DuracionRecuperacion);
                    string enlace = urlSitio + "/#restablecer:" + token;
                    string nombre = usuario.NombreCompleto;
                    string destino = usuario.Correo;
                    int minutos = (int)DuracionRecuperacion.TotalMinutes;
                    _correo.EnSegundoPlano("recuperación de contraseña", () => _correo.EnviarRecuperacionAsync(destino, nombre, enlace, minutos, urlSitio));
                }
                return Ok(Respuesta.Exito(mensaje));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al solicitar la recuperación de contraseña");
                return StatusCode(500, Respuesta.Fallo(500, "No se pudo procesar la solicitud. Inténtalo de nuevo en unos momentos."));
            }
        }

        // POST restablecer-contraseña
        [HttpPost("restablecer-contrasena")]
        [EnableRateLimiting("recuperacion")]
        public async Task<IActionResult> RestablecerContrasena([FromBody] RestablecerContrasenaRequest r)
        {
            const string enlaceInvalido = "El enlace no es válido o ya venció. Solicita uno nuevo desde «¿Olvidaste tu contraseña?».";
            string nueva = r.Password ?? string.Empty;

            if (nueva.Length < 6 || nueva.Length > 100) return Invalido("La contraseña debe tener entre 6 y 100 caracteres");
            if (Clave.Length < 32) return StatusCode(500, Respuesta.Fallo(500, "Falta configurar la clave del token en el servidor."));

            var datos = TokenRecuperacion.Leer(r.Token, Clave);
            if (datos == null) return BadRequest(Respuesta.Fallo(50030, enlaceInvalido));

            try
            {
                var usuario = await BuscarUsuarioAsync(datos.IdUsuario, null);
                if (usuario == null || !usuario.Activo || !TokenRecuperacion.HuellaCoincide(datos.Huella, usuario.Contrasena, Clave))
                    return BadRequest(Respuesta.Fallo(50030, enlaceInvalido));

                var pNumeroError = SalidaInt("@numeroError");
                var pRespuesta = SalidaTexto("@respuesta");

                // Se reutiliza sp_editarUsuario
                await _sql.EjecutarAsync("sp_editarUsuario",
                    Param("@IdUsuario", usuario.IdUsuario),
                    Param("@NombreCompleto", usuario.NombreCompleto),
                    Param("@Correo", usuario.Correo),
                    Param("@Contrasena", HashContrasena.Hashear(nueva)),
                    pNumeroError, pRespuesta);

                int numeroError = Convert.ToInt32(pNumeroError.Value);
                if (numeroError != 0)
                    return BadRequest(Respuesta.Fallo(numeroError, Convert.ToString(pRespuesta.Value) ?? "No se pudo cambiar la contraseña."));

                
                string? urlSitio = _correo.UrlSitio(Request);
                if (urlSitio != null)
                {
                    string nombre = usuario.NombreCompleto;
                    string destino = usuario.Correo;
                    _correo.EnSegundoPlano("contraseña cambiada", () => _correo.EnviarContrasenaCambiadaAsync(destino, nombre, urlSitio));
                }

                return Ok(Respuesta.Exito("Tu contraseña se cambió correctamente. Ya puedes iniciar sesión."));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al restablecer la contraseña");
                return StatusCode(500, Respuesta.Fallo(500, "No se pudo cambiar la contraseña. Inténtalo de nuevo en unos momentos."));
            }
        }

        private async Task<UsuarioCuenta?> BuscarUsuarioAsync(int? idUsuario, string? correo)
        {
            var lista = await _sql.ConsultarAsync("sp_obtenerUsuario", lector => new UsuarioCuenta
            {
                IdUsuario = Convert.ToInt32(lector["IdUsuario"]),
                NombreCompleto = lector["NombreCompleto"].ToString() ?? string.Empty,
                Correo = lector["Correo"].ToString() ?? string.Empty,
                Contrasena = lector["Contrasena"].ToString() ?? string.Empty,
                TipoUsuario = lector["TipoUsuario"].ToString() ?? string.Empty,
                Activo = Convert.ToBoolean(lector["Activo"])
            }, Param("@IdUsuario", idUsuario), Param("@Correo", correo));

            return lista.FirstOrDefault();
        }

        private object RespuestaSesion(string mensaje, int id, string nombre, string correo, string tipo) => new
        {
            isSuccess = true,
            numeroError = 0,
            respuesta = mensaje,
            usuario = new { id, nombre, correo, tipo },
            token = TokenSesion.Crear(id, tipo, Clave, DuracionToken)
        };

        private IActionResult Invalido(string mensaje) => BadRequest(Respuesta.Fallo(400, mensaje));
    }
}