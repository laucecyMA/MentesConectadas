// ===== IDIOMA ES / EN =====
import { UI_EN, UI_PATTERNS } from '../content/en/ui.en.js';
import { GUIAS_EN } from '../content/en/guias.en.js';
import { state } from './state.js';
import { isAdmin } from './config.js';

const KEY = 'mc_lang';
const norm = (s) => s.replace(/\s+/g, ' ').trim();

const DICT = new Map();
for (const [k, v] of Object.entries({ ...GUIAS_EN, ...UI_EN })) DICT.set(norm(k), v);

let lang = 'es';
try { lang = localStorage.getItem(KEY) === 'en' ? 'en' : 'es'; } catch (e) { }

let onChange = () => {};
let descripcionEs = '';

export const getLang = () => lang;
export const activeLang = () => (lang === 'en' && !isAdmin(state.user) ? 'en' : 'es');
export const isEnglish = () => activeLang() === 'en';
export const dateLocale = () => (isEnglish() ? 'en-US' : 'es-MX');

const tKey = (s) => DICT.get(norm(s)) ?? s;

function translateString(str) {
  const key = norm(str);
  if (!key) return str;
  let out = DICT.get(key);
  if (out === undefined) {
    for (const [re, fn] of UI_PATTERNS) {
      const m = key.match(re);
      if (m) { out = fn(tKey, ...m.slice(1)); break; }
    }
  }
  if (out === undefined) return str;
  return str.match(/^\s*/)[0] + out + str.match(/\s*$/)[0];
}

export const t = (s) => (isEnglish() ? translateString(s) : s);

// ----- Traductor del DOM -----
const ATTRS = ['placeholder', 'title', 'aria-label', 'alt'];
const NO_CHILDREN = new Set(['SCRIPT', 'STYLE', 'TEXTAREA', 'CODE', 'PRE']);

const textOrig = new Map();
const attrOrig = new Map();
const fueraDeApp = (el) => !el.closest('#app');
function podar() {
  if (textOrig.size + attrOrig.size < 300) return;
  for (const n of [...textOrig.keys()]) if (!n.isConnected) textOrig.delete(n);
  for (const e of [...attrOrig.keys()]) if (!e.isConnected) attrOrig.delete(e);
}
function restaurar() {
  for (const [n, o] of textOrig) if (n.isConnected) n.nodeValue = o;
  for (const [e, obj] of attrOrig) if (e.isConnected) for (const a in obj) e.setAttribute(a, obj[a]);
  textOrig.clear(); attrOrig.clear();
}

function walk(node) {
  if (node.nodeType === 3) {
    const v = node.nodeValue;
    if (v && v.trim()) {
      const o = translateString(v);
      if (o !== v) {
        const p = node.parentElement;
        if (p && fueraDeApp(p) && !textOrig.has(node)) { podar(); textOrig.set(node, v); }
        node.nodeValue = o;
      }
    }
    return;
  }
  if (node.nodeType !== 1) return;
  if (node.hasAttribute('data-no-i18n')) return;
  for (const a of ATTRS) {
    const v = node.getAttribute(a);
    if (v) {
      const o = translateString(v);
      if (o !== v) {
        if (fueraDeApp(node)) { podar(); const r = attrOrig.get(node) || {}; if (!(a in r)) r[a] = v; attrOrig.set(node, r); }
        node.setAttribute(a, o);
      }
    }
  }
  if (NO_CHILDREN.has(node.nodeName)) return;
  node.childNodes.forEach(walk);
}

let observer = null;
const observe = () => observer.observe(document.body, {
  childList: true, subtree: true, characterData: true, attributes: true, attributeFilter: ATTRS
});

function startObserver() {
  if (observer || typeof MutationObserver === 'undefined') return;
  observer = new MutationObserver((muts) => {
    if (!isEnglish()) return;
    observer.disconnect();
    try {
      for (const m of muts) {
        if (m.type === 'childList') m.addedNodes.forEach(walk);
        else if (m.type === 'characterData') walk(m.target);
        else if (m.type === 'attributes') walk(m.target);
      }
    } finally { observe(); }
  });
  observe();
}

// ----- Idioma del documento -----
export function syncDocLang() {
  const en = isEnglish();
  document.documentElement.lang = en ? 'en' : 'es-MX';
  document.querySelector('meta[name="description"]')?.setAttribute('content',
    en ? 'Mentes Conectadas - information and practical guidance on neurodivergence in the university environment.' : descripcionEs);
}

export function initLang(rerender) {
  onChange = rerender;
  descripcionEs = document.querySelector('meta[name="description"]')?.getAttribute('content') || '';
  syncDocLang();
  startObserver();
  window.i18nFaltantes = faltantes;
}

export function setLang(next) {
  next = next === 'en' ? 'en' : 'es';
  if (next === lang) return;
  lang = next;
  try { localStorage.setItem(KEY, next); } catch (e) { }
  const saved = [...document.querySelectorAll('#app form [id]')]
    .filter((e) => 'value' in e).map((e) => [e.id, e.value]);
  syncDocLang();
  if (next === 'es') restaurar();
  onChange();
  if (isEnglish() && observer) { observer.disconnect(); try { walk(document.body); } finally { observe(); } }
  saved.forEach(([id, v]) => { const e = document.getElementById(id); if (e && !e.value) e.value = v; });
}

export function langSwitch() {
  if (isAdmin(state.user)) return '';
  const en = lang === 'en';
  return `<div class="lang-switch" role="group" aria-label="Idioma">`
    + `<button type="button" class="${en ? '' : 'active'}" onclick="setLang('es')" aria-pressed="${!en}" lang="es" title="Español">ES</button>`
    + `<button type="button" class="${en ? 'active' : ''}" onclick="setLang('en')" aria-pressed="${en}" lang="en" title="English">EN</button></div>`;
}

export function faltantes() {
  const esp = /[áéíóúñ¿¡]|\b(el|la|los|las|de|del|para|con|que|tu|tus|una|un|por|en|se|es|no|mi|al)\b/i;
  const vistos = new Set();
  const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  while (w.nextNode()) {
    const n = w.currentNode, p = n.parentElement;
    if (!p || ['SCRIPT', 'STYLE'].includes(p.tagName)) continue;
    const v = norm(n.nodeValue);
    if (v && esp.test(v)) vistos.add(v);
  }
  const lista = [...vistos];
  console.table(lista.map((texto) => ({ texto })));
  return lista;
}
