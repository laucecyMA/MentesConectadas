// ===== GUÍAS =====

namespace MentesConectadasAPI.Models
{
    public class Guia
    {
        public int IdGuia { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string Categoria { get; set; } = string.Empty;
        public string Descripcion { get; set; } = string.Empty;
        public string? Video { get; set; }
        public int IdNeurodivergencia { get; set; }
        public string Neurodivergencia { get; set; } = string.Empty;
        public bool ParaEstudiante { get; set; }
        public bool ParaDocente { get; set; }
        public bool Activo { get; set; }
        public List<string> Situaciones { get; set; } = new();
        public int TotalPreguntas { get; set; }
        public decimal? PromedioCalificacion { get; set; }
        public int TotalCalificaciones { get; set; }
        public int TotalComentarios { get; set; }
    }

    public class GuiaDetalle : Guia
    {
        public DateTime FechaCreacion { get; set; }
        public DateTime FechaActualizacion { get; set; }
        public List<string> Recomendaciones { get; set; } = new();
        public List<string> Evitar { get; set; } = new();
        public int? IdEvaluacion { get; set; }
        public List<PreguntaGuia> Preguntas { get; set; } = new();
    }

    public class PreguntaGuia
    {
        public int IdPregunta { get; set; }
        public int Orden { get; set; }
        public string Texto { get; set; } = string.Empty;
        public string OpcionA { get; set; } = string.Empty;
        public string OpcionB { get; set; } = string.Empty;
        public string? OpcionC { get; set; }
        public string? OpcionD { get; set; }
        public string Correcta { get; set; } = string.Empty;
    }
    public class GuiaGuardar
    {
        public string Titulo { get; set; } = string.Empty;
        public string Neurodivergencia { get; set; } = string.Empty;
        public string Categoria { get; set; } = string.Empty;
        public string Descripcion { get; set; } = string.Empty;
        public List<string> Recomendaciones { get; set; } = new();
        public List<string> Evitar { get; set; } = new();
        public bool ParaEstudiante { get; set; }
        public bool ParaDocente { get; set; }
        public List<string> Situaciones { get; set; } = new();
        public bool Activo { get; set; } = true;
    }
    public class GuiaVisibilidad
    {
        public bool Ocultar { get; set; }
    }
}