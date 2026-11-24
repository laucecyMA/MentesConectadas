// ===== ACTIVIDAD DE LOS USUARIOS =====

namespace MentesConectadasAPI.Models
{
    public class VistaGuiaRequest { public int IdGuia { get; set; } }

    public class FavoritoNuevoRequest { public int IdGuia { get; set; } }

    public class CalificacionGuardar { public int Estrellas { get; set; } }

    public class ComentarioNuevoRequest
    {
        public int IdGuia { get; set; }
        public string Texto { get; set; } = string.Empty;
    }

    public class ResultadoNuevoRequest
    {
        public int IdGuia { get; set; }
        public int Aciertos { get; set; }
        public int Total { get; set; }
    }

    public class DonacionNuevaRequest
    {
        public decimal Monto { get; set; }
        public bool OtraCantidad { get; set; }
    }
}