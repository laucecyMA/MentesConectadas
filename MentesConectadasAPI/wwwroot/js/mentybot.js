// ===== MENTYBOT =====
import { esc } from './ui.js';
import { logAssistantQuery, state } from './state.js';
import { getNeuroData, getVisibleGuides } from './content.js';
import { API_BASE_URL } from './api.js';
import { assistantFind } from './assistant.js';
import { isEnglish, t } from './i18n.js';
import { isAdmin } from './config.js';

const txt = (x) => Array.isArray(x) ? x.join('; ') : String(x || '');
const cut = (s, n) => (s.length > n ? s.slice(0, n) + '…' : s);
function buildContext(found) {
  const guides = found.guides.slice(0, 3).map(g => cut(`GUÍA: ${g.title} (${g.category}; ${g.neuro})\nDescripción: ${g.desc}\nPasos: ${txt(g.steps)}\nQué evitar: ${txt(g.avoid)}`, 1800));
  const neuros = found.neuros.slice(0, 2).map(n => cut(`INFORMACIÓN: ${n.name}\n${n.description}\nCaracterísticas: ${txt(n.characteristics)}\nAprendizaje: ${txt(n.learning)}\nComunicación: ${txt(n.communication)}`, 2200));
  return [...guides, ...neuros];
}
const chat = { msgs: [], busy: false, open: false };
function formatAI(text) {
  let html = '', list = false;
  for (const raw of esc(text).split(/\r?\n/)) {
    const line = raw.trim();
    const m = line.match(/^(?:[-*•]|\d+[.)])\s+(.*)$/);
    if (m) { if (!list) { html += '<ul>'; list = true; } html += `<li>${m[1]}</li>`; }
    else { if (list) { html += '</ul>'; list = false; } if (line) html += `<p>${line}</p>`; }
  }
  if (list) html += '</ul>';
  return html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
}
function msgHTML(m) {
  if (m.role === 'user') return `<div class="mb-msg mb-user"><p>${esc(m.text)}</p></div>`;
  if (m.local) {
    if (m.offline) return `<div class="mb-msg mb-bot"><p>El asistente no está disponible por el momento, inténtelo después.</p></div>`;
    const f = m.found || { guides: [], neuros: [] };
    const cards = f.guides.slice(0, 3).map(g => `<div class="mb-result"><strong>${g.title}</strong><span>${cut(String(g.desc || ''), 110)}</span><button type="button" class="btn btn-pink btn-small" onclick="openGuide('${g.id}')">Leer guía</button></div>`).join('')
      + f.neuros.slice(0, 2).map(n => `<div class="mb-result"><strong>${n.name}</strong><span>${cut(String(n.description || ''), 110)}</span><button type="button" class="btn btn-outline btn-small" onclick="go('neurodetalle:${n.id}')">Ver información</button></div>`).join('');
    return cards ? `<div class="mb-msg mb-bot"><p>El asistente con IA no está disponible en este momento. Esto encontré en las guías:</p>${cards}</div>`
      : `<div class="mb-msg mb-bot"><p>Por el momento no se cuenta con esa información, inténtelo después.</p></div>`;
  }
  return `<div class="mb-msg mb-bot">${formatAI(m.text)}</div>`;
}
function paint() {
  const log = document.getElementById('menty-log');
  if (!log) return;
  log.innerHTML = (chat.msgs.length ? '' : `<div class="mb-msg mb-bot"><p>Hola, soy <strong>MentyBot</strong>. Te ayudo a saber qué hacer con alumnos neurodivergentes y cómo convivir con compañeros neurodivergentes para que estén tranquilos en la universidad.</p><p>Pregúntame, por ejemplo: <em>¿Qué hago ante una sobrecarga?</em></p></div>`) + chat.msgs.map(msgHTML).join('') + (chat.busy ? '<div class="mb-msg mb-bot mb-typing"><span></span><span></span><span></span></div>' : '');
  log.scrollTop = log.scrollHeight;
  const btn = document.getElementById('menty-send');
  if (btn) btn.disabled = chat.busy;
}
async function send(text) {
  const input = document.getElementById('menty-input');
  const q = (text || input?.value || '').trim();
  if (!q || chat.busy) return;
  if (input) input.value = '';
  chat.msgs.push({ role: 'user', text: q });
  chat.busy = true; paint();
  const found = assistantFind(q);
  let ai = null;
  if (!navigator.onLine) {
    chat.msgs.push({ role: 'assistant', local: true, offline: true, found });
    chat.busy = false; paint();
    return;
  }
  try {
    const r = await fetch(API_BASE_URL + '/Chatbot/preguntar', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ mensaje: q, tipo: state.user?.type || null, historial: chat.msgs.slice(0, -1).filter(m => m.role === 'user' || m.ia).slice(-6).map(m => ({ rol: m.role, texto: m.text })), contexto: buildContext(found), idioma: isEnglish() ? 'en' : 'es' })
    });
    const data = await r.json().catch(() => ({}));
    if (r.ok && data.isSuccess && data.response?.texto) ai = data.response;
  } catch (e) { ai = null; }
  if (ai) {
    logAssistantQuery(q, q.toLowerCase(), ai.sinInfo ? 0 : 1);
    if (ai.sinInfo) chat.msgs.push({ role: 'assistant', ia: false, text: 'Por el momento no se cuenta con esa información, inténtelo después.' });
    else chat.msgs.push({ role: 'assistant', ia: true, text: ai.texto });
  } else {
    chat.msgs.push({ role: 'assistant', local: true, found });
  }
  chat.busy = false; paint();
}
function toggle(open) {
  chat.open = open ?? !chat.open;
  const panel = document.getElementById('menty-panel');
  const fab = document.getElementById('menty-fab');
  if (panel) panel.classList.toggle('open', chat.open);
  if (fab) fab.setAttribute('aria-expanded', String(chat.open));
  if (chat.open) setTimeout(() => document.getElementById('menty-input')?.focus(), 100);
}
function mentyDebeOcultarse() {
  const hash = (location.hash || '').toLowerCase();
  const ruta = (window.location.pathname || '').toLowerCase();
  if (hash.includes('login') || hash.includes('registro') || hash.includes('register') || hash.includes('recuperar') || hash.includes('olvide') || ruta.includes('login')) return true;
  try { if (!state.user) return true; } catch (e) {}
  try { if (isAdmin(state.user)) return true; } catch (e) {}
  return false;
}
function mentyActualizarVisibilidad() {
  const root = document.getElementById('menty-root');
  if (!root) return;
  const ocultar = mentyDebeOcultarse();
  root.style.display = ocultar ? 'none' : '';
  if (ocultar && chat.open) toggle(false);
}
export function resetMentyBot() {
  chat.msgs = []; chat.busy = false;
  try { toggle(false); } catch (e) {}
  paint();
}
export function initMentyBot() {
  if (document.getElementById('menty-root')) { mentyActualizarVisibilidad(); return; }
  const root = document.createElement('div');
  root.id = 'menty-root';
  root.innerHTML = `
    <button id="menty-fab" class="menty-fab" aria-label="Abrir MentyBot" aria-expanded="false">
      <img class="menty-fab-logo" src="/assets/img/logo.png" alt="MentyBot" /><span class="menty-fab-text">MentyBot</span><span class="menty-dot"></span>
    </button>
    <section id="menty-panel" class="menty-panel" aria-label="Chat con MentyBot">
      <header class="menty-head">
        <div><strong>MentyBot</strong><small>En línea • Mentes Conectadas</small></div>
        <div class="menty-head-btns"><button type="button" id="menty-close">—</button></div>
      </header>
      <div id="menty-log" class="menty-log" aria-live="polite"></div>
      <div class="menty-chips">
        <button type="button" data-q="¿Qué hago ante una sobrecarga?">Sobrecarga</button>
        <button type="button" data-q="Mi alumno se está pegando, ¿qué hago?">Crisis en el aula</button>
        <button type="button" data-q="¿Cómo trato a un compañero autista?">Tratar a un compañero</button>
      </div>
      <form class="menty-form" onsubmit="return false;">
        <input id="menty-input" maxlength="500" placeholder="Pregúntale a MentyBot..." autocomplete="off" />
        <button id="menty-send" type="button">Enviar</button>
      </form>
      <p class="menty-aviso">Respuestas orientativas, no sustituyen a un profesional. No escribas nombres ni datos personales.</p>
    </section>`;
  document.body.appendChild(root);
  document.getElementById('menty-fab').addEventListener('click', () => toggle());
  document.getElementById('menty-close').addEventListener('click', () => toggle(false));
  document.getElementById('menty-send').addEventListener('click', () => send());
  document.getElementById('menty-input').addEventListener('keydown', e => { if (e.key === 'Enter') { e.preventDefault(); send(); } });
  root.querySelectorAll('.menty-chips button').forEach(b => b.addEventListener('click', () => { if (!chat.open) toggle(true); send(t(b.dataset.q)); }));
  document.addEventListener('click', (e) => {
    if (!chat.open) return;
    if (e.composedPath().includes(root)) return;
    toggle(false);
  });
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && chat.open) toggle(false); });
  window.mentyAbrir = () => toggle(true);
  window.mentyAsk = (t) => { if (!chat.open) toggle(true); send(t); };
  window.addEventListener('hashchange', mentyActualizarVisibilidad);
  setInterval(mentyActualizarVisibilidad, 1000);
  mentyActualizarVisibilidad();
  paint();
}
