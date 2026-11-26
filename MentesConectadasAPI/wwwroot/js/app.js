// ===== PUNTO DE ENTRADA =====
import { state, save, loadFavoritesForCurrentUser } from './state.js';
import { normalizeUserType } from './config.js';
import { crearSesionCompartida } from './sesion-tabs.js';
import { cambioDeRuta } from './paginado.js';
import { cargarCatalogo } from './catalogo.js';
import { go } from './navigation.js';
import { render } from './router.js';
import { closeModal, showToast } from './ui.js';
import { doLogin, doRegister, logout, showTypeHint, regLimpiarError, doOlvide, doRestablecer, regError } from './auth.js';
import { saveProfile } from './profile.js';
import { filterNeuro } from './neuro.js';
import { applyGuideFilters, clearGuideFilters, goGuidePage, openGuide, setGuideRating } from './guides.js';
import { toggleFavorite } from './favorites.js';
import { startEvaluation, cancelEvaluation, selectAnswer, nextQuestion, previousQuestion, finishEvaluation, applyEvalFilters, clearEvalFilters, goEvalPage } from './evaluations.js';
import { runAssistant } from './assistant.js';
import { selectDonationAmount, startDonation, submitDonation, setCustomDonation, blockNonDigits, pasteDigits } from './donations.js';
import { initTheme, toggleTheme } from './theme.js';
import { postComment, deleteMyComment } from './guides.js';
import { adminSetCommentsGuide, adminToggleComment, adminAskDeleteComment, adminDeleteComment, adminToggleDonation, adminAskDeleteDonation, adminDeleteDonation, adminExportDonations } from './admin-extra.js';
import { adminFilterRows, adminToggleHidden, adminEditGuide, adminAskDeleteGuide, adminDeleteGuide, adminAskRestore, adminRestore, adminSaveGuide, adminAskDeleteEvaluation, adminDeleteEvaluation, adminOpenQuestion, adminSaveQuestion, adminAskDeleteQuestion, adminDeleteQuestion, adminSetStats, adminExportExcel, adminOpenEvalSetup, adminSaveEvalSetup } from './admin.js';
import { initLazyVideos } from './videos.js';
import { adminReintentar } from './admin-db.js';
import { apiObtenerPerfil } from './api.js';
import { cargarActividad } from './actividad.js';
import { initConexion } from './conexion.js';
import { initMentyBot } from './mentybot.js';
import { initLang, setLang } from './i18n.js';


document.addEventListener('keydown', e => { if (e.key === 'Escape') closeModal(); });
document.addEventListener('click', e => { if (e.target.classList?.contains('modal-backdrop')) closeModal(); });

Object.assign(window, {
  go, closeModal, doLogin, doRegister, doOlvide, doRestablecer, regError, regLimpiarError, logout, saveProfile, filterNeuro,
  applyGuideFilters, clearGuideFilters, goGuidePage, openGuide, setGuideRating, toggleFavorite,
  applyEvalFilters, clearEvalFilters, goEvalPage,
  startEvaluation, cancelEvaluation, selectAnswer, nextQuestion, previousQuestion, finishEvaluation,
  runAssistant, selectDonationAmount, startDonation, submitDonation, setCustomDonation, blockNonDigits, pasteDigits,
  showTypeHint, toggleTheme,
    adminFilterRows, adminToggleHidden, adminEditGuide, adminAskDeleteGuide, adminDeleteGuide, adminAskRestore, adminRestore, adminSaveGuide,
  adminAskDeleteEvaluation, adminDeleteEvaluation, adminOpenQuestion, adminSaveQuestion, adminAskDeleteQuestion, adminDeleteQuestion,
  adminSetStats, adminExportExcel, adminOpenEvalSetup, adminSaveEvalSetup,
  postComment, deleteMyComment,
  adminSetCommentsGuide, adminToggleComment, adminAskDeleteComment, adminDeleteComment,
  adminToggleDonation, adminAskDeleteDonation, adminDeleteDonation, adminExportDonations,
  adminReintentar, setLang
});


window.addEventListener('hashchange', () => {
  const route = location.hash.replace('#', '') || 'inicio';
  if (route !== state.route) { cambioDeRuta(state.route, route); state.route = route; render(); }
});

initTheme();
initLang(render);
initConexion();
initMentyBot();


const sesionCompartida = crearSesionCompartida({
    obtenerUsuario: () => state.user,
    aplicarUsuario: (u) => { state.user = { ...u, type: normalizeUserType(u.type) }; loadFavoritesForCurrentUser(); save(); },
    almacen: localStorage
});
await sesionCompartida.adoptar();
sesionCompartida.iniciarPulso();

if (state.user?.token) {
    try {
        const p = await apiObtenerPerfil(state.user.token);
        state.user = { ...state.user, name: p.nombre, email: p.correo, type: p.tipo };
        save();
    } catch (e) {
        if (e.numeroError === 401) { state.user = null; loadFavoritesForCurrentUser(); save(); }
    }
}

try { await cargarCatalogo(); } catch (e) { }
await cargarActividad();

window.addEventListener('mc-sesion-vencida', () => {
    if (!state.user) return;
    state.user = null;
    state.evaluations = [];
    loadFavoritesForCurrentUser();
    save();
    showToast('Tu sesión venció. Inicia sesión de nuevo para continuar.', 'error');
    window.go('login');
});
render();



initLazyVideos();

function registerServiceWorker() {
  if ('serviceWorker' in navigator) navigator.serviceWorker.register('./sw.js').catch(() => {});
}
if (document.readyState === 'complete') registerServiceWorker();
else window.addEventListener('load', registerServiceWorker);

// ----- Menú de hamburguesa -----
function cerrarMenuMovil() { document.querySelectorAll('.mobile-nav.open').forEach(m => m.classList.remove('open')); }
document.addEventListener('click', (e) => {
  const abierto = document.querySelector('.mobile-nav.open');
  if (!abierto) return;
  if (e.target.closest('.menu-btn')) return;                
  if (e.target.closest('.mobile-nav') && !e.target.closest('a, button')) return; 
  cerrarMenuMovil();
});
document.addEventListener('keydown', (e) => { if (e.key === 'Escape') cerrarMenuMovil(); });
