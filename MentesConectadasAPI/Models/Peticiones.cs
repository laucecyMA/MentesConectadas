// ===== PETICIONES =====

namespace MentesConectadasAPI.Models
{

    public class IdRequest
    {
        public int Id { get; set; }
    }

    public class OcultarComentarioRequest
    {
        public int IdComentario { get; set; }
        public bool Oculto { get; set; }
    }

    public class EstadoDonacionRequest
    {
        public int IdDonacion { get; set; }
        public string Estado { get; set; } = string.Empty;
    }
}
