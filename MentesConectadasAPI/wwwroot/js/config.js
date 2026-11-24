// ===== CONFIGURACIÓN =====

export const ASSISTANT_ENABLED = true;



export const SHOW_ADMIN_STATS = true;

export const USER_TYPES = ['Estudiante', 'Docente'];

// ----- Administrador -----

export const ADMIN_TYPE = 'Administrador';
export const isAdmin = (user) => Boolean(user && user.type === ADMIN_TYPE);


export function normalizeUserType(type) {
  return USER_TYPES.includes(type) || type === ADMIN_TYPE ? type : '';
}


export const TOPIC_AUDIENCE = {
  'sobrecarga':        ['Estudiante', 'Docente'],
  'comunicacion':      ['Estudiante', 'Docente'],
  'cambios':           ['Estudiante', 'Docente'],
  'participacion':     ['Estudiante', 'Docente'],
  'trabajo-equipo':    ['Estudiante'],
  'examen':            ['Docente'],
  'retroalimentacion': ['Docente'],
  'correccion':        ['Docente']
};

export const TOPIC_LABELS = {
  'sobrecarga': 'Sobrecarga de estímulos',
  'comunicacion': 'Comunicación',
  'cambios': 'Cambios inesperados',
  'participacion': 'Participación en clase',
  'trabajo-equipo': 'Trabajo en equipo',
  'examen': 'Situaciones durante un examen',
  'retroalimentacion': 'Retroalimentación',
  'correccion': 'Corrección respetuosa'
};


export const STORAGE_KEYS = {
  user: 'mc_user',
  favorites: 'mc_favorites',
  evaluations: 'mc_evaluations',
  ratings: 'mc_ratings',
  favoritesByUser: 'mc_favorites_by_user',
  views: 'mc_views',
  userLog: 'mc_user_log',
  guideOverrides: 'mc_guide_overrides',
  guideDeleted: 'mc_guide_deleted',
  theme: 'mc_theme',
  comments: 'mc_comments',
  donations: 'mc_donations',
  assistantLog: 'mc_assistant_log'
};

// ----- Donaciones -----

export const DONATION_AMOUNTS = [15, 30, 50];
export const DONATION_CURRENCY = 'MXN';

export const DONATION_LINKS = {
  15: '',
  30: '',
  50: ''
};
// Monto libre de donacion
export const DONATION_CUSTOM_LINK = '';
export const DONATION_MIN = 10;
export const DONATION_MAX = 100000;



export const API_BASE_URL = '/api';
export const API_ENDPOINTS = {
    guias: '/Guia',
    evaluaciones: '/Evaluacion',
    authLogin: '/Auth/login',
    authRegistro: '/Auth/registro',
    authPerfil: '/Auth/perfil',


  // ----- Actividad de los usuarios -----
  actVistas: '/Actividad/vistas',
  actFavoritos: '/Actividad/favoritos',
  actCalificaciones: '/Actividad/calificaciones',
  actComentarios: '/Actividad/comentarios',
  actResultados: '/Actividad/resultados',
  actDonaciones: '/Actividad/donaciones',
  donIniciar: '/Donacion/iniciar',

  // ----- Panel del administrador - AdminController -----
  adminResumen: '/Admin/resumen',
  adminComentarios: '/Admin/comentarios',
  adminComentarioOculto: '/Admin/comentario/oculto',
  adminComentarioEliminar: '/Admin/comentario/eliminar',
  adminDonaciones: '/Admin/donaciones',
  adminDonacionEstado: '/Admin/donacion/estado',
  adminDonacionEliminar: '/Admin/donacion/eliminar',
  adminEstadisticas: '/Admin/estadisticas'
};