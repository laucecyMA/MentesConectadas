// ===== MENTYBOT =====

namespace MentesConectadasAPI.Models
{
    public class MensajeChat
    {
        public string Rol { get; set; } = string.Empty;
        public string Texto { get; set; } = string.Empty;
    }

    public class ChatbotRequest
    {
        public string Mensaje { get; set; } = string.Empty;
        public string? Tipo { get; set; }
        public List<MensajeChat>? Historial { get; set; }
        public string? Idioma { get; set; }
        public List<string>? Contexto { get; set; }
    }

    public class ChatbotResultado
    {
        public string Texto { get; set; } = string.Empty;
        public bool SinInfo { get; set; }
        public string Proveedor { get; set; } = string.Empty;
    }
}
