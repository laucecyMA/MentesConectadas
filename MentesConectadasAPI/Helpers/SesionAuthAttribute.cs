// ===== PROTECCIÓN SESIÓN INICIADA =====

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace MentesConectadasAPI.Helpers
{
    public class SesionAuthAttribute : ActionFilterAttribute
    {
        public bool SoloAdministrador { get; set; }

        public override void OnActionExecuting(ActionExecutingContext context)
        {
            var configuracion = context.HttpContext.RequestServices.GetRequiredService<IConfiguration>();
            string cabecera = context.HttpContext.Request.Headers["Authorization"].ToString();
            string token = cabecera.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
                ? cabecera.Substring(7).Trim()
                : string.Empty;

            DatosSesion? sesion = TokenSesion.Validar(token, configuracion["Admin:ClaveToken"] ?? string.Empty);

            if (sesion == null)
            {
                context.Result = new ObjectResult(Respuesta.Fallo(401, "Sesión no válida o vencida.")) { StatusCode = 401 };
                return;
            }

            if (SoloAdministrador && sesion.TipoUsuario != "Administrador")
            {
                context.Result = new ObjectResult(Respuesta.Fallo(403, "No tienes permiso para esta acción.")) { StatusCode = 403 };
                return;
            }

            context.HttpContext.Items["IdUsuario"] = sesion.IdUsuario;
            context.HttpContext.Items["TipoUsuario"] = sesion.TipoUsuario;
        }
    }
}