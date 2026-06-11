/*
 * app_layout.js — Shell de la aplicación (escritorio y móvil).
 * 
 * RESPONSABILIDADES:
 * - Inicializar el shell responsive (desktop sidebar / mobile bottom nav)
 * - Filtrado del menú por rol de usuario (RBAC)
 * - Guards de ruta (redirección a login si no autenticado)
 * - Breadcrumbs dinámicos según ruta actual
 * - Sistema de notificaciones (stock bajo)
 * - Modo oscuro persistente (localStorage)
 * 
 * BREAKPOINT RESPONSIVE: 900px
 * - ≥ 900px: DesktopShell (sidebar izquierda + cabecera)
 * - < 900px: MobileShell (AppBar + bottom navigation)
 */

// Grupos de roles para filtrar ítems del menú
const _allStaff = [UserRole.admin, UserRole.jefe, UserRole.empleado];
const _admin = [UserRole.admin];
const _adminJefe = [UserRole.admin, UserRole.jefe];

const _cliente = [UserRole.cliente];

// Ítems del menú: etiqueta, icono Material, ruta lógica y roles permitidos
const navItems = [
  { label: 'Dashboard', icon: 'dashboard', route: '/dashboard', roles: _allStaff },
  { label: 'Clientes', icon: 'group', route: '/clientes', roles: _allStaff },
  { label: 'Citas', icon: 'event', route: '/citas', roles: _allStaff },
  { label: 'Inventario', icon: 'inventory_2', route: '/inventario', roles: _adminJefe },
  { label: 'Facturas', icon: 'description', route: '/facturas', roles: _adminJefe },
  { label: 'Gastos', icon: 'receipt_long', route: '/gastos', roles: _adminJefe },
  { label: 'Ventas', icon: 'point_of_sale', route: '/ventas', roles: _allStaff },
  { label: 'Board', icon: 'view_kanban', route: '/board', roles: _allStaff },
  { label: 'Informes', icon: 'bar_chart', route: '/reportes', roles: _allStaff },
  { label: 'Ajustes', icon: 'settings', route: '/ajustes', roles: [..._allStaff, UserRole.cliente] },
  { label: 'Usuarios', icon: 'admin_panel_settings', route: '/ajustes/usuarios', roles: _adminJefe },
  { label: 'Mis citas', icon: 'event', route: '/area-cliente', roles: _cliente },
  { label: 'Solicitar cita', icon: 'add_circle', route: '/area-cliente/solicitar', roles: _cliente },
];

/** Mapa de rutas lógicas a archivos HTML físicos */
const ROUTE_TO_PAGE = {
  '/dashboard': '../dashboard/dashboard.html',
  '/clientes': '../clientes/clientes.html',
  '/clientes/detalle': '../cliente_detalle/cliente_detalle.html',
  '/citas': '../citas/citas.html',
  '/inventario': '../inventario/inventario.html',
  '/ventas': '../ventas/ventas.html',
  '/board': '../board/board.html',
  '/reportes': '../reportes/reportes.html',
  '/ajustes': '../ajustes/ajustes.html',
  '/ajustes/usuarios': '../usuarios/usuarios.html',
  '/facturas': '../facturas/facturas.html',
  '/gastos': '../gastos/gastos.html',
  '/area-cliente': '../area_clientes/area_clientes.html',
  '/area-cliente/solicitar': '../solicitar_cita/solicitar_cita.html',
};

function getCurrentRoute() { return document.body.dataset.route || window.location.pathname; }
function isWide() { return window.matchMedia('(min-width: 900px)').matches; }
function prettyCrumb(s) { return s.charAt(0).toUpperCase() + s.slice(1); }

/** Guard de ruta: redirige a login si no hay sesión o según rol */
function guardAuth() {
  const route = getCurrentRoute();
  const auth = SessionController.instance.isAuth;
  if (!auth && route !== '/login') { window.location.href = '../login/login.html'; return false; }
  if (auth && route === '/login') {
    const rol = SessionController.instance.user.rol;
    window.location.href = rol === UserRole.cliente ? '../area_clientes/area_clientes.html' : '../dashboard/dashboard.html';
    return false;
  }
  if (auth && SessionController.instance.user.rol === UserRole.cliente && route !== '/area-cliente' && route !== '/area-cliente/solicitar' && route !== '/ajustes') {
    window.location.href = '../area_clientes/area_clientes.html'; return false;
  }
  return true;
}

/** Renderiza el shell según el ancho de pantalla (desktop o mobile) */
function renderAppShell(contentEl) {
  if (!guardAuth()) return;
  const user = SessionController.instance.user;
  if (!user) return;
  const currentRoute = getCurrentRoute();
  const wide = isWide();
  if (wide) { contentEl.innerHTML = buildDesktopShell(currentRoute, user); bindDesktopEvents(); }
  else { contentEl.innerHTML = buildMobileShell(currentRoute, user); bindMobileEvents(currentRoute, user); }
}

// Variables globales para caché de notificaciones de stock
window.kronoStockNotificationsLoaded = window.kronoStockNotificationsLoaded ?? false;
window.kronoStockNotifications = window.kronoStockNotifications || [];
function getStockNotifications() { return window.kronoStockNotificationsLoaded === false ? null : window.kronoStockNotifications || []; }

/** Carga notificaciones de stock bajo desde la API */
async function refreshStockNotifications() {
  const mount = document.getElementById('krono-notifications-mount');
  window.kronoStockNotificationsLoaded = false;
  if (mount) mount.innerHTML = buildNotificationsDropdown();
  try {
    const productos = await ApiClient.get('/productos');
    window.kronoStockNotifications = (productos || []).filter((p) => (p.stock || 0) <= (p.stockMin || 0)).map((p, idx) => ({
      id: `stock-${p.id}-${idx}`, titulo: `Stock bajo: ${p.nombre || 'Producto'}`,
      mensaje: `El producto "${p.nombre || 'sin nombre'}" tiene ${p.stock || 0} unidades y el mínimo es ${p.stockMin || 0}.`,
      fecha: new Date(), leida: false
    }));
  } catch (e) { window.kronoStockNotifications = []; console.error('Error cargando notificaciones de stock:', e); }
  finally { window.kronoStockNotificationsLoaded = true; if (mount) mount.innerHTML = buildNotificationsDropdown(); }
}

/** Construye el layout de escritorio: sidebar + header + breadcrumbs */
function buildDesktopShell(currentRoute, user) {
  const visible = navItems.filter((n) => n.roles.includes(user.rol));
  const crumbs = currentRoute.split('/').filter((s) => s);
  const sidebarItems = visible.map((item) => {
    const active = currentRoute.startsWith(item.route);
    return `<div class="_SidebarItem${active ? ' _SidebarItem--active' : ''}"><a class="_SidebarItem-link" href="${ROUTE_TO_PAGE[item.route] || '#'}"><span class="material-symbols-outlined">${item.icon}</span>${item.label}</a></div>`;
  }).join('');
  const breadcrumb = crumbs.map((c, i) => {
    const sep = i > 0 ? '<span class="material-symbols-outlined mx-1" style="font-size:16px;color:var(--krono-muted)">chevron_right</span>' : '';
    const style = i === crumbs.length - 1 ? 'color:var(--krono-foreground);font-weight:600' : 'color:var(--krono-muted);font-weight:400';
    return sep + `<span style="${style}">${prettyCrumb(c)}</span>`;
  }).join('');
  return `
    <div class="AppShell--desktop d-flex flex-row min-vh-100">
      <aside class="AppShell-sidebar d-flex flex-column">
        <div class="AppShell-sidebar-brand d-flex flex-row align-items-center">
          <div class="AppShell-sidebar-logo"><span class="material-symbols-outlined">schedule</span></div><span class="AppShell-sidebar-title ms-2">KronoCore</span></div>
        <nav class="AppShell-sidebar-nav d-flex flex-column">${sidebarItems}</nav><hr class="krono-divider m-0" />
        <div class="AppShell-sidebar-logout"><button type="button" class="btn btn-link text-decoration-none w-100 text-start text-danger" id="btnLogout"><span class="material-symbols-outlined me-2" style="font-size:20px">logout</span>Cerrar sesión</button></div>
      </aside><hr class="krono-divider m-0" style="width:1px;height:auto" />
      <main class="AppShell-main d-flex flex-column flex-fill">
        <header class="_DesktopHeader d-flex flex-row align-items-center">
          <div class="d-flex flex-row align-items-center">${breadcrumb}</div><div class="flex-fill"></div>
          <div class="_DesktopHeader-search"><input type="search" class="form-control krono-form-control" placeholder="Buscar  ⌘K" /></div>
          <div id="krono-notifications-mount">${buildNotificationsDropdown()}</div>
          <div class="d-flex flex-row align-items-center ms-2"><span class="_DesktopHeader-avatar rounded-circle d-inline-flex align-items-center justify-content-center">${user.nombre[0]}</span><div class="d-flex flex-column ms-2"><span class="_DesktopHeader-userName">${user.nombre}</span><span class="_DesktopHeader-userRol">${UserRoleLabel[user.rol]}</span></div></div>
        </header><hr class="krono-divider m-0" /><div class="AppShell-main-content flex-fill" id="shellPageContent"></div>
      </main></div>`;
}

/** Construye el layout móvil: AppBar + bottom navigation */
function buildMobileShell(currentRoute, user) {
  const isCliente = user.rol === UserRole.cliente;
  const tabs = isCliente ? [
    { label: 'Mis citas', icon: 'event', route: '/area-cliente' },
    { label: 'Solicitar', icon: 'add_circle', route: '/area-cliente/solicitar' },
    { label: 'Ajustes', icon: 'settings', route: '/ajustes' }
  ] : [
    { label: 'Dashboard', icon: 'dashboard', route: '/dashboard' },
    { label: 'Citas', icon: 'event', route: '/citas' },
    { label: 'TPV', icon: 'point_of_sale', route: '/ventas' },
    { label: 'Board', icon: 'view_kanban', route: '/board' },
    { label: 'Informes', icon: 'bar_chart', route: '/reportes' },
    { label: 'Más', icon: 'menu', route: '__more' }
  ];
  let activeIdx = tabs.findIndex((t) => currentRoute.startsWith(t.route)); if (activeIdx < 0) activeIdx = 0;
  const title = navItems.find((n) => currentRoute.startsWith(n.route))?.label || tabs[activeIdx]?.label || 'KronoCore';
  const navHtml = tabs.map((t, i) => {
    const active = i === activeIdx;
    if (t.route === '__more') return `<button type="button" class="_MobileShell-bottomNav-item${active ? ' _MobileShell-bottomNav-item--active' : ''}" data-more="1"><span class="material-symbols-outlined">${t.icon}</span>${t.label}</button>`;
    return `<a href="${ROUTE_TO_PAGE[t.route]}" class="_MobileShell-bottomNav-item${active ? ' _MobileShell-bottomNav-item--active' : ''}"><span class="material-symbols-outlined">${t.icon}</span>${t.label}</a>`;
  }).join('');
  return `<div class="_MobileShell min-vh-100 d-flex flex-column"><nav class="navbar px-3"><span class="navbar-brand mb-0 h6">${title}</span><div id="krono-notifications-mount">${buildNotificationsDropdown()}</div></nav><div class="_MobileShell-body flex-fill" id="shellPageContent"></div><nav class="_MobileShell-bottomNav">${navHtml}</nav></div>`;
}

/** Dropdown de notificaciones con badge */
function buildNotificationsDropdown() {
  const notis = getStockNotifications(); const loading = notis === null; let items = '';
  if (loading) items = '<li class="px-3 py-2 text-muted">Cargando notificaciones...</li>';
  else if (notis.length === 0) items = '<li class="px-3 py-2 text-muted">No hay alertas de stock.</li>';
  else items = notis.map(n => {
    const time = n.fecha.getHours().toString().padStart(2, '0') + ':' + n.fecha.getMinutes().toString().padStart(2, '0');
    return `<li><a class="dropdown-item d-flex align-items-start py-2" href="#"><div class="me-3 mt-1" style="color: ${n.leida ? 'var(--krono-muted)' : 'var(--krono-primary)'}"><span class="material-symbols-outlined" style="font-size: 20px;">notifications</span></div><div class="flex-fill"><div class="d-flex justify-content-between align-items-center"><strong style="font-size: 13px; font-weight: ${n.leida ? 'normal' : 'bold'}">${n.titulo}</strong><small class="text-muted" style="font-size: 11px;">${time}</small></div><div style="font-size: 12px; white-space: normal; color: var(--krono-foreground);">${n.mensaje}</div></div></a></li>`;
  }).join('');
  const badgeHtml = !loading && notis.length > 0 ? `<span class="position-absolute top-25 start-75 translate-middle badge rounded-pill bg-danger">${notis.length}</span>` : '';
  return `<div class="dropdown ms-3"><button class="btn btn-link text-muted p-1 position-relative" type="button" data-bs-toggle="dropdown" aria-expanded="false"><span class="material-symbols-outlined">notifications</span>${badgeHtml}</button><ul class="dropdown-menu dropdown-menu-end shadow-sm" style="width: 300px; max-height: 400px; overflow-y: auto;"><li><h6 class="dropdown-header">Notificaciones</h6></li>${items}</ul></div>`;
}

function bindDesktopEvents() { document.getElementById('btnLogout')?.addEventListener('click', () => { SessionController.instance.logout(); window.location.href = '../login/login.html'; }); }

function bindMobileEvents(currentRoute, user) { document.querySelector('[data-more="1"]')?.addEventListener('click', () => showMoreSheet(user)); }

/** Modal inferior con enlaces del menú no visibles en la barra móvil */
function showMoreSheet(user) {
  const extras = navItems.filter((n) => n.roles.includes(user.rol) && !['/dashboard', '/citas', '/ventas', '/board', '/reportes'].includes(n.route));
  const modal = document.createElement('div'); modal.className = 'modal fade';
  modal.innerHTML = `<div class="modal-dialog modal-dialog-centered modal-fullscreen-sm-down"><div class="modal-content _MoreSheet border-0 rounded-top"><div class="modal-body p-0"><div class="list-group list-group-flush">${extras.map((item) => `<a href="${ROUTE_TO_PAGE[item.route]}" class="list-group-item list-group-item-action d-flex align-items-center"><span class="material-symbols-outlined me-3">${item.icon}</span>${item.label}</a>`).join('')}<hr class="krono-divider" /><button type="button" class="list-group-item list-group-item-action text-danger" id="moreLogout"><span class="material-symbols-outlined me-3">logout</span>Cerrar sesión</button></div></div></div></div>`;
  document.body.appendChild(modal); const bsModal = new bootstrap.Modal(modal); bsModal.show();
  modal.querySelector('#moreLogout')?.addEventListener('click', () => { bsModal.hide(); SessionController.instance.logout(); window.location.href = '../login/login.html'; });
  modal.addEventListener('hidden.bs.modal', () => modal.remove());
}

/** Punto de entrada: tema oscuro, render del shell y traslado de #page-content */
function initAppShell() {
  if (localStorage.getItem('krono-dark-mode') === 'true') document.body.classList.add('dark-theme');
  else document.body.classList.remove('dark-theme');
  const mount = document.getElementById('app-shell-mount');
  const pageContent = document.getElementById('page-content');
  if (!mount || !pageContent) return;
  renderAppShell(mount); refreshStockNotifications();
  const target = document.getElementById('shellPageContent');
  if (target) { while (pageContent.firstChild) target.appendChild(pageContent.firstChild); pageContent.remove(); }
}