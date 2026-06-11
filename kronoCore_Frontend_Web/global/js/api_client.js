/*
 * api_client.js — Cliente HTTP centralizado para el API REST de KronoCore.
 * 
 * FUNCIONES PRINCIPALES:
 * - Gestiona la URL base de la API (https://kronobackend-ctach7cya4cxb9d8.spaincentral-01.azurewebsites.net/api)
 * - Añade cabeceras JWT Bearer automáticamente (Authorization)
 * - Añade cabeceras de contexto multi-tenant (X-Empresa-Id, X-User-Rol)
 * - Auto-refresh de token JWT cuando expira (detecta 401 y reintenta)
 * - Métodos HTTP: get(), post(), put(), patch(), delete()
 * 
 * USO: ApiClient.get('/clientes'), ApiClient.post('/clientes', data)
 */

/**
 * api_client.js
 * Cliente HTTP simple para consumir el backend Spring Boot con JWT.
 */

// Cabeceras legacy de tenant (mantenido para exportarCSV y compatibilidad)
function tenantHeaders() {
  const u = typeof SessionController !== 'undefined' ? SessionController.instance.user : null;
  if (!u) return {};
  const h = {};
  if (u.rol) h['X-User-Rol'] = u.rol;
  if (u.empresaId != null && u.rol !== 'cliente' && u.rol !== 'admin') h['X-Empresa-Id'] = String(u.empresaId);
  if (u.rol === 'admin' && SessionController.instance.adminEmpresaId != null) h['X-Empresa-Id'] = String(SessionController.instance.adminEmpresaId);
  return h;
}

// Cabeceras de autenticación JWT + contexto de empresa
function authHeaders() {
  const u = typeof SessionController !== 'undefined' ? SessionController.instance.user : null;
  if (!u) return {};
  const h = {};
  // Token JWT de acceso - se envía en cada petición como Bearer
  const token = SessionController.instance.accessToken;
  if (token) h['Authorization'] = 'Bearer ' + token;
  // Contexto multi-tenant (soporte legacy, JWT ya lleva rol y empresaId)
  if (u.rol) h['X-User-Rol'] = u.rol;
  if (u.empresaId != null && u.rol !== 'cliente' && u.rol !== 'admin') h['X-Empresa-Id'] = String(u.empresaId);
  if (u.rol === 'admin' && SessionController.instance.adminEmpresaId != null) h['X-Empresa-Id'] = String(SessionController.instance.adminEmpresaId);
  return h;
}

// Objeto con la configuración base y los métodos de petición al servidor
const ApiClient = {
  baseUrl: 'https://kronobackend-ctach7cya4cxb9d8.spaincentral-01.azurewebsites.net/api',

  /**
   * Petición genérica: concatena baseUrl + path, parsea JSON y propaga errores HTTP.
   * 
   * FLUJO:
   * 1. Realiza la petición HTTP con fetch()
   * 2. Parsea la respuesta como JSON (si hay contenido)
   * 3. Si la respuesta es 401 (token expirado), intenta refrescar automáticamente
   * 4. Si el refresh falla, redirige al login
   * 5. Si la respuesta es OK, devuelve los datos
   * 
   * @param {string} path - Ruta del endpoint (ej: '/clientes')
   * @param {object} options - Opciones de fetch (method, body, etc.)
   * @returns {Promise<object>} - Datos parseados de la respuesta
   */
  async request(path, options = {}) {
    const response = await fetch(`${this.baseUrl}${path}`, {
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        ...authHeaders(),
        ...(options.headers || {}),
      },
      ...options,
    });

    let body = null;
    const text = await response.text();
    if (text) {
      try {
        body = JSON.parse(text);
      } catch {
        body = text;
      }
    }

    if (!response.ok) {
      const message = (body && body.message) || `HTTP ${response.status}`;
      // Si el token expiró (401), intentar refrescar automáticamente
      if (response.status === 401 && SessionController.instance.refreshToken) {
        try {
          await SessionController.instance.refreshAccessToken();
          // Reintentar la petición original con el nuevo token
          const retryHeaders = { ...authHeaders(), ...(options.headers || {}) };
          const retryResp = await fetch(`${this.baseUrl}${path}`, {
            headers: {
              'Content-Type': 'application/json',
              Accept: 'application/json',
              ...retryHeaders,
            },
            ...options,
          });
          const retryText = await retryResp.text();
          if (retryText) {
            try { return JSON.parse(retryText); } catch { return retryText; }
          }
          return null;
        } catch {
          // Refresh falló: redirigir a login
          SessionController.instance.logout();
          window.location.href = '../login/login.html';
          throw new Error('Sesión expirada');
        }
      }
      throw new Error(message);
    }

    return body;
  },

  /** GET: obtener datos del servidor */
  get(path) { return this.request(path, { method: 'GET' }); },
  
  /** POST: crear un nuevo recurso */
  post(path, data) { return this.request(path, { method: 'POST', body: JSON.stringify(data) }); },
  
  /** PUT: actualizar un recurso completo */
  put(path, data) { return this.request(path, { method: 'PUT', body: JSON.stringify(data) }); },
  
  /** PATCH: actualización parcial de un recurso */
  patch(path, data) { return this.request(path, { method: 'PATCH', body: JSON.stringify(data) }); },
  
  /** DELETE: eliminar un recurso */
  delete(path) { return this.request(path, { method: 'DELETE' }); },
};