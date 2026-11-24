// ===== AVISO DE CONEXIÓN =====
import { showToast } from './ui.js';

// ----- Sin conexión a internet -----
let avisoSinConexion = null;
let tiempoAviso = null;

function quitarAviso() {
    clearTimeout(tiempoAviso);
    tiempoAviso = null;
    if (avisoSinConexion) { avisoSinConexion.remove(); avisoSinConexion = null; }
}

function mostrarSinConexion() {
    quitarAviso();
    avisoSinConexion = document.createElement('div');
    avisoSinConexion.id = 'offline-notice';
    avisoSinConexion.setAttribute('role', 'alert');
    avisoSinConexion.innerHTML = '<strong>Se perdió la conexión a internet.</strong><span>Puedes seguir viendo lo que ya cargó. Iniciar sesión, guardar o consultar datos nuevos no funcionará hasta que regrese.</span>';
    avisoSinConexion.addEventListener('click', quitarAviso);
    document.body.appendChild(avisoSinConexion);
    tiempoAviso = setTimeout(quitarAviso, 6000);
}

// ----- Barra de carga -----
let pendientes = 0;
let espera = null;
let barraCarga = null;

function actualizarBarra() {
    if (pendientes > 0) {
        if (!espera && !barraCarga) {
            espera = setTimeout(() => {
                espera = null;
                if (pendientes > 0 && !barraCarga) {
                    barraCarga = document.createElement('div');
                    barraCarga.id = 'loading-bar';
                    barraCarga.setAttribute('role', 'progressbar');
                    barraCarga.setAttribute('aria-label', 'Cargando');
                    document.body.appendChild(barraCarga);
                }
            }, 250);
        }
    } else {
        clearTimeout(espera);
        espera = null;
        if (barraCarga) { barraCarga.remove(); barraCarga = null; }
    }
}

export function initConexion() {
    if (!navigator.onLine) mostrarSinConexion();
    window.addEventListener('offline', mostrarSinConexion);
    window.addEventListener('online', () => { quitarAviso(); showToast('Conexión restablecida'); });

    const fetchOriginal = window.fetch.bind(window);
    window.fetch = async (...args) => {
        const url = typeof args[0] === 'string' ? args[0] : (args[0]?.url || '');
        const esApi = url.includes('/api/');
        if (esApi) { pendientes++; actualizarBarra(); }
        try {
            return await fetchOriginal(...args);
        } finally {
            if (esApi) { pendientes--; actualizarBarra(); }
        }
    };
}