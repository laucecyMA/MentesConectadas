// ===== CATÁLOGO DE GUÍAS DESDE LA BASE DE DATOS =====
import { apiListaGuias, apiObtenerGuia } from './api.js';

export const GUIAS = [];
export const catalogo = { cargado: false, error: '' };

const esc = (s = '') => String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' }[c]));
const slug = (s) => String(s).toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

function aGuia(d) {
    const audience = [];
    if (d.paraEstudiante) audience.push('Estudiante');
    if (d.paraDocente) audience.push('Docente');
    return {
        id: String(d.idGuia),
        title: esc(d.titulo),
        category: esc(d.categoria),
        desc: esc(d.descripcion),
        video: d.video || '',
        neuro: d.neurodivergencia,
        neuroTags: [slug(d.neurodivergencia)],
        situationTags: d.situaciones || [],
        steps: (d.recomendaciones || []).map(t => esc(t)),
        avoid: (d.evitar || []).map(t => esc(t)),
        audience,
        hidden: !d.activo, evalId: d.idEvaluacion ?? null,
        questions: (d.preguntas || []).map(p => ({
            id: p.idPregunta,
            text: esc(p.texto),
            options: ['a', 'b', 'c', 'd']
                .filter(k => p['opcion' + k.toUpperCase()])
                .map(k => ({ key: k, text: esc(p['opcion' + k.toUpperCase()]) })),
            correct: p.correcta
        }))
    };
}

export async function cargarCatalogo() {
    try {
        const lista = await apiListaGuias();
        const detalles = await Promise.all(lista.map(g => apiObtenerGuia(g.idGuia)));
        GUIAS.splice(0, GUIAS.length, ...detalles.map(aGuia));
        catalogo.cargado = true;
        catalogo.error = '';
    } catch (e) {
        catalogo.error = e.message || 'No se pudieron consultar las guías.';
        throw e;
    }
}

export async function recargarGuia(id) {
    const guia = aGuia(await apiObtenerGuia(id));
    const i = GUIAS.findIndex(g => g.id === guia.id);
    if (i >= 0) GUIAS[i] = guia; else GUIAS.push(guia);
    return guia;
}