// ===== PANEL DEL ADMINISTRADOR: INICIO, GUÍAS, AUTOEVALUACIONES Y ESTADÍSTICAS =====
import { state, save, getAllFavorites } from './state.js';
import { USER_TYPES, SHOW_ADMIN_STATS, DONATION_CURRENCY } from './config.js';
import { esc, showToast, closeModal, footer, coverSlot } from './ui.js';
import { header, refreshView, go } from './navigation.js';
import { getGuideData, getGuideById, isOriginalGuide } from './content.js';
import { ratingSummary, ratingStars } from './guides.js';
import { hBars, columns, lineChart, donut, lastDays, countByDay } from './charts.js';
import { db, estadoCarga } from './admin-db.js';

import { apiAdminDonaciones, apiCrearGuia, apiEditarGuia, apiCambiarVisibilidad, apiListaGuias, apiCrearEvaluacion, apiEliminarEvaluacion, apiCrearPregunta, apiEditarPregunta, apiEliminarPregunta } from './api.js';
import { cargarCatalogo, recargarGuia } from './catalogo.js';
import { crearLibro, descargarXlsx } from './xlsx-lite.js';

const NEURO_OPTIONS = ['Autismo', 'TDAH', 'Dislexia', 'Discalculia', 'Dispraxia'];
const SITUATION_TAGS = [
  ['sobrecarga', 'Sobrecarga de estímulos'], ['comunicacion', 'Comunicación'], ['trabajo-equipo', 'Trabajo en equipo'],
  ['examen', 'Exámenes'], ['cambios', 'Cambios inesperados'], ['organizacion', 'Organización'],
  ['participacion', 'Participación'], ['retroalimentacion', 'Retroalimentación'], ['correccion', 'Corrección respetuosa']
];
const decode = (s = '') => String(s).replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&#039;/g, "'").replace(/&amp;/g, '&');
const plain = (s = '') => esc(decode(s)); 
const slug = (s) => String(s).toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 40) || 'guia';
const tagOf = (neuro) => slug(neuro);
const val = (id) => document.getElementById(id)?.value ?? '';

export function openModal(html) {
  closeModal();
  const el = document.createElement('div');
  el.className = 'modal-backdrop';
  el.id = 'modal';
  el.innerHTML = html;
  document.body.appendChild(el);
}
export function confirmAction(title, message, confirmLabel, onConfirm) {
  openModal(`<section class="modal center"><h2>${title}</h2><p style="color:var(--muted)">${message}</p><div class="modal-actions"><button class="btn btn-pink" onclick="${onConfirm}">${confirmLabel}</button><button class="btn btn-outline" onclick="closeModal()">Cancelar</button></div></section>`);
}
function audienceChips(g) { return g.audience.map(a => `<span class="chip chip-${a === 'Docente' ? 'blue' : 'green'}">${a}</span>`).join(''); }

// ----- INICIO -----
export function adminHome() {
  const r = db.resumen;
  const kpi = (n, label) => `<article class="kpi"><b>${n}</b><span>${label}</span></article>`;
  const card = (cls, title, text, route, btn) => `<article class="quick-card ${cls}"><div><h3>${title}</h3><p>${text}</p></div><button class="btn btn-outline btn-small" onclick="go('${route}')">${btn}</button></article>`;
  const registrados = r ? r.estudiantes + r.docentes : 0;
  const kpis = r
    ? `<section class="kpi-grid">${kpi(getGuideData().length, 'Guías')}<article class="kpi"><b>${registrados}</b><span>Personas registradas</span><span class="kpi-split-line">${r.estudiantes} ${r.estudiantes === 1 ? 'Estudiante' : 'Estudiantes'} · ${r.docentes} ${r.docentes === 1 ? 'Docente' : 'Docentes'}</span></article>${kpi(r.favoritos, 'Guías en favoritos')}${kpi(r.promedioCalificacion === null ? '—' : Number(r.promedioCalificacion).toFixed(1), 'Calificación promedio')}${kpi(r.autoevaluaciones, 'Autoevaluaciones realizadas')}${kpi(r.comentarios, 'Comentarios')}${kpi('$' + Number(r.donacionesMonto).toLocaleString('es-MX'), 'Donaciones registradas (' + r.donaciones + ')')}</section>`
    : estadoCarga('resumen');
  return `${header()}<main class="page"><div class="container">
    ${coverSlot('inicio')}
    <section class="dashboard-hero"><h1>Panel de administración</h1><p>Hola, ${esc(state.user?.name || 'Administrador')}</p></section>
    ${kpis}
    <section class="quick-grid quick-grid-2">
      ${card('purple', 'Guías', 'Consulta todas las guías, crea nuevas, edítalas, ocúltalas o elimínalas.', 'admin-guias', 'Administrar guías')}
      ${card('green', 'Autoevaluaciones', 'Agrega, edita y elimina las preguntas de la autoevaluación de cada guía.', 'admin-evaluaciones', 'Administrar autoevaluaciones')}
      ${card('pink', 'Comentarios', 'Lee lo que opinan los usuarios sobre cada guía y modera los comentarios.', 'admin-comentarios', 'Ver comentarios')}
      ${SHOW_ADMIN_STATS ? card('blue', 'Estadísticas', 'Gráficas de vistas, favoritos, calificaciones y resultados de cada guía.', 'admin-estadisticas', 'Ver estadísticas') : ''}
      ${card('purple', 'Donaciones', 'Registro de aportaciones para medir el interés y la monetización.', 'admin-donaciones', 'Ver donaciones')}
    </section></div></main>${footer(false)}`;
}

// ----- GUÍAS -----
export function adminGuides() {
  const guides = getGuideData();
    const rows = guides.map(g => `<tr class="admin-row" data-id="${g.id}" data-text="${esc((g.title + ' ' + g.neuro + ' ' + g.category).toLowerCase())}" data-neuro="${esc(g.neuroTags[0] || '')}">
    <td><div class="admin-title"><div><strong>${g.title}</strong><small>${g.category || ''}</small></div></div></td>
    <td data-label="Neurodivergencia"><span class="tag tag-soft">${g.neuro}</span></td>
    <td data-label="Para" class="cell-chips"><div class="admin-chips">${audienceChips(g)}</div></td>
    <td data-label="Preguntas">${g.questions.length}</td>
    <td data-label="Estado">${g.hidden ? '<span class="chip chip-off">Oculta</span>' : '<span class="chip chip-on">Visible</span>'}</td>
    <td class="admin-actions" data-label="Acciones"><button class="btn btn-outline btn-small" onclick="openGuide('${g.id}')">Ver</button><button class="btn btn-primary btn-small" onclick="adminEditGuide('${g.id}')">Editar</button><button class="btn btn-outline btn-small" onclick="adminToggleHidden('${g.id}')">${g.hidden ? 'Mostrar' : 'Ocultar'}</button></td></tr>`).join('');
  return `${header()}<main class="page"><div class="container">
    ${coverSlot('guias')}
    <div class="content-head"><h1 class="section-title">Guías</h1></div>
    ${estadoCarga('guias')}
    <section class="kpi kpi-summary" aria-label="Resumen de guías"><div><b>${guides.length}</b><span>Total de guías</span></div><div class="kpi-split"><div><b>${guides.filter(g => g.audience.includes('Estudiante')).length}</b><span>Para Estudiantes</span></div><div><b>${guides.filter(g => g.audience.includes('Docente')).length}</b><span>Para Docentes</span></div></div></section>
    <div class="admin-toolbar"><input id="admin-search" class="search-input" placeholder="Buscar guía por nombre" oninput="adminFilterRows()"><select id="admin-neuro" class="search-input" onchange="adminFilterRows()"><option value="">Todas las neurodivergencias</option>${NEURO_OPTIONS.map(n => `<option value="${tagOf(n)}">${n}</option>`).join('')}</select><button class="btn btn-green" onclick="go('admin-guia:new')">+ Nueva guía</button></div>
    <div class="table-wrap"><table class="admin-table stack"><thead><tr><th>Guía</th><th>Neurodivergencia</th><th>Para</th><th>Preguntas</th><th>Estado</th><th>Acciones</th></tr></thead><tbody>${rows || '<tr><td colspan="6">No hay guías.</td></tr>'}</tbody></table></div>
    <p id="admin-empty" class="section-text" style="text-align:left" hidden>No encontramos guías con esos filtros.</p>
  </div></main>${footer(false)}`;
}

let filtroTimer;
export function adminFilterRows() {
    clearTimeout(filtroTimer);
    filtroTimer = setTimeout(consultarFiltro, 250);
}
async function consultarFiltro() {
    if (!document.getElementById('admin-search')) return;
    const texto = val('admin-search').trim();
    const lista = document.getElementById('admin-neuro');
    const neurodivergencia = lista && lista.value ? lista.options[lista.selectedIndex].text : '';
    try {
        const guias = await apiListaGuias({ texto, neurodivergencia });
        const ids = new Set(guias.map(g => String(g.idGuia)));
        let shown = 0;
        document.querySelectorAll('.admin-row').forEach(r => { const ok = ids.has(r.dataset.id); r.hidden = !ok; if (ok) shown++; });
        const empty = document.getElementById('admin-empty'); if (empty) empty.hidden = shown > 0;
    } catch (e) { showToast(e.message, 'error'); }
}

// OCULTAR / MOSTRAR 
export async function adminToggleHidden(id) {
    const g = getGuideById(id); if (!g) return;
    try {
        const r = await apiCambiarVisibilidad(state.user?.token, id, !g.hidden);
        await recargarGuia(id);
        showToast(r.respuesta);
        refreshView();
    } catch (e) {
        showToast(e.message);
    }
}

// EDITAR
export async function adminEditGuide(id) {
    try {
        await recargarGuia(id);
        go('admin-guia:' + id);
    } catch (e) { showToast(e.message, 'error'); }
}

export function adminAskDeleteGuide(id) {
  const g = getGuideById(id); if (!g) return;
  confirmAction('¿Eliminar esta guía?', `Se eliminará «${g.title}» (${g.neuro}) junto con su autoevaluación. Dejará de aparecer para todos los usuarios. Si es una guía original, puedes recuperarla con «Restaurar guías originales».`, 'Sí, eliminar', `adminDeleteGuide('${id}')`);
}
export function adminDeleteGuide(id) {
  delete state.guideOverrides[id];
  if (isOriginalGuide(id) && !state.guideDeleted.includes(id)) state.guideDeleted.push(id);
  state.favorites = state.favorites.filter(x => x !== id);
  save(); closeModal(); showToast('Guía eliminada'); refreshView();
}
export function adminAskRestore() {
  confirmAction('¿Restaurar guías originales?', 'Se quitarán todos los cambios del administrador: las guías nuevas se eliminan y las originales vuelven a su contenido, audiencia y preguntas de fábrica.', 'Sí, restaurar', 'adminRestore()');
}
export function adminRestore() {
  state.guideOverrides = {}; state.guideDeleted = [];
  save(); closeModal(); showToast('Guías originales restauradas'); refreshView();
}

// ----- FORMULARIO DE GUÍA -----
export function adminGuideForm() {
  const id = state.route.split(':')[1];
  const isNew = id === 'new';
  const g = isNew ? { title: '', category: '', image: '', video: '', desc: '', neuro: 'Autismo', steps: [], avoid: [], situationTags: [], audience: [...USER_TYPES], hidden: false } : getGuideById(id);
  if (!g) return `${header()}<main class="page"><div class="container"><p>No encontramos esta guía.</p><button class="btn btn-outline" onclick="go('admin-guias')">Volver a guías</button></div></main>${footer(false)}`;
  const lines = (arr) => arr.map(x => decode(x)).join('\n');
  return `${header()}<main class="page"><div class="container profile-card admin-form">
    <h1>${isNew ? 'Nueva guía' : 'Editar guía'}</h1>
    <p class="section-text" style="text-align:left;margin:0 0 22px">${isNew ? 'Completa los datos. Después podrás agregar su autoevaluación en la pestaña «Autoevaluaciones».' : 'Los cambios se verán de inmediato para los usuarios que puedan ver esta guía.'}</p>
    <form class="form" onsubmit="event.preventDefault();adminSaveGuide('${isNew ? '' : g.id}')">
      <div class="field"><label>Título *</label><input id="gf-title" required maxlength="80" value="${plain(g.title)}"></div>
      <div class="form-row"><div class="field"><label>Neurodivergencia *</label><select id="gf-neuro" required>${NEURO_OPTIONS.map(n => `<option ${g.neuro === n ? 'selected' : ''}>${n}</option>`).join('')}</select></div>
      <div class="field"><label>Categoría *</label><input id="gf-category" required maxlength="60" value="${plain(g.category)}" placeholder="Ej. Comunicación"></div>
      </div>
      <div class="field"><label>Descripción corta *</label><textarea id="gf-desc" required rows="2" maxlength="260">${plain(g.desc)}</textarea></div>
      <div class="field"><label>¿Qué puedes hacer? * (una recomendación por línea)</label><textarea id="gf-steps" required rows="6">${plain(lines(g.steps))}</textarea></div>
      <div class="field"><label>¿Qué conviene evitar? * (una por línea)</label><textarea id="gf-avoid" required rows="4">${plain(lines(g.avoid))}</textarea></div>
      <fieldset class="field check-group"><legend>Para quién es la guía * (puedes marcar ambos)</legend>${USER_TYPES.map(t => `<label class="check"><input type="checkbox" name="gf-audience" value="${t}" ${g.audience.includes(t) ? 'checked' : ''}> ${t}</label>`).join('')}</fieldset>
      <fieldset class="field check-group"><legend>Situaciones relacionadas (sirven para los filtros)</legend>${SITUATION_TAGS.map(([v, l]) => `<label class="check"><input type="checkbox" name="gf-situation" value="${v}" ${g.situationTags.includes(v) ? 'checked' : ''}> ${l}</label>`).join('')}</fieldset>
      <label class="check"><input type="checkbox" id="gf-visible" ${g.hidden ? '' : 'checked'}> Guía visible para los usuarios</label>
      <div id="gf-result" class="form-result" role="status" hidden></div><div class="profile-actions"><button class="btn btn-blue" type="submit">Guardar guía</button><button class="btn btn-outline" type="button" onclick="go('admin-guias')">${isNew ? 'Volver a guías' : 'Cancelar'}</button></div>
    </form></div></main>${footer(false)}`;
}

const toLines = (text) => text.split('\n').map(x => x.trim()).filter(Boolean).map(esc);
const plainLines = (text) => text.split('\n').map(x => x.trim()).filter(Boolean);


function mostrarResultadoApi(ok, respuesta) {
    const caja = document.getElementById('gf-result');
    if (!caja) return;
    caja.className = ok ? 'form-result form-result-ok' : 'alert-error';
    caja.textContent = respuesta;
    caja.hidden = false;
    caja.scrollIntoView({ behavior: 'smooth', block: 'center' });
}

// NUEVA GUÍA
async function crearGuiaEnApi(datos) {
    const boton = document.querySelector('.admin-form button[type="submit"]');
    if (boton) boton.disabled = true;
    try {
        const r = await apiCrearGuia(state.user?.token, datos);
        try { await cargarCatalogo(); } catch (e) {  }
        showToast(r.respuesta);
        go('admin-guias');
    } catch (e) {
        mostrarResultadoApi(false, e.message);
    } finally {
        if (boton) boton.disabled = false;
    }
}

export async function adminSaveGuide(existingId) {
    const title = val('gf-title').trim(), category = val('gf-category').trim(), desc = val('gf-desc').trim();
    const steps = toLines(val('gf-steps')), avoid = toLines(val('gf-avoid'));
    const audience = [...document.querySelectorAll('input[name="gf-audience"]:checked')].map(i => i.value);
    const situations = [...document.querySelectorAll('input[name="gf-situation"]:checked')].map(i => i.value);
    const neuro = val('gf-neuro');
    if (!title || !category || !desc) { showToast('Completa título, categoría y descripción'); return; }
    if (!steps.length || !avoid.length) { showToast('Agrega al menos una recomendación y una cosa por evitar'); return; }
    if (!audience.length) { showToast('Elige para quién es la guía (Estudiante, Docente o ambos)'); return; }

    // NUEVA GUÍA
    if (!existingId) {
        await crearGuiaEnApi({
            titulo: title, neurodivergencia: neuro, categoria: category, descripcion: desc,
            recomendaciones: plainLines(val('gf-steps')), evitar: plainLines(val('gf-avoid')),
            paraEstudiante: audience.includes('Estudiante'), paraDocente: audience.includes('Docente'),
            situaciones: situations, activo: document.getElementById('gf-visible').checked
        });
        return;
    }

    // EDITAR
    const prev = getGuideById(existingId);
    const known = new Set(SITUATION_TAGS.map(([v]) => v));
    const keptExtra = prev ? prev.situationTags.filter(t => !known.has(t)) : [];
    await editarGuiaEnApi(existingId, {
        titulo: title, neurodivergencia: neuro, categoria: category, descripcion: desc,
        recomendaciones: plainLines(val('gf-steps')), evitar: plainLines(val('gf-avoid')),
        paraEstudiante: audience.includes('Estudiante'), paraDocente: audience.includes('Docente'),
        situaciones: [...situations, ...keptExtra], activo: document.getElementById('gf-visible').checked
    });
}

// EDITAR GUÍA
async function editarGuiaEnApi(id, datos) {
    const boton = document.querySelector('.admin-form button[type="submit"]');
    if (boton) boton.disabled = true;
    try {
        const r = await apiEditarGuia(state.user?.token, id, datos);
        try { await recargarGuia(id); } catch (e) { }
        showToast(r.respuesta);
        go('admin-guias');
    } catch (e) {
        mostrarResultadoApi(false, e.message);
    } finally {
        if (boton) boton.disabled = false;
    }
}

// ----- AUTOEVALUACIONES -----
export function adminEvaluations() {
  const guides = getGuideData();
  const cards = guides.map(g => `<article class="guide-card admin-eval-card">
    <div class="tag-row"><span class="tag">${g.category || ''}</span><span class="tag tag-soft">${g.neuro}</span></div>
    <h3>${g.title}</h3>
    <p>${g.evalId ? `${g.questions.length} ${g.questions.length === 1 ? 'pregunta' : 'preguntas'}` : 'Esta guía aún no tiene autoevaluación.'}</p>
    <div class="admin-eval-foot"><div class="admin-chips">${audienceChips(g)}${g.hidden ? '<span class="chip chip-off">Guía oculta</span>' : ''}</div>
    <div class="admin-actions"><button class="btn btn-primary btn-small" onclick="${g.evalId ? `go('admin-eval:${g.id}')` : `adminOpenEvalSetup('${g.id}')`}">${g.evalId ? 'Ver / editar' : 'Crear autoevaluación'}</button>${g.evalId ? `<button class="btn btn-pink btn-small" onclick="adminAskDeleteEvaluation('${g.id}')">Eliminar</button>` : ''}</div></div></article>`).join('');
  return `${header()}<main class="page"><div class="container">
    ${coverSlot('autoevaluaciones')}
    <div class="content-head"><h1 class="section-title">Autoevaluaciones</h1><p class="section-text">Cada guía tiene su autoevaluación. Entra a una para ver sus preguntas, agregar nuevas, editarlas o eliminarlas.</p></div>
    <div class="admin-toolbar"><button class="btn btn-green" onclick="adminOpenEvalSetup()">+ Nueva autoevaluación</button></div>
    <div class="guide-grid">${cards || '<div class="empty" style="grid-column:1/-1">No hay guías.</div>'}</div></div></main>${footer(false)}`;
}

export function adminOpenEvalSetup(preselectId = '') {
  const free = getGuideData().filter(x => !x.evalId);
  if (!free.length) {
      openModal(`<section class="modal center"><button class="close-btn" onclick="closeModal()" aria-label="Cerrar" title="Cerrar">×</button><h2>Todas las guías ya tienen autoevaluación</h2><p style="color:var(--muted)">Cada guía tiene una autoevaluación. Para crear una nueva, primero agrega una guía nueva en «Guías» o elimina la autoevaluación de una guía existente.</p><div class="modal-actions"><button class="btn btn-green" onclick="closeModal();go('admin-guia:new')">+ Nueva guía</button></div></section>`);
    return;
  }
    openModal(`<section class="modal"><button class="close-btn" onclick="closeModal()" aria-label="Cerrar" title="Cerrar">×</button><h2>Nueva autoevaluación</h2>
    <form class="form" onsubmit="event.preventDefault();adminSaveEvalSetup()">
      <div class="field"><label for="ef-guide">Guía a la que se asigna *</label><select id="ef-guide" required>${free.map(x => `<option value="${x.id}" ${x.id === preselectId ? 'selected' : ''}>${x.title} (${x.neuro})</option>`).join('')}</select><small class="cell-sub">Solo aparecen las guías que todavía no tienen autoevaluación.</small></div>
      <div class="modal-actions"><button class="btn btn-blue" type="submit">Crear y agregar preguntas</button><button class="btn btn-outline" type="button" onclick="closeModal()">Cancelar</button></div>
    </form></section>`);
}
const textoError = (e) => e.message;

// CREAR AUTOEVALUACIÓN
export async function adminSaveEvalSetup() {
    const id = val('ef-guide'); const g = getGuideById(id);
    if (!g) { showToast('Elige una guía'); return; }
    const boton = document.querySelector('#modal button[type="submit"]');
    if (boton) boton.disabled = true;
    try {
        const r = await apiCrearEvaluacion(state.user?.token, id);
        await recargarGuia(id);
        closeModal(); showToast(r.respuesta); go('admin-eval:' + id);
    } catch (e) { showToast(textoError(e), 'error'); if (boton) boton.disabled = false; }

}
export function adminAskDeleteEvaluation(id) {
  const g = getGuideById(id); if (!g) return;
  confirmAction('¿Eliminar la autoevaluación?', `Se borrarán las ${g.questions.length} preguntas de «${g.title}» (${g.neuro}). La guía se conserva. Los resultados que los usuarios ya obtuvieron no se borran.`, 'Sí, eliminar', `adminDeleteEvaluation('${id}')`);
}
// ELIMINACIÓN FÍSICA
export async function adminDeleteEvaluation(id) {
    const g = getGuideById(id); if (!g || !g.evalId) return;
    try {
        const r = await apiEliminarEvaluacion(state.user?.token, g.evalId);
        await recargarGuia(id);
        closeModal(); showToast(r.respuesta); refreshView();
    } catch (e) { closeModal(); showToast(textoError(e), 'error'); }
}
export function adminEvalEditor() {
  const g = getGuideById(state.route.split(':')[1]);
  if (!g) return `${header()}<main class="page"><div class="container"><p>No encontramos esta guía.</p><button class="btn btn-outline" onclick="go('admin-evaluaciones')">Volver</button></div></main>${footer(false)}`;
  const qs = g.questions.map((q, i) => `<article class="admin-question"><div class="admin-question-head"><strong>${i + 1}. ${q.text}</strong><div class="admin-actions"><button class="btn btn-outline btn-small" onclick="adminOpenQuestion('${g.id}',${i})">Editar</button><button class="btn btn-pink btn-small" onclick="adminAskDeleteQuestion('${g.id}',${i})">Eliminar</button></div></div><ul class="admin-options">${q.options.map(o => `<li class="${o.key === q.correct ? 'correct' : ''}"><b>${o.key.toUpperCase()}.</b> ${o.text}${o.key === q.correct ? ' <span class="chip chip-on">Correcta</span>' : ''}</li>`).join('')}</ul></article>`).join('');
  return `${header()}<main class="page"><div class="container">
    <button class="btn btn-outline btn-small" onclick="go('admin-evaluaciones')">← Volver a autoevaluaciones</button>
    <div class="content-head" style="margin-top:18px"><h1 class="section-title">${g.title}</h1><p class="section-text">Autoevaluación de la guía de ${g.neuro} · ${g.questions.length} ${g.questions.length === 1 ? 'pregunta' : 'preguntas'}</p></div>
    <div class="admin-footer-actions" style="justify-content:flex-start;margin:0 0 16px">${g.evalId ? `<button class="btn btn-green" onclick="adminOpenQuestion('${g.id}',-1)">+ Agregar pregunta</button>` : `<button class="btn btn-green" onclick="adminOpenEvalSetup('${g.id}')">Crear autoevaluación</button>`}<button class="btn btn-outline" onclick="openGuide('${g.id}')">Ver la guía</button></div>
    ${qs || `<div class="empty">${g.evalId ? 'Esta guía todavía no tiene preguntas. Agrega la primera.' : 'Esta guía todavía no tiene autoevaluación. Créala para poder agregar preguntas.'}</div>`}</div></main>${footer(false)}`;
}
export function adminOpenQuestion(guideId, index) {
  const g = getGuideById(guideId); if (!g) return;
  const q = index >= 0 ? g.questions[index] : { text: '', options: [], correct: 'a' };
  const keys = ['a', 'b', 'c', 'd'];
  const optRow = (k, i) => { const o = q.options.find(x => x.key === k); return `<div class="option-edit"><label class="check"><input type="radio" name="qf-correct" value="${k}" ${q.correct === k || (!q.options.length && i === 0) ? 'checked' : ''}> <b>${k.toUpperCase()}</b></label><input id="qf-opt-${k}" class="search-input" maxlength="180" placeholder="Opción ${k.toUpperCase()}${i < 2 ? ' (obligatoria)' : ' (opcional)'}" value="${o ? plain(o.text) : ''}"></div>`; };
    openModal(`<section class="modal"><button class="close-btn" onclick="closeModal()" aria-label="Cerrar" title="Cerrar">×</button><h2>${index >= 0 ? 'Editar pregunta' : 'Nueva pregunta'}</h2><form class="form" onsubmit="event.preventDefault();adminSaveQuestion('${guideId}',${index})"><div class="field"><label>Pregunta *</label><textarea id="qf-text" required rows="2" maxlength="220">${plain(q.text)}</textarea></div><div class="field"><label>Opciones de respuesta (marca la correcta)</label>${keys.map(optRow).join('')}</div><div class="modal-actions"><button class="btn btn-blue" type="submit">Guardar pregunta</button><button class="btn btn-outline" type="button" onclick="closeModal()">Cancelar</button></div></form></section>`);
}
// AGREGAR / EDITAR PREGUNTA
export async function adminSaveQuestion(guideId, index) {
    const g = getGuideById(guideId); if (!g) return;
    const text = val('qf-text').trim();
    const keys = ['a', 'b', 'c', 'd'];
    const filled = keys.map(k => ({ k, text: val('qf-opt-' + k).trim() })).filter(o => o.text);
    const correctKey = document.querySelector('input[name="qf-correct"]:checked')?.value;
    if (!text) { showToast('Escribe la pregunta'); return; }
    if (filled.length < 2) { showToast('Escribe al menos dos opciones'); return; }
    if (!filled.some(o => o.k === correctKey)) { showToast('Marca como correcta una opción que tenga texto'); return; }
    if (index < 0 && !g.evalId) { showToast('Esta guía todavía no tiene autoevaluación'); return; }
    const boton = document.querySelector('#modal button[type="submit"]');
    if (boton) boton.disabled = true;
    const datos = {
        texto: text, opcionA: filled[0].text, opcionB: filled[1].text,
        opcionC: filled[2]?.text || null, opcionD: filled[3]?.text || null,
        correcta: keys[filled.findIndex(o => o.k === correctKey)]  
    };
    try {
        const r = index >= 0
            ? await apiEditarPregunta(state.user?.token, g.questions[index].id, datos)
            : await apiCrearPregunta(state.user?.token, g.evalId, datos);
        await recargarGuia(guideId);
        closeModal(); showToast(r.respuesta); refreshView();
    } catch (e) { showToast(textoError(e), 'error'); if (boton) boton.disabled = false; }
}
export function adminAskDeleteQuestion(guideId, index) {
  confirmAction('¿Eliminar esta pregunta?', 'La pregunta se quitará de la autoevaluación.', 'Sí, eliminar', `adminDeleteQuestion('${guideId}',${index})`);
}
export async function adminDeleteQuestion(guideId, index) {
    const g = getGuideById(guideId); const q = g?.questions[index]; if (!q) return;
    try {
        const r = await apiEliminarPregunta(state.user?.token, q.id);   
        await recargarGuia(guideId);
        closeModal(); showToast(r.respuesta); refreshView();
    } catch (e) { closeModal(); showToast(textoError(e), 'error'); }
}

// ----- ESTADÍSTICAS -----
let statsSort = 'views';
let statsNeuro = '';
const SORTS = {
    views: ['Más vistas', (a, b) => b.vistas - a.vistas],
    favs: ['Más guardadas en favoritos', (a, b) => b.favoritos - a.favoritos],
    rating: ['Mejor calificadas', (a, b) => (b.promedioCalificacion ?? -1) - (a.promedioCalificacion ?? -1) || b.calificaciones - a.calificaciones],
    evals: ['Más autoevaluaciones', (a, b) => b.autoevaluaciones - a.autoevaluaciones],
    title: ['Nombre (A-Z)', (a, b) => a.titulo.localeCompare(b.titulo, 'es')]
};
export function adminSetStats(sort, neuro) {
    if (sort !== undefined) statsSort = sort;
    if (neuro !== undefined) statsNeuro = neuro;
    refreshView();
}

export function adminStats() {
    const cabecera = `<div class="content-head"><h1 class="section-title">Estadísticas</h1><p class="section-text">Actividad real de los usuarios, tomada de la base de datos.</p></div>`;
    const data = db.estadisticas;
    if (!data) return `${header()}<main class="page"><div class="container">${coverSlot('estadisticas')}${cabecera}${estadoCarga('estadisticas')}</div></main>${footer(false)}`;

    const r = data.resumen;
    const kpi = (n, label) => `<article class="kpi"><b>${n}</b><span>${label}</span></article>`;
    const rows = data.guias.filter(x => !statsNeuro || x.neurodivergencia === statsNeuro).sort(SORTS[statsSort][1]);
    const neuros = [...new Set(data.guias.map(x => x.neurodivergencia))];

    const topViews = [...rows].sort((a, b) => b.vistas - a.vistas).slice(0, 8).filter(x => x.vistas).map(x => ({ label: x.titulo, sub: x.neurodivergencia, value: x.vistas }));
    const topEval = rows.filter(x => x.promedioAciertos !== null).sort((a, b) => b.promedioAciertos - a.promedioAciertos).slice(0, 8).map(x => ({ label: x.titulo, sub: x.neurodivergencia, value: Math.round(x.promedioAciertos) }));
    const people = [{ label: 'Estudiantes', value: r.estudiantes }, { label: 'Docentes', value: r.docentes }];

    const body = rows.map(x => `<tr>
    <td><div class="admin-title"><div><strong>${esc(x.titulo)}</strong><small>${esc(x.neurodivergencia)}${x.activo ? '' : ' · Oculta'}</small></div></div></td>
    <td data-label="Vistas">${x.vistas}</td>
    <td data-label="Favoritos">${x.favoritos}</td>
    <td data-label="Calificación">${x.promedioCalificacion === null ? '<span class="cell-sub">Sin calificaciones</span>' : `<span class="stars">${ratingStars(x.promedioCalificacion)}</span> <strong>${x.promedioCalificacion}/5</strong> <small class="cell-sub">(${x.calificaciones})</small>`}</td>
    <td data-label="Autoevaluaciones">${x.autoevaluaciones}${x.promedioAciertos === null ? '' : ` <small class="cell-sub">· ${Math.round(x.promedioAciertos)}% de aciertos</small>`}</td>
    <td data-label="Comentarios">${x.comentarios}</td>
  </tr>`).join('');

    return `${header()}<main class="page"><div class="container">
    ${coverSlot('estadisticas')}
    ${cabecera}
    ${estadoCarga('estadisticas')}
    <section class="kpi-grid">${kpi(r.estudiantes + r.docentes, 'Personas registradas')}${kpi(r.vistas, 'Vistas de guías')}${kpi(r.favoritos, 'Guías en favoritos')}${kpi(r.promedioCalificacion === null ? '—' : Number(r.promedioCalificacion).toFixed(1), 'Calificación promedio (' + r.calificaciones + ')')}${kpi(r.autoevaluaciones, 'Autoevaluaciones')}${kpi(r.comentarios, 'Comentarios')}</section>
    <section class="chart-grid">
      <article class="admin-panel"><h2>Guías más vistas</h2>${hBars(topViews)}</article>
      <article class="admin-panel"><h2>Promedio de aciertos por guía</h2>${hBars(topEval, { suffix: '%' })}</article>
      <article class="admin-panel"><h2>Personas registradas</h2>${donut(people)}</article>
    </section>
    <div class="admin-toolbar">
      <select class="search-input" onchange="adminSetStats(this.value)" aria-label="Ordenar guías">${Object.entries(SORTS).map(([k, v]) => `<option value="${k}" ${k === statsSort ? 'selected' : ''}>${v[0]}</option>`).join('')}</select>
      <select class="search-input" onchange="adminSetStats(undefined, this.value)" aria-label="Filtrar por neurodivergencia"><option value="">Todas las neurodivergencias</option>${neuros.map(n => `<option value="${esc(n)}" ${n === statsNeuro ? 'selected' : ''}>${esc(n)}</option>`).join('')}</select>
      <button class="btn btn-outline btn-small" onclick="adminExportExcel()">Descargar Excel</button>
      <small class="cell-sub" style="flex:1 1 100%;text-align:left">El Excel incluye también el registro de donaciones.</small>
    </div>
    <div class="table-wrap"><table class="admin-table stack">
      <thead><tr><th>Guía</th><th>Vistas</th><th>Favoritos</th><th>Calificación</th><th>Autoevaluaciones</th><th>Comentarios</th></tr></thead>
      <tbody>${body || '<tr><td colspan="6">Todavía no hay actividad registrada.</td></tr>'}</tbody>
    </table></div>
  </div></main>${footer(false)}`;
}

// ----- DESCARGA DE ESTADÍSTICAS -----
const XL = { navy: '172333', purple: '9B8BC9', purpleDark: '5A47B0', green: '91BBA6', pink: 'C995AA', white: 'F1F0F4', muted: 'B8BDC8', text: '1B2442', band1: 'F2F5FF', band2: 'E4EBFB', head: 'DBE3FA', line: 'B8C5EA', ink: '171524' };

const DON_ESTADO_XL = { confirmada: 'Confirmada', pendiente: 'Pendiente', intencion: 'Sin completar', rechazada: 'Rechazada', reembolsada: 'Reembolsada' };
const DON_METODO_XL = { visa: 'Visa', master: 'Mastercard', amex: 'American Express', debvisa: 'Visa débito', debmaster: 'Mastercard débito', oxxo: 'OXXO', spei: 'SPEI', account_money: 'Saldo Mercado Pago' };

// Descarga de Excel
export async function adminExportExcel(soloDonaciones = false) {
    if (typeof soloDonaciones !== 'boolean') soloDonaciones = false;
    let donaciones = null;
    try { donaciones = await apiAdminDonaciones(state.user?.token); }
    catch (e) { donaciones = db.donaciones?.lista || null; }
    const data = db.estadisticas;
    const guias = data?.guias || [];
    const r = data?.resumen;
    const libro = crearLibro();
    const hoy = new Date().toLocaleDateString('es-MX', { day: 'numeric', month: 'long', year: 'numeric' });
    const sinDato = '—';

    const titulo = { fondo: XL.navy, color: XL.white, negrita: true, tam: 20, v: 'center', sangria: 1 };
    const subtitulo = { fondo: XL.navy, color: XL.muted, cursiva: true, tam: 10, v: 'center', sangria: 1 };
    const seccion = { fondo: XL.head, color: XL.purpleDark, negrita: true, tam: 13, v: 'center', sangria: 1, bordeInferior: XL.purple };
    const th = { fondo: XL.purple, color: XL.ink, negrita: true, h: 'center', ajustar: true, borde: XL.line };
    const fondoFila = (i) => (i % 2 ? XL.band2 : XL.band1);
    const td = (i, extra = {}) => ({ fondo: fondoFila(i), borde: XL.line, ...extra });
    const fila = (hoja, celdas, alto) => hoja.fila(celdas, { alto });
    const banda = (hoja, texto, estilo, columnas, alto) => { fila(hoja, [{ v: texto, e: estilo }, ...Array(columnas - 1).fill({ v: '', e: estilo })], alto); };
    const cabecera = (hoja, nombre, columnas) => {
        banda(hoja, 'Mentes Conectadas · ' + nombre, titulo, columnas, 40);
        hoja.combinar('A1:' + String.fromCharCode(64 + columnas) + '1');
        banda(hoja, 'Generado el ' + hoy + ' · Datos tomados de la base de datos', subtitulo, columnas, 22);
        hoja.combinar('A2:' + String.fromCharCode(64 + columnas) + '2');
        fila(hoja, [], 10);
    };

    if (!soloDonaciones) {
    // ----- Hoja Resumen -----
    const h1 = libro.hoja('Resumen', { anchos: [36, 16, 16, 16, 20, 16, 22], sinCuadricula: true, color: XL.purple });
    cabecera(h1, 'Estadísticas', 7);

    banda(h1, 'Resumen general', seccion, 7, 26); h1.combinar('A4:G4');
    fila(h1, [{ v: 'Indicador', e: th }, { v: 'Valor', e: th }], 24);
    const kpis = r ? [
        ['Personas registradas', r.estudiantes + r.docentes], ['Estudiantes', r.estudiantes], ['Docentes', r.docentes],
        ['Vistas de guías', r.vistas], ['Guías en favoritos', r.favoritos],
        ['Calificación promedio', r.promedioCalificacion === null || r.promedioCalificacion === undefined ? sinDato : Number(Number(r.promedioCalificacion).toFixed(1))],
        ['Autoevaluaciones realizadas', r.autoevaluaciones], ['Comentarios', r.comentarios]
    ] : [];
    kpis.forEach(([nombre, valor], i) => fila(h1, [{ v: nombre, e: td(i, { negrita: true, sangria: 1 }) }, { v: valor, e: td(i, { h: 'center', negrita: true, color: XL.purpleDark, formato: nombre === 'Calificación promedio' ? 'decimal' : 'entero' }) }], 22));
    fila(h1, [], 14);

    const filaSeccion2 = h1.filas.length + 1;
    banda(h1, 'Resumen por neurodivergencia', seccion, 7, 26); h1.combinar(`A${filaSeccion2}:G${filaSeccion2}`);
    fila(h1, ['Neurodivergencia', 'Guías', 'Vistas', 'En favoritos', 'Autoevaluaciones', 'Comentarios', 'Calificación promedio'].map(x => ({ v: x, e: th })), 30);
    const grupos = new Map();
    guias.forEach(g => {
        const x = grupos.get(g.neurodivergencia) || { guias: 0, vistas: 0, favoritos: 0, autoevaluaciones: 0, comentarios: 0, calif: 0, suma: 0 };
        x.guias++; x.vistas += g.vistas; x.favoritos += g.favoritos; x.autoevaluaciones += g.autoevaluaciones; x.comentarios += g.comentarios;
        if (g.promedioCalificacion !== null && g.promedioCalificacion !== undefined) { x.calif += g.calificaciones; x.suma += g.promedioCalificacion * g.calificaciones; }
        grupos.set(g.neurodivergencia, x);
    });
    const promedio = (x) => (x.calif ? Number((x.suma / x.calif).toFixed(1)) : sinDato);
    let i2 = 0;
    const total = { guias: 0, vistas: 0, favoritos: 0, autoevaluaciones: 0, comentarios: 0, calif: 0, suma: 0 };
    for (const [nombre, x] of grupos) {
        fila(h1, [{ v: nombre, e: td(i2, { negrita: true, sangria: 1 }) }, ...['guias', 'vistas', 'favoritos', 'autoevaluaciones', 'comentarios'].map(k => ({ v: x[k], e: td(i2, { h: 'center', formato: 'entero' }) })), { v: promedio(x), e: td(i2, { h: 'center', formato: 'decimal' }) }], 22);
        Object.keys(total).forEach(k => { total[k] += x[k]; });
        i2++;
    }
    if (grupos.size) {
        const eT = { fondo: XL.head, borde: XL.line, negrita: true, color: XL.purpleDark, h: 'center' };
        fila(h1, [{ v: 'Total', e: { ...eT, h: 'left', sangria: 1 } }, ...['guias', 'vistas', 'favoritos', 'autoevaluaciones', 'comentarios'].map(k => ({ v: total[k], e: { ...eT, formato: 'entero' } })), { v: promedio(total), e: { ...eT, formato: 'decimal' } }], 24);
    } else {
        fila(h1, [{ v: 'Todavía no hay actividad registrada.', e: { cursiva: true, color: XL.text, sangria: 1 } }]);
    }

    // ----- Hoja Guías -----
    const h2 = libro.hoja('Guías', { anchos: [46, 20, 12, 10, 13, 15, 14, 17, 17, 14], sinCuadricula: true, color: XL.green, congelarFilas: 4 });
    cabecera(h2, 'Estadísticas por guía', 10);
    fila(h2, ['Guía', 'Neurodivergencia', 'Estado', 'Vistas', 'En favoritos', 'Calificación promedio', 'Número de calificaciones', 'Autoevaluaciones realizadas', 'Promedio de aciertos', 'Comentarios'].map(x => ({ v: x, e: th })), 34);
    guias.forEach((g, i) => {
        const sinCalif = g.promedioCalificacion === null || g.promedioCalificacion === undefined;
        const sinAciertos = g.promedioAciertos === null || g.promedioAciertos === undefined;
        const estado = g.activo ? { fondo: XL.green, color: XL.ink, negrita: true, h: 'center', borde: XL.line } : { fondo: XL.pink, color: XL.ink, negrita: true, h: 'center', borde: XL.line };
        fila(h2, [
            { v: g.titulo, e: td(i, { negrita: true, ajustar: true, sangria: 1 }) },
            { v: g.neurodivergencia, e: td(i, { ajustar: true }) },
            { v: g.activo ? 'Visible' : 'Oculta', e: estado },
            { v: g.vistas, e: td(i, { h: 'center', formato: 'entero' }) },
            { v: g.favoritos, e: td(i, { h: 'center', formato: 'entero' }) },
            { v: sinCalif ? sinDato : Number(Number(g.promedioCalificacion).toFixed(1)), e: td(i, { h: 'center', formato: 'decimal' }) },
            { v: g.calificaciones, e: td(i, { h: 'center', formato: 'entero' }) },
            { v: g.autoevaluaciones, e: td(i, { h: 'center', formato: 'entero' }) },
            { v: sinAciertos ? sinDato : Math.round(g.promedioAciertos), e: td(i, { h: 'center', formato: 'porcentaje' }) },
            { v: g.comentarios, e: td(i, { h: 'center', formato: 'entero' }) }
        ], 24);
    });
    if (!guias.length) fila(h2, [{ v: 'Todavía no hay actividad registrada.', e: { cursiva: true, color: XL.text, sangria: 1 } }]);
    else h2.autoFiltro(`A4:J${4 + guias.length}`);
    }

    // ----- Hoja Donaciones -----
    if (Array.isArray(donaciones)) {
        const COLS = 9;
        const h3 = libro.hoja('Donaciones', { anchos: [20, 26, 30, 14, 10, 22, 16, 18, 44], sinCuadricula: true, color: XL.pink, congelarFilas: 4 });
        cabecera(h3, 'Registro de donaciones', COLS);
        fila(h3, ['Fecha', 'Donante', 'Correo', 'Monto', 'Moneda', 'Método de pago', 'Estado', 'ID de pago', 'Mensaje'].map(x => ({ v: x, e: th })), 34);
        const fechaXl = (iso) => { const d = new Date(iso); return isNaN(d) ? '' : d.toLocaleDateString('es-MX') + ' ' + d.toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' }); };
        donaciones.forEach((x, i) => {
            const ok = x.estado === 'confirmada';
            const estadoE = { fondo: ok ? XL.green : (x.estado === 'pendiente' ? XL.purple : XL.pink), color: XL.ink, negrita: true, h: 'center', borde: XL.line };
            fila(h3, [
                { v: fechaXl(x.fecha), e: td(i, { h: 'center' }) },
                { v: x.nombreDonante || x.nombre || 'Sin datos', e: td(i, { negrita: true, ajustar: true, sangria: 1 }) },
                { v: x.correoDonante || x.correo || sinDato, e: td(i, { ajustar: true }) },
                { v: Number(x.monto) || 0, e: td(i, { h: 'center', formato: 'dinero' }) },
                { v: x.moneda || DONATION_CURRENCY, e: td(i, { h: 'center' }) },
                { v: x.metodoPago ? (DON_METODO_XL[x.metodoPago] || String(x.metodoPago).toUpperCase()) : sinDato, e: td(i, { h: 'center' }) },
                { v: DON_ESTADO_XL[x.estado] || x.estado || sinDato, e: estadoE },
                { v: x.idPagoProveedor || sinDato, e: td(i, { h: 'center' }) },
                { v: x.mensaje || sinDato, e: td(i, { ajustar: true }) }
            ], 24);
        });
        if (!donaciones.length) fila(h3, [{ v: 'Todavía no hay donaciones registradas.', e: { cursiva: true, color: XL.text, sangria: 1 } }]);
        else {
            const confirmadas = donaciones.filter(x => x.estado === 'confirmada');
            const eT = { fondo: XL.head, borde: XL.line, negrita: true, color: XL.purpleDark, h: 'center' };
            fila(h3, [{ v: 'Total confirmado (' + confirmadas.length + ' donaciones)', e: { ...eT, h: 'left', sangria: 1 } }, { v: '', e: eT }, { v: '', e: eT }, { v: confirmadas.reduce((t, x) => t + (Number(x.monto) || 0), 0), e: { ...eT, formato: 'dinero' } }, ...Array(COLS - 4).fill({ v: '', e: eT })], 26);
            h3.combinar(`A${h3.filas.length}:C${h3.filas.length}`);
            h3.autoFiltro(`A4:I${4 + donaciones.length}`);
        }
    } else if (soloDonaciones) {
        showToast('No se pudo consultar el registro de donaciones', 'error');
        return;
    }

    descargarXlsx(libro, `${soloDonaciones ? 'donaciones' : 'estadisticas'}-mentes-conectadas-${new Date().toISOString().slice(0, 10)}.xlsx`);
    showToast(soloDonaciones ? 'Excel de donaciones descargado' : 'Excel de estadísticas y donaciones descargado');
}
