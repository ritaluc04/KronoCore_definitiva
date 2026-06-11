/**
 * dashboard_page.js — Lógica del panel principal (Dashboard).
 * 
 * RESPONSABILIDADES:
 * - Cargar métricas del backend (/api/dashboard/resumen)
 * - Renderizar tarjetas de KPI (MetricCard)
 * - Cargar datos adicionales (ventas, citas, tareas) para feed y gráfico
 * - Renderizar alertas de stock bajo
 * - Renderizar feed de actividad reciente
 * - Inicializar gráfico de ventas con Chart.js
 * 
 * FLUJO:
 * 1. Cargar datos de 4 endpoints en paralelo (Promise.all)
 * 2. Renderizar tarjetas de métricas
 * 3. Renderizar alerta de stock bajo
 * 4. Renderizar chips de estado
 * 5. Renderizar feed de actividad
 * 6. Inicializar gráfico Chart.js
 */

/** Inicializa y renderiza la pantalla del Dashboard */
async function initDashboardPage() {
  const metricsEl = document.getElementById('metricsWrap');
  const activityEl = document.getElementById('activityFeed');
  metricsEl.innerHTML = htmlLoadingView();
  activityEl.innerHTML = htmlLoadingView();

  try {
    // Cargar datos en paralelo para máxima velocidad
    const [resumen, ventas, citas, tareas] = await Promise.all([
      ApiClient.get('/dashboard/resumen'),
      ApiClient.get('/ventas'),
      ApiClient.get('/citas'),
      ApiClient.get('/tareas'),
    ]);

    const citasPendientes = citas.filter((c) => c.estado === 'pendiente').length;
    const citasConfirmadas = citas.filter((c) => c.estado === 'confirmada').length;
    const tareasActivas = tareas.filter((t) => t.estado !== 'finalizado').length;
    const tareasAlta = tareas.filter((t) => t.prioridad === 'alta').length;

    // Tarjetas de métricas (6 KPIs)
    metricsEl.innerHTML = [
      htmlMetricCard({ titulo: 'Ventas hoy', valor: `${Number(resumen.ventasHoy || 0).toFixed(2)} €`, delta: '+0%', icon: 'point_of_sale', color: 'var(--krono-primary)' }),
      htmlMetricCard({ titulo: 'Ventas del mes', valor: `${Number(resumen.ventasMes || 0).toFixed(2)} €`, delta: '', icon: 'trending_up', color: 'var(--krono-accent)' }),
      htmlMetricCard({ titulo: 'Citas hoy', valor: String(resumen.citasHoy || 0), delta: '+0', icon: 'event', color: 'var(--krono-accent)' }),
      htmlMetricCard({ titulo: 'Stock alertas', valor: String((resumen.productosStockBajo || []).length), delta: '-1', icon: 'inventory_2', color: 'var(--krono-warning)' }),
      htmlMetricCard({ titulo: 'Tareas activas', valor: String(tareasActivas), delta: '+0', icon: 'task_alt', color: 'var(--krono-success)' }),
      htmlMetricCard({ titulo: 'Alta prioridad', valor: String(tareasAlta), delta: '+0', icon: 'flag', color: 'var(--krono-danger)' }),
    ].map((h) => `<div class="MetricCard-wrap">${h}</div>`).join('');

    // Chips informativos (citas confirmadas, tareas alta prioridad)
    const chartHeaderWrap = document.getElementById('chartExtraChips');
    if (chartHeaderWrap) {
      chartHeaderWrap.innerHTML = 
        htmlStatusChip(`Confirmadas ${citasConfirmadas}`, 'var(--krono-success)', 'check_circle') +
        '<span class="mx-1"></span>' +
        htmlStatusChip(`Tareas altas ${tareasAlta}`, 'var(--krono-danger)', 'flag');
    }

    // Alerta de stock bajo (tarjeta roja si hay productos críticos)
    if (resumen.productosStockBajo && resumen.productosStockBajo.length > 0) {
      const stockHtml = '<div class="KronoCard mt-3 p-3" style="border-left:4px solid var(--krono-danger)">' +
        '<div class="d-flex flex-row align-items-center mb-2">' +
        '<span class="material-symbols-outlined me-2" style="color:var(--krono-danger)">warning</span>' +
        '<span class="krono-title-medium">Productos con stock bajo</span></div>' +
        resumen.productosStockBajo.map(p =>
          `<div class="d-flex flex-row align-items-center py-1" style="font-size:13px"><span class="flex-fill">${esc(p.nombre || '')}</span><span style="color:var(--krono-danger);font-weight:600">${p.stock ?? 0} / ${p.stockMin ?? 0}</span></div>`
        ).join('') + '</div>';
      metricsEl.innerHTML += stockHtml;
    }

    // Feed de actividad reciente (ventas + citas recientes)
    activityEl.innerHTML =
      '<div class="d-flex flex-row mb-3"><span class="krono-title-medium">Actividad reciente</span></div>' +
      [...ventas.slice(0, 3).map((v) => ({ icon: 'point_of_sale', texto: `${v.clienteNombre || 'Venta'} · ${Number(v.total || 0).toFixed(2)} €`, time: v.fecha })),
       ...citas.slice(0, 3).map((c) => ({ icon: 'event', texto: `${c.clienteNombre || 'Cliente'} · ${c.servicio}`, time: c.inicio }))]
        .map((item) => {
          const time = new Date(item.time).toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });
          return `<div class="_ActivityFeed-item d-flex flex-row align-items-start"><div class="_ActivityFeed-icon"><span class="material-symbols-outlined" style="font-size:16px;color:var(--krono-muted)">${item.icon}</span></div><div class="flex-fill ms-2" style="font-size:13px">${esc(item.texto)}</div><span style="font-size:11px;color:var(--krono-muted)">${time}</span></div>`;
        }).join('');

    initVentasChart(ventas);
  } catch (e) {
    metricsEl.innerHTML = htmlErrorView(String(e.message || e), 'retryDashboard');
    activityEl.innerHTML = '';
    document.getElementById('retryDashboard')?.addEventListener('click', () => initDashboardPage());
  }
}

/** Inicializa y pinta el gráfico de líneas de ventas con Chart.js */
function initVentasChart(ventas) {
  const ctx = document.getElementById('ventasChart');
  if (!ctx || typeof Chart === 'undefined') return;

  const dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  const values = dias.map((_, index) => {
    const target = new Date(); target.setDate(target.getDate() - (6 - index));
    return ventas.filter((v) => new Date(v.fecha).toDateString() === target.toDateString()).reduce((sum, v) => sum + Number(v.total || 0), 0);
  });

  new Chart(ctx, {
    type: 'line', data: { labels: dias, datasets: [{ data: values, borderColor: '#1d4ed8', backgroundColor: 'rgba(29, 78, 216, 0.12)', borderWidth: 3, fill: true, tension: 0.35, pointRadius: 4, pointBackgroundColor: '#1d4ed8' }] },
    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { x: { grid: { display: false }, ticks: { color: '#64748b', font: { size: 11 } } }, y: { grid: { color: '#e2e8f0', drawBorder: false }, ticks: { color: '#64748b', font: { size: 10 } } } } }
  });
}

/** Escapa HTML para insertar texto de usuario de forma segura en el DOM */
function esc(s) { return String(s).replace(/&/g, '&').replace(/</g, '<').replace(/>/g, '>'); }