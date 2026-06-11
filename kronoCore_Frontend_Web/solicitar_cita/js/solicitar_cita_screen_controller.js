/**
 * Controlador del asistente «Solicitar cita» (área cliente).
 * Wizard de 5 pasos: empresa, servicio, día, hora y confirmación con POST /citas.
 */

/** Arranca el stepper en #solicitarStepper y mantiene el estado del flujo en un objeto local. */
function initSolicitarCitaScreen() {
  const mount = document.getElementById('solicitarStepper');
  if (!mount) return;

  // Estado del wizard: paso actual y selecciones del usuario
  const state = {
    step: 0,
    servicio: 'Corte',
    diaSeleccionado: null,
    horaSeleccionada: null,
    empresaSeleccionada: null,
    empresas: [],
    cargaEmpresas: false,
  };

  const servicios = ['Corte', 'Color', 'Tratamiento', 'Corte + barba'];
  const fmtDia = new Intl.DateTimeFormat('es-ES', { weekday: 'short', day: 'numeric', month: 'short' });
  const fmtHora = (h, m) => `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;

  /** Genera los próximos 14 días laborables (excluye domingos) para elegir fecha. */
  function getDiasDisponibles() {
    const dias = [];
    const hoy = new Date();
    for (let i = 1; i <= 14; i++) {
      const d = new Date(hoy.getFullYear(), hoy.getMonth(), hoy.getDate() + i);
      if (d.getDay() !== 0) dias.push(d);
    }
    return dias;
  }

  /** Busca empresas por nombre vía GET /empresas?q= y actualiza la lista del paso 0. */
  async function buscarEmpresas(q) {
    if (!q.trim()) {
      state.empresas = [];
      state.empresaSeleccionada = null;
      render();
      return;
    }
    state.cargaEmpresas = true;
    render();
    try {
      state.empresas = await ApiClient.get(`/empresas?q=${encodeURIComponent(q.trim())}`);
    } catch (e) {
      state.empresas = [];
      showSolToast('Error buscando empresas: ' + String(e.message || e));
    } finally {
      state.cargaEmpresas = false;
      render();
    }
  }

  /** Franjas horarias fijas ofrecidas en el paso de selección de hora. */
  function getHorasDisponibles() {
    return [9, 10, 11, 12, 13, 16, 17, 18, 19].map((h) => ({ hora: h, minutos: 0 }));
  }

  /**
   * Pinta el indicador de pasos, el cuerpo del paso actual y los botones Continuar/Atrás.
   * Re-enlaza eventos tras cada render porque el DOM se sustituye por innerHTML.
   */
  function render() {
    const totalSteps = 5;
    const dots = Array.from({ length: totalSteps }, (_, i) =>
      `<div class="step-dot${state.step >= i ? ' step-dot--active' : ''}"></div>`
    ).join('');

    let body = '';
    if (state.step === 0) {
      body = '<div class="SolicitarCitaScreen-stepTitle">Busca tu empresa</div>';
      body += `
        <div class="mb-3">
          <input type="text" class="form-control krono-form-control" id="empresaSearch" placeholder="Nombre de tu empresa" />
          <div class="form-text">Si ya existe, seleccionala de la lista.</div>
        </div>`;
      if (state.cargaEmpresas) {
        body += '<div class="text-muted">Buscando...</div>';
      } else if (state.empresas.length) {
        body += '<div class="d-grid gap-2">';
        state.empresas.forEach((e) => {
          body += `<button type="button" class="btn ${state.empresaSeleccionada?.id === e.id ? 'btn-krono-primary' : 'btn-krono-outlined'}" data-empresa="${e.id}">${esc(e.nombre)}</button>`;
        });
        body += '</div>';
      } else if (state.empresaSeleccionada) {
        body += `<div class="alert alert-success">Seleccionada: ${esc(state.empresaSeleccionada.nombre)}</div>`;
      }
    } else if (state.step === 1) {
      body = '<div class="SolicitarCitaScreen-stepTitle">Selecciona el servicio</div><div class="d-flex flex-wrap gap-2">';
      servicios.forEach((s) => {
        const active = state.servicio === s;
        body += `<button type="button" class="btn ${active ? 'btn-krono-primary' : 'btn-krono-outlined'}" data-svc="${escAttr(s)}">${esc(s)}</button>`;
      });
      body += '</div>';
    } else if (state.step === 2) {
      body = '<div class="SolicitarCitaScreen-stepTitle">Selecciona un día libre</div><div class="row g-2">';
      getDiasDisponibles().forEach((d) => {
        const active = state.diaSeleccionado && d.toDateString() === state.diaSeleccionado.toDateString();
        body += `
          <div class="col-6 col-sm-4 col-md-3">
            <button type="button" class="btn w-100 ${active ? 'btn-krono-primary' : 'btn-krono-outlined'}" data-dia="${d.getTime()}">
              <div class="small text-uppercase">${fmtDia.format(d).split(' ')[0]}</div>
              <div class="fw-bold">${d.getDate()}</div>
              <div class="small">${d.toLocaleString('default', { month: 'short' })}</div>
            </button>
          </div>`;
      });
      body += '</div>';
    } else if (state.step === 3) {
      body = `<div class="SolicitarCitaScreen-stepTitle">Horas disponibles para el ${fmtDia.format(state.diaSeleccionado)}</div><div class="d-flex flex-wrap gap-2">`;
      getHorasDisponibles().forEach((h) => {
        const label = fmtHora(h.hora, h.minutos);
        const active = state.horaSeleccionada === label;
        body += `<button type="button" class="btn ${active ? 'btn-krono-primary' : 'btn-krono-outlined'}" data-hora="${label}">${label}</button>`;
      });
      body += '</div>';
    } else {
      body = `
        <div class="SolicitarCitaScreen-stepTitle">Confirmar cita</div>
        ${htmlKronoCard(`
          <div class="mb-2"><strong>Empresa:</strong> ${esc(state.empresaSeleccionada?.nombre || 'No seleccionada')}</div>
          <div class="mb-2"><strong>Servicio:</strong> ${esc(state.servicio)}</div>
          <div><strong>Fecha y hora:</strong> ${fmtDia.format(state.diaSeleccionado)} a las ${state.horaSeleccionada}</div>
        `)}
      `;
    }

    const isLast = state.step === 4;
    const canContinue = (state.step === 0 && state.empresaSeleccionada) ||
                        (state.step === 1 && state.servicio) ||
                        (state.step === 2 && state.diaSeleccionado) ||
                        (state.step === 3 && state.horaSeleccionada) ||
                        isLast;

    mount.innerHTML = `
      <div class="step-indicator">${dots}</div>
      <div class="SolicitarCitaScreen-pane">${body}</div>
      <div class="d-flex flex-row flex-wrap gap-2 mt-4">
        <button type="button" class="btn btn-krono-primary" id="solPrimary" ${!canContinue ? 'disabled' : ''}>
          ${isLast ? 'Confirmar Reserva' : 'Continuar'}
        </button>
        ${state.step > 0 ? '<button type="button" class="btn btn-krono-text" id="solBack">Atrás</button>' : ''}
      </div>`;

    document.getElementById('empresaSearch')?.addEventListener('input', (e) => buscarEmpresas(e.target.value));
    mount.querySelectorAll('[data-empresa]').forEach((b) => {
      b.addEventListener('click', () => {
        state.empresaSeleccionada = state.empresas.find((x) => String(x.id) === b.getAttribute('data-empresa')) || null;
        render();
      });
    });
    mount.querySelectorAll('[data-svc]').forEach((b) => b.addEventListener('click', () => { state.servicio = b.getAttribute('data-svc'); render(); }));
    mount.querySelectorAll('[data-dia]').forEach((b) => b.addEventListener('click', () => { state.diaSeleccionado = new Date(parseInt(b.getAttribute('data-dia'))); state.horaSeleccionada = null; render(); }));
    mount.querySelectorAll('[data-hora]').forEach((b) => b.addEventListener('click', () => { state.horaSeleccionada = b.getAttribute('data-hora'); render(); }));

    document.getElementById('solPrimary')?.addEventListener('click', async () => {
      if (isLast) {
        try {
          const res = await ApiClient.post('/citas', {
            clienteId: SessionController.instance.user?.id || 'CLIENTE_ID_SESION',
            clienteNombre: SessionController.instance.user?.nombre || 'Cliente',
            servicio: state.servicio,
            empleado: 'Por asignar',
            empresaNombre: state.empresaSeleccionada?.nombre || null,
            inicio: new Date(state.diaSeleccionado.getFullYear(), state.diaSeleccionado.getMonth(), state.diaSeleccionado.getDate(), parseInt(state.horaSeleccionada.split(':')[0]), 0).toISOString(),
            duracionMinutos: 60,
            estado: 'pendiente',
          });
          showSolToast(res && res.id ? ('¡Cita solicitada · id: ' + res.id) : '¡Cita solicitada con éxito!');
          setTimeout(() => window.location.href = '../area_clientes/area_clientes.html', 1500);
        } catch (err) {
          showSolToast(err.message || String(err));
        }
        return;
      }
      state.step++;
      render();
    });

    document.getElementById('solBack')?.addEventListener('click', () => { state.step--; render(); });
  }

  render();
}

/** Muestra notificación toast tras acciones del wizard (búsqueda, reserva, errores). */
function showSolToast(msg) {
  const el = document.createElement('div');
  el.className = 'toast align-items-center text-bg-primary border-0 position-fixed bottom-0 end-0 m-3';
  el.innerHTML =
    '<div class="d-flex"><div class="toast-body">' +
    esc(msg) +
    '</div><button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button></div>';
  document.body.appendChild(el);
  const t = new bootstrap.Toast(el, { delay: 3200 });
  t.show();
  el.addEventListener('hidden.bs.toast', () => el.remove());
}

/** Escapa texto para insertarlo como contenido HTML. */
function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

/** Escapa texto para usarlo dentro de atributos HTML (data-svc, etc.). */
function escAttr(s) {
  return String(s).replace(/"/g, '&quot;');
}
