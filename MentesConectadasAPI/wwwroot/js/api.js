// ===== CONEXIÓN CON LA API =====

import { API_BASE_URL, API_ENDPOINTS } from './config.js';
export { API_BASE_URL, API_ENDPOINTS };

const MSG_SIN_API = 'No se pudo conectar con el servidor. Revisa tu conexión a internet e inténtalo de nuevo.';


export async function apiRequest(path, options = {}) {
  let response;
  try {
    response = await fetch(API_BASE_URL + path, {
      headers: { 'Content-Type': 'application/json' },
      ...options
    });
  } catch (e) {
    throw new Error(MSG_SIN_API);
  }
  const data = await response.json().catch(() => ({})); 
  if (!response.ok || data.isSuccess === false) {
    const detalle = data.respuesta || 'La API no pudo completar la solicitud.';
    throw new Error(response.status === 404 ? detalle + ' ' + MSG_SIN_API : detalle);
  }
  return data;
}

// ----- INICIO DE SESIÓN DEL ADMINISTRADOR -----
async function apiAcceso(path, body) {
    let response;
    try {
        response = await fetch(API_BASE_URL + path, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });
    } catch (e) {
        throw new Error(MSG_SIN_API);
    }
    const data = await response.json().catch(() => ({}));
    if (response.status === 401) throw new Error('Correo o contraseña incorrectos. Revisa tus datos e inténtalo nuevamente.');
    if (!response.ok || !data.isSuccess || !data.usuario) throw new Error(data.respuesta || MSG_SIN_API);
    return { ...data.usuario, token: data.token };
}

export const apiLogin = (correo, password) => apiAcceso(API_ENDPOINTS.authLogin, { correo, password });
export const apiRegistro = (nombreCompleto, correo, password, tipoUsuario) =>
    apiAcceso(API_ENDPOINTS.authRegistro, { nombreCompleto, correo, password, tipoUsuario });


// ----- ACTIVIDAD DE LOS USUARIOS - BASE DE DATOS -----
export function apiGuardarVista(token, idGuia) {
    try {
        fetch(API_BASE_URL + API_ENDPOINTS.actVistas, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + (token || '') },
            body: JSON.stringify({ idGuia: Number(idGuia) }),
            keepalive: true
        }).catch(() => { });
    } catch (e) { }
}

export const apiListaFavoritos = async (token) => (await apiSesion(API_ENDPOINTS.actFavoritos, token)).response || [];
export const apiAgregarFavorito = (token, idGuia) =>
    apiSesion(API_ENDPOINTS.actFavoritos, token, { method: 'POST', body: JSON.stringify({ idGuia: Number(idGuia) }) });
export const apiQuitarFavorito = (token, idGuia) =>
    apiSesion(API_ENDPOINTS.actFavoritos + '/' + Number(idGuia), token, { method: 'DELETE' });

export const apiListaCalificaciones = async (token) => (await apiSesion(API_ENDPOINTS.actCalificaciones, token)).response || [];
export const apiGuardarCalificacion = (token, idGuia, estrellas) =>
    apiSesion(API_ENDPOINTS.actCalificaciones + '/' + Number(idGuia), token, { method: 'PUT', body: JSON.stringify({ estrellas }) });

export const apiListaComentarios = async (token) => (await apiSesion(API_ENDPOINTS.actComentarios, token)).response || [];
export const apiCrearComentario = (token, idGuia, texto) =>
    apiSesion(API_ENDPOINTS.actComentarios, token, { method: 'POST', body: JSON.stringify({ idGuia: Number(idGuia), texto }) });
export const apiEliminarComentario = (token, idComentario) =>
    apiSesion(API_ENDPOINTS.actComentarios + '/' + Number(idComentario), token, { method: 'DELETE' });

export const apiListaResultados = async (token) => (await apiSesion(API_ENDPOINTS.actResultados, token)).response || [];
export const apiGuardarResultado = (token, idGuia, aciertos, total) =>
    apiSesion(API_ENDPOINTS.actResultados, token, { method: 'POST', body: JSON.stringify({ idGuia: Number(idGuia), aciertos, total }) });

export const apiIniciarDonacion = async (token, datos) =>
    (await apiSesion(API_ENDPOINTS.donIniciar, token, { method: 'POST', body: JSON.stringify(datos) })).response;

export const apiGuardarDonacion = (token, monto, otraCantidad) =>
    apiSesion(API_ENDPOINTS.actDonaciones, token, { method: 'POST', body: JSON.stringify({ monto, otraCantidad: Boolean(otraCantidad) }) });


// ----- PANEL DEL ADMINISTRADOR <- BASE DE DATOS -----
async function apiSesion(path, token, options = {}) {
    let response;
    try {
        response = await fetch(API_BASE_URL + path, {
            ...options,
            headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + (token || '') }
        });
    } catch (e) {
        throw new Error(MSG_SIN_API);
    }
    const data = await response.json().catch(() => ({}));
    if (response.status === 401) {
        window.dispatchEvent(new Event('mc-sesion-vencida'));
        const err = new Error('Tu sesión no es válida o venció. Inicia sesión de nuevo.');
        err.numeroError = 401;
        throw err;
    }
    if (!response.ok || data.isSuccess === false) {
        const err = new Error(data.respuesta || 'La API no pudo completar la solicitud. Inténtalo de nuevo en unos momentos.');
        err.numeroError = data.numeroError ?? response.status;
        throw err;
    }
    return data;
}

async function apiAdmin(path, token, options = {}) {
    return (await apiSesion(path, token, options)).response;
}

export const apiObtenerPerfil = async (token) => (await apiSesion(API_ENDPOINTS.authPerfil, token)).response;
export const apiEditarPerfil = async (token, datos) =>
    (await apiSesion(API_ENDPOINTS.authPerfil, token, { method: 'PUT', body: JSON.stringify(datos) })).response;




const adminPost = (path, token, body) => apiAdmin(path, token, { method: 'POST', body: JSON.stringify(body) });

export const apiAdminResumen = (token) => apiAdmin(API_ENDPOINTS.adminResumen, token);
export const apiAdminComentarios = (token) => apiAdmin(API_ENDPOINTS.adminComentarios, token);
export const apiAdminComentarioOculto = (token, idComentario, oculto) => adminPost(API_ENDPOINTS.adminComentarioOculto, token, { idComentario, oculto });
export const apiAdminComentarioEliminar = (token, idComentario) => adminPost(API_ENDPOINTS.adminComentarioEliminar, token, { id: idComentario });
export const apiAdminDonaciones = (token) => apiAdmin(API_ENDPOINTS.adminDonaciones, token);
export const apiAdminDonacionEstado = (token, idDonacion, estado) => adminPost(API_ENDPOINTS.adminDonacionEstado, token, { idDonacion, estado });
export const apiAdminDonacionEliminar = (token, idDonacion) => adminPost(API_ENDPOINTS.adminDonacionEliminar, token, { id: idDonacion });
export const apiAdminEstadisticas = (token) => apiAdmin(API_ENDPOINTS.adminEstadisticas, token);


// ----- GUÍAS <- BASE DE DATOS -----
export async function apiListaGuias(filtros = {}) {
    const query = new URLSearchParams(Object.entries(filtros).filter(([, v]) => v !== undefined && v !== null && v !== '')).toString();
    const data = await apiRequest(API_ENDPOINTS.guias + (query ? '?' + query : ''));
    return data.response || [];
}

export async function apiObtenerGuia(id) {
    const data = await apiRequest(API_ENDPOINTS.guias + '/' + encodeURIComponent(id));
    return data.response;
}


async function apiEscribirGuia(metodo, path, token, datos) {
    let response;
    try {
        response = await fetch(API_BASE_URL + path, {
            method: metodo,
            headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + (token || '') },
            body: datos == null ? undefined : JSON.stringify(datos)
        });
    } catch (e) {
        throw new Error(MSG_SIN_API);
    }
    const data = await response.json().catch(() => ({}));
    if (response.status === 401) {
        const err = new Error('La sesión de administrador no es válida o venció. Cierra sesión y vuelve a entrar.');
        err.numeroError = 401;
        throw err;
    }
    if (!response.ok || data.isSuccess === false) {
        const err = new Error(data.respuesta || 'La API no pudo completar la solicitud.');
        err.numeroError = data.numeroError ?? response.status;
        throw err;
    }
    return { numeroError: data.numeroError, respuesta: data.respuesta, idGuia: data.response?.idGuia };
}

export const apiCrearGuia = (token, datos) => apiEscribirGuia('POST', API_ENDPOINTS.guias, token, datos);


export const apiEditarGuia = (token, id, datos) => apiEscribirGuia('PUT', API_ENDPOINTS.guias + '/' + encodeURIComponent(id), token, datos);

export const apiCambiarVisibilidad = (token, id, ocultar) => apiEscribirGuia('PUT', API_ENDPOINTS.guias + '/' + encodeURIComponent(id) + '/visibilidad', token, { ocultar });


// ----- AUTOEVALUACIONES <- BASE DE DATOS -----
export const apiCrearEvaluacion = (token, idGuia) => apiEscribirGuia('POST', API_ENDPOINTS.evaluaciones, token, { idGuia: Number(idGuia) });

export const apiEliminarEvaluacion = (token, id) => apiEscribirGuia('DELETE', API_ENDPOINTS.evaluaciones + '/' + id, token, null);
export const apiCrearPregunta = (token, idEvaluacion, datos) => apiEscribirGuia('POST', API_ENDPOINTS.evaluaciones + '/' + idEvaluacion + '/preguntas', token, datos);
export const apiEditarPregunta = (token, idPregunta, datos) => apiEscribirGuia('PUT', API_ENDPOINTS.evaluaciones + '/preguntas/' + idPregunta, token, datos);
export const apiEliminarPregunta = (token, idPregunta) => apiEscribirGuia('DELETE', API_ENDPOINTS.evaluaciones + '/preguntas/' + idPregunta, token, null);