// ===== GUÍAS =====
import { state, save, recordView } from './state.js';
import { isAdmin } from './config.js';
import { esc, showToast, closeModal, guideWarning, footer, coverSlot, heartIcon } from './ui.js';
import { header } from './navigation.js';
import { getVisibleGuides, getGuideById, canAccessGuide } from './content.js';
import { isFavorite } from './favorites.js';
import { guideArt } from './videos.js';
import { apiGuardarCalificacion, apiCrearComentario, apiEliminarComentario } from './api.js';
import { cargarActividad } from './actividad.js';
import { dateLocale } from './i18n.js';
import { vista, paginar, pagerHTML, subirALista } from './paginado.js';

export function ratingSummary(id) { const rows = Array.isArray(state.ratings[id]) ? state.ratings[id] : []; if (!rows.length) return { avg: null, count: 0, user: null }; const avg = rows.reduce((s, r) => s + Number(r.rating), 0) / rows.length; const mine = rows.find(r => r.mine); return { avg: Number(avg.toFixed(1)), count: rows.length, user: mine ? mine.rating : null }; }
export function ratingStars(avg){if(avg===null)return '☆ ☆ ☆ ☆ ☆';return [1,2,3,4,5].map(i=>i<=Math.round(avg)?'★':'☆').join(' ');}
export async function setGuideRating(id, value) {
    if (!state.user) { showToast('Inicia sesión para calificar una guía'); return; }
    const rating = Math.max(1, Math.min(5, Number(value)));
    try {
        await apiGuardarCalificacion(state.user.token, id, rating);
        await cargarActividad();
        showToast('Tu calificación fue guardada');
        openGuide(id, false);
    } catch (error) { showToast(error.message, 'error'); }
}

// ----- Comentarios de las guías -----
const MAX_COMMENT=300, MAX_PER_GUIDE=3;
export function visibleComments(id){return state.comments.filter(c=>c.guideId===id&&!c.hidden).sort((a,b)=>b.date.localeCompare(a.date));}
function commentsSection(g){
  const admin=isAdmin(state.user);const list=visibleComments(g.id);
  const mine=state.comments.filter(c=>c.guideId===g.id&&c.mine).length;
  const rating=(c)=>c.rating?`<span class="stars">${'★'.repeat(c.rating)}${'☆'.repeat(5-c.rating)}</span>`:'';
  const items=list.map(c=>`<li class="comment"><div class="comment-head"><strong>${esc(c.name)}</strong>${c.type?`<span class="chip chip-${c.type==='Docente'?'blue':'green'}">${esc(c.type)}</span>`:''}${rating(c)}<small>${new Date(c.date).toLocaleDateString(dateLocale())}</small>${c.mine?`<button class="link-btn" onclick="deleteMyComment('${c.id}','${g.id}')">Eliminar</button>`:''}</div><p>${esc(c.text)}</p></li>`).join('');
  const form=admin?'':(mine>=MAX_PER_GUIDE?`<small class="cell-sub">Ya enviaste ${MAX_PER_GUIDE} comentarios en esta guía. Puedes eliminar uno para escribir otro.</small>`:`<div class="comment-form"><label for="comment-text">Deja un comentario (opcional)</label><textarea id="comment-text" rows="3" maxlength="${MAX_COMMENT}" placeholder="¿Qué te pareció la guía? ¿Qué agregarías o cambiarías?"></textarea><div class="comment-actions"><small>Máximo ${MAX_COMMENT} caracteres. Se mostrará tu nombre de pila.</small><button class="btn btn-primary btn-small" onclick="postComment('${g.id}')">Enviar comentario</button></div></div>`);
  return `<section class="comments-box"><h4>Comentarios (${list.length})</h4>${form}${items?`<ul class="comment-list">${items}</ul>`:'<p class="cell-sub">Aún no hay comentarios en esta guía.</p>'}</section>`;
}
export async function postComment(id){
  if(!state.user||isAdmin(state.user))return;
  const text=(document.getElementById('comment-text')?.value||'').trim();
  if(text.length<3){showToast('Escribe tu comentario antes de enviarlo');return;}
  if(text.length>MAX_COMMENT){showToast('El comentario es demasiado largo');return;}
  if(state.comments.filter(c=>c.guideId===id&&c.mine).length>=MAX_PER_GUIDE){showToast('Ya enviaste el máximo de comentarios en esta guía');return;}
  const btn=document.querySelector('.comment-actions button');if(btn){btn.disabled=true;btn.textContent='Enviando...';}
  try{
    await apiCrearComentario(state.user.token,id,text);
    await cargarActividad();
    showToast('Gracias por tu comentario');
    openGuide(id,false);
  }catch(error){
      showToast(error.message, 'error');
    if(btn){btn.disabled=false;btn.textContent='Enviar comentario';}
  }
}
export async function deleteMyComment(commentId,guideId){
  if(!state.user)return;
  try{
    await apiEliminarComentario(state.user.token,commentId);
    await cargarActividad();
    showToast('Comentario eliminado');
    openGuide(guideId,false);
  } catch (error) {showToast(error.message, 'error');}
}

const POR_PAGINA_GUIAS=3;
export const NEURO_OPTIONS=[['autismo','Autismo'],['tdah','TDAH'],['dislexia','Dislexia'],['discalculia','Discalculia'],['dispraxia','Dispraxia']];
const opcion=(v,l,sel)=>`<option value="${v}"${v===sel?' selected':''}>${l}</option>`;
function guiasDeLaVista(favoritesOnly){
  const v=vista(favoritesOnly?'favoritas':'guias',{neuro:'all',situacion:'all',q:''});
  let list=getVisibleGuides();
  if(favoritesOnly)list=list.filter(g=>isFavorite(g.id));
  else{
    if(v.neuro!=='all')list=list.filter(g=>g.neuroTags.includes(v.neuro));
    if(v.situacion!=='all')list=list.filter(g=>g.situationTags.includes(v.situacion));
    if(v.q)list=list.filter(g=>(g.title+' '+g.category+' '+g.desc+' '+g.neuro+' '+g.situationTags.join(' ')).toLowerCase().includes(v.q));
  }
  const p=paginar(list,v.pagina,POR_PAGINA_GUIAS);v.pagina=p.actual;
  return {v,p};
}
function pintarGuias(){
  const fav=state.route==='favoritas';const {p}=guiasDeLaVista(fav);
  const grid=document.getElementById('guide-grid'),pager=document.getElementById('guide-pager');
  if(grid)grid.innerHTML=guideCards(p.items,fav?'No se encontraron guías favoritas':undefined);
  if(pager)pager.innerHTML=pagerHTML(p,'goGuidePage','guia');
}
export function goGuidePage(n){const v=vista(state.route==='favoritas'?'favoritas':'guias');v.pagina=Number(n)||1;pintarGuias();subirALista('guide-grid');}
export function guideList(favoritesOnly = false) { const all = getVisibleGuides(); const {v,p}=guiasDeLaVista(favoritesOnly); return `${header()}<main class="page"><div class="container">${favoritesOnly ? '' : coverSlot('guias')}<div class="content-head"><h1 class="section-title">${favoritesOnly ? 'Mis guías' : 'Guías prácticas'}</h1><p class="section-text">${favoritesOnly ? 'Guías que guardaste para consultar posteriormente.' : 'Busca una situación y filtra las guías por neurodivergencia.'}</p></div>${!favoritesOnly ? guideWarning() : ''}${!favoritesOnly ?`<div class="guide-search"><small>BUSCADOR DE GUÍAS</small><h2>Encuentra una situación</h2><div class="filter-grid"><label><span>Neurodivergencia</span><select id="filter-neuro" onchange="applyGuideFilters()">${opcion('all','Todas',v.neuro)}${NEURO_OPTIONS.map(([k,l])=>opcion(k,l,v.neuro)).join('')}</select></label><label><span>Situación</span><select id="filter-situation" onchange="applyGuideFilters()">${situationOptions(all,v.situacion)}</select></label></div><div class="filter-search"><input id="guide-search" class="search-input" placeholder="Buscar por palabra o situación" value="${esc(v.q)}" oninput="applyGuideFilters()"><button class="btn btn-outline btn-small" onclick="clearGuideFilters()">Limpiar filtros</button></div></div>`:''}<div id="guide-grid" class="guide-grid">${guideCards(p.items,favoritesOnly?'No se encontraron guías favoritas':undefined)}</div><div id="guide-pager">${pagerHTML(p,'goGuidePage','guia')}</div></div></main>${footer()}`;}
export const SITUATION_OPTIONS=[['sobrecarga','Sobrecarga de estímulos'],['comunicacion','Comunicación'],['trabajo-equipo','Trabajo en equipo'],['examen','Exámenes'],['cambios','Cambios inesperados'],['organizacion','Organización'],['participacion','Participación'],['retroalimentacion','Retroalimentación'],['correccion','Corrección respetuosa']];

function situationOptions(guides,sel='all'){const tags=new Set(guides.flatMap(g=>g.situationTags));return opcion('all','Todas',sel)+SITUATION_OPTIONS.filter(([v])=>tags.has(v)).map(([v,l])=>opcion(v,l,sel)).join('');}
export function guideCards(list,emptyMsg='No encontramos guías con esos filtros.'){if(!list.length)return `<div class="empty" style="grid-column:1/-1">${emptyMsg}</div>`;return list.map(g=>{const r=ratingSummary(g.id);return `<article class="guide-card">${guideArt(g)}<div class="tag-row"><span class="tag">${g.category}</span><span class="tag tag-soft">${g.neuro}</span></div><h3>${g.title}</h3><p>${g.desc}</p><div class="guide-rating-preview">${r.avg===null?'Sin calificaciones':`${ratingStars(r.avg)} <span>${r.avg} (${r.count})</span>`}${visibleComments(g.id).length?` <span>· ${visibleComments(g.id).length} ${visibleComments(g.id).length===1?'comentario':'comentarios'}</span>`:''}</div><div class="guide-card-actions"><button class="btn btn-pink btn-small" onclick="openGuide('${g.id}')">Consultar guía</button><button class="fav ${isFavorite(g.id)?'active':''}" onclick="toggleFavorite('${g.id}')" title="Favorito">${heartIcon(isFavorite(g.id))}</button></div></article>`}).join('');}
export function applyGuideFilters(){const v=vista('guias',{neuro:'all',situacion:'all',q:''});v.neuro=document.getElementById('filter-neuro')?.value||'all';v.situacion=document.getElementById('filter-situation')?.value||'all';v.q=(document.getElementById('guide-search')?.value||'').toLowerCase().trim();v.pagina=1;pintarGuias();}
export function clearGuideFilters(){document.getElementById('filter-neuro').value='all';document.getElementById('filter-situation').value='all';document.getElementById('guide-search').value='';applyGuideFilters();}
export function openGuide(id, track = true) { closeModal(); const found = getGuideById(id); if (!canAccessGuide(state.user, found)) { showToast('Esta guía no está disponible para tu tipo de usuario'); return; } state.selectedGuide = found; const g = state.selectedGuide; if (track && !isAdmin(state.user)) recordView(g.id); const r = ratingSummary(g.id); const el = document.createElement('div'); el.className = 'modal-backdrop'; el.id = 'modal'; el.innerHTML = `<section class="modal"><button class="close-btn" onclick="closeModal()" aria-label="Cerrar" title="Cerrar">×</button>${g.image ? `<img class="guide-modal-img" src="${esc(g.image)}" alt="" onerror="this.remove()">` : ''}<div class="tag-row"><span class="tag">${g.category}</span><span class="tag tag-soft">${g.neuro}</span></div><h2>${g.title}</h2><p style="color:var(--muted)">${g.desc}</p><h4>¿Qué puedes hacer?</h4><ul>${g.steps.map(x=>`<li>${x}</li>`).join('')}</ul><h4>¿Qué conviene evitar?</h4><ul>${g.avoid.map(x=>`<li>${x}</li>`).join('')}</ul>${isAdmin(state.user)?`${commentsSection(g)}<div class="modal-actions"><button class="btn btn-green" onclick="closeModal();go('admin-eval:${g.id}')">Ver autoevaluación</button><button class="btn btn-primary" onclick="closeModal();go('admin-guia:${g.id}')">Editar guía</button></div>`:`<section class="rating-box"><h4>¿Qué te pareció esta guía?</h4><div class="rating-summary">${r.avg===null?'Aún no hay calificaciones':`${ratingStars(r.avg)} <strong>${r.avg}/5</strong> · ${r.count} ${r.count===1?'calificación':'calificaciones'}`}</div><div class="rating-buttons" role="group" aria-label="Calificar guía">${[1,2,3,4,5].map(n=>`<button class="rating-star ${r.user===n?'selected':''}" onclick="setGuideRating('${g.id}',${n})" title="${n} de 5">${n<= (r.user||0)?'★':'☆'}</button>`).join('')}</div><small>Tu calificación puede modificarse posteriormente.</small></section>${commentsSection(g)}<div class="modal-actions"><button class="btn ${isFavorite(g.id)?'btn-green':'btn-pink'}" onclick="toggleFavorite('${g.id}');closeModal();">${isFavorite(g.id)?'Quitar de favoritas':'Guardar guía'}</button>${g.questions.length ? `<button class="btn btn-green" onclick="closeModal();startEvaluation('${g.id}')">Hacer autoevaluación</button>` : ''}</div>`}</section>`;document.body.appendChild(el);}
