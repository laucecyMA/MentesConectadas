// ===== AUTOEVALUACIONES =====

namespace MentesConectadasAPI.Models
{
    public class EvaluacionCrear
    {
        public int IdGuia { get; set; }
    }

    public class PreguntaGuardar
    {
        public string Texto { get; set; } = string.Empty;
        public string OpcionA { get; set; } = string.Empty;
        public string OpcionB { get; set; } = string.Empty;
        public string? OpcionC { get; set; }
        public string? OpcionD { get; set; }
        public string Correcta { get; set; } = string.Empty;
    }
}