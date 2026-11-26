// ===== AUTOEVALUACIONES =====
import { state, save } from './state.js';
import { esc, evaluationNotice, footer, coverSlot, showToast } from './ui.js';
import { header, go, refreshView } from './navigation.js';
import { templateText, getGuideById, getVisibleEvaluations, canAccessGuide } from './content.js';
import { apiGuardarResultado } from './api.js';
import { cargarActividad } from './actividad.js';
import { vista, paginar, pagerHTML, subirALista } from './paginado.js';
import { NEURO_OPTIONS, SITUATION_OPTIONS } from './guides.js';

export function evalArt(g){const src=g.evalImage||g.image;return src?`<div class="guide-art eval-art guide-art-image"><img src="${esc(src)}" alt="" loading="lazy" onerror="this.parentNode.remove()"></div>`:'';}
const POR_PAGINA_EVAL=6;
const opc=(v,l,sel)=>`<option value="${v}"${v===sel?' selected':''}>${l}</option>`;
function evalsDeLaVista(){
  const v=vista('evaluaciones',{neuro:'all',situacion:'all',q:''});
  const todas=getVisibleEvaluations();
  let list=todas;
  if(v.neuro!=='all')list=list.filter(g=>g.neuroTags.includes(v.neuro));
  if(v.situacion!=='all')list=list.filter(g=>g.situationTags.includes(v.situacion));
  if(v.q)list=list.filter(g=>(g.title+' '+g.category+' '+g.desc+' '+g.neuro+' '+g.situationTags.join(' ')).toLowerCase().includes(v.q));
  const p=paginar(list,v.pagina,POR_PAGINA_EVAL);v.pagina=p.actual;
  return {v,todas,p};
}
function evalTiles(items,hayEvaluaciones){
  if(!items.length)return hayEvaluaciones?'<div class="empty" style="grid-column:1/-1">No encontramos autoevaluaciones con esos filtros.</div>':'';
  return items.map(g=>`<article class="eval-tile">${evalArt(g)}<div class="tag-row"><span class="tag">${g.category}</span><span class="tag tag-soft">${g.neuro}</span></div><h3>${g.title}</h3><p>${g.questions.length} ${g.questions.length===1?'pregunta relacionada':'preguntas relacionadas'} con esta guía.</p><button class="btn btn-primary" onclick="startEvaluation('${g.id}')">Comenzar</button></article>`).join('');
}
function pintarEvaluaciones(){
  const {todas,p}=evalsDeLaVista();
  const grid=document.getElementById('eval-grid'),pager=document.getElementById('eval-pager');
  if(grid)grid.innerHTML=evalTiles(p.items,todas.length>0);
  if(pager)pager.innerHTML=pagerHTML(p,'goEvalPage','autoevaluacion');
}
export function goEvalPage(n){vista('evaluaciones').pagina=Number(n)||1;pintarEvaluaciones();subirALista('eval-grid');}
export function applyEvalFilters(){const v=vista('evaluaciones',{neuro:'all',situacion:'all',q:''});v.neuro=document.getElementById('eval-filter-neuro')?.value||'all';v.situacion=document.getElementById('eval-filter-situation')?.value||'all';v.q=(document.getElementById('eval-search')?.value||'').toLowerCase().trim();v.pagina=1;pintarEvaluaciones();}
export function clearEvalFilters(){document.getElementById('eval-filter-neuro').value='all';document.getElementById('eval-filter-situation').value='all';document.getElementById('eval-search').value='';applyEvalFilters();}
export function evaluationLanding(){const {v,todas,p}=evalsDeLaVista();const neuros=NEURO_OPTIONS.filter(([k])=>todas.some(g=>g.neuroTags.includes(k)));const sits=SITUATION_OPTIONS.filter(([k])=>todas.some(g=>g.situationTags.includes(k)));const filtros=todas.length?`<div class="guide-search eval-search"><small>BUSCADOR DE AUTOEVALUACIONES</small><h2>Encuentra una autoevaluación</h2><div class="filter-grid"><label><span>Neurodivergencia</span><select id="eval-filter-neuro" onchange="applyEvalFilters()">${opc('all','Todas',v.neuro)}${neuros.map(([k,l])=>opc(k,l,v.neuro)).join('')}</select></label><label><span>Situación</span><select id="eval-filter-situation" onchange="applyEvalFilters()">${opc('all','Todas',v.situacion)}${sits.map(([k,l])=>opc(k,l,v.situacion)).join('')}</select></label></div><div class="filter-search"><input id="eval-search" class="search-input" placeholder="Buscar por palabra o situación" value="${esc(v.q)}" oninput="applyEvalFilters()"><button class="btn btn-outline btn-small" onclick="clearEvalFilters()">Limpiar filtros</button></div></div>`:'';return `${header()}<main class="page"><div class="container">${coverSlot('autoevaluaciones')}<div class="content-head"><span class="pill-title">Autoevaluación</span><p class="section-text">${templateText('dashboard-content','evaluation-description')} Selecciona una guía para comenzar.</p></div>${evaluationNotice()}${todas.length?'':'<div class="empty">Por ahora no hay autoevaluaciones disponibles para tu tipo de usuario.</div>'}${filtros}<div id="eval-grid" class="eval-grid">${evalTiles(p.items,todas.length>0)}</div><div id="eval-pager">${pagerHTML(p,'goEvalPage','autoevaluacion')}</div></div></main>${footer()}`;}
export function startEvaluation(guideId){const g=getGuideById(guideId);if(!g||!g.questions.length||!canAccessGuide(state.user,g))return;state.evalGuideId=guideId;state.evalIndex=0;state.evalAnswers=[];state.evalScore=0;go('evaluacion:'+guideId);}
export function currentEvalGuide(){const g=getGuideById(state.evalGuideId);return g&&g.questions.length&&canAccessGuide(state.user,g)?g:undefined;}
export function cancelEvaluation(){state.evalGuideId=null;state.evalIndex=0;state.evalAnswers=[];state.evalScore=0;go('evaluacion');}
export function evaluationView() { const g = currentEvalGuide(); if (!g) return evaluationLanding(); const q = g.questions[state.evalIndex]; const selected = state.evalAnswers[state.evalIndex]; const progress = ((state.evalIndex + 1) / g.questions.length) * 100; return `${header()}<main class="page"><div class="container eval-wrap"><div class="eval-card"><div class="eval-top"><div><div class="question-number">AUTOEVALUACIÓN · ${esc(g.title)}</div><div class="question-number">Pregunta ${state.evalIndex+1} de ${g.questions.length}</div></div><button class="btn btn-outline btn-small" onclick="cancelEvaluation()">Cancelar</button></div><div class="progress"><div class="progress-bar" style="width:${progress}%"></div></div><div class="question-text">${q.text}</div><div class="options">${q.options.map(o=>`<button class="option ${selected===o.key?'selected':''}" onclick="selectAnswer('${o.key}')"><strong>${o.key.toUpperCase()}.</strong> ${o.text}</button>`).join('')}</div><div class="eval-nav"><button class="btn btn-outline" ${state.evalIndex===0?'disabled':''} onclick="previousQuestion()">Anterior</button>${state.evalIndex<g.questions.length-1?`<button class="btn btn-primary" ${selected?'':'disabled'} onclick="nextQuestion()">Siguiente</button>`:`<button class="btn btn-green" ${selected?'':'disabled'} onclick="finishEvaluation()">Finalizar</button>`}</div></div></div></main>${footer()}`;}
export function selectAnswer(key){state.evalAnswers[state.evalIndex]=key;refreshView();}
export function nextQuestion(){if(!state.evalAnswers[state.evalIndex])return;state.evalIndex++;refreshView();}
export function previousQuestion() { if (state.evalIndex > 0) { state.evalIndex--; refreshView(); } }

export async function finishEvaluation() {
    const g = currentEvalGuide(); if (!g || !state.evalAnswers[state.evalIndex]) return;
    const score = g.questions.reduce((sum, q, i) => sum + (state.evalAnswers[i] === q.correct ? 1 : 0), 0);
    const btn = document.querySelector('.eval-nav .btn-green'); if (btn) { btn.disabled = true; btn.textContent = 'Guardando...'; }
    try {
        await apiGuardarResultado(state.user.token, g.id, score, g.questions.length);
    } catch (error) {
        showToast('No se pudo guardar tu resultado: ' + error.message);
    }
    state.evalScore = score;
    await cargarActividad();
    go('resultado:' + g.id);
}
export function evaluationResult() { const g = currentEvalGuide(); if (!g) return evaluationLanding(); const total = g.questions.length, p = state.evalScore / total; let title = 'Hay información que conviene reforzar'; let msg = 'Revisa nuevamente la guía y vuelve a realizar la autoevaluación cuando quieras.'; if (p === 1) { title = 'Tienes claros los puntos principales'; msg = 'Tu resultado muestra que identificaste correctamente los puntos principales de esta guía.'; } else if (p >= .67) { title = 'Buen punto de partida'; msg = 'Reconociste buena parte de las recomendaciones. Puedes revisar los puntos que te resultaron más difíciles.'; } return `${header()}<main class="page"><div class="container eval-wrap"><section class="eval-card center"><div class="question-number">RESULTADO · ${esc(g.title)}</div><div class="result-score">${state.evalScore}/${total}</div><h2>${title}</h2><p class="section-text">${msg}</p><div class="result-box"><strong>Recomendación</strong><p style="color:var(--muted)">Consulta nuevamente las recomendaciones de esta guía y observa las situaciones relacionadas con ella.</p></div><div class="related-guide"><div style="text-align:left"><strong>${g.title}</strong><div style="color:var(--muted);font-size:11px">${g.category}</div></div></div><div class="modal-actions"><button class="btn btn-primary" onclick="openGuide('${g.id}')">Ver guía</button><button class="btn btn-outline" onclick="go('evaluacion')">Elegir otra guía</button><button class="btn btn-green" onclick="startEvaluation('${g.id}')">Repetir</button></div></section></div></main>${footer()}`;}
