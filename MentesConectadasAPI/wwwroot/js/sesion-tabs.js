// ===== SESIÓN COMPARTIDA ENTRE PESTAÑAS =====

const NOMBRE_CANAL = 'mc-sesion';
const CLAVE_PULSO = 'mc_sesion_viva';
const VIGENCIA_PULSO_MS = 60000;   
const INTERVALO_PULSO_MS = 5000;
const ESPERA_MS = 250;

export function crearSesionCompartida({
  obtenerUsuario,
  aplicarUsuario,
  almacen,
  Canal = globalThis.BroadcastChannel,
  ahora = Date.now,
  esperaMs = ESPERA_MS
}) {
  let canal = null;
  try { if (Canal) canal = new Canal(NOMBRE_CANAL); } catch (e) { canal = null; }

  const usuarioValido = (u) => u && typeof u === 'object' && typeof u.token === 'string' && u.token.length > 0 && typeof u.email === 'string';

  
  if (canal) {
    canal.addEventListener('message', (e) => {
      const d = e.data;
      const usuario = obtenerUsuario();
      if (d && d.tipo === 'pedir' && typeof d.id === 'string' && usuarioValido(usuario)) {
        canal.postMessage({ tipo: 'sesion', para: d.id, usuario });
      }
    });
  }

  function marcarPulso() {
    try { if (usuarioValido(obtenerUsuario())) almacen.setItem(CLAVE_PULSO, String(ahora())); } catch (e) { }
  }

  function hayPestanaConSesion() {
    try {
      const t = Number(almacen.getItem(CLAVE_PULSO));
      return Number.isFinite(t) && t > 0 && ahora() - t < VIGENCIA_PULSO_MS;
    } catch (e) { return false; }
  }

  
  function adoptar() {
    if (!canal || usuarioValido(obtenerUsuario()) || !hayPestanaConSesion()) return Promise.resolve(false);
    return new Promise((resolve) => {
      const id = Math.random().toString(36).slice(2) + ahora().toString(36);
      let terminado = false;
      const terminar = (resultado) => {
        if (terminado) return;
        terminado = true;
        clearTimeout(temporizador);
        canal.removeEventListener('message', alRecibir);
        resolve(resultado);
      };
      const alRecibir = (e) => {
        const d = e.data;
        if (d && d.tipo === 'sesion' && d.para === id && usuarioValido(d.usuario)) {
          aplicarUsuario(d.usuario);
          marcarPulso();
          terminar(true);
        }
      };
      const temporizador = setTimeout(() => terminar(false), esperaMs);
      canal.addEventListener('message', alRecibir);
      canal.postMessage({ tipo: 'pedir', id });
    });
  }

  
  function iniciarPulso() {
    marcarPulso();
    const intervalo = setInterval(marcarPulso, INTERVALO_PULSO_MS);
    return () => clearInterval(intervalo);
  }

  return { adoptar, iniciarPulso };
}
