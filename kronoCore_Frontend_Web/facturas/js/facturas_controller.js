/**
 * facturas_controller.js — Controlador del módulo de Facturación.
 * 
 * RESPONSABILIDADES:
 * - Listar todas las facturas emitidas con su número único, cliente, total y estado
 * - Crear nuevas facturas con datos fiscales del cliente y de la empresa
 * - Cambiar el estado de una factura (emitida → pagada / vencida / cancelada)
 * - Eliminar facturas del sistema
 * - Mostrar totales de facturación del mes actual
 * 
 * ENDPOINTS UTILIZADOS:
 * - GET /api/facturas → Listar facturas
 * - POST /api/facturas → Crear factura
 * - GET /api/facturas/{id} → Obtener detalle de factura
 * - PATCH /api/facturas/{id}/estado → Cambiar estado
 * - DELETE /api/facturas/{id} → Eliminar factura
 * - GET /api/facturas/totales-mes → Totales facturación del mes
 * 
 * FLUJO DE CREACIÓN DE FACTURA:
 * 1. El usuario selecciona un cliente (se autocompletan nombre y NIF)
 * 2. Introduce base imponible, IVA y método de pago
 * 3. El sistema calcula automáticamente IVA y total
 * 4. El backend genera el número de factura único (F-YYYY-NNNN)
 * 5. La factura se guarda con los datos fiscales de la empresa
 */

/** Estado compartido del módulo de facturas */
let facturasState = {
  facturas: [],            // Lista de facturas cargadas
  cargando: false,         // Indicador de carga
  totalFacturado: 0,       // Total facturado del mes actual
  totalPendiente: 0,       // Total pendiente de cobro
  totalPagado: 0,          // Total ya cobrado
};

/**
 * Inicializa la pantalla de Facturación.
 * Carga las facturas y los totales del mes desde la API,
 * luego renderiza la tabla y enlaza los eventos de los botones.
 */
async function initFacturasScreen() {
  const tableWrap = document.getElementById('facturasTableWrap');
  if (!tableWrap) return;

  facturasState.cargando = true;
  tableWrap.innerHTML = htmlLoadingView();

  try {
    // Cargar facturas y totales del mes en paralelo
    const [facturas, totales] = await Promise.all([
      ApiClient.get('/facturas'),
      ApiClient.get('/facturas/totales-mes'),
    ]);

    facturasState.facturas = facturas || [];
    facturasState.totalFacturado = totales?.totalFacturado || 0;
    facturasState.totalPendiente = totales?.totalPendiente || 0;
    facturasState.totalPagado = totales?.totalPagado || 0;

    renderFacturasTable(tableWrap);
  } catch (e) {
    tableWrap.innerHTML = htmlErrorView(String(e.message || e), 'retryFacturas');
    document.getElementById('retryFacturas')?.addEventListener('click', () => initFacturasScreen());
    if (typeof showVentasToast === 'function') {
      showVentasToast('Error cargando facturas: ' + String(e.message || e), 'danger');
    }
  } finally {
    facturasState.cargando = false;
  }

  // Actualizar el resumen de totales en la cabecera
  const totalEl = document.getElementById('facturasTotalMes');
  if (totalEl) {
    totalEl.textContent = facturasState.totalFacturado.toFixed(2) + ' €';
  }

  // Cargar clientes para el selector del modal
  await cargarClientesFacturaSelect();

  // Enlazar botones de acción
  document.getElementById('btnNuevaFactura')?.addEventListener('click', openNewFactura);
  document.getElementById('btnSaveFactura')?.addEventListener('click', saveFactura);
}

/**
 * Renderiza la tabla de facturas con todas las facturas cargadas.
 * Muestra: número de factura, cliente, total, estado (con chip de color) y fecha de emisión.
 * 
 * @param {HTMLElement} mount - Contenedor HTML donde se pinta la tabla
 */
function renderFacturasTable(mount) {
  if (!mount) return;

  if (facturasState.facturas.length === 0) {
    mount.innerHTML = htmlEmptyView({
      icon: 'description',
      title: 'Sin facturas',
      message: 'No hay facturas registradas todavía.',
      actionLabel: 'Nueva factura',
      onActionId: 'emptyNewFactura',
    });
    document.getElementById('emptyNewFactura')?.addEventListener('click', openNewFactura);
    return;
  }

  // Construir filas de la tabla
  const rows = facturasState.facturas.map(f => {
    const estadoColor = getEstadoColor(f.estado);
    const estadoLabel = getEstadoLabelStr(f.estado);
    const fecha = f.fechaEmision ? new Date(f.fechaEmision).toLocaleDateString('es-ES') : '-';
    const total = Number(f.total || 0).toFixed(2);

    return `
      <tr>
        <td>${esc(f.numeroFactura || '-')}</td>
        <td>${esc(f.clienteNombre || '-')}</td>
        <td class="text-end">${total} €</td>
        <td>${htmlStatusChip(estadoLabel, estadoColor)}</td>
        <td>${fecha}</td>
        <td>
          <div class="d-flex gap-1">
            <button class="btn btn-sm btn-outline-secondary" onclick="openEditFactura('${f.id}')" title="Ver/Editar">
              <span class="material-symbols-outlined" style="font-size:16px">visibility</span>
            </button>
            <button class="btn btn-sm btn-outline-success" onclick="marcarPagada('${f.id}')" title="Marcar como pagada" ${f.estado === 'pagada' ? 'disabled' : ''}>
              <span class="material-symbols-outlined" style="font-size:16px">check</span>
            </button>
            <button class="btn btn-sm btn-outline-danger" onclick="eliminarFactura('${f.id}')" title="Eliminar">
              <span class="material-symbols-outlined" style="font-size:16px">delete</span>
            </button>
          </div>
        </td>
      </tr>`;
  }).join('');

  mount.innerHTML = `
    <div class="KronoCard KronoCard--padding-zero">
      <table class="table table-hover mb-0">
        <thead>
          <tr>
            <th>Nº Factura</th>
            <th>Cliente</th>
            <th class="text-end">Total</th>
            <th>Estado</th>
            <th>Fecha</th>
            <th style="width:140px">Acciones</th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    </div>`;
}

/**
 * Abre el modal para crear una nueva factura.
 * Limpia los campos del formulario y resetea los valores por defecto.
 */
function openNewFactura() {
  // Limpiar campos del formulario
  document.getElementById('factCliente').value = '';
  document.getElementById('factClienteId').value = '';
  document.getElementById('factNif').value = '';
  document.getElementById('factBase').value = '';
  document.getElementById('factIvaPct').value = '21';
  document.getElementById('factIvaImp').value = '';
  document.getElementById('factTotal').value = '';
  document.getElementById('factMetodo').value = 'transferencia';

  // Abrir el modal de Bootstrap
  const modal = new bootstrap.Modal(document.getElementById('facturaModal'));
  modal.show();
}

/**
 * Guarda una nueva factura en el backend.
 * Lee los datos del formulario, calcula IVA y total si no están informados,
 * y envía la petición POST /api/facturas.
 */
async function saveFactura() {
  // Leer datos del formulario
  const clienteNombre = document.getElementById('factCliente')?.value.trim() || '';
  const clienteId = document.getElementById('factClienteId')?.value || null;
  const nif = document.getElementById('factNif')?.value.trim() || '';
  let base = parseFloat(document.getElementById('factBase')?.value) || 0;
  const ivaPct = parseFloat(document.getElementById('factIvaPct')?.value) || 21;
  let ivaImp = parseFloat(document.getElementById('factIvaImp')?.value) || 0;
  let total = parseFloat(document.getElementById('factTotal')?.value) || 0;
  const metodo = document.getElementById('factMetodo')?.value || 'transferencia';

  // Validar datos mínimos
  if (!clienteNombre || base <= 0) {
    alert('El cliente y la base imponible son obligatorios');
    return;
  }

  // Calcular IVA y total si no se han informado manualmente
  if (ivaImp === 0) ivaImp = base * (ivaPct / 100);
  if (total === 0) total = base + ivaImp;

  const payload = {
    clienteId: clienteId ? parseInt(clienteId) : null,
    clienteNombre: clienteNombre,
    clienteNif: nif,
    baseImponible: base,
    ivaPorcentaje: ivaPct,
    ivaImporte: Math.round(ivaImp * 100) / 100,
    total: Math.round(total * 100) / 100,
    estado: 'emitida',
    metodoPago: metodo,
    fechaVencimiento: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString(), // +15 días
  };

  try {
    await ApiClient.post('/facturas', payload);
    bootstrap.Modal.getInstance(document.getElementById('facturaModal'))?.hide();
    initFacturasScreen(); // Recargar para ver la nueva factura
    if (typeof showVentasToast === 'function') {
      showVentasToast('Factura creada correctamente', 'success');
    }
  } catch (e) {
    alert('Error al crear factura: ' + String(e.message || e));
  }
}

/**
 * Abre el modal de edición para una factura existente.
 * Carga los datos actuales de la factura desde el backend y los muestra en el formulario.
 * 
 * @param {string} id - ID de la factura a editar
 */
async function openEditFactura(id) {
  try {
    const factura = await ApiClient.get('/facturas/' + id);
    if (!factura) return;

    // Precargar los campos del formulario con los datos actuales
    document.getElementById('factCliente').value = factura.clienteNombre || '';
    document.getElementById('factClienteId').value = factura.clienteId || '';
    document.getElementById('factNif').value = factura.clienteNif || '';
    document.getElementById('factBase').value = factura.baseImponible || '';
    document.getElementById('factIvaPct').value = factura.ivaPorcentaje || '21';
    document.getElementById('factIvaImp').value = factura.ivaImporte || '';
    document.getElementById('factTotal').value = factura.total || '';
    document.getElementById('factMetodo').value = factura.metodoPago || 'transferencia';

    // Abrir el modal
    const modal = new bootstrap.Modal(document.getElementById('facturaModal'));
    modal.show();
  } catch (e) {
    alert('Error al cargar factura: ' + String(e.message || e));
  }
}

/**
 * Marca una factura como pagada.
 * Envía PATCH /api/facturas/{id}/estado con estado "pagada".
 * El backend registra automáticamente la fecha de pago.
 * 
 * @param {string} id - ID de la factura a marcar como pagada
 */
async function marcarPagada(id) {
  if (!confirm('¿Marcar esta factura como pagada?')) return;

  try {
    await ApiClient.patch('/facturas/' + id + '/estado', { estado: 'pagada' });
    initFacturasScreen(); // Recargar para ver el cambio
    if (typeof showVentasToast === 'function') {
      showVentasToast('Factura marcada como pagada', 'success');
    }
  } catch (e) {
    alert('Error al actualizar factura: ' + String(e.message || e));
  }
}

/**
 * Elimina una factura del sistema.
 * Solicita confirmación antes de eliminar.
 * 
 * @param {string} id - ID de la factura a eliminar
 */
async function eliminarFactura(id) {
  if (!confirm('¿Estás seguro de eliminar esta factura? Esta acción no se puede deshacer.')) return;

  try {
    await ApiClient.delete('/facturas/' + id);
    initFacturasScreen(); // Recargar para ver el cambio
    if (typeof showVentasToast === 'function') {
      showVentasToast('Factura eliminada', 'success');
    }
  } catch (e) {
    alert('Error al eliminar factura: ' + String(e.message || e));
  }
}

/**
 * Devuelve el color asociado a cada estado de factura.
 * @param {string} estado - emitida, pagada, vencida, cancelada
 * @returns {string} Color CSS
 */
function getEstadoColor(estado) {
  const colors = {
    emitida: 'var(--krono-warning)',
    pagada: 'var(--krono-success)',
    vencida: 'var(--krono-danger)',
    cancelada: 'var(--krono-muted)',
  };
  return colors[estado] || 'var(--krono-muted)';
}

/**
 * Devuelve la etiqueta legible del estado de factura.
 * @param {string} estado - emitida, pagada, vencida, cancelada
 * @returns {string} Etiqueta en español
 */
function getEstadoLabelStr(estado) {
  const labels = {
    emitida: 'Emitida',
    pagada: 'Pagada',
    vencida: 'Vencida',
    cancelada: 'Cancelada',
  };
  return labels[estado] || estado || 'Emitida';
}

/** Carga clientes desde la API y llena el select del modal de facturas */
async function cargarClientesFacturaSelect() {
  const sel = document.getElementById('factCliente');
  if (!sel || sel.tagName !== 'SELECT') return;
  try {
    const clientes = await ApiClient.get('/clientes');
    clientes.forEach(c => {
      const opt = document.createElement('option');
      opt.value = c.nombre;
      opt.textContent = c.nombre + (c.apellidos ? ' ' + c.apellidos : '');
      sel.appendChild(opt);
    });
  } catch (e) {
    console.warn('No se pudieron cargar clientes:', e);
  }
}

/** Escapa HTML para prevenir XSS */
function esc(s) {
  if (typeof window.esc === 'function') return window.esc(s);
  return String(s).replace(/&/g, '&').replace(/</g, '<').replace(/>/g, '>');
}