/* ==================================================================================
   MENTES CONECTADAS 
   ================================================================================== */
   /* CREACION DE LA BASE DE DATOS */
IF DB_ID(N'MentesConectadasDB') IS NULL
    CREATE DATABASE [MentesConectadasDB];
GO
USE [MentesConectadasDB];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
GO


/* ==================================================================================
   LIMPIEZA: borrar objetos anteriores, si existen
   ================================================================================== */

DROP PROCEDURE IF EXISTS [dbo].[sp_adminEliminarComentario];
DROP PROCEDURE IF EXISTS [dbo].[sp_adminEliminarDonacion];
DROP PROCEDURE IF EXISTS [dbo].[sp_adminEstadisticasGuias];
DROP PROCEDURE IF EXISTS [dbo].[sp_adminEstadoDonacion];
DROP PROCEDURE IF EXISTS [dbo].[sp_adminListaComentarios];
DROP PROCEDURE IF EXISTS [dbo].[sp_adminListaDonaciones];
DROP PROCEDURE IF EXISTS [dbo].[sp_adminOcultarComentario];
DROP PROCEDURE IF EXISTS [dbo].[sp_adminResumen];
DROP PROCEDURE IF EXISTS [dbo].[sp_asignarPreferenciaDonacion];
DROP PROCEDURE IF EXISTS [dbo].[sp_crearComentario];
DROP PROCEDURE IF EXISTS [dbo].[sp_crearDonacion];
DROP PROCEDURE IF EXISTS [dbo].[sp_crearEvaluacion];
DROP PROCEDURE IF EXISTS [dbo].[sp_crearFavorito];
DROP PROCEDURE IF EXISTS [dbo].[sp_crearGuia];
DROP PROCEDURE IF EXISTS [dbo].[sp_crearPregunta];
DROP PROCEDURE IF EXISTS [dbo].[sp_crearUsuario];
DROP PROCEDURE IF EXISTS [dbo].[sp_editarGuia];
DROP PROCEDURE IF EXISTS [dbo].[sp_editarPregunta];
DROP PROCEDURE IF EXISTS [dbo].[sp_editarUsuario];
DROP PROCEDURE IF EXISTS [dbo].[sp_eliminarComentario];
DROP PROCEDURE IF EXISTS [dbo].[sp_eliminarEvaluacion];
DROP PROCEDURE IF EXISTS [dbo].[sp_eliminarFavorito];
DROP PROCEDURE IF EXISTS [dbo].[sp_eliminarPregunta];
DROP PROCEDURE IF EXISTS [dbo].[sp_guardarCalificacion];
DROP PROCEDURE IF EXISTS [dbo].[sp_guardarResultado];
DROP PROCEDURE IF EXISTS [dbo].[sp_iniciarDonacion];
DROP PROCEDURE IF EXISTS [dbo].[sp_listaCalificaciones];
DROP PROCEDURE IF EXISTS [dbo].[sp_listaComentarios];
DROP PROCEDURE IF EXISTS [dbo].[sp_listaEvaluaciones];
DROP PROCEDURE IF EXISTS [dbo].[sp_listaFavoritos];
DROP PROCEDURE IF EXISTS [dbo].[sp_listaGuias];
DROP PROCEDURE IF EXISTS [dbo].[sp_listaGuiasSinEvaluacion];
DROP PROCEDURE IF EXISTS [dbo].[sp_listaNeurodivergencias];
DROP PROCEDURE IF EXISTS [dbo].[sp_listaResultados];
DROP PROCEDURE IF EXISTS [dbo].[sp_listaSituaciones];
DROP PROCEDURE IF EXISTS [dbo].[sp_obtenerDonacion];
DROP PROCEDURE IF EXISTS [dbo].[sp_obtenerEvaluacion];
DROP PROCEDURE IF EXISTS [dbo].[sp_obtenerGuia];
DROP PROCEDURE IF EXISTS [dbo].[sp_obtenerUsuario];
DROP PROCEDURE IF EXISTS [dbo].[sp_ocultarGuia];
DROP PROCEDURE IF EXISTS [dbo].[sp_registrarAcceso];
DROP PROCEDURE IF EXISTS [dbo].[sp_registrarPagoDonacion];
DROP PROCEDURE IF EXISTS [dbo].[sp_registrarVista];
DROP FUNCTION IF EXISTS [dbo].[fn_dividirTexto];
DROP TABLE IF EXISTS [dbo].[Donacion];
DROP TABLE IF EXISTS [dbo].[Comentario];
DROP TABLE IF EXISTS [dbo].[ResultadoEvaluacion];
DROP TABLE IF EXISTS [dbo].[Calificacion];
DROP TABLE IF EXISTS [dbo].[Favorito];
DROP TABLE IF EXISTS [dbo].[VistaGuia];
DROP TABLE IF EXISTS [dbo].[Pregunta];
DROP TABLE IF EXISTS [dbo].[Evaluacion];
DROP TABLE IF EXISTS [dbo].[Recomendacion];
DROP TABLE IF EXISTS [dbo].[GuiaSituacion];
DROP TABLE IF EXISTS [dbo].[Guia];
DROP TABLE IF EXISTS [dbo].[Usuario];
DROP TABLE IF EXISTS [dbo].[Situacion];
DROP TABLE IF EXISTS [dbo].[Neurodivergencia];
GO
GO


/* ==================================================================================
   FUNCION AUXILIAR
   ================================================================================== */

-- ===== FUNCION fn_dividirTexto =====
create function [dbo].[fn_dividirTexto](@Texto varchar(max), @Separador char(1))
returns @Resultado table(Orden int, Valor varchar(500))
as
begin
	declare @Orden int = 0
	declare @Pos int
	declare @Parte varchar(max)

	set @Texto = replace(isnull(@Texto, ''), char(13), '')

	while len(@Texto) > 0
	begin
		set @Pos = charindex(@Separador, @Texto)
		if @Pos = 0
		begin
			set @Parte = @Texto
			set @Texto = ''
		end
		else
		begin
			set @Parte = left(@Texto, @Pos - 1)
			set @Texto = substring(@Texto, @Pos + 1, len(@Texto))
		end

		set @Parte = ltrim(rtrim(@Parte))
		if @Parte <> ''
		begin
			set @Orden = @Orden + 1
			insert into @Resultado(Orden, Valor) values (@Orden, left(@Parte, 500))
		end
	end

	return
end
GO


/* ==================================================================================
   CREACION DE TABLAS
   ================================================================================== */
   /* CREACION DE LA TABLA CALIFICACION*/
CREATE TABLE [dbo].[Calificacion](
	[IdUsuario] [int] NOT NULL,
	[IdGuia] [int] NOT NULL,
	[Estrellas] [tinyint] NOT NULL,
	[Fecha] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[IdUsuario] ASC,
	[IdGuia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/* CREACION DE LA TABLA COMENTARIOS */
CREATE TABLE [dbo].[Comentario](
	[IdComentario] [int] IDENTITY(1,1) NOT NULL,
	[IdUsuario] [int] NOT NULL,
	[IdGuia] [int] NOT NULL,
	[Texto] [varchar](300) NOT NULL,
	[Oculto] [bit] NOT NULL,
	[Fecha] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[IdComentario] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/* CREACION DE LA TABLA DONACION*/
CREATE TABLE [dbo].[Donacion](
	[IdDonacion] [int] IDENTITY(1,1) NOT NULL,
	[IdUsuario] [int] NULL,
	[Monto] [decimal](10, 2) NOT NULL,
	[OtraCantidad] [bit] NOT NULL,
	[Estado] [varchar](12) NOT NULL,
	[Fecha] [datetime] NOT NULL,
	[NombreDonante] [varchar](100) NULL,
	[CorreoDonante] [varchar](150) NULL,
	[Mensaje] [varchar](300) NULL,
	[Moneda] [char](3) NOT NULL,
	[Proveedor] [varchar](20) NULL,
	[IdPreferencia] [varchar](100) NULL,
	[IdPagoProveedor] [varchar](40) NULL,
	[MetodoPago] [varchar](40) NULL,
	[DetalleEstado] [varchar](60) NULL,
	[FechaPago] [datetime] NULL,
	[FechaActualizacion] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[IdDonacion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/* CREACION DE LA TABLA EVALUACION */
CREATE TABLE [dbo].[Evaluacion](
	[IdEvaluacion] [int] IDENTITY(1,1) NOT NULL,
	[IdGuia] [int] NOT NULL,
	[FechaCreacion] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[IdEvaluacion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/* CREACION DE LA TABLA FAVORITO */
CREATE TABLE [dbo].[Favorito](
	[IdUsuario] [int] NOT NULL,
	[IdGuia] [int] NOT NULL,
	[FechaAgregado] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[IdUsuario] ASC,
	[IdGuia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/* CREACION DE LA TABLA GUIA */
CREATE TABLE [dbo].[Guia](
	[IdGuia] [int] IDENTITY(1,1) NOT NULL,
	[IdNeurodivergencia] [int] NOT NULL,
	[Titulo] [varchar](80) NOT NULL,
	[Categoria] [varchar](60) NOT NULL,
	[Descripcion] [varchar](260) NOT NULL,
	[Video] [varchar](200) NULL,
	[ParaEstudiante] [bit] NOT NULL,
	[ParaDocente] [bit] NOT NULL,
	[Activo] [bit] NOT NULL,
	[FechaCreacion] [datetime] NOT NULL,
	[FechaActualizacion] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[IdGuia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/* CREACION DE LA TABLA GUIA SITUACION */
CREATE TABLE [dbo].[GuiaSituacion](
	[IdGuia] [int] NOT NULL,
	[IdSituacion] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[IdGuia] ASC,
	[IdSituacion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/* CREACION DE LA TABLA NEURODIVERGENCIA */
CREATE TABLE [dbo].[Neurodivergencia](
	[IdNeurodivergencia] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [varchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[IdNeurodivergencia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/* CREACION DE LA TABLA PREGUNTA */
CREATE TABLE [dbo].[Pregunta](
	[IdPregunta] [int] IDENTITY(1,1) NOT NULL,
	[IdEvaluacion] [int] NOT NULL,
	[Orden] [int] NOT NULL,
	[Texto] [varchar](220) NOT NULL,
	[OpcionA] [varchar](180) NOT NULL,
	[OpcionB] [varchar](180) NOT NULL,
	[OpcionC] [varchar](180) NULL,
	[OpcionD] [varchar](180) NULL,
	[Correcta] [char](1) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[IdPregunta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/* CREACION DE LA TABLA RECOMENDACION */
CREATE TABLE [dbo].[Recomendacion](
	[IdRecomendacion] [int] IDENTITY(1,1) NOT NULL,
	[IdGuia] [int] NOT NULL,
	[Tipo] [varchar](10) NOT NULL,
	[Orden] [int] NOT NULL,
	[Texto] [varchar](500) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[IdRecomendacion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/* CREACION DE LA TABLA RESULTADO EVALUACION */
CREATE TABLE [dbo].[ResultadoEvaluacion](
	[IdResultado] [int] IDENTITY(1,1) NOT NULL,
	[IdUsuario] [int] NOT NULL,
	[IdGuia] [int] NOT NULL,
	[Aciertos] [int] NOT NULL,
	[Total] [int] NOT NULL,
	[Fecha] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[IdResultado] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/* CREACION DE LA TABLA SITUACION */
CREATE TABLE [dbo].[Situacion](
	[IdSituacion] [int] IDENTITY(1,1) NOT NULL,
	[Clave] [varchar](30) NOT NULL,
	[Nombre] [varchar](60) NOT NULL,
	[EsFiltro] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[IdSituacion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/* CREACION DE LA TABLA USUARIO */
CREATE TABLE [dbo].[Usuario](
	[IdUsuario] [int] IDENTITY(1,1) NOT NULL,
	[NombreCompleto] [varchar](100) NOT NULL,
	[Correo] [varchar](150) NOT NULL,
	[Contrasena] [varchar](200) NOT NULL,
	[TipoUsuario] [varchar](15) NOT NULL,
	[Activo] [bit] NOT NULL,
	[FechaRegistro] [datetime] NOT NULL,
	[FechaUltimoAcceso] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[IdUsuario] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/* CREACION DE LA TABLA VISTA GUIA */
CREATE TABLE [dbo].[VistaGuia](
	[IdVista] [int] IDENTITY(1,1) NOT NULL,
	[IdUsuario] [int] NOT NULL,
	[IdGuia] [int] NOT NULL,
	[Fecha] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[IdVista] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


/* ==================================================================================
   4. INSERCION DE DATOS
   ================================================================================== */
   /* INSERTAR DATOS EN LA TABLA EVALUACION */
SET IDENTITY_INSERT [dbo].[Evaluacion] ON 

INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (1, 1, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (2, 2, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (3, 3, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (4, 4, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (5, 5, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (6, 6, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (7, 7, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (8, 8, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (9, 9, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (10, 10, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (11, 11, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (12, 12, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (13, 13, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (14, 14, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (15, 15, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
INSERT [dbo].[Evaluacion] ([IdEvaluacion], [IdGuia], [FechaCreacion]) VALUES (16, 16, CAST(N'2026-11-11T12:03:20.803' AS DateTime))
SET IDENTITY_INSERT [dbo].[Evaluacion] OFF
GO
/* INSERTAR DATOS EN LA TABLA GUIA */
SET IDENTITY_INSERT [dbo].[Guia] ON 

INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (1, 1, N'Sobrecarga de estímulos', N'Sobrecarga y entorno', N'Identifica posibles señales de sobrecarga sensorial y cómo reducir estímulos sin invadir el espacio personal.', N'assets/videos/autismo/autismo-sobrecarga.mp4', 1, 1, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-22T15:15:01.870' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (2, 1, N'Comunicación clara', N'Comunicación', N'Pautas para dar instrucciones comprensibles y respetar el tiempo de procesamiento.', N'assets/videos/autismo/autismo-comunicacion.mp4', 1, 1, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (3, 1, N'Trabajo en equipo', N'Convivencia y colaboración', N'Organiza las actividades y distribuye responsabilidades de forma clara, aprovechando distintas maneras de participar.', N'assets/videos/autismo/autismo-trabajo-equipo.mp4', 1, 0, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (4, 1, N'Situaciones durante un examen', N'Evaluación', N'Reduce obstáculos ambientales y ofrece instrucciones explícitas para que el estudiante pueda demostrar sus conocimientos.', N'assets/videos/autismo/autismo-examen.mp4', 0, 1, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (5, 1, N'Cambios inesperados', N'Rutinas y transiciones', N'Comunica modificaciones de manera clara y anticipada, y da tiempo para adaptarse a una nueva rutina.', N'assets/videos/autismo/autismo-cambios.mp4', 1, 1, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (6, 1, N'Participación en clase', N'Participación inclusiva', N'Ofrece distintas formas de participar y evita medir el conocimiento únicamente por la exposición oral o la extroversión.', N'assets/videos/autismo/autismo-participacion.mp4', 1, 1, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (7, 1, N'Retroalimentación', N'Retroalimentación y mejora', N'Da comentarios específicos, privados y estructurados para que la persona pueda revisar qué conservar y qué mejorar.', N'assets/videos/autismo/autismo-retroalimentacion.mp4', 0, 1, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (8, 1, N'Corrección respetuosa', N'Corrección y respeto', N'Explica el error de forma neutral y privada, y muestra el procedimiento correcto sin avergonzar.', N'assets/videos/autismo/autismo-correccion.mp4', 0, 1, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (9, 2, N'Sobrecarga y estímulos', N'Atención y entorno', N'Reduce distractores y divide las instrucciones para apoyar la atención y la regulación durante actividades académicas.', N'assets/videos/tdah/tdah-sobrecarga.mp4', 1, 1, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (10, 2, N'Comunicación e instrucciones', N'Instrucciones claras', N'Da indicaciones concretas, secuenciadas y fáciles de revisar; confirma entregables y fechas.', N'assets/videos/tdah/tdah-comunicacion.mp4', 1, 1, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (11, 2, N'Trabajo en equipo', N'Convivencia y colaboración', N'Distribuye tareas, acuerda responsabilidades y fechas y usa apoyos que ayuden a recordar los compromisos.', N'assets/videos/tdah/tdah-trabajo-equipo.mp4', 1, 0, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (12, 2, N'Situaciones durante un examen', N'Evaluación', N'Facilita instrucciones claras, control visual del tiempo y un entorno con menos interrupciones.', N'assets/videos/tdah/tdah-examen.mp4', 0, 1, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (13, 2, N'Cambios inesperados', N'Organización y transiciones', N'Explica los cambios con anticipación y actualiza los acuerdos, prioridades y recordatorios.', N'assets/videos/tdah/tdah-cambios.mp4', 1, 1, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (14, 2, N'Participación e impulsividad', N'Participación en clase', N'Establece reglas claras y ofrece vías respetuosas para participar y regular intervenciones impulsivas.', N'assets/videos/tdah/tdah-participacion.mp4', 1, 1, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (15, 2, N'Retroalimentación y organización', N'Organización y mejora', N'Combina comentarios concretos con prioridades, fechas claras y recordatorios para facilitar la aplicación de mejoras.', N'assets/videos/tdah/tdah-retroalimentacion.mp4', 0, 1, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
INSERT [dbo].[Guia] ([IdGuia], [IdNeurodivergencia], [Titulo], [Categoria], [Descripcion], [Video], [ParaEstudiante], [ParaDocente], [Activo], [FechaCreacion], [FechaActualizacion]) VALUES (16, 2, N'Corrección y manejo respetuoso', N'Corrección y respeto', N'Corrige con respeto y claridad, sin atribuir intención negativa a una intervención impulsiva.', N'assets/videos/tdah/tdah-correccion.mp4', 0, 1, 1, CAST(N'2026-11-11T12:03:20.700' AS DateTime), CAST(N'2026-11-11T12:03:20.700' AS DateTime))
SET IDENTITY_INSERT [dbo].[Guia] OFF
GO

INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (1, 1)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (1, 10)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (1, 11)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (1, 12)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (2, 2)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (2, 13)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (2, 14)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (3, 3)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (3, 15)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (3, 16)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (4, 4)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (4, 13)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (4, 17)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (5, 5)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (5, 6)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (5, 18)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (6, 7)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (6, 13)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (6, 19)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (7, 6)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (7, 8)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (7, 20)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (8, 9)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (8, 16)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (8, 21)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (9, 1)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (9, 10)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (9, 11)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (9, 12)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (10, 2)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (10, 13)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (10, 14)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (11, 3)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (11, 15)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (11, 16)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (12, 4)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (12, 13)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (12, 17)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (13, 5)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (13, 6)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (13, 18)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (14, 7)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (14, 13)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (14, 19)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (15, 6)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (15, 8)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (15, 20)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (16, 9)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (16, 16)
INSERT [dbo].[GuiaSituacion] ([IdGuia], [IdSituacion]) VALUES (16, 21)
GO
/* INSERTAR DATOS EN LA TABLA DE NEURODIVERGENCIA */
SET IDENTITY_INSERT [dbo].[Neurodivergencia] ON 

INSERT [dbo].[Neurodivergencia] ([IdNeurodivergencia], [Nombre]) VALUES (1, N'Autismo')
INSERT [dbo].[Neurodivergencia] ([IdNeurodivergencia], [Nombre]) VALUES (4, N'Discalculia')
INSERT [dbo].[Neurodivergencia] ([IdNeurodivergencia], [Nombre]) VALUES (3, N'Dislexia')
INSERT [dbo].[Neurodivergencia] ([IdNeurodivergencia], [Nombre]) VALUES (5, N'Dispraxia')
INSERT [dbo].[Neurodivergencia] ([IdNeurodivergencia], [Nombre]) VALUES (2, N'TDAH')
SET IDENTITY_INSERT [dbo].[Neurodivergencia] OFF
GO
/* INSERTAR DATOS EN LA TABLA DE PREGUNTA */
SET IDENTITY_INSERT [dbo].[Pregunta] ON 

INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (1, 1, 1, N'¿Qué es la sobrecarga de estímulos?', N'Un colapso en el que se recibe más información sensorial de la que se puede procesar.', N'Una conducta para llamar la atención.', N'Falta de ganas de trabajar.', NULL, N'a')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (2, 1, 2, N'¿Cuál puede ser una señal física de sobrecarga?', N'Pedir participar más.', N'Taparse los oídos u ojos, balancearse intensamente o respirar agitadamente.', N'Sonreír constantemente.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (3, 1, 3, N'¿Qué conviene hacer primero?', N'Aumentar el ruido para distraer.', N'Reducir estímulos innecesarios cuando sea posible.', N'Exigir una respuesta inmediata.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (4, 1, 4, N'¿Qué debe evitarse durante una sobrecarga?', N'Tocar sin consentimiento, hacer preguntas complejas o regañar.', N'Guiar a un espacio tranquilo.', N'Dar espacio y tiempo.', NULL, N'a')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (5, 1, 5, N'¿Cómo cuidar la seguridad durante una crisis?', N'Sujetar fuertemente a la persona.', N'Permanecer cerca sin invadir su espacio corporal.', N'Llevarla al centro del salón.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (6, 1, 6, N'¿Cómo reducir estímulos del entorno?', N'Poner música alta.', N'Apagar luces fluorescentes, silenciar dispositivos y bajar la voz.', N'Hacer preguntas complejas.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (7, 2, 1, N'¿Cómo debe ser una instrucción?', N'Corta, concreta, ordenada y con voz calmada.', N'Con sarcasmo y dobles sentidos.', N'Larga y con mucha información a la vez.', NULL, N'a')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (8, 2, 2, N'¿Cuál es un ejemplo de instrucción concreta?', N'Termina pronto.', N'Escribe las conclusiones de la página 3 y entrégalas a las 4:00 p. m.', N'Échale ganas.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (9, 2, 3, N'¿Por qué evitar dobles sentidos, sarcasmo e ironías?', N'El procesamiento puede ser literal y generar confusión.', N'Porque es divertido.', N'Porque no les gusta reírse.', NULL, N'a')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (10, 2, 4, N'¿Cuánto tiempo esperar antes de repetir una pregunta?', N'Un segundo.', N'Entre 5 y 10 segundos.', N'No esperar.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (11, 2, 5, N'¿La falta de contacto visual significa falta de atención?', N'Sí, es falta de respeto.', N'No necesariamente; mirar a los ojos puede dificultar escuchar para algunas personas.', N'Sí, significa desinterés.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (12, 2, 6, N'¿Cómo confirmar que comprendió sin señalar?', N'Preguntar frente a todos si entendió porque es obvio.', N'Pedir que explique con sus palabras el primer paso.', N'Asumir que el silencio significa que sí.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (13, 3, 1, N'¿Cómo organizar las actividades del equipo?', N'Con listas de tareas y calendarios digitales compartidos.', N'Dejando todo a la improvisación.', N'Solo con instrucciones verbales rápidas.', NULL, N'a')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (14, 3, 2, N'¿Cómo distribuir responsabilidades?', N'Que todos hagan todo sin orden.', N'Asignar roles específicos según las fortalezas individuales.', N'Que una persona decida todo.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (15, 3, 3, N'¿Qué debe evitarse al pedir ideas?', N'Permitir aportes por escrito.', N'Obligar a que la lluvia de ideas sea únicamente verbal y caótica.', N'Usar chat o notas.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (16, 3, 4, N'¿Qué establecer desde el primer día?', N'Nada.', N'Normas escritas: canales, horarios y formatos.', N'Cambiar las reglas a diario.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (17, 3, 5, N'¿Cómo comunicar un cambio de integrante o fecha?', N'No decir nada.', N'Avisar pronto con un mensaje claro que explique el nuevo plan.', N'Esperar que el equipo lo adivine.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (18, 3, 6, N'¿Qué favorece una colaboración inclusiva?', N'Listas visuales, roles claros y aportes por escrito cuando sea posible.', N'Solo lluvia de ideas verbal y caótica.', N'Observar fijamente a quien trabaja.', NULL, N'a')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (19, 4, 1, N'¿Qué hacer si hay dificultad relacionada con el ambiente?', N'Permitir sentarse lejos de ventanas o pasillos concurridos.', N'Sentar junto a una fuente de ruido.', N'Sentar en medio del ruido.', NULL, N'a')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (20, 4, 2, N'¿Qué genera presión innecesaria?', N'Usar un cronómetro visual silencioso.', N'Recordar constantemente el tiempo en tono de advertencia.', N'Escribir instrucciones explícitas.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (21, 4, 3, N'¿Cómo deben ser las instrucciones del examen?', N'Con trampas lingüísticas.', N'Explícitas y sin trampas interpretativas.', N'Solo verbales y rápidas.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (22, 4, 4, N'¿Qué hacer ante una posible sobrecarga?', N'Quitar el examen abruptamente.', N'Considerar un pase discreto para caminar o tomar agua, según los acuerdos.', N'Observar fijamente al estudiante.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (23, 4, 5, N'¿Qué se debe evitar durante el examen?', N'Responder dudas con neutralidad.', N'Invalidar dudas por considerarlas obvias o quitar el examen abruptamente.', N'Permitir herramientas de autorregulación acordadas.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (24, 4, 6, N'¿Cuál es el objetivo de adaptar el entorno?', N'Dar una ventaja académica.', N'Reducir la carga sensorial para que pueda demostrar sus conocimientos.', N'Hacer más fácil el contenido.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (25, 5, 1, N'¿Cómo comunicar un cambio?', N'De forma asertiva, objetiva y con apoyos visuales si es posible.', N'Con frases vagas.', N'Gritándolo en el último segundo.', NULL, N'a')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (26, 5, 2, N'¿Cuándo avisar de un cambio?', N'Nunca.', N'Con la mayor anticipación posible por correo o mensaje.', N'Dos minutos antes sin explicar.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (27, 5, 3, N'¿Por qué puede ayudar la predictibilidad?', N'Porque saber qué ocurrirá puede reducir la incertidumbre y facilitar la adaptación.', N'Porque no le gusta estudiar.', N'Porque toda conducta es aprendida.', NULL, N'a')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (28, 5, 4, N'¿Qué frase conviene evitar?', N'La clase cambia al salón B a las 10:00.', N'Al rato vemos dónde nos acomodamos.', N'Te envío el nuevo plan con hora y lugar.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (29, 5, 5, N'¿Cómo comunicar un cambio inesperado?', N'Con anticipación, objetividad y apoyo visual cuando sea posible.', N'Con frases vagas.', N'Avisando dos minutos antes sin explicar.', NULL, N'a')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (30, 5, 6, N'¿Qué hacer después del cambio?', N'Exigir rendimiento óptimo inmediato.', N'Permitir una ventana de transición.', N'Asignar un examen sorpresa.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (31, 6, 1, N'¿Cuál es una forma válida de participar?', N'Solo hablando frente a todos.', N'Chats, encuestas, ensayos breves o notas escritas.', N'Si no habla, no participa.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (32, 6, 2, N'¿Qué se debe evitar al preguntar?', N'Permitir una respuesta escrita después.', N'Lanzar preguntas al azar frente a todo el grupo.', N'Dar tiempo para preparar.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (33, 6, 3, N'¿La exposición pública obligatoria puede ser?', N'La única forma de evaluar.', N'Un detonante de ansiedad intensa.', N'Obligatoria sin excepción.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (34, 6, 4, N'¿Qué rol inclusivo puede ofrecerse en una dinámica?', N'Obligar a actuar aunque cause malestar.', N'Moderador escrito, evaluador o documentador.', N'Excluir a la persona.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (35, 6, 5, N'¿Cómo medir la competencia académica?', N'Por el conocimiento, no por la extroversión.', N'Por quién habla más fuerte.', N'Por quién mira más a los ojos.', NULL, N'a')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (36, 6, 6, N'¿Qué afirmación es incorrecta?', N'Diseñar métodos alternativos.', N'Si no participa oralmente, no sabe.', N'La participación puede ser asincrónica.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (37, 7, 1, N'¿Cómo dar retroalimentación clara?', N'Gritando frente al grupo.', N'En privado, estructurada y por escrito cuando sea útil.', N'Con indirectas.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (38, 7, 2, N'¿Cómo separar persona y conducta?', N'Decir que siempre hace todo mal.', N'Indicar que el reporte necesita ajustes.', N'Personalizar el error.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (39, 7, 3, N'¿Qué comentario ambiguo conviene evitar?', N'En página 2 agrega dos referencias APA.', N'Dale otra pasada o ponle más ganas.', N'Cambia el orden de las secciones.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (40, 7, 4, N'¿Cómo dar una corrección útil?', N'En privado, neutral, específica y con ejemplo.', N'En voz alta frente a todos.', N'Con frases ambiguas.', NULL, N'a')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (41, 7, 5, N'¿Por qué puede ayudar darla por escrito?', N'Para regañar después.', N'Para revisar la información sin la carga emocional del momento.', N'No sirve.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (42, 7, 6, N'¿Qué significa ser específico?', N'Decir «mejóralo».', N'Indicar exactamente qué se espera del trabajo revisado.', N'Decir «no me gustó».', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (43, 8, 1, N'¿Cómo corregir de manera respetuosa?', N'Con tono neutro y hechos objetivos, sin sarcasmo.', N'Con enojo frente a todos.', N'Burlándose.', NULL, N'a')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (44, 8, 2, N'¿Qué hacer después de explicar qué ocurrió?', N'Dejar a la persona sola.', N'Mostrar cómo hacerlo correctamente con un ejemplo paso a paso.', N'Decirle que lo averigüe.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (45, 8, 3, N'¿Qué se debe evitar al corregir?', N'Agendar una charla privada.', N'Avergonzar a la persona frente al grupo.', N'Corregir en privado.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (46, 8, 4, N'¿Dónde corregir un error conceptual o una conducta de autorregulación?', N'En voz alta delante de todos.', N'En privado, sin exponerla ante compañeros.', N'Publicándolo en el grupo.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (47, 8, 5, N'¿Cómo describir el error?', N'Juzgando la intención.', N'Describir lo ocurrido sin juzgar la intención.', N'Decir que lo hizo a propósito.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (48, 8, 6, N'Si evita la mirada o se balancea al corregir, ¿qué conviene recordar?', N'Que es falta de respeto.', N'Puede ser una forma de procesar frustración o ansiedad.', N'Que no le importa.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (49, 9, 1, N'¿Qué puede contribuir a una sobrecarga de estímulos?', N'Un ambiente silencioso.', N'Exceso de estímulos, ruido y muchas instrucciones a la vez.', N'Una tarea clara.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (50, 9, 2, N'¿Qué hacer primero ante la sobrecarga?', N'Dar cinco instrucciones juntas.', N'Reducir estímulos, dar una instrucción a la vez y acordar apoyos.', N'Añadir distractores.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (51, 9, 3, N'¿Qué debe evitar el entorno?', N'Usar calendarios compartidos.', N'Interrupciones innecesarias y cambios sin avisar.', N'Mantener comunicación clara.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (52, 9, 4, N'¿Qué ayuda a reducir distracciones?', N'Música alta.', N'Organizar tiempo, reducir distractores y usar recordatorios visuales.', N'Luces parpadeantes.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (53, 9, 5, N'¿Qué hacer si pierde la concentración?', N'Ridiculizar.', N'Redirigir la atención con respeto e instrucción concreta.', N'Quitarle todo el trabajo.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (54, 9, 6, N'¿Qué puede ayudar ante una posible sobrecarga?', N'Aumentar el ruido.', N'Reducir estímulos y dividir las tareas.', N'Exigir respuesta inmediata.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (55, 10, 1, N'¿Cómo deben ser las instrucciones?', N'Demasiado generales.', N'Claras, concretas, por pasos y por escrito.', N'Con indirectas.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (56, 10, 2, N'¿Qué conviene evitar?', N'Confirmar qué se entrega.', N'Instrucciones demasiado generales como «haz lo que puedas».', N'Recordatorios oportunos.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (57, 10, 3, N'¿Cómo mantener comunicación clara?', N'Cambiar el plan sin avisar.', N'Usar recordatorios, acuerdos del equipo y comunicación clara.', N'Interrumpir constantemente.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (58, 10, 4, N'¿Cómo confirmar que comprendió?', N'Asumir que el silencio significa sí.', N'Confirmar con sus palabras qué debe entregar y cuándo.', N'No confirmar.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (59, 10, 5, N'¿Cómo debe ser una instrucción?', N'Larga y general.', N'Corta, concreta, ordenada y con fecha clara.', N'Con sarcasmo.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (60, 10, 6, N'¿Qué hacer si hay distracción por instrucciones confusas?', N'Regañar.', N'Aclarar la instrucción y evitar interrupciones innecesarias.', N'Dar instrucciones más confusas.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (61, 11, 1, N'¿Cómo distribuir tareas?', N'Dar una tarea enorme sin dividir.', N'Dividir tareas grandes en pasos claros.', N'No establecer fechas.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (62, 11, 2, N'¿Cómo establecer responsabilidades?', N'Que nadie sepa qué hace.', N'Definir responsabilidades, fechas y entregables.', N'Cambiar tareas constantemente.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (63, 11, 3, N'¿Qué ayuda a cumplir entregas?', N'No recordar nunca.', N'Recordar entregas importantes y usar recordatorios.', N'Comunicar solo verbalmente y sin detalles.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (64, 11, 4, N'¿Una distracción significa falta de interés?', N'Siempre es flojera.', N'No debe asumirse automáticamente.', N'Siempre es falta de compromiso.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (65, 11, 5, N'¿Qué favorece el trabajo en equipo?', N'Presión y lluvia de ideas caótica.', N'Listas, roles claros, fechas y participación por escrito cuando sea viable.', N'Observar fijamente a la persona.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (66, 11, 6, N'¿Qué herramienta puede ayudar al equipo?', N'Asumir desinterés.', N'Listas, checklists y calendarios compartidos.', N'Instrucciones confusas.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (67, 12, 1, N'¿Qué puede ayudar durante un examen?', N'Sentarse junto a una ventana ruidosa.', N'Menos distractores, instrucciones claras y organización del tiempo.', N'Aumentar el ruido.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (68, 12, 2, N'¿Qué evitar durante el examen?', N'Un cronómetro visual silencioso.', N'Interrupciones innecesarias y presión constante por el tiempo.', N'Instrucciones escritas.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (69, 12, 3, N'¿Cómo organizar el tiempo?', N'Hacer todo de golpe sin orden.', N'Dividir el examen en bloques y hacer visible el tiempo.', N'No usar ninguna referencia de tiempo.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (70, 12, 4, N'¿Qué hacer ante distracciones?', N'Quitar el examen.', N'Considerar una pausa breve de regulación y redirigir con una instrucción concreta.', N'Exponer al estudiante.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (71, 12, 5, N'¿Qué no debe hacerse?', N'Permitir agua según los acuerdos.', N'Quitar el examen abruptamente o invalidar dudas.', N'Dar instrucciones claras.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (72, 12, 6, N'¿Qué favorece el rendimiento?', N'Música alta.', N'Ambiente estructurado, pocas interrupciones y recordatorios claros.', N'Observar fijamente desde atrás.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (73, 13, 1, N'¿Cómo comunicar un cambio inesperado?', N'Con una frase vaga.', N'Con anticipación, claridad, por escrito y con recordatorio.', N'A última hora sin explicar.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (74, 13, 2, N'¿Qué frase conviene evitar?', N'La junta cambia al martes a las 10:00 en el salón B.', N'Al rato vemos dónde nos acomodamos.', N'Te envío el nuevo plan.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (75, 13, 3, N'¿Cómo se debe comunicar un cambio?', N'Con frases vagas.', N'De forma clara, objetiva, anticipada y con apoyo visual si es posible.', N'Avisando dos minutos antes sin explicar.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (76, 13, 4, N'¿Qué conviene dar después del cambio?', N'Exigir rendimiento inmediato.', N'Una ventana de transición y ayuda para priorizar.', N'Una tarea extra sin explicación.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (77, 13, 5, N'¿Por qué puede ser difícil un cambio?', N'Porque no quiere trabajar.', N'Puede requerir reorganizar el plan y actualizar recordatorios.', N'Porque es rebeldía.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (78, 13, 6, N'¿Qué ayuda a adaptarse?', N'No explicar nada.', N'Mostrar el nuevo plan y confirmar qué se entrega y cuándo.', N'Improvisar.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (79, 14, 1, N'¿Una intervención impulsiva significa falta de respeto?', N'Sí, siempre.', N'No debe interpretarse automáticamente como falta de respeto.', N'Se hace siempre para molestar.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (80, 14, 2, N'¿Cómo manejar la impulsividad en clase?', N'Prohibir participar.', N'Establecer reglas claras y dar oportunidades de participación.', N'Ridiculizar.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (81, 14, 3, N'¿Cómo participar sin presión innecesaria?', N'Solo oralmente y de inmediato.', N'Ofrecer chat, notas o turnos claros.', N'Hacer preguntas sorpresa frente al grupo.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (82, 14, 4, N'¿Qué hacer si interrumpe?', N'Señalar frente al grupo.', N'Redirigir con respeto y recordar la regla de forma privada.', N'Ignorar y excluir.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (83, 14, 5, N'¿Qué debe evitarse?', N'Dar turnos claros.', N'Señalar o ridiculizar frente al grupo.', N'Permitir aportes por escrito.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (84, 14, 6, N'¿Qué ayuda a la participación?', N'No establecer reglas.', N'Reglas claras y oportunidades organizadas de participación.', N'Cambiar reglas a diario.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (85, 15, 1, N'¿Cómo dar retroalimentación?', N'Gritando frente al grupo.', N'En privado, clara, específica y por escrito cuando sea útil.', N'Con indirectas.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (86, 15, 2, N'¿Cómo organizar el tiempo?', N'Todo al mismo tiempo sin orden.', N'Dividir en bloques, priorizar y usar recordatorios.', N'No recordar nunca.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (87, 15, 3, N'¿Qué significa priorizar?', N'No ordenar las actividades.', N'Ordenar qué es urgente e importante.', N'Hacer primero lo menos importante.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (88, 15, 4, N'¿Qué conviene recordar?', N'Nada.', N'Entregas importantes y fechas claras.', N'Solo verbalmente, sin detalles.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (89, 15, 5, N'¿Qué ayuda a aplicar la retroalimentación?', N'Dar comentarios ambiguos y gritar.', N'Indicar por escrito qué mantener y ajustar, y confirmar qué se entrega y cuándo.', N'No dar retroalimentación.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (90, 15, 6, N'¿Qué condiciones previenen frustración y facilitan cumplir?', N'Instrucciones ambiguas y cambios sin aviso.', N'Fechas claras, recordatorios oportunos y acuerdos visibles y estables.', N'Eliminar toda estructura.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (91, 16, 1, N'Ante una intervención impulsiva, ¿qué interpretación es más adecuada?', N'Asumir que es una falta de respeto intencional.', N'Entender que puede relacionarse con dificultad para inhibir impulsos y no asumir falta de respeto.', N'Asumir que quiere molestar.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (92, 16, 2, N'¿Qué hacer después de explicar un error?', N'Dejar a la persona sola.', N'Mostrar cómo hacerlo correctamente paso a paso y dar tiempo de transición.', N'Decirle que lo averigüe.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (93, 16, 3, N'¿Qué evitar al corregir?', N'Dar un ejemplo.', N'Señalar o ridiculizar frente al grupo.', N'Dar oportunidad de volver a participar.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (94, 16, 4, N'¿Qué alternativa inclusiva puede ofrecerse?', N'Quitarle la oportunidad de participar.', N'Anotar la idea en chat o nota, o esperar su turno.', N'Ignorar su aportación.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (95, 16, 5, N'¿Qué ayuda a mantener la motivación tras corregir una conducta?', N'Centrarse solo en el error y excluir.', N'Indicar cómo reincorporarse y reconocer el esfuerzo por regularse.', N'Ignorar a la persona el resto de la clase.', NULL, N'b')
INSERT [dbo].[Pregunta] ([IdPregunta], [IdEvaluacion], [Orden], [Texto], [OpcionA], [OpcionB], [OpcionC], [OpcionD], [Correcta]) VALUES (96, 16, 6, N'¿Qué debe evitar el entorno durante una corrección?', N'Usar recordatorios visuales.', N'Interrumpir innecesariamente, ridiculizar o asumir falta de interés.', N'Establecer reglas claras y dividir tareas.', NULL, N'b')
SET IDENTITY_INSERT [dbo].[Pregunta] OFF
GO
/* INSERTAR DATOS EN LA TABLA DE RECOMENDACION */
SET IDENTITY_INSERT [dbo].[Recomendacion] ON 

INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (9, 2, N'hacer', 1, N'Usa oraciones cortas, voz calmada y un orden claro.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (10, 2, N'hacer', 2, N'Da instrucciones concretas y, cuando sea útil, por escrito.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (11, 2, N'hacer', 3, N'Evita sarcasmo, ironías o dobles sentidos cuando puedan generar confusión.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (12, 2, N'hacer', 4, N'Espera entre 5 y 10 segundos antes de repetir una pregunta.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (13, 2, N'hacer', 5, N'No asumas que evitar el contacto visual significa falta de atención; confirma comprensión con respeto.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (14, 2, N'evitar', 1, N'Dar instrucciones vagas o demasiado extensas.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (15, 2, N'evitar', 2, N'Interpretar el silencio como ignorancia o falta de atención.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (16, 2, N'evitar', 3, N'Preguntar de forma que la persona se sienta señalada.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (17, 3, N'hacer', 1, N'Estructura el trabajo con listas de tareas y calendarios compartidos.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (18, 3, N'hacer', 2, N'Asigna roles concretos según fortalezas e intereses individuales.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (19, 3, N'hacer', 3, N'Permite aportaciones por escrito o asincrónicas cuando sea viable.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (20, 3, N'hacer', 4, N'Acuerda por escrito canales, horarios, entregables y formatos.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (21, 3, N'hacer', 5, N'Comunica inmediatamente cambios de integrantes o fechas y explica el nuevo plan.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (22, 3, N'evitar', 1, N'Obligar a que toda lluvia de ideas sea únicamente verbal y caótica.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (23, 3, N'evitar', 2, N'Dejar responsabilidades implícitas o cambiar reglas constantemente.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (24, 3, N'evitar', 3, N'Asumir que una forma distinta de participar es falta de compromiso.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (25, 4, N'hacer', 1, N'Permite sentarse lejos de distractores como ventanas o pasillos concurridos cuando sea posible.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (26, 4, N'hacer', 2, N'Escribe instrucciones explícitas y evita trampas lingüísticas o interpretativas.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (27, 4, N'hacer', 3, N'Utiliza un cronómetro visual silencioso en lugar de advertencias verbales constantes.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (28, 4, N'hacer', 4, N'Ante señales de sobrecarga, considera una pausa o pase de salida discreto según los acuerdos disponibles.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (29, 4, N'hacer', 5, N'Responde dudas de forma neutral y respetuosa.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (30, 4, N'evitar', 1, N'Quitar el examen abruptamente.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (31, 4, N'evitar', 2, N'Invalidar dudas como si fueran obvias.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (32, 4, N'evitar', 3, N'Pararse detrás del asiento y observar fijamente.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (33, 5, N'hacer', 1, N'Comunica el cambio de forma asertiva y objetiva, usando apoyos visuales si es posible.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (34, 5, N'hacer', 2, N'Avisa tan pronto como se conozca el cambio, por correo o mensaje.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (35, 5, N'hacer', 3, N'Explica el nuevo plan, el lugar, la hora y los pasos siguientes.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (36, 5, N'hacer', 4, N'Permite una ventana de transición antes de exigir rendimiento pleno.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (37, 5, N'evitar', 1, N'Usar frases vagas como «al rato vemos».')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (38, 5, N'evitar', 2, N'Avisar a última hora sin explicar.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (39, 5, N'evitar', 3, N'Exigir una transición inmediata sin tiempo de adaptación.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (40, 6, N'hacer', 1, N'Permite participar por chat, encuestas, notas o ensayos breves.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (41, 6, N'hacer', 2, N'Da tiempo para preparar respuestas y evita preguntas al azar frente al grupo.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (42, 6, N'hacer', 3, N'En debates o dinámicas, ofrece roles como moderador escrito, evaluador o documentador.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (43, 6, N'hacer', 4, N'Evalúa el conocimiento y los objetivos de aprendizaje, no la extroversión.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (44, 6, N'evitar', 1, N'Obligar a participar oralmente como única opción.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (45, 6, N'evitar', 2, N'Exigir respuestas inmediatas delante del grupo.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (46, 6, N'evitar', 3, N'Interpretar que no hablar equivale a no saber.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (47, 7, N'hacer', 1, N'Ofrece retroalimentación en privado y, cuando sea útil, por escrito.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (48, 7, N'hacer', 2, N'Organiza los comentarios: puntos positivos y después aspectos a mejorar.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (49, 7, N'hacer', 3, N'Separa a la persona del trabajo o conducta que se está revisando.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (50, 7, N'hacer', 4, N'Indica acciones concretas, por ejemplo, qué sección corregir o qué referencia agregar.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (51, 7, N'evitar', 1, N'Gritar o corregir frente al grupo.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (52, 7, N'evitar', 2, N'Usar frases ambiguas como «dale otra pasada» o «ponle más ganas».')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (53, 7, N'evitar', 3, N'Personalizar el error o atribuir malas intenciones.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (54, 8, N'hacer', 1, N'Usa un tono neutral, sin sarcasmo ni enojo.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (55, 8, N'hacer', 2, N'Describe qué ocurrió sin juzgar la intención.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (56, 8, N'hacer', 3, N'Muestra un ejemplo o modelo visual del procedimiento correcto, paso a paso.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (57, 8, N'hacer', 4, N'Habla en privado cuando sea necesario corregir un error conceptual o una conducta de autorregulación.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (58, 8, N'evitar', 1, N'Avergonzar a la persona frente al grupo.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (59, 8, N'evitar', 2, N'Interpretar automáticamente una reacción emocional como falta de respeto.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (60, 8, N'evitar', 3, N'Juzgar la intención en lugar de describir el hecho.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (61, 9, N'hacer', 1, N'Reduce estímulos innecesarios y evita interrupciones que no sean necesarias.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (62, 9, N'hacer', 2, N'Da una instrucción a la vez y divide la actividad en pasos.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (63, 9, N'hacer', 3, N'Usa listas, recordatorios visuales y organización del tiempo.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (64, 9, N'hacer', 4, N'Si pierde la concentración, redirige la atención con respeto y una indicación concreta.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (65, 9, N'evitar', 1, N'Dar muchas instrucciones juntas.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (66, 9, N'evitar', 2, N'Añadir distractores o interrupciones innecesarias.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (67, 9, N'evitar', 3, N'Ridiculizar o quitar la actividad como castigo por distraerse.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (68, 10, N'hacer', 1, N'Da instrucciones claras, concretas, por pasos y también por escrito cuando sea útil.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (69, 10, N'hacer', 2, N'Evita indicaciones generales como «haz lo que puedas».')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (70, 10, N'hacer', 3, N'Confirma qué se debe entregar, en qué formato y cuándo.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (71, 10, N'hacer', 4, N'Usa recordatorios o acuerdos visibles y mantén comunicación clara.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (72, 10, N'evitar', 1, N'Cambiar el plan sin avisar.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (73, 10, N'evitar', 2, N'Interrumpir constantemente.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (74, 10, N'evitar', 3, N'Suponer que el silencio confirma que todo quedó claro.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (75, 11, N'hacer', 1, N'Divide tareas grandes en pasos pequeños.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (76, 11, N'hacer', 2, N'Establece responsabilidades, fechas y entregables claros.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (77, 11, N'hacer', 3, N'Utiliza listas, checklists, calendarios compartidos y recordatorios.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (78, 11, N'hacer', 4, N'Mantén acuerdos visibles y comunicación clara.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (79, 11, N'hacer', 5, N'No asumas que una distracción significa falta de interés.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (80, 11, N'evitar', 1, N'Dejar tareas enormes sin dividir ni fecha.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (81, 11, N'evitar', 2, N'Cambiar responsabilidades constantemente.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (82, 11, N'evitar', 3, N'Interpretar automáticamente una distracción como flojera o falta de compromiso.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (83, 12, N'hacer', 1, N'Permite ubicarse lejos de distractores cuando sea posible.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (84, 12, N'hacer', 2, N'Presenta instrucciones claras y por escrito.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (85, 12, N'hacer', 3, N'Divide el examen en bloques o ayuda a priorizar actividades y tiempo disponible.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (86, 12, N'hacer', 4, N'Utiliza referencias visuales de tiempo y evita interrupciones innecesarias.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (87, 12, N'hacer', 5, N'Ante distracciones, considera una pausa breve acordada y redirige con una instrucción concreta.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (88, 12, N'evitar', 1, N'Presionar constantemente por el tiempo.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (89, 12, N'evitar', 2, N'Invalidar dudas o quitar el examen abruptamente.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (90, 12, N'evitar', 3, N'Añadir interrupciones o exponer al estudiante delante del grupo.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (91, 13, N'hacer', 1, N'Comunica los cambios con anticipación, de forma clara y por escrito cuando sea posible.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (92, 13, N'hacer', 2, N'Explica el nuevo plan y actualiza recordatorios y fechas.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (93, 13, N'hacer', 3, N'Permite una ventana de transición y ayuda a priorizar tareas.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (94, 13, N'hacer', 4, N'Confirma qué debe entregarse y cuándo.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (95, 13, N'evitar', 1, N'Usar frases vagas o avisar en el último momento sin explicación.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (96, 13, N'evitar', 2, N'Exigir una transición inmediata sin aclarar prioridades.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (97, 13, N'evitar', 3, N'Cambiar acuerdos sin hacerlos visibles.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (98, 14, N'hacer', 1, N'Establece reglas de turnos claras y oportunidades de participación.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (99, 14, N'hacer', 2, N'Redirige la atención de manera respetuosa y recuerda los acuerdos de forma discreta.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (100, 14, N'hacer', 3, N'Permite aportar ideas por chat o notas, o usar turnos asignados.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (101, 14, N'hacer', 4, N'Reconoce el esfuerzo por regularse y facilitar la reincorporación a la actividad.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (102, 14, N'evitar', 1, N'Interpretar automáticamente una interrupción como falta de respeto.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (103, 14, N'evitar', 2, N'Señalar o ridiculizar frente al grupo.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (104, 14, N'evitar', 3, N'Excluir a la persona después de una intervención impulsiva.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (105, 15, N'hacer', 1, N'Da retroalimentación en privado, clara, específica y por escrito cuando sea útil.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (106, 15, N'hacer', 2, N'Indica qué mantener, qué ajustar y cuáles son los siguientes pasos.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (107, 15, N'hacer', 3, N'Divide el trabajo en bloques y prioriza lo urgente e importante.')
GO
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (108, 15, N'hacer', 4, N'Confirma fechas, entregables y acuerdos; mantén recordatorios visibles.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (109, 15, N'evitar', 1, N'Gritar frente al grupo o usar indirectas.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (110, 15, N'evitar', 2, N'Usar frases ambiguas como «échale más ganas».')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (111, 15, N'evitar', 3, N'Cambiar acuerdos sin avisar ni dejar recordatorios.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (112, 16, N'hacer', 1, N'Explica el error sin asumir que fue intencional.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (113, 16, N'hacer', 2, N'Indica cómo hacerlo correctamente, paso a paso, y da tiempo para reincorporarse.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (114, 16, N'hacer', 3, N'Ofrece vías alternativas para aportar, como anotar la idea o esperar un turno.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (115, 16, N'hacer', 4, N'Reconoce el esfuerzo por regularse y mantener la participación.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (116, 16, N'evitar', 1, N'Ridiculizar o señalar frente al grupo.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (117, 16, N'evitar', 2, N'Quitar toda oportunidad de participar después de una interrupción.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (118, 16, N'evitar', 3, N'Suponer automáticamente que una distracción demuestra desinterés.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (125, 1, N'hacer', 1, N'Reduce ruidos, luces, olores u otros estímulos que sea posible disminuir.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (126, 1, N'hacer', 2, N'Guía a la persona a un espacio tranquilo, silencioso y con luz tenue.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (127, 1, N'hacer', 3, N'Permanece cerca para cuidar la seguridad, sin invadir el espacio corporal.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (128, 1, N'hacer', 4, N'Da espacio y tiempo; no exijas que hable o participe de inmediato.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (129, 1, N'hacer', 5, N'Facilita herramientas de autorregulación, como auriculares o un objeto manipulable, si la persona las utiliza.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (130, 1, N'evitar', 1, N'Tocar sin consentimiento explícito.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (131, 1, N'evitar', 2, N'Hacer preguntas complejas, regañar u obligar a hablar durante la sobrecarga.')
INSERT [dbo].[Recomendacion] ([IdRecomendacion], [IdGuia], [Tipo], [Orden], [Texto]) VALUES (132, 1, N'evitar', 3, N'Aumentar el ruido o reunir personas alrededor.')
SET IDENTITY_INSERT [dbo].[Recomendacion] OFF
GO
/* INSERTAR DATOS EN LA TABLA DE SITUACION */
SET IDENTITY_INSERT [dbo].[Situacion] ON 

INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (1, N'sobrecarga', N'Sobrecarga de estímulos', 1)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (2, N'comunicacion', N'Comunicación', 1)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (3, N'trabajo-equipo', N'Trabajo en equipo', 1)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (4, N'examen', N'Exámenes', 1)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (5, N'cambios', N'Cambios inesperados', 1)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (6, N'organizacion', N'Organización', 1)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (7, N'participacion', N'Participación', 1)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (8, N'retroalimentacion', N'Retroalimentación', 1)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (9, N'correccion', N'Corrección respetuosa', 1)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (10, N'estimulos', N'Estímulos', 0)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (11, N'aula', N'Aula', 0)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (12, N'atencion', N'Atención', 0)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (13, N'clase', N'Clase', 0)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (14, N'instrucciones', N'Instrucciones', 0)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (15, N'colaboracion', N'Colaboración', 0)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (16, N'convivencia', N'Convivencia', 0)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (17, N'evaluacion', N'Evaluación', 0)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (18, N'transiciones', N'Transiciones', 0)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (19, N'impulsividad', N'Impulsividad', 0)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (20, N'mejora', N'Mejora', 0)
INSERT [dbo].[Situacion] ([IdSituacion], [Clave], [Nombre], [EsFiltro]) VALUES (21, N'respeto', N'Respeto', 0)
SET IDENTITY_INSERT [dbo].[Situacion] OFF
GO
/* INSERTAR DATOS EN LA TABLA DE USUARIO */
SET IDENTITY_INSERT [dbo].[Usuario] ON 

INSERT [dbo].[Usuario] ([IdUsuario], [NombreCompleto], [Correo], [Contrasena], [TipoUsuario], [Activo], [FechaRegistro], [FechaUltimoAcceso]) VALUES (1, N'Administrador', N'adminmentesconectadas@gmail.com', N'100000.4BaCkjMZwSH7VYE/Gc6LxA==.+v3zaxq3dn6nt82561EekcKxtrqbbTJKiMZqNx300+U=', N'Administrador', 1, CAST(N'2026-11-11T12:03:20.673' AS DateTime), CAST(N'2026-11-22T15:14:08.477' AS DateTime))
INSERT [dbo].[Usuario] ([IdUsuario], [NombreCompleto], [Correo], [Contrasena], [TipoUsuario], [Activo], [FechaRegistro], [FechaUltimoAcceso]) VALUES (2, N'Estudiante de prueba', N'estudiante.prueba@correo.com', N'100000.Em+B7Q0r6BjF/GlwIWd6Cg==.x92tuvvV+iQC4Mq6WdEAnRH9nNktheD+UdS8AQ1Pi+Y=', N'Estudiante', 1, CAST(N'2026-11-11T12:03:20.673' AS DateTime), CAST(N'2026-11-22T11:48:26.723' AS DateTime))
INSERT [dbo].[Usuario] ([IdUsuario], [NombreCompleto], [Correo], [Contrasena], [TipoUsuario], [Activo], [FechaRegistro], [FechaUltimoAcceso]) VALUES (3, N'Docente de prueba', N'docente.prueba@correo.com', N'100000.ZuyobbJooBdY6FTplC2r1Q==.7NSUcXBwHTLghXopbJO+jmjDEq/DVGv4q8YrtMWI9oQ=', N'Docente', 1, CAST(N'2026-11-11T12:03:20.673' AS DateTime), CAST(N'2026-11-22T15:08:14.540' AS DateTime))
SET IDENTITY_INSERT [dbo].[Usuario] OFF
GO
/* INSERTAR DATOS EN LA TABLA DE VISTA GUIA */
SET IDENTITY_INSERT [dbo].[VistaGuia] ON 

INSERT [dbo].[VistaGuia] ([IdVista], [IdUsuario], [IdGuia], [Fecha]) VALUES (1, 2, 1, CAST(N'2026-11-11T12:20:53.173' AS DateTime))
INSERT [dbo].[VistaGuia] ([IdVista], [IdUsuario], [IdGuia], [Fecha]) VALUES (2, 2, 1, CAST(N'2026-11-17T15:22:52.467' AS DateTime))
INSERT [dbo].[VistaGuia] ([IdVista], [IdUsuario], [IdGuia], [Fecha]) VALUES (3, 2, 1, CAST(N'2026-11-21T17:19:39.757' AS DateTime))
INSERT [dbo].[VistaGuia] ([IdVista], [IdUsuario], [IdGuia], [Fecha]) VALUES (4, 2, 1, CAST(N'2026-11-21T18:05:07.687' AS DateTime))
SET IDENTITY_INSERT [dbo].[VistaGuia] OFF
GO


/* ==================================================================================
   INDICES Y RESTRICCIONES UNIQUE
   ================================================================================== */

CREATE NONCLUSTERED INDEX [IX_Comentario_IdGuia] ON [dbo].[Comentario]
(
	[IdGuia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_Donacion_Estado] ON [dbo].[Donacion]
(
	[Estado] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_Donacion_IdPagoProveedor] ON [dbo].[Donacion]
(
	[IdPagoProveedor] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Evaluacion] ADD UNIQUE NONCLUSTERED 
(
	[IdGuia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Neurodivergencia] ADD UNIQUE NONCLUSTERED 
(
	[Nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_ResultadoEvaluacion_IdGuia] ON [dbo].[ResultadoEvaluacion]
(
	[IdGuia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Situacion] ADD UNIQUE NONCLUSTERED 
(
	[Clave] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Usuario] ADD UNIQUE NONCLUSTERED 
(
	[Correo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_VistaGuia_IdGuia] ON [dbo].[VistaGuia]
(
	[IdGuia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO


/* ==================================================================================
   VALORES POR DEFECTO
   ================================================================================== */

ALTER TABLE [dbo].[Calificacion] ADD  DEFAULT (getdate()) FOR [Fecha]
GO

ALTER TABLE [dbo].[Comentario] ADD  DEFAULT ((0)) FOR [Oculto]
GO
ALTER TABLE [dbo].[Comentario] ADD  DEFAULT (getdate()) FOR [Fecha]
GO

ALTER TABLE [dbo].[Donacion] ADD  DEFAULT ((0)) FOR [OtraCantidad]
GO
ALTER TABLE [dbo].[Donacion] ADD  DEFAULT ('intencion') FOR [Estado]
GO
ALTER TABLE [dbo].[Donacion] ADD  DEFAULT (getdate()) FOR [Fecha]
GO
ALTER TABLE [dbo].[Donacion] ADD  CONSTRAINT [DF_Donacion_Moneda]  DEFAULT ('MXN') FOR [Moneda]
GO
ALTER TABLE [dbo].[Donacion] ADD  CONSTRAINT [DF_Donacion_FechaActualizacion]  DEFAULT (getdate()) FOR [FechaActualizacion]
GO

ALTER TABLE [dbo].[Evaluacion] ADD  DEFAULT (getdate()) FOR [FechaCreacion]
GO

ALTER TABLE [dbo].[Favorito] ADD  DEFAULT (getdate()) FOR [FechaAgregado]
GO

ALTER TABLE [dbo].[Guia] ADD  DEFAULT ((0)) FOR [ParaEstudiante]
GO
ALTER TABLE [dbo].[Guia] ADD  DEFAULT ((0)) FOR [ParaDocente]
GO
ALTER TABLE [dbo].[Guia] ADD  DEFAULT ((1)) FOR [Activo]
GO
ALTER TABLE [dbo].[Guia] ADD  DEFAULT (getdate()) FOR [FechaCreacion]
GO
ALTER TABLE [dbo].[Guia] ADD  DEFAULT (getdate()) FOR [FechaActualizacion]
GO

ALTER TABLE [dbo].[ResultadoEvaluacion] ADD  DEFAULT (getdate()) FOR [Fecha]
GO

ALTER TABLE [dbo].[Situacion] ADD  DEFAULT ((0)) FOR [EsFiltro]
GO

ALTER TABLE [dbo].[Usuario] ADD  DEFAULT ((1)) FOR [Activo]
GO
ALTER TABLE [dbo].[Usuario] ADD  DEFAULT (getdate()) FOR [FechaRegistro]
GO

ALTER TABLE [dbo].[VistaGuia] ADD  DEFAULT (getdate()) FOR [Fecha]
GO


/* ==================================================================================
   LLAVES FORANEAS
   ================================================================================== */

ALTER TABLE [dbo].[Calificacion]  WITH CHECK ADD FOREIGN KEY([IdGuia])
REFERENCES [dbo].[Guia] ([IdGuia])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Calificacion]  WITH CHECK ADD FOREIGN KEY([IdUsuario])
REFERENCES [dbo].[Usuario] ([IdUsuario])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[Comentario]  WITH CHECK ADD FOREIGN KEY([IdGuia])
REFERENCES [dbo].[Guia] ([IdGuia])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Comentario]  WITH CHECK ADD FOREIGN KEY([IdUsuario])
REFERENCES [dbo].[Usuario] ([IdUsuario])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[Donacion]  WITH CHECK ADD FOREIGN KEY([IdUsuario])
REFERENCES [dbo].[Usuario] ([IdUsuario])
ON DELETE SET NULL
GO

ALTER TABLE [dbo].[Evaluacion]  WITH CHECK ADD FOREIGN KEY([IdGuia])
REFERENCES [dbo].[Guia] ([IdGuia])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[Favorito]  WITH CHECK ADD FOREIGN KEY([IdGuia])
REFERENCES [dbo].[Guia] ([IdGuia])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Favorito]  WITH CHECK ADD FOREIGN KEY([IdUsuario])
REFERENCES [dbo].[Usuario] ([IdUsuario])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[Guia]  WITH CHECK ADD FOREIGN KEY([IdNeurodivergencia])
REFERENCES [dbo].[Neurodivergencia] ([IdNeurodivergencia])
GO

ALTER TABLE [dbo].[GuiaSituacion]  WITH CHECK ADD FOREIGN KEY([IdGuia])
REFERENCES [dbo].[Guia] ([IdGuia])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[GuiaSituacion]  WITH CHECK ADD FOREIGN KEY([IdSituacion])
REFERENCES [dbo].[Situacion] ([IdSituacion])
GO

ALTER TABLE [dbo].[Pregunta]  WITH CHECK ADD FOREIGN KEY([IdEvaluacion])
REFERENCES [dbo].[Evaluacion] ([IdEvaluacion])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[Recomendacion]  WITH CHECK ADD FOREIGN KEY([IdGuia])
REFERENCES [dbo].[Guia] ([IdGuia])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[ResultadoEvaluacion]  WITH CHECK ADD FOREIGN KEY([IdGuia])
REFERENCES [dbo].[Guia] ([IdGuia])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ResultadoEvaluacion]  WITH CHECK ADD FOREIGN KEY([IdUsuario])
REFERENCES [dbo].[Usuario] ([IdUsuario])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[VistaGuia]  WITH CHECK ADD FOREIGN KEY([IdGuia])
REFERENCES [dbo].[Guia] ([IdGuia])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[VistaGuia]  WITH CHECK ADD FOREIGN KEY([IdUsuario])
REFERENCES [dbo].[Usuario] ([IdUsuario])
ON DELETE CASCADE
GO


/* ==================================================================================
   RESTRICCIONES CHECK
   ================================================================================== */

ALTER TABLE [dbo].[Calificacion]  WITH CHECK ADD CHECK  (([Estrellas]>=(1) AND [Estrellas]<=(5)))
GO

ALTER TABLE [dbo].[Donacion]  WITH CHECK ADD CHECK  (([Monto]>(0)))
GO
ALTER TABLE [dbo].[Donacion]  WITH CHECK ADD  CONSTRAINT [CK_Donacion_Estado] CHECK  (([Estado]='reembolsada' OR [Estado]='rechazada' OR [Estado]='confirmada' OR [Estado]='pendiente' OR [Estado]='intencion'))
GO
ALTER TABLE [dbo].[Donacion] CHECK CONSTRAINT [CK_Donacion_Estado]
GO

ALTER TABLE [dbo].[Guia]  WITH CHECK ADD CHECK  (([ParaEstudiante]=(1) OR [ParaDocente]=(1)))
GO

ALTER TABLE [dbo].[Pregunta]  WITH CHECK ADD CHECK  (([Correcta]='d' OR [Correcta]='c' OR [Correcta]='b' OR [Correcta]='a'))
GO

ALTER TABLE [dbo].[Recomendacion]  WITH CHECK ADD CHECK  (([Tipo]='evitar' OR [Tipo]='hacer'))
GO

ALTER TABLE [dbo].[ResultadoEvaluacion]  WITH CHECK ADD CHECK  (([Total]>(0) AND [Aciertos]>=(0) AND [Aciertos]<=[Total]))
GO

ALTER TABLE [dbo].[Usuario]  WITH CHECK ADD CHECK  (([TipoUsuario]='Administrador' OR [TipoUsuario]='Docente' OR [TipoUsuario]='Estudiante'))
GO


/* ==================================================================================
   STORED PROCEDURES
   ================================================================================== */


/* ---------- CATALOGOS Y GUIAS ---------- */

-- ===== STORED PROCEDURE sp_listaNeurodivergencias =====
create procedure [dbo].[sp_listaNeurodivergencias]
as
begin
	set nocount on;

	select IdNeurodivergencia, Nombre
	from Neurodivergencia
	order by IdNeurodivergencia
end
GO

-- ===== STORED PROCEDURE sp_listaSituaciones =====
create procedure [dbo].[sp_listaSituaciones]
as
begin
	set nocount on;

	select IdSituacion, Clave, Nombre, EsFiltro
	from Situacion
	order by IdSituacion
end
GO

-- ===== STORED PROCEDURE sp_listaGuias =====
-- Consulta general con filtros opcionales 
-- Administrador: @TipoUsuario = NULL y @SoloVisibles = 0 
-- Estudiante o Docente: @TipoUsuario = 'Estudiante' o 'Docente' y @SoloVisibles = 1.
create procedure [dbo].[sp_listaGuias](
@IdNeurodivergencia int = null,
@Situacion varchar(30) = null,
@Texto varchar(100) = null,
@TipoUsuario varchar(15) = null,
@SoloVisibles bit = 0
)
as
begin
	set nocount on;

	declare @Patron varchar(102)
	set @Patron = '%' + ltrim(rtrim(isnull(@Texto, ''))) + '%'

	select
		g.IdGuia,
		g.Titulo,
		g.Categoria,
		g.Descripcion,
		g.Video,
		g.IdNeurodivergencia,
		n.Nombre as Neurodivergencia,
		g.ParaEstudiante,
		g.ParaDocente,
		g.Activo,
		stuff((select ',' + s.Clave
			from GuiaSituacion gs
			inner join Situacion s on s.IdSituacion = gs.IdSituacion
			where gs.IdGuia = g.IdGuia
			order by s.IdSituacion
			for xml path('')), 1, 1, '') as Situaciones,
		(select count(*) from Evaluacion e
			inner join Pregunta p on p.IdEvaluacion = e.IdEvaluacion
			where e.IdGuia = g.IdGuia) as TotalPreguntas,
		cast((select avg(cast(c.Estrellas as decimal(5,2))) from Calificacion c where c.IdGuia = g.IdGuia) as decimal(3,1)) as PromedioCalificacion,
		(select count(*) from Calificacion c where c.IdGuia = g.IdGuia) as TotalCalificaciones,
		(select count(*) from Comentario m where m.IdGuia = g.IdGuia and m.Oculto = 0) as TotalComentarios
	from Guia g
	inner join Neurodivergencia n on n.IdNeurodivergencia = g.IdNeurodivergencia
	where (@IdNeurodivergencia is null or g.IdNeurodivergencia = @IdNeurodivergencia)
	and (@SoloVisibles = 0 or g.Activo = 1)
	and (@TipoUsuario is null
		or @TipoUsuario not in ('Estudiante','Docente')
		or (@TipoUsuario = 'Estudiante' and g.ParaEstudiante = 1)
		or (@TipoUsuario = 'Docente' and g.ParaDocente = 1))
	and (isnull(@Situacion, '') = ''
		or exists (select 1 from GuiaSituacion gs
			inner join Situacion s on s.IdSituacion = gs.IdSituacion
			where gs.IdGuia = g.IdGuia and s.Clave = @Situacion))
	and (len(@Patron) = 2
		or g.Titulo like @Patron collate Latin1_General_CI_AI
		or g.Categoria like @Patron collate Latin1_General_CI_AI
		or g.Descripcion like @Patron collate Latin1_General_CI_AI
		or n.Nombre like @Patron collate Latin1_General_CI_AI
		or exists (select 1 from GuiaSituacion gs
			inner join Situacion s on s.IdSituacion = gs.IdSituacion
			where gs.IdGuia = g.IdGuia
			and (s.Clave like @Patron collate Latin1_General_CI_AI or s.Nombre like @Patron collate Latin1_General_CI_AI)))
	order by g.IdGuia
end
GO

-- ===== STORED PROCEDURE sp_obtenerGuia =====

create procedure [dbo].[sp_obtenerGuia](
@IdGuia int
)
as
begin
	set nocount on;

	select
		g.IdGuia,
		g.Titulo,
		g.Categoria,
		g.Descripcion,
		g.Video,
		g.IdNeurodivergencia,
		n.Nombre as Neurodivergencia,
		g.ParaEstudiante,
		g.ParaDocente,
		g.Activo,
		g.FechaCreacion,
		g.FechaActualizacion
	from Guia g
	inner join Neurodivergencia n on n.IdNeurodivergencia = g.IdNeurodivergencia
	where g.IdGuia = @IdGuia

	select Tipo, Orden, Texto
	from Recomendacion
	where IdGuia = @IdGuia
	order by Tipo, Orden

	select s.IdSituacion, s.Clave, s.Nombre, s.EsFiltro
	from GuiaSituacion gs
	inner join Situacion s on s.IdSituacion = gs.IdSituacion
	where gs.IdGuia = @IdGuia
	order by s.IdSituacion
end
GO

-- ===== STORED PROCEDURE sp_crearGuia =====

create procedure [dbo].[sp_crearGuia](
@Titulo varchar(80),
@IdNeurodivergencia int,
@Categoria varchar(60),
@Descripcion varchar(260),
@Recomendaciones varchar(max),
@Evitar varchar(max),
@ParaEstudiante bit,
@ParaDocente bit,
@Situaciones varchar(500),
@Activo bit,
@IdGuia int output,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	set @IdGuia = 0
	set @Titulo = ltrim(rtrim(isnull(@Titulo, '')))
	set @Categoria = ltrim(rtrim(isnull(@Categoria, '')))
	set @Descripcion = ltrim(rtrim(isnull(@Descripcion, '')))

	if @Titulo = '' or @Categoria = '' or @Descripcion = ''
	begin
		set @numeroError = 50001
		set @respuesta = 'Completa título, categoría y descripción'
		return
	end

	if not exists (select 1 from Neurodivergencia where IdNeurodivergencia = @IdNeurodivergencia)
	begin
		set @numeroError = 50002
		set @respuesta = 'La neurodivergencia seleccionada no existe'
		return
	end

	if not exists (select 1 from dbo.fn_dividirTexto(@Recomendaciones, char(10)))
		or not exists (select 1 from dbo.fn_dividirTexto(@Evitar, char(10)))
	begin
		set @numeroError = 50003
		set @respuesta = 'Agrega al menos una recomendación y una cosa por evitar'
		return
	end

	if isnull(@ParaEstudiante, 0) = 0 and isnull(@ParaDocente, 0) = 0
	begin
		set @numeroError = 50004
		set @respuesta = 'Elige para quién es la guía (Estudiante, Docente o ambos)'
		return
	end

	if exists (select 1 from Guia where Titulo = @Titulo and IdNeurodivergencia = @IdNeurodivergencia)
	begin
		set @numeroError = 50005
		set @respuesta = 'Ya existe una guía con ese título para esa neurodivergencia'
		return
	end

	begin try
		begin transaction

		insert into Guia(IdNeurodivergencia, Titulo, Categoria, Descripcion, ParaEstudiante, ParaDocente, Activo)
		values (@IdNeurodivergencia, @Titulo, @Categoria, @Descripcion, isnull(@ParaEstudiante, 0), isnull(@ParaDocente, 0), isnull(@Activo, 1))

		set @IdGuia = scope_identity()

		insert into Recomendacion(IdGuia, Tipo, Orden, Texto)
		select @IdGuia, 'hacer', Orden, Valor from dbo.fn_dividirTexto(@Recomendaciones, char(10))

		insert into Recomendacion(IdGuia, Tipo, Orden, Texto)
		select @IdGuia, 'evitar', Orden, Valor from dbo.fn_dividirTexto(@Evitar, char(10))

		insert into GuiaSituacion(IdGuia, IdSituacion)
		select distinct @IdGuia, s.IdSituacion
		from dbo.fn_dividirTexto(@Situaciones, ',') t
		inner join Situacion s on s.Clave = t.Valor

		commit transaction

		set @numeroError = 0
		set @respuesta = 'Guía agregada correctamente'
	end try
	begin catch
		if @@trancount > 0 rollback transaction
		set @IdGuia = 0
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_editarGuia =====

create procedure [dbo].[sp_editarGuia](
@IdGuia int,
@Titulo varchar(80),
@IdNeurodivergencia int,
@Categoria varchar(60),
@Descripcion varchar(260),
@Recomendaciones varchar(max),
@Evitar varchar(max),
@ParaEstudiante bit,
@ParaDocente bit,
@Situaciones varchar(500),
@Activo bit,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	set @Titulo = ltrim(rtrim(isnull(@Titulo, '')))
	set @Categoria = ltrim(rtrim(isnull(@Categoria, '')))
	set @Descripcion = ltrim(rtrim(isnull(@Descripcion, '')))

	if not exists (select 1 from Guia where IdGuia = @IdGuia)
	begin
		set @numeroError = 50006
		set @respuesta = 'La guía no existe'
		return
	end

	if @Titulo = '' or @Categoria = '' or @Descripcion = ''
	begin
		set @numeroError = 50001
		set @respuesta = 'Completa título, categoría y descripción'
		return
	end

	if not exists (select 1 from Neurodivergencia where IdNeurodivergencia = @IdNeurodivergencia)
	begin
		set @numeroError = 50002
		set @respuesta = 'La neurodivergencia seleccionada no existe'
		return
	end

	if not exists (select 1 from dbo.fn_dividirTexto(@Recomendaciones, char(10)))
		or not exists (select 1 from dbo.fn_dividirTexto(@Evitar, char(10)))
	begin
		set @numeroError = 50003
		set @respuesta = 'Agrega al menos una recomendación y una cosa por evitar'
		return
	end

	if isnull(@ParaEstudiante, 0) = 0 and isnull(@ParaDocente, 0) = 0
	begin
		set @numeroError = 50004
		set @respuesta = 'Elige para quién es la guía (Estudiante, Docente o ambos)'
		return
	end

	if exists (select 1 from Guia where Titulo = @Titulo and IdNeurodivergencia = @IdNeurodivergencia and IdGuia <> @IdGuia)
	begin
		set @numeroError = 50005
		set @respuesta = 'Ya existe una guía con ese título para esa neurodivergencia'
		return
	end

	begin try
		begin transaction

		update Guia
		set
			IdNeurodivergencia = @IdNeurodivergencia,
			Titulo = @Titulo,
			Categoria = @Categoria,
			Descripcion = @Descripcion,
			ParaEstudiante = isnull(@ParaEstudiante, 0),
			ParaDocente = isnull(@ParaDocente, 0),
			Activo = isnull(@Activo, 1),
			FechaActualizacion = getdate()
		where IdGuia = @IdGuia

		delete from Recomendacion where IdGuia = @IdGuia
		delete from GuiaSituacion where IdGuia = @IdGuia

		insert into Recomendacion(IdGuia, Tipo, Orden, Texto)
		select @IdGuia, 'hacer', Orden, Valor from dbo.fn_dividirTexto(@Recomendaciones, char(10))

		insert into Recomendacion(IdGuia, Tipo, Orden, Texto)
		select @IdGuia, 'evitar', Orden, Valor from dbo.fn_dividirTexto(@Evitar, char(10))

		insert into GuiaSituacion(IdGuia, IdSituacion)
		select distinct @IdGuia, s.IdSituacion
		from dbo.fn_dividirTexto(@Situaciones, ',') t
		inner join Situacion s on s.Clave = t.Valor

		commit transaction

		set @numeroError = 0
		set @respuesta = 'Guía actualizada correctamente'
	end try
	begin catch
		if @@trancount > 0 rollback transaction
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_ocultarGuia =====

create procedure [dbo].[sp_ocultarGuia](
@IdGuia int,
@Ocultar bit,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	begin try
		update Guia
		set
			Activo = case when @Ocultar = 1 then 0 else 1 end,
			FechaActualizacion = getdate()
		where IdGuia = @IdGuia

		if @@rowcount = 0
		begin
			set @numeroError = 50006
			set @respuesta = 'La guía no existe'
			return
		end

		set @numeroError = 0
		set @respuesta = case when @Ocultar = 1 then 'Guía oculta correctamente' else 'Guía visible nuevamente' end
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO


/* ---------- AUTOEVALUACIONES Y PREGUNTAS ---------- */

-- ===== STORED PROCEDURE sp_listaEvaluaciones =====

create procedure [dbo].[sp_listaEvaluaciones]
as
begin
	set nocount on;

	select
		e.IdEvaluacion,
		e.IdGuia,
		g.Titulo,
		n.Nombre as Neurodivergencia,
		g.Activo as GuiaActiva,
		(select count(*) from Pregunta p where p.IdEvaluacion = e.IdEvaluacion) as TotalPreguntas,
		e.FechaCreacion
	from Evaluacion e
	inner join Guia g on g.IdGuia = e.IdGuia
	inner join Neurodivergencia n on n.IdNeurodivergencia = g.IdNeurodivergencia
	order by e.IdEvaluacion
end
GO

-- ===== STORED PROCEDURE sp_listaGuiasSinEvaluacion =====

create procedure [dbo].[sp_listaGuiasSinEvaluacion]
as
begin
	set nocount on;

	select g.IdGuia, g.Titulo, n.Nombre as Neurodivergencia
	from Guia g
	inner join Neurodivergencia n on n.IdNeurodivergencia = g.IdNeurodivergencia
	where not exists (select 1 from Evaluacion e where e.IdGuia = g.IdGuia)
	order by g.IdGuia
end
GO

-- ===== STORED PROCEDURE sp_obtenerEvaluacion =====

create procedure [dbo].[sp_obtenerEvaluacion](
@IdGuia int
)
as
begin
	set nocount on;

	select e.IdEvaluacion, e.IdGuia, g.Titulo, n.Nombre as Neurodivergencia, e.FechaCreacion
	from Evaluacion e
	inner join Guia g on g.IdGuia = e.IdGuia
	inner join Neurodivergencia n on n.IdNeurodivergencia = g.IdNeurodivergencia
	where e.IdGuia = @IdGuia

	select p.IdPregunta, p.IdEvaluacion, p.Orden, p.Texto, p.OpcionA, p.OpcionB, p.OpcionC, p.OpcionD, p.Correcta
	from Pregunta p
	inner join Evaluacion e on e.IdEvaluacion = p.IdEvaluacion
	where e.IdGuia = @IdGuia
	order by p.Orden, p.IdPregunta
end
GO

-- ===== STORED PROCEDURE sp_crearEvaluacion =====
create procedure [dbo].[sp_crearEvaluacion](
@IdGuia int,
@IdEvaluacion int output,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	set @IdEvaluacion = 0

	if not exists (select 1 from Guia where IdGuia = @IdGuia)
	begin
		set @numeroError = 50006
		set @respuesta = 'La guía no existe'
		return
	end

	if exists (select 1 from Evaluacion where IdGuia = @IdGuia)
	begin
		set @numeroError = 50007
		set @respuesta = 'Esta guía ya tiene una autoevaluación'
		return
	end

	begin try
		insert into Evaluacion(IdGuia) values (@IdGuia)
		set @IdEvaluacion = scope_identity()

		set @numeroError = 0
		set @respuesta = 'Autoevaluación creada correctamente'
	end try
	begin catch
		set @IdEvaluacion = 0
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_eliminarEvaluacion =====

create procedure [dbo].[sp_eliminarEvaluacion](
@IdEvaluacion int,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	if not exists (select 1 from Evaluacion where IdEvaluacion = @IdEvaluacion)
	begin
		set @numeroError = 50008
		set @respuesta = 'La autoevaluación no existe'
		return
	end

	begin try
		begin transaction

		delete from Pregunta where IdEvaluacion = @IdEvaluacion
		delete from Evaluacion where IdEvaluacion = @IdEvaluacion

		commit transaction

		set @numeroError = 0
		set @respuesta = 'Autoevaluación eliminada correctamente'
	end try
	begin catch
		if @@trancount > 0 rollback transaction
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_crearPregunta =====
create procedure [dbo].[sp_crearPregunta](
@IdEvaluacion int,
@Texto varchar(220),
@OpcionA varchar(180),
@OpcionB varchar(180),
@OpcionC varchar(180) = null,
@OpcionD varchar(180) = null,
@Correcta char(1),
@IdPregunta int output,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	set @IdPregunta = 0
	set @Texto = ltrim(rtrim(isnull(@Texto, '')))
	set @OpcionA = ltrim(rtrim(isnull(@OpcionA, '')))
	set @OpcionB = ltrim(rtrim(isnull(@OpcionB, '')))
	set @OpcionC = nullif(ltrim(rtrim(isnull(@OpcionC, ''))), '')
	set @OpcionD = nullif(ltrim(rtrim(isnull(@OpcionD, ''))), '')
	set @Correcta = lower(isnull(@Correcta, ''))

	if not exists (select 1 from Evaluacion where IdEvaluacion = @IdEvaluacion)
	begin
		set @numeroError = 50008
		set @respuesta = 'La autoevaluación no existe'
		return
	end

	if @Texto = ''
	begin
		set @numeroError = 50009
		set @respuesta = 'Escribe la pregunta'
		return
	end

	if @OpcionA = '' or @OpcionB = ''
	begin
		set @numeroError = 50009
		set @respuesta = 'Escribe al menos dos opciones'
		return
	end

	if @OpcionD is not null and @OpcionC is null
	begin
		set @numeroError = 50009
		set @respuesta = 'Las opciones deben ser consecutivas (A, B, C, D)'
		return
	end

	if @Correcta not in ('a','b','c','d')
		or (@Correcta = 'c' and @OpcionC is null)
		or (@Correcta = 'd' and @OpcionD is null)
	begin
		set @numeroError = 50010
		set @respuesta = 'Marca como correcta una opción que tenga texto'
		return
	end

	begin try
		insert into Pregunta(IdEvaluacion, Orden, Texto, OpcionA, OpcionB, OpcionC, OpcionD, Correcta)
		values (
			@IdEvaluacion,
			isnull((select max(Orden) from Pregunta where IdEvaluacion = @IdEvaluacion), 0) + 1,
			@Texto, @OpcionA, @OpcionB, @OpcionC, @OpcionD, @Correcta
		)
		set @IdPregunta = scope_identity()

		set @numeroError = 0
		set @respuesta = 'Pregunta agregada correctamente'
	end try
	begin catch
		set @IdPregunta = 0
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_editarPregunta =====
create procedure [dbo].[sp_editarPregunta](
@IdPregunta int,
@Texto varchar(220),
@OpcionA varchar(180),
@OpcionB varchar(180),
@OpcionC varchar(180) = null,
@OpcionD varchar(180) = null,
@Correcta char(1),
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	set @Texto = ltrim(rtrim(isnull(@Texto, '')))
	set @OpcionA = ltrim(rtrim(isnull(@OpcionA, '')))
	set @OpcionB = ltrim(rtrim(isnull(@OpcionB, '')))
	set @OpcionC = nullif(ltrim(rtrim(isnull(@OpcionC, ''))), '')
	set @OpcionD = nullif(ltrim(rtrim(isnull(@OpcionD, ''))), '')
	set @Correcta = lower(isnull(@Correcta, ''))

	if not exists (select 1 from Pregunta where IdPregunta = @IdPregunta)
	begin
		set @numeroError = 50011
		set @respuesta = 'La pregunta no existe'
		return
	end

	if @Texto = ''
	begin
		set @numeroError = 50009
		set @respuesta = 'Escribe la pregunta'
		return
	end

	if @OpcionA = '' or @OpcionB = ''
	begin
		set @numeroError = 50009
		set @respuesta = 'Escribe al menos dos opciones'
		return
	end

	if @OpcionD is not null and @OpcionC is null
	begin
		set @numeroError = 50009
		set @respuesta = 'Las opciones deben ser consecutivas (A, B, C, D)'
		return
	end

	if @Correcta not in ('a','b','c','d')
		or (@Correcta = 'c' and @OpcionC is null)
		or (@Correcta = 'd' and @OpcionD is null)
	begin
		set @numeroError = 50010
		set @respuesta = 'Marca como correcta una opción que tenga texto'
		return
	end

	begin try
		update Pregunta
		set
			Texto = @Texto,
			OpcionA = @OpcionA,
			OpcionB = @OpcionB,
			OpcionC = @OpcionC,
			OpcionD = @OpcionD,
			Correcta = @Correcta
		where IdPregunta = @IdPregunta

		set @numeroError = 0
		set @respuesta = 'Pregunta actualizada correctamente'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_eliminarPregunta =====
create procedure [dbo].[sp_eliminarPregunta](
@IdPregunta int,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	begin try
		delete from Pregunta where IdPregunta = @IdPregunta

		if @@rowcount = 0
		begin
			set @numeroError = 50011
			set @respuesta = 'La pregunta no existe'
			return
		end

		set @numeroError = 0
		set @respuesta = 'Pregunta eliminada correctamente'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO


/* ---------- USUARIOS (registro, login y perfil) ---------- */

-- ===== STORED PROCEDURE sp_crearUsuario =====

create procedure [dbo].[sp_crearUsuario](
@NombreCompleto varchar(100),
@Correo varchar(150),
@Contrasena varchar(200),
@TipoUsuario varchar(15),
@IdUsuario int output,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	set @IdUsuario = 0
	set @NombreCompleto = ltrim(rtrim(isnull(@NombreCompleto, '')))
	set @Correo = lower(ltrim(rtrim(isnull(@Correo, ''))))

	if @NombreCompleto = '' or @Correo = '' or isnull(@Contrasena, '') = ''
	begin
		set @numeroError = 50020
		set @respuesta = 'Completa nombre, correo y contraseña'
		return
	end

	if isnull(@TipoUsuario, '') not in ('Estudiante','Docente')
	begin
		set @numeroError = 50020
		set @respuesta = 'Elige si eres Estudiante o Docente'
		return
	end

	if exists (select 1 from Usuario where Correo = @Correo)
	begin
		set @numeroError = 50021
		set @respuesta = 'Ya existe una cuenta con ese correo'
		return
	end

	begin try
		insert into Usuario(NombreCompleto, Correo, Contrasena, TipoUsuario)
		values (@NombreCompleto, @Correo, @Contrasena, @TipoUsuario)

		set @IdUsuario = scope_identity()

		set @numeroError = 0
		set @respuesta = 'Cuenta creada correctamente'
	end try
	begin catch
		set @IdUsuario = 0
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_obtenerUsuario =====

create procedure [dbo].[sp_obtenerUsuario](
@IdUsuario int = null,
@Correo varchar(150) = null
)
as
begin
	set nocount on;

	select IdUsuario, NombreCompleto, Correo, Contrasena, TipoUsuario, Activo
	from Usuario
	where (@IdUsuario is not null and IdUsuario = @IdUsuario)
	or (@IdUsuario is null and Correo = lower(ltrim(rtrim(isnull(@Correo, '')))))
end
GO

-- ===== STORED PROCEDURE sp_registrarAcceso =====
create procedure [dbo].[sp_registrarAcceso](
@IdUsuario int,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	begin try
		update Usuario set FechaUltimoAcceso = getdate() where IdUsuario = @IdUsuario

		set @numeroError = 0
		set @respuesta = 'Acceso registrado'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_editarUsuario =====

create procedure [dbo].[sp_editarUsuario](
@IdUsuario int,
@NombreCompleto varchar(100),
@Correo varchar(150),
@Contrasena varchar(200) = null,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	set @NombreCompleto = ltrim(rtrim(isnull(@NombreCompleto, '')))
	set @Correo = lower(ltrim(rtrim(isnull(@Correo, ''))))

	if not exists (select 1 from Usuario where IdUsuario = @IdUsuario)
	begin
		set @numeroError = 50022
		set @respuesta = 'El usuario no existe'
		return
	end

	if @NombreCompleto = '' or @Correo = ''
	begin
		set @numeroError = 50020
		set @respuesta = 'Completa nombre y correo'
		return
	end

	if exists (select 1 from Usuario where Correo = @Correo and IdUsuario <> @IdUsuario)
	begin
		set @numeroError = 50021
		set @respuesta = 'Ya existe una cuenta con ese correo'
		return
	end

	begin try
		update Usuario
		set
			NombreCompleto = @NombreCompleto,
			Correo = @Correo,
			Contrasena = isnull(nullif(@Contrasena, ''), Contrasena)
		where IdUsuario = @IdUsuario

		set @numeroError = 0
		set @respuesta = 'Perfil actualizado correctamente'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO


/* ---------- ACTIVIDAD DE LOS USUARIOS (vistas, favoritos, calificaciones, resultados y comentarios) ---------- */

-- ===== STORED PROCEDURE sp_registrarVista =====
create procedure [dbo].[sp_registrarVista](
@IdUsuario int,
@IdGuia int,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	begin try
		insert into VistaGuia(IdUsuario, IdGuia) values (@IdUsuario, @IdGuia)

		set @numeroError = 0
		set @respuesta = 'Vista registrada'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_listaFavoritos =====
create procedure [dbo].[sp_listaFavoritos](
@IdUsuario int
)
as
begin
	set nocount on;

	select IdGuia, FechaAgregado
	from Favorito
	where IdUsuario = @IdUsuario
	order by FechaAgregado desc
end
GO

-- ===== STORED PROCEDURE sp_crearFavorito =====
create procedure [dbo].[sp_crearFavorito](
@IdUsuario int,
@IdGuia int,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	begin try
		if not exists (select 1 from Favorito where IdUsuario = @IdUsuario and IdGuia = @IdGuia)
			insert into Favorito(IdUsuario, IdGuia) values (@IdUsuario, @IdGuia)

		set @numeroError = 0
		set @respuesta = 'Guía guardada en favoritos'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_eliminarFavorito =====
create procedure [dbo].[sp_eliminarFavorito](
@IdUsuario int,
@IdGuia int,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	begin try
		delete from Favorito where IdUsuario = @IdUsuario and IdGuia = @IdGuia

		set @numeroError = 0
		set @respuesta = 'Guía quitada de favoritos'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_guardarCalificacion =====

create procedure [dbo].[sp_guardarCalificacion](
@IdUsuario int,
@IdGuia int,
@Estrellas tinyint,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	if @Estrellas is null or @Estrellas not between 1 and 5
	begin
		set @numeroError = 50030
		set @respuesta = 'La calificación debe ser de 1 a 5 estrellas'
		return
	end

	begin try
		update Calificacion
		set Estrellas = @Estrellas, Fecha = getdate()
		where IdUsuario = @IdUsuario and IdGuia = @IdGuia

		if @@rowcount = 0
			insert into Calificacion(IdUsuario, IdGuia, Estrellas) values (@IdUsuario, @IdGuia, @Estrellas)

		set @numeroError = 0
		set @respuesta = 'Calificación guardada correctamente'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_listaCalificaciones =====
create procedure [dbo].[sp_listaCalificaciones](
@IdGuia int = null
)
as
begin
	set nocount on;

	select IdGuia, IdUsuario, Estrellas, Fecha
	from Calificacion
	where @IdGuia is null or IdGuia = @IdGuia
	order by Fecha desc
end
GO

-- ===== STORED PROCEDURE sp_guardarResultado =====
create procedure [dbo].[sp_guardarResultado](
@IdUsuario int,
@IdGuia int,
@Aciertos int,
@Total int,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	if @Total is null or @Total < 1 or @Aciertos is null or @Aciertos < 0 or @Aciertos > @Total
	begin
		set @numeroError = 50031
		set @respuesta = 'El resultado de la autoevaluación no es válido'
		return
	end

	begin try
		insert into ResultadoEvaluacion(IdUsuario, IdGuia, Aciertos, Total)
		values (@IdUsuario, @IdGuia, @Aciertos, @Total)

		set @numeroError = 0
		set @respuesta = 'Resultado guardado correctamente'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_listaResultados =====
create procedure [dbo].[sp_listaResultados](
@IdUsuario int
)
as
begin
	set nocount on;

	select r.IdResultado, r.IdGuia, g.Titulo, r.Aciertos, r.Total, r.Fecha
	from ResultadoEvaluacion r
	inner join Guia g on g.IdGuia = r.IdGuia
	where r.IdUsuario = @IdUsuario
	order by r.Fecha desc, r.IdResultado desc
end
GO

-- ===== STORED PROCEDURE sp_crearComentario =====

create procedure [dbo].[sp_crearComentario](
@IdUsuario int,
@IdGuia int,
@Texto varchar(300),
@IdComentario int output,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	set @IdComentario = 0
	set @Texto = ltrim(rtrim(isnull(@Texto, '')))

	if len(@Texto) < 3
	begin
		set @numeroError = 50032
		set @respuesta = 'Escribe tu comentario antes de enviarlo'
		return
	end

	if (select count(*) from Comentario where IdUsuario = @IdUsuario and IdGuia = @IdGuia) >= 3
	begin
		set @numeroError = 50033
		set @respuesta = 'Ya enviaste el máximo de comentarios en esta guía'
		return
	end

	begin try
		insert into Comentario(IdUsuario, IdGuia, Texto) values (@IdUsuario, @IdGuia, @Texto)
		set @IdComentario = scope_identity()

		set @numeroError = 0
		set @respuesta = 'Gracias por tu comentario'
	end try
	begin catch
		set @IdComentario = 0
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_listaComentarios =====

create procedure [dbo].[sp_listaComentarios](
@IdGuia int = null
)
as
begin
	set nocount on;

	select
		m.IdComentario,
		m.IdGuia,
		m.IdUsuario,
		left(u.NombreCompleto, charindex(' ', u.NombreCompleto + ' ') - 1) as Nombre,
		u.TipoUsuario,
		m.Texto,
		m.Fecha,
		k.Estrellas
	from Comentario m
	inner join Usuario u on u.IdUsuario = m.IdUsuario
	left join Calificacion k on k.IdUsuario = m.IdUsuario and k.IdGuia = m.IdGuia
	where m.Oculto = 0 and (@IdGuia is null or m.IdGuia = @IdGuia)
	order by m.Fecha desc, m.IdComentario desc
end
GO

-- ===== STORED PROCEDURE sp_eliminarComentario =====

create procedure [dbo].[sp_eliminarComentario](
@IdComentario int,
@IdUsuario int,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	begin try
		delete from Comentario where IdComentario = @IdComentario and IdUsuario = @IdUsuario

		if @@rowcount = 0
		begin
			set @numeroError = 50034
			set @respuesta = 'No se encontró el comentario'
			return
		end

		set @numeroError = 0
		set @respuesta = 'Comentario eliminado'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO


/* ---------- DONACIONES (incluye el pago en linea con Mercado Pago) ---------- */

-- ===== STORED PROCEDURE sp_crearDonacion =====

create procedure [dbo].[sp_crearDonacion](
@IdUsuario int = null,
@Monto decimal(10,2),
@OtraCantidad bit,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	if @Monto is null or @Monto < 1 or @Monto > 100000
	begin
		set @numeroError = 50035
		set @respuesta = 'El monto de la donación no es válido'
		return
	end

	begin try
		insert into Donacion(IdUsuario, Monto, OtraCantidad) values (@IdUsuario, @Monto, isnull(@OtraCantidad, 0))

		set @numeroError = 0
		set @respuesta = 'Donación registrada'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_iniciarDonacion =====
-- Se llama cuando la persona llena el formulario y presiona "Pagar". Crea la donacion en estado 'intencion'
-- y regresa su IdDonacion, que la API manda a Mercado Pago como referencia
-- @IdUsuario = NULL cuando la persona dono sin iniciar sesion.
create   procedure [dbo].[sp_iniciarDonacion](
@IdUsuario int = null,
@NombreDonante varchar(100),
@CorreoDonante varchar(150),
@Monto decimal(10,2),
@OtraCantidad bit = 0,
@Mensaje varchar(300) = null,
@IdDonacion int output,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;
	set @IdDonacion = null

	if @Monto is null or @Monto < 10 or @Monto > 100000
	begin
		set @numeroError = 50035
		set @respuesta = 'El monto de la donación no es válido (mínimo $10, máximo $100,000)'
		return
	end

	if len(ltrim(rtrim(isnull(@NombreDonante, '')))) = 0
	begin
		set @numeroError = 50038
		set @respuesta = 'Escribe tu nombre'
		return
	end

	if @CorreoDonante is null or @CorreoDonante not like '%_@_%._%'
	begin
		set @numeroError = 50039
		set @respuesta = 'Escribe un correo electrónico válido'
		return
	end

	begin try
		insert into Donacion(IdUsuario, NombreDonante, CorreoDonante, Mensaje, Monto, OtraCantidad, Estado, Proveedor)
		values (@IdUsuario, ltrim(rtrim(@NombreDonante)), lower(ltrim(rtrim(@CorreoDonante))),
				nullif(ltrim(rtrim(isnull(@Mensaje, ''))), ''), @Monto, isnull(@OtraCantidad, 0), 'intencion', 'MercadoPago')

		set @IdDonacion = scope_identity()
		set @numeroError = 0
		set @respuesta = 'Donación creada'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_asignarPreferenciaDonacion =====
-- Guarda el id de la preferencia de pago que creo Mercado Pago para esa donacion
create   procedure [dbo].[sp_asignarPreferenciaDonacion](
@IdDonacion int,
@IdPreferencia varchar(100),
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	begin try
		update Donacion set IdPreferencia = @IdPreferencia, FechaActualizacion = getdate() where IdDonacion = @IdDonacion

		if @@rowcount = 0
		begin
			set @numeroError = 50037
			set @respuesta = 'No se encontró la donación'
			return
		end

		set @numeroError = 0
		set @respuesta = 'Preferencia guardada'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_obtenerDonacion =====
-- La API la usa para comparar el monto que dice Mercado Pago contra el monto que se guardo al crear la donacion
create   procedure [dbo].[sp_obtenerDonacion]
@IdDonacion int
as
begin
	set nocount on;

	select IdDonacion, Monto, Moneda, Estado, IdPagoProveedor
	from Donacion
	where IdDonacion = @IdDonacion
end
GO

-- ===== STORED PROCEDURE sp_registrarPagoDonacion =====
-- Guarda el resultado del pago. La API lo llama DESPUES de consultar el pago directamente a Mercado Pago
-- (nunca con lo que mande el navegador). Se puede llamar varias veces para el mismo pago sin problema.
-- Una donacion ya 'confirmada' no se baja a pendiente/rechazada por un aviso que llegue tarde.
create   procedure [dbo].[sp_registrarPagoDonacion](
@IdDonacion int,
@Estado varchar(12),
@IdPagoProveedor varchar(40),
@MetodoPago varchar(40) = null,
@DetalleEstado varchar(60) = null,
@FechaPago datetime = null,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	if isnull(@Estado, '') not in ('intencion','pendiente','confirmada','rechazada','reembolsada')
	begin
		set @numeroError = 50036
		set @respuesta = 'El estado de la donación no es válido'
		return
	end

	-- Un mismo pago de Mercado Pago no puede quedar ligado a dos donaciones distintas
	if exists (select 1 from Donacion where IdPagoProveedor = @IdPagoProveedor and IdDonacion <> @IdDonacion)
	begin
		set @numeroError = 50040
		set @respuesta = 'Ese pago ya está asociado a otra donación'
		return
	end

	begin try
		if exists (select 1 from Donacion where IdDonacion = @IdDonacion and Estado = 'confirmada')
			and @Estado in ('intencion','pendiente','rechazada')
		begin
			set @numeroError = 0
			set @respuesta = 'La donación ya estaba confirmada'
			return
		end

		update Donacion set
			Estado = @Estado,
			IdPagoProveedor = @IdPagoProveedor,
			MetodoPago = @MetodoPago,
			DetalleEstado = @DetalleEstado,
			FechaPago = case when @Estado = 'confirmada' then isnull(@FechaPago, getdate()) else FechaPago end,
			FechaActualizacion = getdate()
		where IdDonacion = @IdDonacion

		if @@rowcount = 0
		begin
			set @numeroError = 50037
			set @respuesta = 'No se encontró la donación'
			return
		end

		set @numeroError = 0
		set @respuesta = 'Pago registrado'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO


/* ---------- PANEL DEL ADMINISTRADOR ---------- */

-- ===== STORED PROCEDURE sp_adminResumen =====

create   procedure [dbo].[sp_adminResumen]
as
begin
	set nocount on;

	select
		(select count(*) from Usuario where TipoUsuario <> 'Administrador') as TotalUsuarios,
		(select count(*) from Usuario where TipoUsuario = 'Estudiante') as Estudiantes,
		(select count(*) from Usuario where TipoUsuario = 'Docente') as Docentes,
		(select count(*) from VistaGuia) as Vistas,
		(select count(*) from Favorito) as Favoritos,
		(select count(*) from Calificacion) as Calificaciones,
		(select cast(avg(cast(Estrellas as decimal(5,2))) as decimal(3,1)) from Calificacion) as PromedioCalificacion,
		(select count(*) from ResultadoEvaluacion) as Autoevaluaciones,
		(select count(*) from Comentario) as Comentarios,
		(select count(*) from Donacion where Estado = 'confirmada') as Donaciones,
		(select isnull(sum(Monto), 0) from Donacion where Estado = 'confirmada') as DonacionesMonto
end
GO

-- ===== STORED PROCEDURE sp_adminListaComentarios =====

create procedure [dbo].[sp_adminListaComentarios]
as
begin
	set nocount on;

	select
		m.IdComentario,
		m.IdGuia,
		g.Titulo as TituloGuia,
		u.Correo,
		u.NombreCompleto as Nombre,
		u.TipoUsuario,
		m.Texto,
		m.Oculto,
		m.Fecha,
		k.Estrellas
	from Comentario m
	inner join Usuario u on u.IdUsuario = m.IdUsuario
	inner join Guia g on g.IdGuia = m.IdGuia
	left join Calificacion k on k.IdUsuario = m.IdUsuario and k.IdGuia = m.IdGuia
	order by m.Fecha desc, m.IdComentario desc
end
GO

-- ===== STORED PROCEDURE sp_adminOcultarComentario =====
create procedure [dbo].[sp_adminOcultarComentario](
@IdComentario int,
@Oculto bit,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	begin try
		update Comentario set Oculto = @Oculto where IdComentario = @IdComentario

		if @@rowcount = 0
		begin
			set @numeroError = 50034
			set @respuesta = 'No se encontró el comentario'
			return
		end

		set @numeroError = 0
		set @respuesta = case when @Oculto = 1 then 'Comentario oculto' else 'Comentario visible' end
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_adminEliminarComentario =====
create procedure [dbo].[sp_adminEliminarComentario](
@IdComentario int,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	begin try
		delete from Comentario where IdComentario = @IdComentario

		if @@rowcount = 0
		begin
			set @numeroError = 50034
			set @respuesta = 'No se encontró el comentario'
			return
		end

		set @numeroError = 0
		set @respuesta = 'Comentario eliminado'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_adminListaDonaciones =====

create   procedure [dbo].[sp_adminListaDonaciones]
as
begin
	set nocount on;

	select d.IdDonacion, u.Correo, u.NombreCompleto as Nombre, d.NombreDonante, d.CorreoDonante, d.Mensaje,
		d.Monto, d.Moneda, d.OtraCantidad, d.Estado, d.MetodoPago, d.IdPagoProveedor, d.Fecha, d.FechaPago
	from Donacion d
	left join Usuario u on u.IdUsuario = d.IdUsuario
	order by d.Fecha desc, d.IdDonacion desc
end
GO

-- ===== STORED PROCEDURE sp_adminEstadoDonacion =====
create   procedure [dbo].[sp_adminEstadoDonacion](
@IdDonacion int,
@Estado varchar(12),
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	if isnull(@Estado, '') not in ('intencion','pendiente','confirmada','rechazada','reembolsada')
	begin
		set @numeroError = 50036
		set @respuesta = 'El estado no es válido'
		return
	end

	begin try
		update Donacion set Estado = @Estado, FechaActualizacion = getdate() where IdDonacion = @IdDonacion

		if @@rowcount = 0
		begin
			set @numeroError = 50037
			set @respuesta = 'No se encontró la donación'
			return
		end

		set @numeroError = 0
		set @respuesta = 'Estado de la donación actualizado'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_adminEliminarDonacion =====
create procedure [dbo].[sp_adminEliminarDonacion](
@IdDonacion int,
@numeroError int output,
@respuesta varchar(1000) output
)
as
begin
	set nocount on;

	begin try
		delete from Donacion where IdDonacion = @IdDonacion

		if @@rowcount = 0
		begin
			set @numeroError = 50037
			set @respuesta = 'No se encontró la donación'
			return
		end

		set @numeroError = 0
		set @respuesta = 'Donación eliminada'
	end try
	begin catch
		set @numeroError = error_number()
		set @respuesta = error_message()
	end catch
end
GO

-- ===== STORED PROCEDURE sp_adminEstadisticasGuias =====

create procedure [dbo].[sp_adminEstadisticasGuias]
as
begin
	set nocount on;

	select
		g.IdGuia,
		g.Titulo,
		n.Nombre as Neurodivergencia,
		g.Activo,
		(select count(*) from VistaGuia v where v.IdGuia = g.IdGuia) as Vistas,
		(select count(*) from Favorito f where f.IdGuia = g.IdGuia) as Favoritos,
		(select count(*) from Calificacion c where c.IdGuia = g.IdGuia) as Calificaciones,
		cast((select avg(cast(c.Estrellas as decimal(5,2))) from Calificacion c where c.IdGuia = g.IdGuia) as decimal(3,1)) as PromedioCalificacion,
		(select count(*) from ResultadoEvaluacion r where r.IdGuia = g.IdGuia) as Autoevaluaciones,
		cast((select avg(cast(r.Aciertos as decimal(7,2)) * 100 / r.Total) from ResultadoEvaluacion r where r.IdGuia = g.IdGuia) as decimal(5,1)) as PromedioAciertos,
		(select count(*) from Comentario m where m.IdGuia = g.IdGuia) as Comentarios
	from Guia g
	inner join Neurodivergencia n on n.IdNeurodivergencia = g.IdNeurodivergencia
	order by g.IdGuia
end
GO
