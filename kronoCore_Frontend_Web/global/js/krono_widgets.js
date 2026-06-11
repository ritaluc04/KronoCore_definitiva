/*
 * krono_widgets.js — Funciones que generan HTML de widgets reutilizables.
 * 
 * WIDGETS DISPONIBLES:
 * - htmlKronoCard(content, paddingZero) → Tarjeta base Krono
 * - htmlMetricCard({titulo, valor, delta, icon, color}) → Tarjeta de KPI
 * - htmlStatusChip(label, color, icon) → Chip de estado/pendiente
 * - htmlAvatarCircle(name, size) → Avatar circular con iniciales
 * - htmlLoadingView() → Indicador de carga
 * - htmlEmptyView({icon, title, message, actionLabel, onActionId}) → Lista vacía
 * - htmlErrorView(message, retryId) → Vista de error con reintento
 * 
 * HELPERS:
 * - colorToAlpha(color, alpha) → Convierte var CSS a rgba
 * - avatarHue(name) → Hue determinista desde nombre para colorear avatar
 */

/** Convierte un color del design system (var CSS) a rgba con la opacidad indicada */
function colorToAlpha(color, alpha) {
  const map = {
    'var(--krono-primary)': [29, 78, 216],
    'var(--krono-accent)': [6, 182, 212],
    'var(--krono-warning)': [245, 158, 11],
    'var(--krono-success)': [22, 163, 74],
    'var(--krono-danger)': [220, 38, 38],
    'var(--krono-muted)': [100, 116, 139],
  };
  const rgb = map[color] || [29, 78, 216];
  return `rgba(${rgb[0]}, ${rgb[1]}, ${rgb[2]}, ${alpha})`;
}

/** Tarjeta base Krono con padding opcional cero */
function htmlKronoCard(content, paddingZero = false) {
  const pz = paddingZero ? ' KronoCard--padding-zero' : '';
  return '<div class="KronoCard' + pz + '">' + content + '</div>';
}

/** Tarjeta de KPI con icono, valor principal y variación (delta) coloreada */
function htmlMetricCard({ titulo, valor, delta, icon, color = 'var(--krono-primary)' }) {
  const positivo = !String(delta).startsWith('-');
  const deltaColor = positivo ? 'var(--krono-success)' : 'var(--krono-danger)';
  const deltaBg = positivo ? 'rgba(22,163,74,0.12)' : 'rgba(220,38,38,0.12)';
  return (
    '<div class="MetricCard KronoCard">' +
    '<div class="d-flex flex-row align-items-start">' +
    '<div class="MetricCard-iconWrap" style="background:' + colorToAlpha(color, 0.12) + '"><span class="material-symbols-outlined" style="color:' + color + ';font-size:20px">' + icon + '</span></div>' +
    '<div class="flex-fill"></div>' +
    '<span class="MetricCard-delta" style="background:' + deltaBg + ';color:' + deltaColor + '">' + delta + '</span></div>' +
    '<div class="MetricCard-titulo">' + titulo + '</div>' +
    '<div class="MetricCard-valor">' + valor + '</div></div>'
  );
}

/** Chip de estado compacto con fondo y borde semitransparentes */
function htmlStatusChip(label, color, icon = null) {
  const bg = colorToAlpha(color, 0.12);
  const border = colorToAlpha(color, 0.25);
  const iconHtml = icon ? '<span class="material-symbols-outlined">' + icon + '</span>' : '';
  return '<span class="StatusChip" style="background:' + bg + ';color:' + color + ';border-color:' + border + '">' + iconHtml + label + '</span>';
}

/** Hue determinista (0–359) a partir del nombre para colorear el avatar */
function avatarHue(name) { return [...name].reduce((a, c) => a + c.charCodeAt(0), 0) % 360; }

/** Círculo con iniciales del nombre y color de fondo HSL derivado del nombre */
function htmlAvatarCircle(name, size = 36) {
  const parts = name.trim().split(/\s+/);
  const initials = parts.length > 1 ? parts[0][0] + parts[parts.length - 1][0] : parts[0]?.[0] || '?';
  const hue = avatarHue(name);
  const bg = 'hsl(' + hue + ', 35%, 55%)';
  return '<span class="AvatarCircle" style="width:' + size + 'px;height:' + size + 'px;background:' + bg + ';font-size:' + (size * 0.38) + 'px">' + initials.toUpperCase() + '</span>';
}

/** Vista centrada con spinner de Bootstrap mientras se cargan datos */
function htmlLoadingView() {
  return '<div class="LoadingView"><div class="spinner-border" role="status"><span class="visually-hidden">Cargando...</span></div></div>';
}

/** Vista de lista vacía con icono, mensaje y botón de acción opcional */
function htmlEmptyView({ icon, title, message, actionLabel, onActionId }) {
  let btn = '';
  if (actionLabel && onActionId) btn = '<button type="button" class="btn btn-krono-primary mt-4" id="' + onActionId + '"><span class="material-symbols-outlined me-1" style="font-size:18px;vertical-align:middle">add</span>' + actionLabel + '</button>';
  return '<div class="EmptyView"><div class="EmptyView-iconWrap"><span class="material-symbols-outlined">' + icon + '</span></div><h5 class="krono-title-large mt-3">' + title + '</h5><p class="text-muted mb-0">' + message + '</p>' + btn + '</div>';
}

/** Vista de error con mensaje y botón de reintentar opcional */
function htmlErrorView(message, retryId) {
  let retry = '';
  if (retryId) retry = '<button type="button" class="btn btn-krono-outlined mt-3" id="' + retryId + '"><span class="material-symbols-outlined me-1" style="font-size:18px">refresh</span>Reintentar</button>';
  return '<div class="ErrorView"><span class="material-symbols-outlined">error_outline</span><p class="mt-3 mb-0">' + message + '</p>' + retry + '</div>';
}