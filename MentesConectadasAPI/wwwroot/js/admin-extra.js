// ===== PANEL DEL ADMINISTRADOR COMENTARIOS Y DONACIONES =====

import { state } from './state.js';
import { DONATION_CURRENCY } from './config.js';
import { esc, showToast, closeModal, footer } from './ui.js';
import { header, refreshView } from './navigation.js';
import { getGuideData, getGuideById } from './content.js';
import { confirmAction, adminExportExcel } from './admin.js';
import { db, estadoCarga, recargarAdmin } from './admin-db.js';
import { apiAdminComentarioOculto, apiAdminComentarioEliminar, apiAdminDonacionEstado, apiAdminDonacionEliminar } from './api.js';

const kpi = (n, label) => `<article class="kpi"><b>${n}</b><span>${label}</span></article>`;
const money = (n) => '$' + Number(n).toLocaleString('es-MX');
const fmtDate = (iso) => { const d = new Date(iso); return isNaN(d) ? '' : d.toLocaleDateString('es-MX') + ' ' + d.toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' }); };

const shell = (inner) => `${header()}<main class="page"><div class="container">${inner}</div></main>${footer(false)}`;
const token = () => state.user?.token;

// ----- COMENTARIOS -----
let commentsGuide = '';
export function adminSetCommentsGuide(id) { commentsGuide = id; refreshView(); }
export function adminComments() {
  const guides = getGuideData();
  const cabecera = `<div class="content-head"><h1 class="section-title">Comentarios</h1><p class="section-text">Opiniones que los usuarios dejan en cada guía. Un comentario oculto se conserva aquí pero se marca como oculto.</p></div>`;
  const all = db.comentarios;
  if (!all) return shell(cabecera + estadoCarga('comentarios'), false);
  const list = all.filter(c => !commentsGuide || c.idGuia === commentsGuide); 
  const stars = (n) => n ? `<span class="stars">${'★'.repeat(n)}${'☆'.repeat(5 - n)}</span>` : '';
  const items = list.map(c => { const g = guides.find(x => x.id === c.idGuia); return `<article class="admin-question ${c.oculto ? 'is-hidden' : ''}"><div class="admin-question-head"><div><strong>${g ? g.title : 'Guía eliminada'}</strong><small class="cell-sub">${g ? g.neuro : ''} · ${esc(c.nombre)}${c.tipoUsuario ? ' (' + esc(c.tipoUsuario) + ')' : ''} · ${fmtDate(c.fecha)} ${stars(c.estrellas)}</small></div><div class="admin-actions">${c.oculto ? '<span class="chip chip-off">Oculto</span>' : ''}<button class="btn btn-outline btn-small" onclick="adminToggleComment(${c.idComentario})">${c.oculto ? 'Mostrar' : 'Ocultar'}</button><button class="btn btn-pink btn-small" onclick="adminAskDeleteComment(${c.idComentario})">Eliminar</button></div></div><p class="comment-text">${esc(c.texto)}</p></article>`; }).join('');
  const conComentarios = new Set(all.map(c => c.idGuia)).size;
  return shell(`${cabecera}
    ${estadoCarga('comentarios')}
    <section class="kpi-grid">${kpi(all.length, 'Comentarios en total')}${kpi(all.filter(c => c.oculto).length, 'Ocultos')}${kpi(conComentarios, 'Guías con comentarios')}</section>
    <div class="admin-toolbar"><select class="search-input admin-select-wide" onchange="adminSetCommentsGuide(this.value)" aria-label="Filtrar por guía"><option value="">Todas las guías</option>${guides.map(g => `<option value="${g.id}" ${g.id === commentsGuide ? 'selected' : ''}>${g.title} (${g.neuro})</option>`).join('')}</select></div>
    ${(() => { const sel = guides.find(x => x.id === commentsGuide); return sel ? `<p class="section-text filter-note">Mostrando comentarios de: <strong>${sel.title}</strong> (${sel.neuro})</p>` : ''; })()}
    ${items || '<div class="empty">Todavía no hay comentarios.</div>'}`, false);
}
export async function adminToggleComment(id) {
  const c = db.comentarios?.find(x => x.idComentario === id); if (!c) return;
  try {
    await apiAdminComentarioOculto(token(), id, !c.oculto);
    showToast(c.oculto ? 'Comentario visible' : 'Comentario oculto');
    recargarAdmin('admin-comentarios');
  } catch (e) { showToast(e.message, 'error'); }
}
export function adminAskDeleteComment(id) {
  confirmAction('¿Eliminar este comentario?', 'Se borrará de forma definitiva de la base de datos. Si solo quieres que no se muestre, usa «Ocultar».', 'Sí, eliminar', `adminDeleteComment(${id})`);
}
export async function adminDeleteComment(id) {
  try {
    await apiAdminComentarioEliminar(token(), id);
    closeModal(); showToast('Comentario eliminado');
    recargarAdmin('admin-comentarios');
  } catch (e) { closeModal(); showToast(e.message, 'error'); }
}

// ----- DONACIONES -----
const DON_ESTADO = {
  confirmada: ['Confirmada', 'chip-on'],
  pendiente: ['Pendiente', 'chip-blue'],
  intencion: ['Sin completar', 'chip-off'],
  rechazada: ['Rechazada', 'chip-off'],
  reembolsada: ['Reembolsada', 'chip-off']
};
const DON_METODO = { visa: 'Visa', master: 'Mastercard', amex: 'American Express', debvisa: 'Visa débito', debmaster: 'Mastercard débito', oxxo: 'OXXO', spei: 'SPEI', account_money: 'Saldo Mercado Pago' };

export function adminDonations() {
  const cabecera = `<div class="content-head"><h1 class="section-title">Donaciones</h1></div>`;
  const data = db.donaciones;
  if (!data) return shell(cabecera + estadoCarga('donaciones'), false);
  const d = data.lista;
  const sum = (arr) => arr.reduce((s, x) => s + x.monto, 0);
  const confirmed = d.filter(x => x.estado === 'confirmada');
  const pending = d.filter(x => x.estado === 'pendiente');
  const unfinished = d.filter(x => x.estado === 'intencion' || x.estado === 'rechazada');
  const donors = new Set(confirmed.map(x => (x.correoDonante || x.correo || ('anonimo-' + x.idDonacion)).toLowerCase())).size;
  const rows = d.map(x => {
    const nombre = x.nombreDonante || x.nombre || '';
    const correo = x.correoDonante || x.correo || '';
    const [etiqueta, clase] = DON_ESTADO[x.estado] || [x.estado, 'chip'];
    const metodo = x.metodoPago ? (DON_METODO[x.metodoPago] || x.metodoPago.toUpperCase()) : '—';
    return `<tr><td data-label="Fecha">${fmtDate(x.fecha)}</td><td data-label="Donante">${nombre || correo ? `${esc(nombre)}<small class="cell-sub">${esc(correo)}</small>` : '<span class="cell-sub">Sin datos</span>'}</td><td data-label="Monto"><strong>${money(x.monto)}</strong> <small class="cell-sub">${esc(x.moneda || DONATION_CURRENCY)}</small></td><td data-label="Método">${esc(metodo)}${x.idPagoProveedor ? `<small class="cell-sub">Pago ${esc(x.idPagoProveedor)}</small>` : ''}</td><td data-label="Estado"><span class="chip ${clase}">${etiqueta}</span>${x.fechaPago ? `<small class="cell-sub">${fmtDate(x.fechaPago)}</small>` : ''}</td><td data-label="Mensaje" style="max-width:240px;white-space:normal">${x.mensaje ? esc(x.mensaje) : '<span class="cell-sub">—</span>'}</td><td class="admin-actions"><button class="btn btn-pink btn-small" onclick="adminAskDeleteDonation(${x.idDonacion})">Eliminar</button></td></tr>`;
  }).join('');
  return shell(`${cabecera}
    ${estadoCarga('donaciones')}
    <section class="kpi-grid">${kpi(confirmed.length, 'Donaciones confirmadas')}${kpi(money(sum(confirmed)), 'Monto recaudado')}${kpi(pending.length, 'Pagos pendientes')}${kpi(confirmed.length ? money(Math.round(sum(confirmed) / confirmed.length)) : '—', 'Aportación promedio')}${kpi(donors, 'Personas que donaron')}${kpi(unfinished.length, 'Sin completar')}</section>
    <div class="admin-toolbar"><span class="section-text" style="margin:0;text-align:left;flex:1 1 auto">Registro de donaciones</span><button class="btn btn-outline btn-small" onclick="adminExportDonations()">Descargar Excel</button></div>
    <div class="table-wrap"><table class="admin-table stack don-table"><thead><tr><th>Fecha</th><th>Donante</th><th>Monto</th><th>Método</th><th>Estado</th><th>Mensaje</th><th>Acciones</th></tr></thead><tbody>${rows || '<tr><td colspan="7">Todavía no hay donaciones registradas.</td></tr>'}</tbody></table></div>`, false);
}
export async function adminToggleDonation(id) {
  const x = db.donaciones?.lista.find(v => v.idDonacion === id); if (!x) return;
  try {
    await apiAdminDonacionEstado(token(), id, x.estado === 'confirmada' ? 'intencion' : 'confirmada');
    recargarAdmin('admin-donaciones');
  } catch (e) { showToast(e.message, 'error'); }
}
export function adminAskDeleteDonation(id) {
  confirmAction('¿Eliminar este registro?', 'Se quitará del historial de donaciones (base de datos).', 'Sí, eliminar', `adminDeleteDonation(${id})`);
}
export async function adminDeleteDonation(id) {
  try {
    await apiAdminDonacionEliminar(token(), id);
    closeModal(); showToast('Registro eliminado');
    recargarAdmin('admin-donaciones');
  } catch (e) { closeModal(); showToast(e.message, 'error'); }
}
export function adminExportDonations() { adminExportExcel(true); }
