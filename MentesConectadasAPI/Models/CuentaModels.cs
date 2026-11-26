// ===== CUENTAS =====

namespace MentesConectadasAPI.Models
{
    public class RegistroRequest
    {
        public string NombreCompleto { get; set; } = string.Empty;
        public string Correo { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string TipoUsuario { get; set; } = string.Empty;
    }

    public class PerfilRequest
    {
        public string NombreCompleto { get; set; } = string.Empty;
        public string Correo { get; set; } = string.Empty;
        public string? PasswordActual { get; set; }
        public string? PasswordNueva { get; set; }
    }

    public class OlvideContrasenaRequest
    {
        public string Correo { get; set; } = string.Empty;
    }

    public class RestablecerContrasenaRequest
    {
        public string Token { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class UsuarioCuenta
    {
        public int IdUsuario { get; set; }
        public string NombreCompleto { get; set; } = string.Empty;
        public string Correo { get; set; } = string.Empty;
        public string Contrasena { get; set; } = string.Empty;
        public string TipoUsuario { get; set; } = string.Empty;
        public bool Activo { get; set; }
    }
}