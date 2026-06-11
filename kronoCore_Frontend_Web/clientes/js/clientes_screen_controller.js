/**
 * screen_controller.js — Controlador de las pantallas de Clientes.
 * 
 * RESPONSABILIDADES:
 * - Listar todos los clientes registrados en una tabla
 * - Buscar clientes por nombre o email en tiempo real
 * - Crear nuevos clientes con nombre, apellidos, email, teléfono y etiquetas
 * - Editar clientes existentes
 * - Eliminar clientes con confirmación previa
 * - Mostrar detalle del cliente con pestañas (datos, historial, compras, notas)
 * 
 * ENDPOINTS UTILIZADOS:
 * - GET /api/clientes → Listar todos los clientes
 * - POST /api/clientes → Crear nuevo cliente
 * - PUT /api/clientes/{id} → Actualizar cliente
 * - DELETE /api/clientes/{id} → Eliminar cliente
 * - GET /api/clientes/{id} → Obtener detalle de cliente
 * 
 * CADA CLIENTE TIENE:
 * - Nombre, apellidos, email, teléfono
 * - Etiquetas (tags) para segmentación: VIP, Frecuente, Nuevo, etc.
 * - Última cita registrada
 * - Empresa a la que pertenece (multi-tenant)
 */

/** Estado compartido del módulo de clientes */
let clientesState = {
  clientes: [],           // Lista completa de clientes cargados
  cargando: false,        // Indicador de carga
  busqueda: '',           // Texto de búsqueda actual
  clienteEditando: null,  // Cliente que se está editando (null = nuevo)
};

/**
 * Inicializa la pantalla de Clientes.
 * Carga los clientes desde la API, renderiza la tabla y enlaza los eventos.
 */
async function initClientesScreen() {
  const listWrap = document.getElementById('clientesListWrap');
  if (!listWrap) return;

  clientesState.cargando = true;
  listWrap.innerHTML = htmlLoadingView();

  try {
    const data = await ApiClient.get('/clientes');
    clientesState.clientes = data || [];
    renderClientesTable(listWrap);
  } catch (e) {
    listWrap.innerHTML = htmlErrorView(String(e.message || e), 'retryClientes');
    document.getElementById('retryClientes')?.addEventListener('click', () => initClientesScreen());
  } finally {
    clientesState.cargando = false;
  }

  // Enlazar eventos
  document.getElementById('searchClientes')?.addEventListener('input', (e) => {
    clientesState.busqueda = e.target.value;
    const listWrap = document.getElementById('clientesListWrap');
    if (listWrap) renderClientesTable(listWrap);
  });

  document.getElementById('btnNuevoCliente')?.addEventListener('click', openNewCliente);
  document.getElementById('btnCrearCliente')?.addEventListener('click', saveCliente);
}

/**
 * Renderiza la tabla de clientes con los datos actuales.
 * Aplica el filtro de búsqueda si hay texto en el campo de búsqueda.
 * 
 * @param {HTMLElement} mount - Contenedor HTML donde se pinta la tabla
 */
function renderClientesTable(mount) {
  if (!mount) return;

  // Filtrar clientes según la búsqueda activa
  let clientes = clientesState.clientes;
  if (clientesState.busqueda.trim()) {
    const q = clientesState.busqueda.toLowerCase();
    clientes = clientes.filter(c =>
      (c.nombre || '').toLowerCase().includes(q) ||
      (c.email || '').toLowerCase().includes(q)
    );
  }

  if (clientes.length === 0) {
    mount.innerHTML = htmlEmptyView({
      icon: 'people_outline',
      title: clientesState.busqueda ? 'Sin resultados' : 'Sin clientes',
      message: clientesState.busqueda
        ? 'Prueba con otro término o crea un nuevo cliente.'
        : 'No hay clientes registrados todavía.',
      actionLabel: 'Nuevo cliente',
      onActionId: 'emptyNewCliente',
    });
    document.getElementById('emptyNewCliente')?.addEventListener('click', openNewCliente);
    return;
  }

  // Construir filas de la tabla
  const rows = clientes.map(c => {
    const fecha = c.ultimaCita ? new Date(c.ultimaCita).toLocaleDateString('es-ES', { day: '2-digit', month: 'short' }) : '-';
    const etiquetasHtml = (c.etiquetas || []).map(e => htmlStatusChip(e, 'var(--krono-accent)')).join(' ');

    return `
      <div class="ClientesScreen-row d-flex flex-row align-items-center" onclick="window.location.href='../cliente_detalle/cliente_detalle.html?id=${c.id}'" style="cursor:pointer">
        ${htmlAvatarCircle((c.nombre || '') + ' ' + (c.apellidos || ''), 40)}
        <div class="ms-3 flex-fill" style="min-width:0;overflow:hidden">
          <div class="fw-semibold" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${esc(c.nombre || '')} ${esc(c.apellidos || '')}</div>
          <div class="text-muted small" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${esc(c.email || '')}</div>
          ${etiquetasHtml ? `<div class="mt-1">${etiquetasHtml}</div>` : ''}
        </div>
        <div class="text-end me-3 flex-shrink-0">
          <div class="small">${esc(c.telefono || '')}</div>
          <div class="text-muted smaller">${fecha}</div>
        </div>
        <button class="btn btn-sm btn-outline-secondary me-1 flex-shrink-0" onclick="event.stopPropagation(); openEditCliente('${c.id}')" title="Editar">
          <span class="material-symbols-outlined" style="font-size:18px">edit</span>
        </button>
        <button class="btn btn-sm btn-outline-danger flex-shrink-0" onclick="event.stopPropagation(); eliminarCliente('${c.id}')" title="Eliminar">
          <span class="material-symbols-outlined" style="font-size:18px">delete</span>
        </button>
      </div>`;
  }).join('');

  mount.innerHTML = htmlKronoCard(rows, true);
}

/**
 * Abre el modal para crear un nuevo cliente.
 * Limpia los campos del formulario.
 */
function openNewCliente() {
  document.getElementById('ncNombre').value = '';
  document.getElementById('ncEmail').value = '';
  document.getElementById('ncTelefono').value = '';
  clientesState.clienteEditando = null;
  const modal = new bootstrap.Modal(document.getElementById('newClientModal'));
  modal.show();
}

/**
 * Abre el modal de edición para un cliente existente.
 * Busca el cliente en la lista cargada y precarga los campos.
 * 
 * @param {string} id - ID del cliente a editar
 */
function openEditCliente(id) {
  const cliente = clientesState.clientes.find(c => String(c.id) === String(id));
  if (!cliente) return;
  clientesState.clienteEditando = cliente;

  // Parsear nombre y apellidos del campo nombre completo
  const partes = (cliente.nombre || '').split(' ');
  const nombre = partes[0] || '';
  const apellidos = partes.length > 1 ? partes.slice(1).join(' ') : '';

  document.getElementById('ncNombre').value = nombre + (apellidos ? ' ' + apellidos : '');
  document.getElementById('ncEmail').value = cliente.email || '';
  document.getElementById('ncTelefono').value = cliente.telefono || '';

  const modal = new bootstrap.Modal(document.getElementById('newClientModal'));
  modal.show();
}

/**
 * Guarda un cliente (nuevo o edición) en el backend.
 * Lee los datos del formulario, separa nombre y apellidos,
 * y envía la petición POST o PUT según corresponda.
 */
async function saveCliente() {
  const nombreCompleto = document.getElementById('ncNombre')?.value.trim() || '';
  const email = document.getElementById('ncEmail')?.value.trim() || '';
  const telefono = document.getElementById('ncTelefono')?.value.trim() || '';

  if (!nombreCompleto || !telefono) {
    alert('Nombre y teléfono son obligatorios');
    return;
  }

  // Separar nombre y apellidos
  const partes = nombreCompleto.split(' ');
  const nombre = partes[0];
  const apellidos = partes.length > 1 ? partes.slice(1).join(' ') : '';

  const payload = {
    nombre: nombre,
    apellidos: apellidos,
    email: email,
    telefono: telefono,
    etiquetas: [],
  };

  try {
    if (clientesState.clienteEditando) {
      await ApiClient.put('/clientes/' + clientesState.clienteEditando.id, payload);
    } else {
      await ApiClient.post('/clientes', payload);
    }
    bootstrap.Modal.getInstance(document.getElementById('newClientModal'))?.hide();
    initClientesScreen(); // Recargar lista
  } catch (e) {
    alert('Error al guardar cliente: ' + String(e.message || e));
  }
}

/**
 * Elimina un cliente del sistema.
 * Solicita confirmación antes de eliminar.
 * 
 * @param {string} id - ID del cliente a eliminar
 */
async function eliminarCliente(id) {
  if (!confirm('¿Estás seguro de eliminar este cliente?')) return;

  try {
    await ApiClient.delete('/clientes/' + id);
    initClientesScreen(); // Recargar lista
  } catch (e) {
    alert('Error al eliminar cliente: ' + String(e.message || e));
  }
}

/** Escapa HTML para prevenir XSS */
function esc(s) { return String(s).replace(/&/g, '&').replace(/</g, '<').replace(/>/g, '>'); }