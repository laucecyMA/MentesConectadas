// ===== FAVORITOS, MIS GUÍAS =====
import { state, save } from './state.js';
import { showToast } from './ui.js';
import { refreshView } from './navigation.js';
import { apiAgregarFavorito, apiQuitarFavorito } from './api.js';

export function isFavorite(guideId) {
  return state.favorites.includes(guideId);
}
export async function toggleFavorite(id) {
    if (!state.user) return;
    const activar = !state.favorites.includes(id);
    try {
        if (activar) await apiAgregarFavorito(state.user.token, id); else await apiQuitarFavorito(state.user.token, id);
        state.favorites = activar ? [...state.favorites, id] : state.favorites.filter(x => x !== id);
        save();
        showToast(activar ? 'Guía guardada en Mis guías' : 'Guía quitada de Mis guías');
        if (['guias', 'favoritas', 'perfil'].includes(state.route)) refreshView();
    } catch (error) { showToast(error.message, 'error'); }
}