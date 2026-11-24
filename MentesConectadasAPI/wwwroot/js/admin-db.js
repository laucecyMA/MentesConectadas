// ===== PANEL DEL ADMINISTRADOR =====

import { state } from './state.js';
import { esc } from './ui.js';
import { refreshView } from './navigation.js';
import { apiAdminResumen, apiAdminComentarios, apiAdminDonaciones, apiAdminEstadisticas } from './api.js';
import { cargarCatalogo } from './catalogo.js';

export const db = { resumen: null, comentarios: null, donaciones: null, guias: null, estadisticas: null, error: '' };

const CARGADORES = {
  'admin-guias': { clave: 'guias', pedir: async () => { await cargarCatalogo(); return true; } },
  'admin': { clave: 'resumen', pedir: (t) => apiAdminResumen(t) },
  'admin-comentarios': { clave: 'comentarios', pedir: (t) => apiAdminComentarios(t) },
  'admin-donaciones': { clave: 'donaciones', pedir: async (t) => { const [lista, resumen] = await Promise.all([apiAdminDonaciones(t), apiAdminResumen(t)]); return { lista, totalUsuarios: resumen.totalUsuarios }; } },
  'admin-estadisticas': { clave: 'estadisticas', pedir: async (t) => { const [guias, resumen] = await Promise.all([apiAdminEstadisticas(t), apiAdminResumen(t)]); return { guias, resumen }; } }
};

const cargando = {};   
let rutaAnterior = ''; 

async function cargar(ruta) {
  const c = CARGADORES[ruta];
  if (!c || cargando[c.clave]) return;
  cargando[c.clave] = true;
  try {
    db[c.clave] = await c.pedir(state.user?.token);
    db.error = '';
  } catch (e) {
    db.error = e.message || 'No se pudieron consultar los datos.';
  } finally {
    cargando[c.clave] = false;
    if (state.route === ruta) refreshView(); 
  }
}

export function cargarDatosAdmin(ruta) {
  const cambio = ruta !== rutaAnterior;
  rutaAnterior = ruta;
  const c = CARGADORES[ruta];
  if (!c) return;
  if (cambio || (db[c.clave] === null && !db.error)) cargar(ruta);
}

export function recargarAdmin(ruta) { return cargar(ruta); }
export function adminReintentar() { db.error = ''; cargar(state.route); }

export function estadoCarga(clave) {
  if (db.error) return `<div class="alert-error" role="alert"><span>${esc(db.error)}</span><button class="btn btn-outline btn-small" onclick="adminReintentar()">Reintentar</button></div>`;
  if (db[clave] === null) return '<p class="section-text" style="text-align:center">Cargando información…</p>';
  return '';
}