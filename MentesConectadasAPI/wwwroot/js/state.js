// ===== ESTADO Y SESIÓN =====

import { STORAGE_KEYS as K, normalizeUserType } from './config.js';
import { apiGuardarVista, apiGuardarDonacion } from './api.js';

function read(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    return raw === null ? fallback : JSON.parse(raw);
  } catch (e) {
    return fallback; 
  }
}


function readSession(key, fallback) {
    try {
        const raw = sessionStorage.getItem(key);
        return raw === null ? fallback : JSON.parse(raw);
    } catch (e) {
        return fallback;
    }
}
try { localStorage.removeItem('mc_user'); localStorage.removeItem('mc_registered_user'); } catch (e) { }
try {
    if (!localStorage.getItem('mc_limpieza_4b')) {
        ['mc_favorites', 'mc_favorites_by_user', 'mc_evaluations', 'mc_ratings', 'mc_comments'].forEach(k => localStorage.removeItem(k));
        localStorage.setItem('mc_limpieza_4b', '1');
    }
} catch (e) { }

const storedUser = readSession(K.user, null);
const favoritesByUser = read(K.favoritesByUser, {});
const legacyFavorites = read(K.favorites, []); 


function favoritesFor(user) {
  if (!user) return [];
  if (Array.isArray(favoritesByUser[user.email])) return favoritesByUser[user.email];
  return Object.keys(favoritesByUser).length === 0 && Array.isArray(legacyFavorites) ? [...legacyFavorites] : [];
}

export const state = {
  user: storedUser ? { ...storedUser, type: normalizeUserType(storedUser.type) } : null,
  favorites: favoritesFor(storedUser),
  evaluations: read(K.evaluations, []),
  ratings: read(K.ratings, {}),
  views: read(K.views, {}),
  userLog: read(K.userLog, {}),
  guideOverrides: read(K.guideOverrides, {}),
  guideDeleted: read(K.guideDeleted, []),
  comments: read(K.comments, []),
  donations: read(K.donations, []),
  assistantLog: read(K.assistantLog, []),
  route: location.hash.replace('#', '') || 'inicio',
  selectedNeuro: null,
  selectedGuide: null,
  evalIndex: 0,
  evalAnswers: [],
  evalGuideId: null,
  evalScore: 0
};

export function save() {
    try {
        if (state.user) sessionStorage.setItem(K.user, JSON.stringify(state.user));
        else sessionStorage.removeItem(K.user);
    } catch (e) { }
  if (state.user) favoritesByUser[state.user.email] = state.favorites;
  localStorage.setItem(K.favoritesByUser, JSON.stringify(favoritesByUser));
  localStorage.setItem(K.favorites, JSON.stringify(state.favorites));
  localStorage.setItem(K.evaluations, JSON.stringify(state.evaluations));
  localStorage.setItem(K.ratings, JSON.stringify(state.ratings));
  localStorage.setItem(K.views, JSON.stringify(state.views));
  localStorage.setItem(K.userLog, JSON.stringify(state.userLog));
  localStorage.setItem(K.guideOverrides, JSON.stringify(state.guideOverrides));
  localStorage.setItem(K.guideDeleted, JSON.stringify(state.guideDeleted));
  localStorage.setItem(K.comments, JSON.stringify(state.comments));
  localStorage.setItem(K.donations, JSON.stringify(state.donations));
  localStorage.setItem(K.assistantLog, JSON.stringify(state.assistantLog));
}


export function loadFavoritesForCurrentUser() {
  state.favorites = favoritesFor(state.user);
}


export function getAllFavorites() {
  if (state.user) favoritesByUser[state.user.email] = state.favorites;
  return favoritesByUser;
}


export function logUser(user) {
  if (!user || !user.email) return;
  const prev = state.userLog[user.email];
  state.userLog[user.email] = { name: user.name, type: user.type, first: prev?.first || new Date().toISOString(), last: new Date().toISOString() };
}


export function recordView(guideId) {
  if (!state.user) return;
  apiGuardarVista(state.user.token, guideId); 
}


export function getSavedTheme() {
  return read(K.theme, 'dark') === 'light' ? 'light' : 'dark';
}
export function saveTheme(theme) {
  try { localStorage.setItem(K.theme, JSON.stringify(theme)); } catch (e) { }
}


const newId = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 6);


export async function logDonation(amount, custom) {
  await apiGuardarDonacion(state.user?.token, amount, custom);
}


export function logAssistantQuery(q, norm, hits) {
  state.assistantLog.push({ id: newId(), q: q.slice(0, 120), norm, hits, user: state.user?.email || '', date: new Date().toISOString() });
  if (state.assistantLog.length > 2000) state.assistantLog = state.assistantLog.slice(-2000);
  save();
}
