/**
 * Ajustes — screen_controller.js
 * Construye la pantalla de perfil, seguridad, preferencias y bloque admin.
 */

/**
 * Constructor de la pantalla de Ajustes web.
 * Extrae el usuario de la sesión actual, renderiza los bloques de perfil, seguridad
 * y preferencias. Si el usuario es administrador, añade el bloque de gestión de usuarios.
 */
function initAjustesScreen() {
  const user = SessionController.instance.user;
  const root = document.getElementById('ajustesRoot');
  if (!root || !user) return;

  const isAdmin = user.rol === UserRole.admin;
  const rolChip = htmlStatusChip(UserRoleLabel[user.rol], 'var(--krono-primary)');

  // Bloque visible solo para administradores: enlace a gestión de usuarios
  let adminBlock = '';
  if (isAdmin) {
    adminBlock =
      htmlKronoCard(
        '<div class="d-flex flex-row align-items-start flex-wrap gap-2">' +
        '<div class="flex-fill">' +
        '<div class="fw-bold">Usuarios del equipo</div>' +
        '<p class="text-muted small mb-0 mt-2">Solo administradores. Crea, desactiva o cambia el rol de usuarios.</p>' +
        '</div>' +
        '<a class="btn btn-krono-primary" href="../usuarios/usuarios.html">' +
        '<span class="material-symbols-outlined me-1" style="font-size:18px;vertical-align:middle">open_in_new</span>Gestionar' +
        '</a></div>'
      ) +
      '<div class="mt-3"></div>';
  }

  root.innerHTML =
    '<h2 class="krono-headline-medium">Ajustes</h2>' +
    '<p class="text-muted mb-4">Gestiona tu cuenta y preferencias</p>' +
    htmlKronoCard(
      '<div class="fw-bold mb-3">Perfil</div>' +
        '<div class="d-flex flex-row flex-wrap align-items-start gap-3 mb-3">' +
        htmlAvatarCircle(user.nombre, 64) +
        '<div>' +
        '<div class="fw-semibold">' +
        esc(user.nombre) +
        '</div>' +
        '<div class="text-muted">' +
        esc(user.email) +
        '</div>' +
        '<div class="mt-2">' +
        rolChip +
        '</div></div></div>' +
        '<div class="row g-2 mb-3">' +
        '<div class="col-md-6"><label class="form-label krono-form-label">Nombre</label><input type="text" class="form-control krono-form-control" id="ajNombre" value="' +
        escAttr(user.nombre) +
        '" /></div>' +
        '<div class="col-md-6"><label class="form-label krono-form-label">Email</label><input type="email" class="form-control krono-form-control" id="ajEmail" value="' +
        escAttr(user.email) +
        '" /></div></div>' +
        '<div class="text-end"><button type="button" class="btn btn-krono-primary" id="ajGuardarPerfil">Guardar</button></div>'
    ) +
    '<div class="mt-3"></div>' +
    htmlKronoCard(
      '<div class="fw-bold mb-2">Seguridad</div>' +
        '<div class="list-group list-group-flush">' +
        '<button type="button" class="list-group-item list-group-item-action d-flex align-items-center">' +
        '<span class="material-symbols-outlined me-3">lock</span><div class="flex-fill text-start">Cambiar contraseña</div>' +
        '<span class="material-symbols-outlined text-muted">chevron_right</span></button>' +
        '<hr class="krono-divider m-0" />' +
        '<button type="button" class="list-group-item list-group-item-action d-flex align-items-center">' +
        '<span class="material-symbols-outlined me-3">devices</span>' +
        '<div class="flex-fill text-start"><div>Sesiones activas</div><div class="small text-muted">2 dispositivos</div></div>' +
        '<span class="material-symbols-outlined text-muted">chevron_right</span></button>' +
        '<hr class="krono-divider m-0" />' +
        '<button type="button" class="list-group-item list-group-item-action d-flex align-items-center">' +
        '<span class="material-symbols-outlined me-3">shield</span>' +
        '<div class="flex-fill text-start"><div>Autenticación en dos pasos</div><div class="small text-muted">Desactivada</div></div>' +
        '<span class="material-symbols-outlined text-muted">chevron_right</span></button></div>'
    ) +
    '<div class="mt-3"></div>' +
    htmlKronoCard(
      '<div class="fw-bold mb-2">Preferencias</div>' +
        '<div class="row g-2 mb-2">' +
        '<div class="col-md-6"><label class="form-label krono-form-label">Idioma</label>' +
        '<select class="form-select krono-form-control" id="ajIdioma"><option value="es" selected>Español</option><option value="en">English</option></select></div>' +
        '<div class="col-md-6"><label class="form-label krono-form-label">Zona horaria</label>' +
        '<select class="form-select krono-form-control"><option>Europe/Madrid</option></select></div></div>' +
        '<div class="form-check form-switch mb-2">' +
        '<input class="form-check-input" type="checkbox" id="ajMail" checked />' +
        '<label class="form-check-label" for="ajMail">Notificaciones por email</label></div>' +
        '<div class="form-check form-switch mb-2">' +
        '<input class="form-check-input" type="checkbox" id="ajPush" />' +
        '<label class="form-check-label" for="ajPush">Notificaciones push</label></div>' +
        '<div class="form-check form-switch">' +
        '<input class="form-check-input" type="checkbox" id="ajDarkMode" />' +
        '<label class="form-check-label" for="ajDarkMode">Modo Oscuro</label></div>'
    ) +
    '<div class="mt-3"></div>' +
    adminBlock;

  document.getElementById('ajGuardarPerfil').addEventListener('click', () => {
    showAjustesToast('Perfil actualizado');
  });

  // Preferencia de modo oscuro (persistida en localStorage)
  const darkModeSwitch = document.getElementById('ajDarkMode');
  if (darkModeSwitch) {
    darkModeSwitch.checked = document.body.classList.contains('dark-theme');
    darkModeSwitch.addEventListener('change', (e) => {
      if (e.target.checked) {
        document.body.classList.add('dark-theme');
        localStorage.setItem('krono-dark-mode', 'true');
      } else {
        document.body.classList.remove('dark-theme');
        localStorage.setItem('krono-dark-mode', 'false');
      }
    });
  }
}

/**
 * Muestra un Toast genérico de información para el panel de ajustes.
 * @param {string} msg - Mensaje a mostrar
 */
function showAjustesToast(msg) {
  const el = document.createElement('div');
  el.className = 'toast align-items-center text-bg-primary border-0 position-fixed bottom-0 end-0 m-3';
  el.innerHTML =
    '<div class="d-flex"><div class="toast-body">' +
    esc(msg) +
    '</div><button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button></div>';
  document.body.appendChild(el);
  const t = new bootstrap.Toast(el, { delay: 2200 });
  t.show();
  el.addEventListener('hidden.bs.toast', () => el.remove());
}

// —— Utilidades de escape HTML ——
function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function escAttr(s) {
  return String(s).replace(/"/g, '&quot;');
}
