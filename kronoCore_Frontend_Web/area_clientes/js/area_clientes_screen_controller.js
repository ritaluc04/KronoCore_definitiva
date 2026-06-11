/**
 * Área de Clientes — screen_controller.js
 * Pantalla del cliente: carga citas y compras recientes desde la API.
 */

/**
 * Inicializa la pantalla "Mis citas" del área de cliente.
 * Carga citas y ventas desde el backend y las renderiza en el DOM.
 */
async function initMisCitasScreen() {
  const wrap = document.getElementById('misCitasList');
  const comprasWrap = document.getElementById('misComprasList');
  if (!wrap) return;

  wrap.innerHTML = htmlLoadingView();
  if (comprasWrap) comprasWrap.innerHTML = htmlLoadingView();

  try {
    const citas = await ApiClient.get('/citas');
    const ventas = await ApiClient.get('/ventas');
    // Mostrar solo las citas y compras más recientes
    const misCitas = citas.slice(0, 4);
    const misCompras = ventas.slice(0, 10).flatMap((venta) =>
      (venta.detalles || []).map((d) => ({
        productoNombre: d.productoNombre,
        subtotal: d.subtotal,
        fecha: venta.fecha,
      }))
    );

    const fmt = new Intl.DateTimeFormat('es-ES', {
      weekday: 'short',
      day: 'numeric',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit',
    });

    wrap.innerHTML = misCitas.length
      ? misCitas.map((c) => {
          const chipColor =
            c.estado === CitaEstado.confirmada
              ? 'var(--krono-success)'
              : c.estado === CitaEstado.pendiente
                ? 'var(--krono-warning)'
                : 'var(--krono-muted)';
          const chip = htmlStatusChip(c.estado, chipColor);
          return (
            '<div class="MisCitasScreen-card">' +
            htmlKronoCard(
              '<div class="d-flex flex-row align-items-center">' +
                '<div class="MisCitasScreen-iconBox flex-shrink-0"><span class="material-symbols-outlined">event</span></div>' +
                '<div class="ms-3 flex-fill" style="min-width:0">' +
                '<div class="fw-semibold">' +
                esc(c.servicio) +
                '</div>' +
                '<div class="text-muted small">' +
                esc(fmt.format(new Date(c.inicio))) +
                '</div>' +
                '<div class="text-muted small">' +
                esc(c.empresaNombre || 'Sin empresa') +
                '</div></div>' +
                chip +
                '<button type="button" class="btn btn-link btn-sm ms-2">Cancelar</button>' +
                '</div>'
            ) +
            '</div>'
          );
        }).join('')
      : htmlEmptyView({
          icon: 'event_busy',
          title: 'Aún no tienes citas',
          message: 'Cuando reserves una cita aparecerá aquí.',
        });

    if (comprasWrap) {
      comprasWrap.innerHTML = misCompras.length
        ? '<div class="table-responsive"><table class="table align-middle mb-0"><thead><tr><th>Producto</th><th>Importe</th><th>Fecha</th></tr></thead><tbody>' +
          misCompras.map((c) => '<tr><td>' + esc(c.productoNombre || '') + '</td><td>€ ' + Number(c.subtotal || 0).toFixed(2) + '</td><td>' + esc(new Intl.DateTimeFormat('es-ES', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }).format(new Date(c.fecha))) + '</td></tr>').join('') +
          '</tbody></table></div>'
        : htmlEmptyView({
            icon: 'shopping_bag',
            title: 'Aún no hay compras',
            message: 'Las compras aparecerán aquí cuando se registren.',
          });
    }
  } catch (e) {
    wrap.innerHTML = htmlErrorView(String(e.message || e), 'retryMisCitas');
    document.getElementById('retryMisCitas')?.addEventListener('click', () => initMisCitasScreen());
    if (typeof showSolToast === 'function') showSolToast('Error cargando tus citas: ' + String(e.message || e));
  }
}

// —— Utilidad de escape HTML ——
function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}
