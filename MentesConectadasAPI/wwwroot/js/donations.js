// ===== DONACIONES =====
import { state } from './state.js';
import { API_BASE_URL, DONATION_AMOUNTS, DONATION_CURRENCY, DONATION_MIN, DONATION_MAX, isAdmin } from './config.js';
import { showToast, esc, footer } from './ui.js';
import { header, go } from './navigation.js';
import { dateLocale, isEnglish } from './i18n.js';
import { apiIniciarDonacion } from './api.js';

let selectedAmount = null;
let customText = '';

const isCustom = () => selectedAmount !== null && !DONATION_AMOUNTS.includes(selectedAmount);
const validCustom = (n) => Number.isInteger(n) && n >= DONATION_MIN && n <= DONATION_MAX;

const amountButtons = () => DONATION_AMOUNTS.map(a => `<button type="button" class="donation-amount ${a === selectedAmount ? 'selected' : ''}" role="radio" aria-checked="${a === selectedAmount}" data-amount="${a}" onclick="selectDonationAmount(${a})">$${a}<small>${DONATION_CURRENCY}</small></button>`).join('');

const customAmountBox = () => `<div class="donation-custom ${isCustom() ? 'selected' : ''}"><label for="donation-custom-input">Otra cantidad</label><div class="donation-custom-row"><span aria-hidden="true">$</span><input id="donation-custom-input" class="donation-custom-input" type="text" inputmode="numeric" pattern="[0-9]*" maxlength="6" autocomplete="off" placeholder="Escribe tu aportación" value="${customText}" oninput="setCustomDonation(this)" onkeydown="blockNonDigits(event)" onpaste="pasteDigits(event)"><span class="donation-currency" aria-hidden="true">${DONATION_CURRENCY}</span></div><small class="donation-error" id="donation-custom-error" role="alert"></small></div>`;

const totalText = () => (selectedAmount ? `$${selectedAmount.toLocaleString(dateLocale())} ${DONATION_CURRENCY}` : '—');

// ----- Sección del inicio / Sobre nosotros -----
export function donationSection() {
  return `<section class="donation-section" aria-labelledby="donation-title"><div class="donation-copy"><h2 id="donation-title">Apoya Mentes Conectadas</h2><p>Mentes Conectadas es un proyecto educativo. Si te resulta útil, puedes hacer una pequeña aportación voluntaria para ayudar a mantenerlo y a seguir creando guías.</p></div><div class="donation-options"><div class="donation-amounts" role="radiogroup" aria-label="Cantidad a donar">${amountButtons()}</div>${customAmountBox()}<button type="button" class="btn btn-pink donation-continue" ${selectedAmount ? '' : 'disabled'} onclick="startDonation()">Continuar con la donación</button></div></section>`;
}

// ----- Estado del pago en curso -----
let flow = null;
let lastDonor = { nombre: '', correo: '' };
const POLL_MS = 4000;
const POLL_MAX_MS = 20 * 60 * 1000;

const homeRoute = () => (isAdmin(state.user) ? 'admin' : (state.user ? 'dashboard' : 'inicio'));

// ----- Pantalla donar -----
export function donationForm() {
  const u = state.user && !isAdmin(state.user) ? state.user : null;
  const back = isAdmin(state.user) ? 'admin' : (state.user ? 'sobre-nosotros' : 'inicio');
  if (flow && flow.fase !== 'confirmada' && flow.fase !== 'agotado' && !flow.timer) flow.timer = setTimeout(poll, 300);
  return `${header(Boolean(state.user))}<main class="auth-page"><section class="auth-card donate-card" id="donation-card">${flow ? panelHtml() : formHtml(u, back)}</section></main>${footer()}`;
}

function formHtml(u, back) {
  return `<h1>Haz tu donación</h1><p>Tu aportación es voluntaria y ayuda a mantener Mentes Conectadas. El pago se realiza en la página segura de Mercado Pago.</p>
<form class="form" onsubmit="event.preventDefault();submitDonation()">
<div class="field"><label for="don-name">Nombre completo</label><input id="don-name" required maxlength="100" autocomplete="name" placeholder="Nombre completo" value="${esc(lastDonor.nombre || u?.name || '')}"></div>
<div class="field"><label for="don-email">Correo electrónico</label><input id="don-email" type="email" required maxlength="150" autocomplete="email" placeholder="Correo electrónico" value="${esc(lastDonor.correo || u?.email || '')}"></div>
<div class="field"><label>Cantidad a donar</label><div class="donation-amounts" role="radiogroup" aria-label="Cantidad a donar">${amountButtons()}</div></div>
${customAmountBox()}
<div class="field"><label for="don-msg">Mensaje (opcional)</label><textarea id="don-msg" rows="3" maxlength="200" placeholder="Escribe un mensaje si quieres"></textarea></div>
<div class="donation-total"><span>Total a donar:</span><strong id="donation-total">${totalText()}</strong></div>
<button type="submit" class="btn btn-pink donation-continue" ${selectedAmount ? '' : 'disabled'}>Pagar con Mercado Pago</button>
<small class="donation-note">Mercado Pago se abrirá en una pestaña nueva. Esta página se actualizará sola cuando el pago se acredite. Aquí no guardamos datos de tarjeta.</small>
</form>
<div class="auth-footer"><button type="button" onclick="go('${back}')">VOLVER</button></div>`;
}

function panelHtml() {
  const f = flow;
  const monto = `$${f.monto.toLocaleString(dateLocale())} ${DONATION_CURRENCY}`;
  const recibo = `<dl class="donation-receipt"><div><dt>Donante</dt><dd>${esc(f.nombre)}</dd></div><div><dt>Monto</dt><dd>${monto}</dd></div>${f.idPago ? `<div><dt>Operación</dt><dd>#${esc(f.idPago)}</dd></div>` : ''}<div><dt>Correo electrónico</dt><dd>${esc(f.correo)}</dd></div></dl>`;
  const reabrir = `<a class="btn btn-primary" href="${esc(f.urlPago)}" target="_blank" rel="noopener">Abrir Mercado Pago de nuevo</a>`;
  const cancelar = `<button type="button" class="btn btn-outline" data-donation-act="cancelar">Cancelar</button>`;
  const aviso = f.manual ? `<p class="donation-note">Tu navegador bloqueó la pestaña automática. Presiona «Abrir Mercado Pago de nuevo» para pagar en una pestaña nueva.</p>` : '';

  if (f.fase === 'confirmada') return `<div class="donate-result" id="donation-panel" role="status"><div class="donate-icon ok" aria-hidden="true">✓</div><h1>¡Gracias por tu donación!</h1><p>Tu pago fue aprobado. Tu aportación ayuda a mantener Mentes Conectadas y a seguir creando guías.</p>${recibo}<p class="donation-note">Mercado Pago puede enviar el comprobante a tu correo electrónico.</p><div class="modal-actions"><button type="button" class="btn btn-primary" data-donation-act="inicio">Volver al inicio</button></div></div>`;
  if (f.fase === 'rechazada') return `<div class="donate-result" id="donation-panel" role="status"><div class="donate-icon bad" aria-hidden="true">!</div><h1>No se pudo completar el pago</h1><p>Mercado Pago rechazó el pago. Puedes intentarlo de nuevo en la pestaña de Mercado Pago o con otro medio de pago.</p><div class="modal-actions">${reabrir}${cancelar}</div></div>`;
  if (f.fase === 'agotado') return `<div class="donate-result" id="donation-panel" role="status"><div class="donate-icon" aria-hidden="true">…</div><h1>Todavía no recibimos la confirmación</h1><p>Si ya pagaste, no te preocupes: tu donación se registrará sola en cuanto Mercado Pago la confirme.</p><div class="modal-actions"><button type="button" class="btn btn-primary" data-donation-act="inicio">Volver al inicio</button><button type="button" class="btn btn-outline" data-donation-act="reintentar">Intentar de nuevo</button></div></div>`;
  if (f.fase === 'pendiente') return `<div class="donate-result" id="donation-panel" role="status"><div class="donate-icon" aria-hidden="true">…</div><h1>Tu pago está pendiente</h1><p>Mercado Pago aún no confirma el pago (por ejemplo, si elegiste OXXO o transferencia). Puedes cerrar esta página: cuando se acredite, tu donación quedará confirmada.</p>${recibo}<div class="modal-actions">${reabrir}${cancelar}</div></div>`;
  return `<div class="donate-result" id="donation-panel" role="status"><div class="donation-spinner" aria-hidden="true"></div><h1>Esperando la confirmación de tu pago</h1><p>Completa el pago en la pestaña de Mercado Pago que se abrió. Esta página se actualizará sola cuando el pago se acredite.</p>${recibo}${aviso}<div class="modal-actions">${reabrir}${cancelar}</div></div>`;
}

function showPanel() {
  const card = document.getElementById('donation-card');
  if (card && flow) { card.innerHTML = panelHtml(); card.scrollIntoView({ block: 'start', behavior: 'smooth' }); }
}

function stopPoll() {
  if (flow?.timer) clearTimeout(flow.timer);
  if (flow) flow.timer = null;
}

async function poll() {
  if (!flow) return;
  flow.timer = null;
  if (!document.getElementById('donation-card')) return;
  try {
    const res = await fetch(`${API_BASE_URL}/Donacion/estado?id=${encodeURIComponent(flow.id)}&clave=${encodeURIComponent(flow.clave)}`);
    const data = await res.json().catch(() => ({}));
    const d = data.response;
    if (res.ok && d) {
      const fase = d.estado === 'confirmada' ? 'confirmada'
        : (d.estado === 'rechazada' || d.estado === 'reembolsada') ? 'rechazada'
        : d.estado === 'pendiente' ? 'pendiente' : 'esperando';
      const cambio = fase !== flow.fase || (d.idPago && d.idPago !== flow.idPago);
      flow.fase = fase;
      flow.idPago = d.idPago || flow.idPago;
      if (cambio) showPanel();
      if (fase === 'confirmada') return;
    }
  } catch { }

  if (Date.now() - flow.inicio > POLL_MAX_MS) { flow.fase = 'agotado'; showPanel(); return; }
  flow.timer = setTimeout(poll, POLL_MS);
}

document.addEventListener('click', (e) => {
  const btn = e.target.closest?.('[data-donation-act]');
  if (!btn || !flow) return;
  const act = btn.dataset.donationAct;
  if (act === 'inicio') { stopPoll(); flow = null; selectedAmount = null; customText = ''; go(homeRoute()); }
  else if (act === 'cancelar' || act === 'reintentar') { stopPoll(); flow = null; go('donar'); }
});

function refreshSelection() {
  document.querySelectorAll('.donation-amount').forEach(btn => {
    const active = Number(btn.dataset.amount) === selectedAmount;
    btn.classList.toggle('selected', active);
    btn.setAttribute('aria-checked', String(active));
  });
  document.querySelectorAll('.donation-custom').forEach(box => box.classList.toggle('selected', isCustom()));
  document.querySelectorAll('.donation-continue').forEach(btn => { btn.disabled = !selectedAmount; });
  const total = document.getElementById('donation-total');
  if (total) total.textContent = totalText();
}

export function selectDonationAmount(amount) {
  if (!DONATION_AMOUNTS.includes(amount)) return;
  selectedAmount = amount;
  customText = '';
  document.querySelectorAll('.donation-custom-input').forEach(i => { i.value = ''; });
  document.querySelectorAll('.donation-error').forEach(e => { e.textContent = ''; });
  refreshSelection();
}

export function setCustomDonation(input) {
  const digits = input.value.replace(/\D/g, '').slice(0, 6);
  if (input.value !== digits) input.value = digits;
  customText = digits;
  const n = digits === '' ? NaN : Number(digits);
  const err = document.getElementById('donation-custom-error');
  if (digits === '') { selectedAmount = null; if (err) err.textContent = ''; }
  else if (validCustom(n)) { selectedAmount = n; if (err) err.textContent = ''; }
  else { selectedAmount = null; if (err) err.textContent = n > DONATION_MAX ? `La cantidad máxima es $${DONATION_MAX.toLocaleString(dateLocale())} ${DONATION_CURRENCY}.` : `La cantidad mínima es $${DONATION_MIN} ${DONATION_CURRENCY}.`; }
  refreshSelection();
}

export function blockNonDigits(e) {
  if (e.ctrlKey || e.metaKey || e.altKey || e.key.length > 1) return;
  if (!/^\d$/.test(e.key)) e.preventDefault();
}

export function pasteDigits(e) {
  e.preventDefault();
  const digits = (e.clipboardData?.getData('text') || '').replace(/\D/g, '');
  const input = e.target;
  const start = input.selectionStart ?? input.value.length, end = input.selectionEnd ?? input.value.length;
  input.value = (input.value.slice(0, start) + digits + input.value.slice(end)).slice(0, 6);
  setCustomDonation(input);
}

export function startDonation() {
  if (!selectedAmount) return;
  go('donar');
}

export async function submitDonation() {
  const nombre = document.getElementById('don-name')?.value.trim() || '';
  const correo = document.getElementById('don-email')?.value.trim() || '';
  const mensaje = document.getElementById('don-msg')?.value.trim() || '';
  if (!selectedAmount) { showToast('Elige o escribe una cantidad a donar'); return; }

  const win = window.open('', '_blank');
  if (win) {
    try { win.opener = null; win.document.title = 'Mercado Pago'; win.document.body.innerHTML = '<p style="font-family:sans-serif;padding:24px">Conectando con Mercado Pago…</p>'; } catch { }
  }

  const btn = document.querySelector('.donation-continue');
  if (btn) { btn.disabled = true; btn.textContent = 'Conectando con Mercado Pago...'; }
  try {
    const r = await apiIniciarDonacion(state.user?.token, { nombre, correo, monto: selectedAmount, otraCantidad: isCustom(), mensaje, idioma: isEnglish() ? 'en' : 'es' });
    if (!r?.urlPago || !String(r.urlPago).startsWith('https://')) throw new Error('No se recibió el enlace de pago. Intenta de nuevo.');

    const abierta = Boolean(win && !win.closed);
    console.info('[donación] pestaña nueva:', abierta ? 'abierta' : 'bloqueada por el navegador', '| clave de confirmación:', r.clave ? 'sí' : 'NO (la API no está actualizada)');

    if (!r.clave) {
      if (abierta) win.close();
      showToast('La API no está actualizada: reiníciala para activar la confirmación automática. Se abrirá Mercado Pago en esta pestaña.', 'error');
      setTimeout(() => { window.location.href = r.urlPago; }, 2500);
      return;
    }

    lastDonor = { nombre, correo };
    flow = { fase: 'esperando', id: r.idDonacion, clave: r.clave, urlPago: r.urlPago, nombre, correo, monto: selectedAmount, idPago: '', inicio: Date.now(), timer: null, manual: !abierta };
    if (abierta) win.location.href = r.urlPago;
    showPanel();
    poll();
  } catch (e) {
    if (win && !win.closed) win.close();
    showToast(e.message, 'error');
    if (btn) { btn.textContent = 'Pagar con Mercado Pago'; btn.disabled = !selectedAmount; }
  }
}
