/**
 * login_controller.js — Controlador de la pantalla de login y registro.
 * 
 * RESPONSABILIDADES:
 * - Validar credenciales (email formato, password longitud mínima)
 * - Enviar peticiones POST /api/auth/login y /api/auth/register
 * - Gestionar sesión con JWT (SessionController.loginWithJwt)
 * - Alternar entre formulario login y registro
 * - Procesar tokens de confirmación de email e invitación desde URL
 * - Redirigir según rol (admin/jefe/empleado → dashboard, cliente → área cliente)
 */
class LoginController {
  constructor() {
    this.loading = false;
    this.rol = UserRole.cliente;
  }

  _setAlert(id, message, type = 'info') {
    const el = document.getElementById(id);
    if (!el) return;
    el.className = `alert alert-${type}`;
    el.textContent = message;
    el.classList.remove('d-none');
  }

  _clearAlert(id) {
    const el = document.getElementById(id);
    if (el) el.classList.add('d-none');
  }

  _syncLoginUI() {
    const btn = document.getElementById('btnLogin');
    if (btn) {
      btn.disabled = this.loading;
      btn.innerHTML = this.loading
        ? '<span class="spinner-border spinner-border-sm" role="status"></span>'
        : 'Iniciar sesión';
    }
  }

  _syncRegisterUI() {
    const btn = document.getElementById('btnRegister');
    const role = document.getElementById('regRole')?.value || 'cliente';
    const companyWrap = document.getElementById('regCompanyWrap');
    if (companyWrap) companyWrap.classList.toggle('d-none', role === 'cliente');
    if (btn) {
      btn.disabled = this.loading;
      btn.innerHTML = this.loading
        ? '<span class="spinner-border spinner-border-sm" role="status"></span>'
        : 'Registrarse';
    }
  }

  async submitLogin() {

    this.loading = true;
    this._syncLoginUI();
    this._clearAlert('loginAlert');

    try {
      const email = document.getElementById('email').value.trim();
      const password = document.getElementById('password').value;
      if (!email || !email.includes('@')) {
        this._setAlert('loginAlert', 'Introduce un email válido', 'danger');
        return;
      }
      if (!password || password.length < 6) {
        this._setAlert('loginAlert', 'La contraseña debe tener al menos 6 caracteres', 'danger');
        return;
      }
      const data = await ApiClient.post('/auth/login', { email, password });
      SessionController.instance.loginWithJwt(data);
      window.location.href = data.rol === UserRole.cliente
        ? '../area_clientes/area_clientes.html'
        : '../dashboard/dashboard.html';
    } catch (err) {
      this._setAlert('loginAlert', err.message || String(err), 'danger');
    } finally {
      this.loading = false;
      this._syncLoginUI();
    }
  }

  async submitRegister() {

    const role = document.getElementById('regRole').value;
    const nombre = document.getElementById('regNombre').value.trim();
    const email = document.getElementById('regEmail').value.trim();
    const password = document.getElementById('regPassword').value;
    const telefono = document.getElementById('regTelefono').value.trim();
    const empresa = document.getElementById('regCompany').value.trim();

    if (!nombre) { this._setAlert('registerAlert', 'El nombre es obligatorio', 'danger'); return; }
    if (!email.includes('@')) { this._setAlert('registerAlert', 'Introduce un email válido', 'danger'); return; }
    if (password.length < 6) { this._setAlert('registerAlert', 'La contraseña debe tener al menos 6 caracteres', 'danger'); return; }
    if (!telefono) { this._setAlert('registerAlert', 'El teléfono es obligatorio', 'danger'); return; }
    if (role !== 'cliente' && !empresa) { this._setAlert('registerAlert', 'Debes indicar la empresa para jefe o empleado', 'danger'); return; }

    const payload = { nombre, email, password, telefono, rol: role, empresaNombre: role === 'cliente' ? null : empresa };

    this.loading = true;
    this._syncRegisterUI();
    this._clearAlert('registerAlert');

    try {
      const data = await ApiClient.post('/auth/register', payload);
      this._setAlert('registerAlert', data.message || 'Cuenta creada. Revisa tu correo para confirmar el registro.', 'success');
      setTimeout(() => { document.getElementById('btnShowLogin').click(); }, 1200);
    } catch (err) {
      this._setAlert('registerAlert', err.message || String(err), 'danger');
    } finally {
      this.loading = false;
      this._syncRegisterUI();
    }
  }
}

function initLoginPage() {
  const controller = new LoginController();

  if (SessionController.instance.isAuth) {
    const rol = SessionController.instance.user.rol;
    window.location.href = rol === UserRole.cliente ? '../area_clientes/area_clientes.html' : '../dashboard/dashboard.html';
    return;
  }

  const params = new URLSearchParams(window.location.search);
  const token = params.get('token');
  if (token) {
    ApiClient.get(`/auth/confirmar?token=${encodeURIComponent(token)}`)
      .then(() => controller._setAlert('loginAlert', 'Cuenta confirmada. Ya puedes iniciar sesión.', 'success'))
      .catch((err) => controller._setAlert('loginAlert', err.message, 'danger'));
  }

  const invite = params.get('invite');
  if (invite) {
    ApiClient.get(`/invitaciones/aceptar?token=${encodeURIComponent(invite)}`)
      .then(() => controller._setAlert('loginAlert', 'Invitación aceptada. Ya puedes iniciar sesión.', 'success'))
      .catch((err) => controller._setAlert('loginAlert', err.message, 'danger'));
  }

  document.getElementById('regRole').addEventListener('change', () => controller._syncRegisterUI());
  document.getElementById('loginForm').addEventListener('submit', (e) => { e.preventDefault(); controller.submitLogin(); });
  document.getElementById('registerForm').addEventListener('submit', (e) => { e.preventDefault(); controller.submitRegister(); });
  document.getElementById('btnShowRegister').addEventListener('click', () => { document.getElementById('loginForm').classList.add('d-none'); document.getElementById('registerForm').classList.remove('d-none'); controller._syncRegisterUI(); });
  document.getElementById('btnShowLogin').addEventListener('click', () => { document.getElementById('registerForm').classList.add('d-none'); document.getElementById('loginForm').classList.remove('d-none'); controller._syncLoginUI(); });

  controller._syncLoginUI();
  controller._syncRegisterUI();
}