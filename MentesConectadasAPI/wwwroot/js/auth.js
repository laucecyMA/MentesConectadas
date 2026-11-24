// ===== INICIO DE SESIÓN Y REGISTRO =====
import { state, save, loadFavoritesForCurrentUser } from './state.js';
import { USER_TYPES, isAdmin, TOPIC_AUDIENCE, TOPIC_LABELS } from './config.js';
import { showToast, confirmModal, footer } from './ui.js';
import { header, go } from './navigation.js';
import { apiLogin, apiRegistro } from './api.js';
import { cargarActividad } from './actividad.js';
import { resetMentyBot } from './mentybot.js';
import { resetAssistant } from './assistant.js';

export function login(){return `${header(false)}<main class="auth-page login-fondo"><section class="auth-card"><h1>Iniciar sesión</h1><p>Ingresa a tu cuenta para consultar y guardar guías prácticas.</p><form class="form" onsubmit="event.preventDefault();doLogin()"><div class="field"><label>Correo electrónico</label><input id="login-email" type="email" required placeholder="Correo electrónico"></div><div class="field"><label>Contraseña</label><input id="login-pass" type="password" required placeholder="Contraseña"></div><button class="btn btn-blue" type="submit">INICIAR SESIÓN</button></form><div class="auth-footer">¿No tienes una cuenta? <button onclick="go('registro')">REGÍSTRATE</button></div></section></main>${footer()}`;}
export function registro(){return `${header(false)}<main class="auth-page"><section class="auth-card"><h1>Crear una cuenta</h1><p>Regístrate para consultar información y guardar guías prácticas.</p><form class="form" novalidate onsubmit="event.preventDefault();doRegister()" oninput="regLimpiarError(event.target)" onchange="regLimpiarError(event.target)"><div class="field"><label>Nombre completo</label><input id="reg-name" required maxlength="80" autocomplete="name" placeholder="Nombre completo" oninput="this.value=this.value.replace(/[^\\p{L}\\s]/gu,'')"><small class="field-error" id="err-reg-name" role="alert" hidden></small></div><div class="field"><label>Correo electrónico</label><input id="reg-email" type="email" required placeholder="Correo electrónico"><small class="field-error" id="err-reg-email" role="alert" hidden></small></div><div class="field"><label>Contraseña</label><input id="reg-pass" type="password" minlength="6" required placeholder="Contraseña"><small class="field-error" id="err-reg-pass" role="alert" hidden></small></div><div class="field"><label>Confirmar contraseña</label><input id="reg-pass2" type="password" minlength="6" required placeholder="Confirmar contraseña"><small class="field-error" id="err-reg-pass2" role="alert" hidden></small></div><div class="field"><label>Tipo de usuario</label><select id="reg-type" required onchange="showTypeHint(this.value)"><option value="">Selecciona una opción</option>${USER_TYPES.map(t=>`<option value="${t}">${t}</option>`).join('')}</select><small class="field-error" id="err-reg-type" role="alert" hidden></small><div id="reg-type-hint" class="type-hint" hidden></div></div><button class="btn btn-blue" type="submit">CREAR CUENTA</button></form><div class="auth-footer">¿Ya tienes una cuenta? <button onclick="go('login')">INICIAR SESIÓN</button></div></section></main>${footer()}`;}
export async function doLogin() {
    const email = document.getElementById('login-email').value.trim();
    const pass = document.getElementById('login-pass').value;
    const btn = document.querySelector('.auth-card button[type="submit"]');
    if (btn) { btn.disabled = true; btn.textContent = 'ENTRANDO...'; }
    try {
        const u = await apiLogin(email, pass);
        state.user = { id: u.id, name: u.nombre, email: u.correo, type: u.tipo, token: u.token };
        loadFavoritesForCurrentUser();
        save();
        await cargarActividad();
        showToast(isAdmin(state.user) ? 'Sesión de administrador iniciada' : 'Sesión iniciada');
        setTimeout(() => go(isAdmin(state.user) ? 'admin' : 'dashboard'), 350);
    } catch (error) {
        showToast(error.message, 'error');
        if (btn) { btn.disabled = false; btn.textContent = 'INICIAR SESIÓN'; }
    }
}
const SOLO_LETRAS = /^[\p{L}]+(?:\s+[\p{L}]+)*$/u;
function regError(id, msg) {
    const input = document.getElementById(id), err = document.getElementById('err-' + id);
    if (!input || !err) return;
    err.textContent = msg; err.hidden = !msg;
    input.classList.toggle('is-invalid', !!msg);
    input.setAttribute('aria-invalid', msg ? 'true' : 'false');
}
export function regLimpiarError(el) {
    if (!el || !el.id || !el.id.startsWith('reg-')) return;
    regError(el.id, '');
    if (el.id === 'reg-pass' || el.id === 'reg-pass2') regError('reg-pass2', '');
}
function validarRegistro() {
    const v = (id) => document.getElementById(id).value;
    const name = v('reg-name').trim(), email = v('reg-email').trim(), pass = v('reg-pass'), pass2 = v('reg-pass2'), type = v('reg-type');
    const errores = {};
    if (!name) errores['reg-name'] = 'Escribe tu nombre completo.';
    else if (!SOLO_LETRAS.test(name)) errores['reg-name'] = 'El nombre solo puede contener letras.';
    if (!email) errores['reg-email'] = 'Escribe tu correo electrónico.';
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) errores['reg-email'] = 'Escribe un correo válido, por ejemplo nombre@correo.com.';
    if (!pass) errores['reg-pass'] = 'Escribe una contraseña.';
    else if (pass.length < 6) errores['reg-pass'] = 'La contraseña debe tener al menos 6 caracteres.';
    if (!pass2) errores['reg-pass2'] = 'Confirma tu contraseña.';
    else if (pass && pass !== pass2) errores['reg-pass2'] = 'Las contraseñas no coinciden.';
    if (!type) errores['reg-type'] = 'Selecciona tu tipo de usuario.';
    ['reg-name', 'reg-email', 'reg-pass', 'reg-pass2', 'reg-type'].forEach(id => regError(id, errores[id] || ''));
    const primero = Object.keys(errores)[0];
    if (primero) document.getElementById(primero)?.focus();
    return !primero;
}
export async function doRegister() {
    if (!validarRegistro()) return;
    const name = document.getElementById('reg-name').value.trim(), email = document.getElementById('reg-email').value.trim(), pass = document.getElementById('reg-pass').value, pass2 = document.getElementById('reg-pass2').value, type = document.getElementById('reg-type').value;
    if (pass !== pass2) { showToast('Las contraseñas no coinciden'); return; }
    if (!USER_TYPES.includes(type)) { showToast('Selecciona un tipo de usuario válido'); return; }
    const btn = document.querySelector('.auth-card button[type="submit"]');
    if (btn) { btn.disabled = true; btn.textContent = 'CREANDO CUENTA...'; }
    try {
        const u = await apiRegistro(name, email, pass, type);
        state.user = { id: u.id, name: u.nombre, email: u.correo, type: u.tipo, token: u.token };
        await cargarActividad();
        confirmModal('Cuenta creada', 'Tu cuenta se creó correctamente y ya iniciaste sesión.', `<button class="btn btn-green" onclick="closeModal();go('dashboard')">Continuar</button>`);
    } catch (error) {
        showToast(error.message, 'error');
        if (btn) { btn.disabled = false; btn.textContent = 'CREAR CUENTA'; }
    }
}
export function logout() { resetMentyBot(); resetAssistant(); state.user = null; state.evaluations = []; loadFavoritesForCurrentUser(); save(); showToast('Sesión cerrada'); setTimeout(() => go('inicio'), 300); }

// Aviso del registro
export function showTypeHint(type){
  const box=document.getElementById('reg-type-hint');if(!box)return;
  if(!USER_TYPES.includes(type)){box.hidden=true;box.innerHTML='';return;}
  const topics=Object.keys(TOPIC_AUDIENCE).filter(k=>TOPIC_AUDIENCE[k].includes(type)).map(k=>TOPIC_LABELS[k]);
  box.hidden=false;
  box.innerHTML=`<strong>Como ${type} tendrás:</strong><ul><li>Toda la información sobre neurodivergencia.</li><li>Guías prácticas y autoevaluaciones de Autismo y TDAH sobre: ${topics.join(', ')}.</li></ul>`;
}
