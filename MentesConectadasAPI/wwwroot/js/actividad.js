// ===== ACTIVIDAD DEL USUARIO: CALIFICACIONES Y COMENTARIOS =====

import { state, save } from './state.js';
import { isAdmin } from './config.js';
import { apiListaFavoritos, apiListaCalificaciones, apiListaComentarios, apiListaResultados } from './api.js';

// Calificaciones y comentarios 
export async function cargarActividad() {
    const token = state.user?.token;
    if (!token) return;

    try {
        const admin = isAdmin(state.user);
        const [califs, comentarios, favoritos, resultados] = await Promise.all([
            apiListaCalificaciones(token),
            apiListaComentarios(token),
            admin ? [] : apiListaFavoritos(token),
            admin ? [] : apiListaResultados(token)
        ]);

        const ratings = {};
        califs.forEach(c => {
            const id = String(c.idGuia);
            if (!ratings[id]) ratings[id] = [];
            ratings[id].push({ rating: c.estrellas, mine: c.esMia, date: c.fecha });
        });
        state.ratings = ratings;

        state.comments = comentarios.map(c => ({
            id: String(c.idComentario),
            guideId: String(c.idGuia),
            name: c.nombre,
            type: c.tipoUsuario || '',
            text: c.texto,
            date: c.fecha,
            hidden: false,
            rating: c.estrellas,
            mine: c.esMio
        }));

        if (!admin) {
            state.favorites = favoritos.map(String);
            state.evaluations = resultados.map(r => ({
                id: r.idResultado,
                user: state.user.email,
                guideId: String(r.idGuia),
                guideTitle: r.titulo,
                score: r.aciertos,
                total: r.total,
                date: new Date(r.fecha).toLocaleString('es-MX')
            }));
        }
        save();
    } catch (e) { }
}