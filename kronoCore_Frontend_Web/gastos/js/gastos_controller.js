/**
 * gastos_controller.js — Controlador del módulo de Gastos del negocio.
 * 
 * RESPONSABILIDADES:
 * - Listar todos los gastos registrados con categoría, proveedor, importe y fecha
 * - Crear nuevos gastos con categorización y marcado de deducibles fiscales
 * - Editar y eliminar gastos existentes
 * - Mostrar totales de gastos del mes actual (total gastos + total deducible)
 * 
 * ENDPOINTS UTILIZADOS:
 * - GET /api/gastos → Listar gastos
 * - POST /api/gastos → Crear gasto
 * - PUT /api/gastos/{id} → Actualizar gasto
 * - DELETE /api/gastos/{id} → Eliminar gasto
 * - GET /api/gastos/{id} → Obtener detalle de gasto
 * - GET /api/gastos/totales-mes → Totales de gastos del mes
 * 
 * CATEGORÍAS DISPONIBLES:
 * - alquiler: Alquiler del local
 * - suministros: Luz, agua, internet, teléfono
 * - proveedores: Material, productos, mercancía
 * - marketing: Publicidad, promoción, redes sociales
 * - otros: Cualquier otro tipo de gasto no categorizado
 * 
 * CADA GASTO INCLUYE:
 * - Categoría, descripción y proveedor
 * - Importe base, IVA (porcentaje e importe), total
 * - Método de pago (efectivo, tarjeta, transferencia)
 * - Indicador de si es fiscalmente deducible
 * - Fecha del gasto y fecha de registro
 */

/** Estado compartido del módulo de gastos */
let gastosState = {
  gastos: [],              // Lista de gastos cargados
  cargando: false,         // Indicador de carga
  totalGastos: 0,          // Total gastos del mes
  totalDeducible: 0,       // Total deducible del mes
};

/**
 * Inicializa la pantalla de Gastos.
 * Carga los gastos y los totales del mes desde la API,
 * luego renderiza la tabla y enlaza los eventos de los botones.
 */
async function initGastosScreen() {
  const tableWrap = document.getElementById('gastosTableWrap');
  if (!tableWrap) return;

  gastosState.cargando = true;
  tableWrap.innerHTML = htmlLoadingView();

  try {
    // Cargar gastos y totales del mes en paralelo
    const [gastos, totales] = await Promise.all([
      ApiClient.get('/gastos'),
      ApiClient.get('/gastos/totales-mes'),
    ]);

    gastosState.gastos = gastos || [];
    gastosState.totalGastos = totales?.totalGastos || 0;
    gastosState.totalDeducible = totales?.totalDeducible || 0;

    renderGastosTable(tableWrap);
  } catch (e) {
    tableWrap.innerHTML = htmlErrorView(String(e.message || e), 'retryGastos');
    document.getElementById('retryGastos')?.addEventListener('click', () => initGastosScreen());
    if (typeof showVentasToast === 'function') {
      showVentasToast('Error cargando gastos: ' + String(e.message || e), 'danger');
    }
  } finally {
    gastosState.cargando = false;
  }

  // Actualizar el resumen de totales en la cabecera
  const totalEl = document.getElementById('gastosTotalMes');
  if (totalEl) {
    totalEl.innerHTML = `Total gastos mes: <strong>${gastosState.totalGastos.toFixed(2)} €</strong> · Deducible: <strong>${gastosState.totalDeducible.toFixed(2)} €</strong>`;
  }

  // Enlazar botones de acción
  document.getElementById('btnNuevoGasto')?.addEventListener('click', openNewGasto);
  document.getElementById('btnGuardarGasto')?.addEventListener('click', saveGasto);
}

/**
 * Renderiza la tabla de gastos con todos los gastos cargados.
 * Muestra: categoría (con icono), descripción, proveedor, importe total y fecha.
 * Cada fila tiene botones para editar y eliminar.
 * 
 * @param {HTMLElement} mount - Contenedor HTML donde se pinta la tabla
 */
function renderGastosTable(mount) {
  if (!mount) return;

  if (gastosState.gastos.length === 0) {
    mount.innerHTML = htmlEmptyView({
      icon: 'receipt_long',
      title: 'Sin gastos',
      message: 'No hay gastos registrados todavía.',
      actionLabel: 'Nuevo gasto',
      onActionId: 'emptyNewGasto',
    });
    document.getElementById('emptyNewGasto')?.addEventListener('click', openNewGasto);
    return;
  }

  // Construir filas de la tabla
  const rows = gastosState.gastos.map(g => {
    const categoriaIcon = getCategoriaIcon(g.categoria);
    const categoriaLabel = getCategoriaLabel(g.categoria);
    const fecha = g.fecha ? new Date(g.fecha).toLocaleDateString('es-ES') : '-';
    const total = Number(g.total || 0).toFixed(2);
    const deducibleBadge = g.deducible
      ? '<span class="badge bg-success ms-1" style="font-size:10px">Deducible</span>'
      : '';

    return `
      <tr>
        <td>
          <span class="material-symbols-outlined me-2" style="font-size:18px;vertical-align:middle">${categoriaIcon}</span>
          ${categoriaLabel}
        </td>
        <td>${esc(g.descripcion || '-')}${deducibleBadge}</td>
        <td>${esc(g.proveedor || '-')}</td>
        <td class="text-end">${total} €</td>
        <td>${fecha}</td>
        <td>
          <div class="d-flex gap-1">
            <button class="btn btn-sm btn-outline-secondary" onclick="openEditGasto('${g.id}')" title="Editar">
              <span class="material-symbols-outlined" style="font-size:16px">edit</span>
            </button>
            <button class="btn btn-sm btn-outline-danger" onclick="eliminarGasto('${g.id}')" title="Eliminar">
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
            <th>Categoría</th>
            <th>Descripción</th>
            <th>Proveedor</th>
            <th class="text-end">Importe</th>
            <th>Fecha</th>
            <th style="width:100px">Acciones</th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    </div>`;
}

/**
 * Abre el modal para crear un nuevo gasto.
 * Limpia los campos del formulario y resetea los valores por defecto.
 * Establece la fecha actual como fecha por defecto del gasto.
 */
function openNewGasto() {
  // Limpiar campos del formulario
  document.getElementById('gastoId').value = '';
  document.getElementById('gastoModalTitle').textContent = 'Nuevo Gasto';
  document.getElementById('gastoCategoria').value = 'proveedores';
  document.getElementById('gastoDescripcion').value = '';
  document.getElementById('gastoProveedor').value = '';
  document.getElementById('gastoImporte').value = '';
  document.getElementById('gastoIvaPct').value = '21';
  document.getElementById('gastoIvaImp').value = '';
  document.getElementById('gastoTotal').value = '';
  document.getElementById('gastoMetodo').value = 'transferencia';
  document.getElementById('gastoDeducible').checked = true;
  document.getElementById('gastoFecha').value = new Date().toISOString().split('T')[0]; // Fecha actual

  // Abrir el modal de Bootstrap
  const modal = new bootstrap.Modal(document.getElementById('gastoModal'));
  modal.show();
}

/**
 * Abre el modal de edición para un gasto existente.
 * Carga los datos actuales del gasto desde el backend y los muestra en el formulario.
 * 
 * @param {string} id - ID del gasto a editar
 */
async function openEditGasto(id) {
  try {
    const gasto = await ApiClient.get('/gastos/' + id);
    if (!gasto) return;

    // Precargar los campos del formulario con los datos actuales
    document.getElementById('gastoId').value = gasto.id;
    document.getElementById('gastoModalTitle').textContent = 'Editar Gasto';
    document.getElementById('gastoCategoria').value = gasto.categoria || 'proveedores';
    document.getElementById('gastoDescripcion').value = gasto.descripcion || '';
    document.getElementById('gastoProveedor').value = gasto.proveedor || '';
    document.getElementById('gastoImporte').value = gasto.importe || '';
    document.getElementById('gastoIvaPct').value = gasto.ivaPorcentaje || '21';
    document.getElementById('gastoIvaImp').value = gasto.ivaImporte || '';
    document.getElementById('gastoTotal').value = gasto.total || '';
    document.getElementById('gastoMetodo').value = gasto.metodoPago || 'transferencia';
    document.getElementById('gastoDeducible').checked = gasto.deducible !== false;
    document.getElementById('gastoFecha').value = gasto.fecha ? gasto.fecha.split('T')[0] : new Date().toISOString().split('T')[0];

    // Abrir el modal
    const modal = new bootstrap.Modal(document.getElementById('gastoModal'));
    modal.show();
  } catch (e) {
    alert('Error al cargar gasto: ' + String(e.message || e));
  }
}

/**
 * Guarda un gasto (nuevo o edición) en el backend.
 * Lee los datos del formulario, calcula IVA y total si no están informados,
 * y envía la petición POST o PUT según corresponda.
 * 
 * Si hay un ID en el campo oculto 'gastoId', se trata de una edición (PUT).
 * Si no hay ID, se trata de un nuevo gasto (POST).
 */
async function saveGasto() {
  const id = document.getElementById('gastoId')?.value || '';
  const isEdit = !!id;

  // Leer datos del formulario
  const categoria = document.getElementById('gastoCategoria')?.value || 'otros';
  const descripcion = document.getElementById('gastoDescripcion')?.value.trim() || '';
  const proveedor = document.getElementById('gastoProveedor')?.value.trim() || '';
  let importe = parseFloat(document.getElementById('gastoImporte')?.value) || 0;
  const ivaPct = parseFloat(document.getElementById('gastoIvaPct')?.value) || 21;
  let ivaImp = parseFloat(document.getElementById('gastoIvaImp')?.value) || 0;
  let total = parseFloat(document.getElementById('gastoTotal')?.value) || 0;
  const metodo = document.getElementById('gastoMetodo')?.value || 'transferencia';
  const deducible = document.getElementById('gastoDeducible')?.checked || false;
  const fecha = document.getElementById('gastoFecha')?.value
    ? new Date(document.getElementById('gastoFecha').value).toISOString()
    : new Date().toISOString();

  // Validar datos mínimos
  if (!descripcion || importe <= 0) {
    alert('La descripción y el importe son obligatorios');
    return;
  }

  // Calcular IVA y total si no se han informado manualmente
  if (ivaImp === 0) ivaImp = importe * (ivaPct / 100);
  if (total === 0) total = importe + ivaImp;

  const payload = {
    categoria: categoria,
    descripcion: descripcion,
    proveedor: proveedor,
    numeroFactura: null,
    importe: importe,
    ivaPorcentaje: ivaPct,
    ivaImporte: Math.round(ivaImp * 100) / 100,
    total: Math.round(total * 100) / 100,
    metodoPago: metodo,
    deducible: deducible,
    fecha: fecha,
  };

  try {
    if (isEdit) {
      await ApiClient.put('/gastos/' + id, payload);
    } else {
      await ApiClient.post('/gastos', payload);
    }
    bootstrap.Modal.getInstance(document.getElementById('gastoModal'))?.hide();
    initGastosScreen(); // Recargar para ver los cambios
    if (typeof showVentasToast === 'function') {
      showVentasToast(isEdit ? 'Gasto actualizado' : 'Gasto creado correctamente', 'success');
    }
  } catch (e) {
    alert('Error al guardar gasto: ' + String(e.message || e));
  }
}

/**
 * Elimina un gasto del sistema.
 * Solicita confirmación antes de eliminar.
 * 
 * @param {string} id - ID del gasto a eliminar
 */
async function eliminarGasto(id) {
  if (!confirm('¿Estás seguro de eliminar este gasto?')) return;

  try {
    await ApiClient.delete('/gastos/' + id);
    initGastosScreen(); // Recargar para ver el cambio
    if (typeof showVentasToast === 'function') {
      showVentasToast('Gasto eliminado', 'success');
    }
  } catch (e) {
    alert('Error al eliminar gasto: ' + String(e.message || e));
  }
}

/**
 * Devuelve el icono de Material Symbols asociado a cada categoría de gasto.
 * @param {string} categoria - alquiler, suministros, proveedores, marketing, otros
 * @returns {string} Nombre del icono de Material Symbols
 */
function getCategoriaIcon(categoria) {
  const icons = {
    alquiler: 'home',
    suministros: 'bolt',
    proveedores: 'inventory_2',
    marketing: 'campaign',
    otros: 'more_horiz',
  };
  return icons[categoria] || 'receipt_long';
}

/**
 * Devuelve la etiqueta legible en español de cada categoría de gasto.
 * @param {string} categoria - alquiler, suministros, proveedores, marketing, otros
 * @returns {string} Etiqueta en español
 */
function getCategoriaLabel(categoria) {
  const labels = {
    alquiler: 'Alquiler',
    suministros: 'Suministros',
    proveedores: 'Proveedores',
    marketing: 'Marketing',
    otros: 'Otros',
  };
  return labels[categoria] || categoria || 'Otros';
}

/** Escapa HTML para prevenir XSS */
function esc(s) {
  if (typeof window.esc === 'function') return window.esc(s);
  return String(s).replace(/&/g, '&').replace(/</g, '<').replace(/>/g, '>');
}