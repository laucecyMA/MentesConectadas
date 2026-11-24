// ===== PROTECCIÓN SOLO ADMINISTRADOR =====

namespace MentesConectadasAPI.Helpers
{
    public class AdminAuthAttribute : SesionAuthAttribute
    {
        public AdminAuthAttribute()
        {
            SoloAdministrador = true;
        }
    }
}