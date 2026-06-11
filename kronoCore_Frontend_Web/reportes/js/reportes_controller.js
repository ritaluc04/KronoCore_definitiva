/**
 * reportes_controller.js — Controlador de la pantalla de Informes y Exportación.
 * 
 * RESPONSABILIDADES:
 * - Cargar métricas resumidas de clientes, citas, ventas y tareas
 * - Permitir exportar datos a CSV con filtros opcionales
 * - Filtros disponibles: rango de fechas, estado de cita, prioridad de tarea
 * 
 * ENDPOINTS UTILIZADOS:
 * - GET /api/clientes → Contar total de clientes
 * - GET /api/citas → Contar citas totales, confirmadas y pendientes
 * - GET /api/ventas → Contar total de ventas
 * - GET /api/tareas → Contar total de tareas y tareas de alta prioridad
 * - GET /api/reportes/clientes → Exportar CSV clientes
 * - GET /api/reportes/citas?estado=&desde=&hasta= → Exportar CSV citas
 * - GET /api/reportes/ventas?desde=&hasta= → Exportar CSV ventas
 * - GET /api/reportes/tareas?estado=&prioridad= → Exportar CSV tareas
 */

/**
 * Inicializa la pantalla de Informes.
 * Carga las métricas y enlaza los botones de exportación CSV.
 */
async function initReportesScreen() {
  const metricsEl = document.getElementById('reportesMetrics');
  const extraChipsEl = document.getElementById('reportesExtraChips');

  // Mostrar indicador de carga mientras se obtienen los datos
  metricsEl.innerHTML = htmlLoadingView();

  try {
    // Cargar todos los datos en paralelo para máxima velocidad
    const [clientes, citas, ventas, tareas] = await Promise.all([
      ApiClient.get('/clientes'),
      ApiClient.get('/citas'),
      ApiClient.get('/ventas'),
      ApiClient.get('/tareas'),
    ]);

    // Calcular métricas
    const totalClientes = (clientes || []).length;
    const totalCitas = (citas || []).length;
    const totalVentas = (ventas || []).length;
    const totalTareas = (tareas || []).length;

    // Cálculos adicionales para chips de estado
    const citasConfirmadas = (citas || []).filter(c => c.estado === 'confirmada').length;
    const citasPendientes = (citas || []).filter(c => c.estado === 'pendiente').length;
    const tareasAlta = (tareas || []).filter(t => t.prioridad === 'alta').length;

    // Renderizar tarjetas de métricas (4 KPIs principales)
    metricsEl.innerHTML = [
      { title: 'Clientes', value: totalClientes, icon: 'people_outline' },
      { title: 'Citas', value: totalCitas, icon: 'event' },
      { title: 'Ventas', value: totalVentas, icon: 'point_of_sale' },
      { title: 'Tareas', value: totalTareas, icon: 'view_kanban' },
    ].map(m => `
      <div style="width:210px">
        <div class="KronoCard">
          <div class="d-flex flex-row align-items-center">
            <div style="width:42px;height:42px;background:rgba(29,78,216,0.12);border-radius:12px;display:flex;align-items:center;justify-content:center">
              <span class="material-symbols-outlined" style="color:var(--krono-primary)">${m.icon}</span>
            </div>
            <div class="ms-3">
              <div style="font-size:12px;color:var(--krono-muted)">${m.title}</div>
              <div style="font-size:22px;font-weight:700">${m.value}</div>
            </div>
          </div>
        </div>
      </div>
    `).join('');

    // Renderizar chips de estado (información adicional)
    if (extraChipsEl) {
      extraChipsEl.innerHTML =
        htmlStatusChip('Confirmadas ' + citasConfirmadas, 'var(--krono-success)', 'check_circle_outline') +
        '<span class="mx-1"></span>' +
        htmlStatusChip('Pendientes ' + citasPendientes, 'var(--krono-warning)', 'schedule') +
        '<span class="mx-1"></span>' +
        htmlStatusChip('Alta prioridad ' + tareasAlta, 'var(--krono-danger)', 'flag_outlined');
    }

  } catch (e) {
    metricsEl.innerHTML = htmlErrorView(String(e.message || e), 'retryReportes');
    document.getElementById('retryReportes')?.addEventListener('click', () => initReportesScreen());
  }

  // Enlazar botones de exportación
  document.getElementById('btnExportClientes')?.addEventListener('click', () => exportarCsv('/reportes/clientes'));
  document.getElementById('btnExportCitas')?.addEventListener('click', () => exportarCitas());
  document.getElementById('btnExportVentas')?.addEventListener('click', () => exportarVentas());
  document.getElementById('btnExportTareas')?.addEventListener('click', () => exportarTareas());
}

/**
 * Exporta clientes a CSV (sin filtros adicionales).
 * Llama directamente al endpoint /api/reportes/clientes
 */
async function exportarCsv(endpoint) {
  try {
    // Construir la URL completa con los filtros de fecha si están informados
    const desde = document.getElementById('reportesDesde')?.value || '';
    const hasta = document.getElementById('reportesHasta')?.value || '';
    let url = endpoint;
    const params = [];
    if (desde) params.push('desde=' + encodeURIComponent(desde));
    if (hasta) params.push('hasta=' + encodeURIComponent(hasta));
    if (params.length > 0) url += '?' + params.join('&');

    // Realizar la petición GET y forzar la descarga del archivo CSV
    const token = SessionController.instance.accessToken;
    const response = await fetch(ApiClient.baseUrl + url, {
      headers: {
        'Authorization': 'Bearer ' + token,
        'Accept': 'text/csv',
      },
    });

    if (!response.ok) throw new Error('Error HTTP ' + response.status);

    // Crear un blob y forzar la descarga en el navegador
    const blob = await response.blob();
    const downloadUrl = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = downloadUrl;
    a.download = endpoint.split('/').pop() + '.csv';
    document.body.appendChild(a);
    a.click();
    a.remove();
    window.URL.revokeObjectURL(downloadUrl);

    if (typeof showVentasToast === 'function') {
      showVentasToast('CSV exportado correctamente', 'success');
    }
  } catch (e) {
    alert('Error al exportar: ' + String(e.message || e));
  }
}

/**
 * Exporta citas a CSV con filtro opcional de estado.
 * Lee el valor del selector de estado de cita en la página.
 */
async function exportarCitas() {
  const estado = document.getElementById('reportesEstado')?.value || '';
  let endpoint = '/reportes/citas';
  const params = [];
  if (estado) params.push('estado=' + encodeURIComponent(estado));
  const desde = document.getElementById('reportesDesde')?.value || '';
  const hasta = document.getElementById('reportesHasta')?.value || '';
  if (desde) params.push('desde=' + encodeURIComponent(desde));
  if (hasta) params.push('hasta=' + encodeURIComponent(hasta));
  if (params.length > 0) endpoint += '?' + params.join('&');
  await exportarCsv(endpoint);
}

/**
 * Exporta ventas a CSV con filtro opcional de rango de fechas.
 */
async function exportarVentas() {
  let endpoint = '/reportes/ventas';
  const params = [];
  const desde = document.getElementById('reportesDesde')?.value || '';
  const hasta = document.getElementById('reportesHasta')?.value || '';
  if (desde) params.push('desde=' + encodeURIComponent(desde));
  if (hasta) params.push('hasta=' + encodeURIComponent(hasta));
  if (params.length > 0) endpoint += '?' + params.join('&');
  await exportarCsv(endpoint);
}

/**
 * Exporta tareas a CSV con filtros opcionales de estado y prioridad.
 */
async function exportarTareas() {
  let endpoint = '/reportes/tareas';
  const params = [];
  const estado = document.getElementById('reportesEstado')?.value || '';
  const prioridad = document.getElementById('reportesPrioridad')?.value || '';
  if (estado) params.push('estado=' + encodeURIComponent(estado));
  if (prioridad) params.push('prioridad=' + encodeURIComponent(prioridad));
  if (params.length > 0) endpoint += '?' + params.join('&');
  await exportarCsv(endpoint);
}