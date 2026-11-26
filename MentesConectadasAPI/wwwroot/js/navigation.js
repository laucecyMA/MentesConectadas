// ===== NAVEGACIÓN =====
import { cambioDeRuta } from './paginado.js';
import { state } from './state.js';
import { ASSISTANT_ENABLED, isAdmin, SHOW_ADMIN_STATS } from './config.js';
import { themeButton } from './theme.js';
import { langSwitch } from './i18n.js';


let renderer = () => {};
export function setRenderer(fn) { renderer = fn; }
export function refreshView() { renderer(); }

export function go(route){cambioDeRuta(state.route,route);state.route=route;location.hash=route;window.scrollTo({top:0,behavior:'instant'});renderer();}

const AUTH_NAV = [
  
  ['dashboard', 'INICIO', 'Inicio'],
  ['neurodivergencias', 'NEURODIVERGENCIA', 'Conoce la neurodivergencia'],
  ['guias', 'GUÍAS PRÁCTICAS', 'Guías prácticas'],
  ['evaluacion', 'AUTOEVALUACIÓN', 'Autoevaluación'],
  ['favoritas', 'MIS GUÍAS', 'Mis guías'],
  ['sobre-nosotros', 'SOBRE NOSOTROS', 'Sobre nosotros'],
  ['perfil', 'MI PERFIL', 'Mi perfil']
];

const ADMIN_NAV = [
  ['admin', 'INICIO', 'Inicio'],
  ['admin-guias', 'GUÍAS', 'Guías'],
  ['admin-evaluaciones', 'AUTOEVALUACIONES', 'Autoevaluaciones'],
  ['admin-comentarios', 'COMENTARIOS', 'Comentarios'],
  ...(SHOW_ADMIN_STATS ? [['admin-estadisticas', 'ESTADÍSTICAS', 'Estadísticas']] : []),
  ['admin-donaciones', 'DONACIONES', 'Donaciones'],
  ['perfil', 'MI PERFIL', 'Mi perfil']
];
const LOGOUT_ICON = '<svg class="logout-icon" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/></svg>';
const navButtons = (index) => (isAdmin(state.user) ? ADMIN_NAV : AUTH_NAV).map(item => `<button onclick="go('${item[0]}')">${item[index]}</button>`).join('')
  + `<button type="button" class="nav-logout" onclick="logout()" aria-label="Cerrar sesión" title="Cerrar sesión">${LOGOUT_ICON}<span class="logout-label">${index === 1 ? 'CERRAR SESIÓN' : 'Cerrar sesión'}</span></button>`;

export function header(auth=true){const admin=auth&&isAdmin(state.user);const home=admin?'admin':(auth?'dashboard':'inicio');return `<header class="header${auth ? ' header-auth' : ''}"><div class="container nav">
  <button class="brand btn-ghost" onclick="go('${home}')"><img src="assets/img/logo.png" alt="Logo de Mentes Conectadas"><span>Mentes Conectadas</span></button>
  <nav class="nav-links">${auth?navButtons(1):`<button onclick="go('inicio')">INICIO</button><button onclick="go('neuropublico')">INFORMACIÓN</button><button onclick="go('sobre-nosotros')">SOBRE NOSOTROS</button>`}</nav>
  <div class="nav-actions">${langSwitch()}${themeButton('icon-btn')}</div>
  <button class="menu-btn" onclick="document.querySelector('.mobile-nav').classList.toggle('open')" aria-label="Abrir menú">☰</button></div>
  <div class="container mobile-nav">${auth?navButtons(2):`<button onclick="go('inicio')">Inicio</button><button onclick="go('neuropublico')">Información</button><button onclick="go('sobre-nosotros')">Sobre nosotros</button><button onclick="go('login')">Iniciar sesión</button><button onclick="go('registro')">Crear cuenta</button>`}${langSwitch()}${themeButton('mobile-theme-btn',true)}</div></header>`;}