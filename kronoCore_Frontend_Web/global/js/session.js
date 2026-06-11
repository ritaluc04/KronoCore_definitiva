/*
 * session.js — Control de sesión de usuario en el navegador.
 * 
 * GESTIONA:
 * - Inicio de sesión con JWT (loginWithJwt)
 * - Persistencia en sessionStorage (se mantiene al recargar)
 * - Renovación automática del Access Token (refreshAccessToken)
 * - Cierre de sesión (logout)
 * - Notificación de cambios (evento session-changed)
 * - Soporte multi-empresa para admin (adminEmpresaId)
 * 
 * USO: SessionController.instance.loginWithJwt(data)
 */

/**
 * session.dart → JavaScript
 * Sesión global con JWT para auth + filtrado por rol.
 * Singleton: solo existe una instancia en toda la aplicación.
 */
class SessionController {
  static instance = new SessionController();

  constructor() {
    this._user = null;
    this._accessToken = null;
    this._refreshToken = null;
    this._load(); // Carga la sesión guardada al iniciar
  }

  get user() { return this._user; }
  get accessToken() { return this._accessToken; }
  get refreshToken() { return this._refreshToken; }
  get isAuth() { return this._user !== null; }

  /** Para que el admin pueda seleccionar una empresa específica */
  get adminEmpresaId() {
    const raw = sessionStorage.getItem('krono_admin_empresa_id');
    return raw ? Number(raw) : null;
  }

  setAdminEmpresaId(id) {
    if (id === null || id === undefined || id === '') {
      sessionStorage.removeItem('krono_admin_empresa_id');
    } else {
      sessionStorage.setItem('krono_admin_empresa_id', String(id));
    }
    window.dispatchEvent(new Event('session-changed'));
  }

  /**
   * Inicia sesión con la respuesta del backend (JWT + datos de usuario).
   * Guarda tokens y datos del usuario en memoria y sessionStorage.
   * 
   * @param {Object} data - Respuesta del endpoint /api/auth/login
   * @param {string} data.accessToken - Token JWT de acceso (1h)
   * @param {string} data.refreshToken - Token JWT de refresco (7d)
   * @param {string} data.id - ID del usuario
   * @param {string} data.nombre - Nombre del usuario
   * @param {string} data.email - Email del usuario
   * @param {string} data.rol - Rol del usuario (admin, jefe, empleado, cliente)
   * @param {string} data.empresaId - ID de la empresa (null para admin)
   */
  loginWithJwt(data) {
    this._accessToken = data.accessToken;
    this._refreshToken = data.refreshToken;
    this._user = {
      id: data.id,
      nombre: data.nombre,
      email: data.email,
      rol: data.rol,
      empresaNombre: data.empresaNombre || null,
      empresaId: data.empresaId != null ? Number(data.empresaId) : null,
    };
    this._save();
    window.dispatchEvent(new Event('session-changed'));
  }

  /**
   * Refresca el Access Token usando el Refresh Token.
   * Se llama automáticamente cuando una petición recibe 401.
   * 
   * FLUJO:
   * 1. Envía POST /api/auth/refresh con el Refresh Token
   * 2. Recibe nuevo Access Token y Refresh Token
   * 3. Actualiza tokens en memoria y sessionStorage
   */
  async refreshAccessToken() {
    if (!this._refreshToken) throw new Error('No hay refresh token');
    const response = await fetch('https://kronobackend-ctach7cya4cxb9d8.spaincentral-01.azurewebsites.net/api/auth/refresh', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: this._refreshToken }),
    });
    if (!response.ok) throw new Error('Error al refrescar token');
    const data = await response.json();
    this._accessToken = data.accessToken;
    this._refreshToken = data.refreshToken;
    const stored = JSON.parse(sessionStorage.getItem('krono_session') || '{}');
    stored.accessToken = this._accessToken;
    stored.refreshToken = this._refreshToken;
    sessionStorage.setItem('krono_session', JSON.stringify(stored));
  }

  /**
   * Cierra la sesión: borra tokens y datos del usuario.
   */
  logout() {
    this._user = null;
    this._accessToken = null;
    this._refreshToken = null;
    sessionStorage.removeItem('krono_session');
    window.dispatchEvent(new Event('session-changed'));
  }

  /** Guarda la sesión en sessionStorage para persistencia entre recargas */
  _save() {
    sessionStorage.setItem('krono_session', JSON.stringify({
      user: this._user,
      accessToken: this._accessToken,
      refreshToken: this._refreshToken,
    }));
  }

  /** Carga la sesión desde sessionStorage al iniciar la app */
  _load() {
    const raw = sessionStorage.getItem('krono_session');
    if (raw) {
      try {
        const data = JSON.parse(raw);
        this._user = data.user || null;
        this._accessToken = data.accessToken || null;
        this._refreshToken = data.refreshToken || null;
      } catch {
        // Si los datos están corruptos, iniciar sin sesión
        this._user = null;
        this._accessToken = null;
        this._refreshToken = null;
      }
    }
  }
}