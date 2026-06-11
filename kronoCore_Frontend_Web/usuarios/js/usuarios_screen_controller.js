/**
 * Usuarios — screen_controller.js
 * Administración de usuarios: listado, invitaciones y edición de roles.
 */

let usersList = [];
let editModalInstance;

function getEmpresaContextId() {
  const u = SessionController.instance.user;
  if (!u) return null;
  if (u.rol === UserRole.admin) return SessionController.instance.adminEmpresaId;
  return u.empresaId ?? null;
}

async function requireAdminEmpresaSelection() {
  const u = SessionController.instance.user;
  if (!u || u.rol !== UserRole.admin) return true;

  // Siempre limpiar la selección anterior para forzar elección
  SessionController.instance.setAdminEmpresaId(null);

  const empresas = await ApiClient.get('/empresas');
  const options = (empresas || [])
    .map((e) => `<option value="${String(e.id)}">${esc(e.nombre || '')}</option>`)
    .join('');

  const modal = document.createElement('div');
  modal.className = 'modal fade';
  modal.innerHTML = `
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">Selecciona empresa</h5>
        </div>
        <div class="modal-body">
          <p class="text-muted mb-2">Para gestionar usuarios como admin, elige la empresa con la que vas a trabajar.</p>
          <select class="form-select krono-form-control" id="adminEmpresaSelect">
            <option value="" selected disabled>Selecciona…</option>
            <option value="clientes">Clientes (sin empresa)</option>
            ${options}
          </select>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-krono-primary" id="btnAdminEmpresaOk" disabled>Continuar</button>
        </div>
      </div>
    </div>`;
  document.body.appendChild(modal);
  const bsModal = new bootstrap.Modal(modal, { backdrop: 'static', keyboard: false });
  bsModal.show();

  const sel = modal.querySelector('#adminEmpresaSelect');
  const btnOk = modal.querySelector('#btnAdminEmpresaOk');
  sel.addEventListener('change', () => {
    btnOk.disabled = !sel.value;
  });

  return await new Promise((resolve) => {
    btnOk.addEventListener('click', () => {
      const val = sel.value;
      // 'clientes' es un valor especial para ver usuarios sin empresa (clientes)
      if (val === 'clientes') {
        SessionController.instance.setAdminEmpresaId(0);
      } else {
        SessionController.instance.setAdminEmpresaId(Number(val));
      }
      bsModal.hide();
      resolve(true);
    });
    modal.addEventListener('hidden.bs.modal', () => modal.remove());
  });
}

/**
 * Inicializa la pantalla de administración de usuarios (solo para Administradores).
 * Enlaza los botones de invitar usuario, envía los correos de invitación y 
 * recarga la tabla de empleados dinámicamente tras cada acción.
 */
async function initUsuariosScreen() {
  await requireAdminEmpresaSelection();
  const wrap = document.getElementById('usuariosListWrap');
  const btnInvitar = document.getElementById('btnInvitarUsuario');
  const inviteModal = new bootstrap.Modal(document.getElementById('inviteEmployeeModal'));
  editModalInstance = new bootstrap.Modal(document.getElementById('editUserModal'));

  if (btnInvitar) {
    btnInvitar.addEventListener('click', () => {
      const form = document.getElementById('inviteUserForm');
      if (form) form.reset();
      document.getElementById('inviteName')?.classList.remove('is-invalid');
      document.getElementById('inviteEmail')?.classList.remove('is-invalid');
      document.getElementById('inviteLinkWrap')?.classList.add('d-none');
      document.getElementById('inviteLinkText').textContent = '';
      const btnSend = document.getElementById('btnSendInvite');
      if (btnSend) {
        btnSend.disabled = false;
        btnSend.innerHTML = 'Enviar';
      }
      inviteModal.show();
    });
  }

  document.getElementById('btnSendInvite')?.addEventListener('click', async () => {
    const nameInput = document.getElementById('inviteName');
    const emailInput = document.getElementById('inviteEmail');

    const nombre = nameInput.value.trim();
    const email = emailInput.value.trim();

    let valid = true;
    if (!nombre) {
      nameInput.classList.add('is-invalid');
      valid = false;
    } else {
      nameInput.classList.remove('is-invalid');
    }

    if (!email || !email.includes('@')) {
      emailInput.classList.add('is-invalid');
      valid = false;
    } else {
      emailInput.classList.remove('is-invalid');
    }

    if (!valid) return;

    const btnSend = document.getElementById('btnSendInvite');
    btnSend.disabled = true;
    btnSend.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>';

    try {
      const empresaId = getEmpresaContextId();
      const payload = { email: email, empresaId: empresaId };
      const resp = await ApiClient.post('/invitaciones/empleado', payload);

      const linkWrap = document.getElementById('inviteLinkWrap');
      const linkText = document.getElementById('inviteLinkText');
      if (resp && resp.link) {
        linkText.textContent = 'Enlace: ' + resp.link;
        linkWrap.classList.remove('d-none');
      }

      showUsuariosToast(`Invitación enviada a ${email}`);
      await cargarUsuarios();
    } catch (e) {
      console.error(e);
      showUsuariosToast('Error: ' + String(e.message || e), 'danger');
    } finally {
      btnSend.disabled = false;
      btnSend.innerHTML = 'Enviar';
    }
  });

  document.getElementById('btnSaveUser')?.addEventListener('click', async () => {
    const btn = document.getElementById('btnSaveUser');
    btn.disabled = true;
    btn.innerHTML = 'Guardando...';

    const id = document.getElementById('editUserId').value;
    const rol = document.getElementById('editUserRole').value;
    const empresaId = document.getElementById('editUserEmpresaId').value;
    const verificado = document.getElementById('editUserActive').checked;

    const payload = { rol: rol, verificado: verificado };
    if (empresaId) payload.empresaId = empresaId;

    try {
      await ApiClient.put('/usuarios/' + id, payload);
      showUsuariosToast('Usuario actualizado');
      editModalInstance.hide();
      await cargarUsuarios();
    } catch (err) {
      showUsuariosToast('Error al actualizar: ' + err.message, 'danger');
    } finally {
      btn.disabled = false;
      btn.innerHTML = 'Guardar cambios';
    }
  });

  document.getElementById('btnDeleteUser')?.addEventListener('click', async () => {
    const id = document.getElementById('editUserId').value;
    if (!id) return;
    if (!confirm('¿Eliminar este usuario? Esta acción no se puede deshacer.')) return;
    try {
      await ApiClient.delete('/usuarios/' + id);
      showUsuariosToast('Usuario eliminado', 'primary');
      editModalInstance.hide();
      await cargarUsuarios();
    } catch (err) {
      showUsuariosToast('Error eliminando usuario: ' + String(err.message || err), 'danger');
    }
  });

  await cargarUsuarios();
}

/**
 * Petición asíncrona para obtener todos los usuarios del sistema.
 * Renderiza la lista con componentes visuales (Avatares, Chips de roles, Estado de verificación).
 */
async function cargarUsuarios() {
  const wrap = document.getElementById('usuariosListWrap');
  if (!wrap) return;
  wrap.innerHTML = htmlKronoCard('<div class="text-muted">Cargando usuarios...</div>', true);

  try {
    usersList = await ApiClient.get('/usuarios');
    if (!usersList || usersList.length === 0) {
      wrap.innerHTML = htmlKronoCard('<div class="text-muted">No hay usuarios registrados.</div>', true);
      return;
    }

    const rows = usersList
      .map((u, i) => {
        const rolChip = htmlStatusChip(UserRoleLabel[u.rol] || u.rol || 'Usuario', 'var(--krono-primary)');
        const actChip = htmlStatusChip(
          u.verificado === false ? 'Pendiente' : 'Activo',
          u.verificado === false ? 'var(--krono-warning)' : 'var(--krono-success)'
        );
        const empresaChip = u.empresaNombre ? htmlStatusChip(esc(u.empresaNombre), 'var(--krono-muted)') : '';
        return (
          '<div class="list-row d-flex flex-row align-items-center" style="overflow:hidden">' +
          htmlAvatarCircle(u.nombre || 'U', 40) +
          '<div class="ms-3 flex-fill" style="min-width:0;overflow:hidden">' +
          '<div class="fw-semibold" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' + esc(u.nombre || '') + '</div>' +
          '<div class="text-muted small" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' + esc(u.email || '') + '</div>' +
          '</div>' +
          '<div class="d-flex flex-row align-items-center gap-2 flex-shrink-0">' +
          rolChip +
          actChip +
          empresaChip +
          '<button type="button" class="btn btn-link p-1 text-muted" data-edit-user="' + u.id + '"><span class="material-symbols-outlined">edit</span></button>' +
          '<button type="button" class="btn btn-link p-1 text-danger" data-delete-user="' + u.id + '"><span class="material-symbols-outlined">delete</span></button>' +
          '</div></div>' +
          (i < usersList.length - 1 ? '<hr class="krono-divider m-0" />' : '')
        );
      })
      .join('');

    wrap.innerHTML = htmlKronoCard(rows, true);

    wrap.querySelectorAll('[data-edit-user]').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.getAttribute('data-edit-user');
        const user = usersList.find(u => String(u.id) === String(id));
        if (user) {
          document.getElementById('editUserId').value = user.id;
          document.getElementById('editUserRole').value = user.rol || 'EMPLEADO';
          document.getElementById('editUserActive').checked = user.verificado !== false;
          document.getElementById('editUserEmpresaId').value = user.empresaId || ''; // empresaId si está disponible en el modelo
          editModalInstance.show();
        }
      });
    });

    wrap.querySelectorAll('[data-delete-user]').forEach(btn => {
      btn.addEventListener('click', async () => {
        const id = btn.getAttribute('data-delete-user');
        if (!id) return;
        if (!confirm('¿Eliminar este usuario? Esta acción no se puede deshacer.')) return;
        try {
          await ApiClient.delete('/usuarios/' + id);
          showUsuariosToast('Usuario eliminado', 'primary');
          await cargarUsuarios();
        } catch (err) {
          console.error(err);
          showUsuariosToast('Error eliminando usuario: ' + String(err.message || err), 'danger');
        }
      });
    });
  } catch (err) {
    wrap.innerHTML = htmlErrorView(String(err.message || err), 'retryLoadUsuarios');
    document.getElementById('retryLoadUsuarios')?.addEventListener('click', () => cargarUsuarios());
    console.error(err);
    showUsuariosToast('Error cargando usuarios: ' + String(err.message || err), 'danger');
  }
}

/**
 * Función auxiliar para mostrar notificaciones flotantes (Toasts).
 * @param {string} msg - Mensaje a mostrar
 * @param {string} type - Tipo de toast ('primary' o 'danger')
 */
function showUsuariosToast(msg, type = 'primary') {
  const el = document.createElement('div');
  el.className = `toast align-items-center text-bg-${type === 'danger' ? 'danger' : 'primary'} border-0 position-fixed bottom-0 end-0 m-3`;
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
