// ===== PAGINADO =====

const vistas = {};

export function vista(clave, inicial = {}) {
  if (!vistas[clave]) vistas[clave] = { pagina: 1, ...inicial };
  return vistas[clave];
}


const familia = (ruta) => {
  const base = String(ruta).split(':')[0];
  return base === 'resultado' ? 'evaluacion' : base;
};
export function cambioDeRuta(desde, hasta) {
  if (familia(desde) === familia(hasta)) return;
  for (const clave of Object.keys(vistas)) delete vistas[clave];
}

export function paginar(lista, pagina, tamano) {
  const total = lista.length;
  const paginas = Math.max(1, Math.ceil(total / tamano));
  const actual = Math.min(Math.max(1, Number(pagina) || 1), paginas);
  return { items: lista.slice((actual - 1) * tamano, actual * tamano), actual, paginas, total };
}

function numerosVisibles(actual, paginas) {
  if (paginas <= 7) return Array.from({ length: paginas }, (_, i) => i + 1);
  const set = new Set([1, paginas, actual - 1, actual, actual + 1]);
  const lista = [...set].filter((n) => n >= 1 && n <= paginas).sort((a, b) => a - b);
  const salida = [];
  lista.forEach((n, i) => {
    if (i > 0 && n - lista[i - 1] > 1) salida.push('…');
    salida.push(n);
  });
  return salida;
}

export function pagerHTML({ actual, paginas, total }, funcion, tipo) {
  if (paginas <= 1) return '';
  const etiqueta = tipo === 'guia' ? 'Paginación de guías' : 'Paginación de autoevaluaciones';
  const nombre = tipo === 'guia'
    ? `${total} ${total === 1 ? 'guía' : 'guías'}`
    : `${total} ${total === 1 ? 'autoevaluación' : 'autoevaluaciones'}`;
  const numeros = numerosVisibles(actual, paginas).map((n) => (n === '…'
    ? '<span class="pager-gap" aria-hidden="true">…</span>'
    : `<button type="button" class="pager-num" onclick="${funcion}(${n})" aria-label="Ir a la página ${n}"${n === actual ? ' aria-current="page"' : ''}>${n}</button>`)).join('');
  return `<nav class="pager" aria-label="${etiqueta}">`
    + `<button type="button" class="btn btn-outline btn-small" onclick="${funcion}(${actual - 1})" aria-label="Página anterior"${actual === 1 ? ' disabled' : ''}>Anterior</button>`
    + `<div class="pager-pages">${numeros}</div>`
    + `<button type="button" class="btn btn-outline btn-small" onclick="${funcion}(${actual + 1})" aria-label="Página siguiente"${actual === paginas ? ' disabled' : ''}>Siguiente</button>`
    + `<span class="pager-info"><span>Página ${actual} de ${paginas}</span> · <span>${nombre}</span></span>`
    + '</nav>';
}

export function subirALista(idLista) {
  document.getElementById(idLista)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
}
