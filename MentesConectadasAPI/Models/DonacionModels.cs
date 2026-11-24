// ===== DONACIONES =====

namespace MentesConectadasAPI.Models
{
    public class DonacionIniciarRequest
    {
        public string Nombre { get; set; } = string.Empty;
        public string Correo { get; set; } = string.Empty;
        public decimal Monto { get; set; }
        public bool OtraCantidad { get; set; }
        public string? Mensaje { get; set; }
        public string? Idioma { get; set; }
    }
}
