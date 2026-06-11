/**
 * Controlador de la pantalla Citas (agenda web).
 * Clase CitasController para día activo, filtrado y render del calendario; funciones de arranque y alta.
 */

/** Gestiona el día visible, la carga de citas y el pintado del calendario por franjas horarias. */
class CitasController {
  constructor() {
    this._day = new Date();
    this._day.setHours(0, 0, 0, 0);
    this.citas = [];
  }

  /** Obtiene todas las citas desde GET /citas y las guarda en memoria. */
  async load() {
    try {
      const res = await ApiClient.get('/citas');
      this.citas = res;
    } catch (e) {
      this.citas = [];
      if (typeof showCitasToast === 'function') showCitasToast('Error cargando citas: ' + String(e.message || e));
    }
  }

  /** Fecha del día que se muestra en el calendario (sin hora). */
  get day() {
    return this._day;
  }

  /** Citas cuya fecha de inicio coincide con el día seleccionado. */
  get dayCitas() {
    return this.citas.filter((c) => new Date(c.inicio).toDateString() === this._day.toDateString());
  }

  /** Avanza un día y vuelve a renderizar. */
  nextDay() {
    this._day.setDate(this._day.getDate() + 1);
    this.render();
  }

  /** Retrocede un día y vuelve a renderizar. */
  previousDay() {
    this._day.setDate(this._day.getDate() - 1);
    this.render();
  }

  /** Restablece el día visible a hoy. */
  goToToday() {
    this._day = new Date();
    this._day.setHours(0, 0, 0, 0);
    this.render();
  }

  /** Color de borde/fondo según el estado de la cita (confirmada, pendiente, etc.). */
  getColorFor(e) {
    return ({ confirmada: 'var(--krono-success)', pendiente: 'var(--krono-warning)', cancelada: 'var(--krono-muted)', noShow: 'var(--krono-danger)' }[e] || 'var(--krono-muted)');
  }

  /**
   * Actualiza la etiqueta del día y genera el HTML del calendario:
   * columnas de horas, filas y bloques posicionados por inicio/duración.
   */
  async render() {
    const label = document.getElementById('citasDayLabel');
    if (label) {
      label.textContent = this._day.toLocaleDateString('es-ES', { weekday: 'long', day: 'numeric', month: 'long' });
    }

    const wrap = document.getElementById('citasCalendarWrap');
    if (!wrap) return;

    const hours = Array.from({ length: 15 }, (_, i) => i + 8);
    const hourCol = hours.map((h) => '<div class="CitasScreen-hourLabel">' + String(h).padStart(2, '0') + ':00</div>').join('');
    const slotRows = hours.map(() => '<div class="CitasScreen-slotRow"></div>').join('');
    const blocks = this.dayCitas.map((c) => {
      const ini = new Date(c.inicio);
      const top = ((ini.getHours() + ini.getMinutes() / 60) - 8) * 40;
      const height = Math.max((Number(c.duracionMinutos || c.duracionMin || 30) / 60) * 40, 42);
      const color = this.getColorFor(c.estado);
      return (
        '<div class="CitasScreen-citaBlock" data-cita-id="' + esc(c.id) + '" style="top:' + top + 'px;height:' + height + 'px;background:' + colorToAlpha(color, 0.12) + ';border-left-color:' + color + ';\cursor:pointer;">' +
        '<strong>' + esc(c.clienteNombre || 'Cliente') + '</strong>' +
        '<div class="text-muted" style="font-size:10px">' + esc(c.servicio || 'Servicio') + ' · ' + esc(c.empresaNombre || 'Sin empresa') + '</div>' +
        '</div>'
      );
    }).join('');

    wrap.innerHTML = htmlKronoCard('<div class="CitasScreen-calendar"><div class="CitasScreen-grid"><div class="CitasScreen-hours">' + hourCol + '</div><div class="CitasScreen-slots">' + slotRows + blocks + '</div></div></div>');
    
    // Asignar eventos de clic a cada bloque
    wrap.querySelectorAll('.CitasScreen-citaBlock').forEach(b => {
      b.addEventListener('click', () => {
        const id = b.getAttribute('data-cita-id');
        const cita = this.citas.find(x => String(x.id) === id);
        if (cita) openCitaModal(cita);
      });
    });
  }
}

// Instancia global del controlador y referencia al modal de nueva cita
let citasCtrl;
let nuevaCitaModal;

/** Carga clientes desde la API y llena el select del modal */
async function cargarClientesSelect() {
  const sel = document.getElementById('citaClienteNombre');
  if (!sel) return;
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

/** Carga empleados (usuarios con rol jefe/empleado) desde la API y llena el select del modal */
async function cargarEmpleadosSelect() {
  const sel = document.getElementById('citaEmpleado');
  if (!sel) return;
  try {
    const usuarios = await ApiClient.get('/usuarios');
    usuarios.forEach(u => {
      if (u.rol === 'jefe' || u.rol === 'empleado') {
        const opt = document.createElement('option');
        opt.value = u.nombre;
        opt.textContent = u.nombre;
        sel.appendChild(opt);
      }
    });
  } catch (e) {
    console.warn('No se pudieron cargar empleados:', e);
  }
}

/**
 * Inicializa la pantalla: enlaza navegación de días, modal, leyenda y primera carga/render.
 */
async function initCitasScreen() {
  citasCtrl = new CitasController();
  nuevaCitaModal = new bootstrap.Modal(document.getElementById('nuevaCitaModal'));

  // Cargar datos para los selects del modal
  await Promise.all([cargarClientesSelect(), cargarEmpleadosSelect()]);

  document.getElementById('btnPrevDay').addEventListener('click', () => citasCtrl.previousDay());
  document.getElementById('btnNextDay').addEventListener('click', () => citasCtrl.nextDay());
  document.getElementById('btnHoy').addEventListener('click', () => citasCtrl.goToToday());
  document.getElementById('btnNuevaCita').addEventListener('click', () => openCitaModal(null));
  document.getElementById('btnGuardarCita').addEventListener('click', guardarCita);
  document.getElementById('citasLegend').innerHTML = [
    htmlStatusChip('Confirmada', 'var(--krono-success)'),
    htmlStatusChip('Pendiente', 'var(--krono-warning)'),
    htmlStatusChip('Cancelada', 'var(--krono-muted)'),
  ].join('');

  await citasCtrl.load();
  await citasCtrl.render();
}

let currentEditingCitaId = null;

function openCitaModal(cita) {
  const modalTitle = document.querySelector('#nuevaCitaModal .modal-title');
  if (modalTitle) modalTitle.textContent = cita ? 'Editar Cita' : 'Nueva Cita';
  
  const btnDelete = document.getElementById('btnBorrarCita');
  // Auto-asignar empresa desde la sesión del usuario
  const sessionUser = SessionController.instance.user;
  const empresaCampo = document.getElementById('citaEmpresa');
  if (empresaCampo) {
    empresaCampo.value = cita
      ? (cita.empresaNombre || sessionUser?.empresaNombre || '')
      : (sessionUser?.empresaNombre || '');
  }

  if (cita) {
    currentEditingCitaId = cita.id;
    document.getElementById('citaClienteNombre').value = cita.clienteNombre || '';
    document.getElementById('citaServicio').value = cita.servicio || '';
    document.getElementById('citaEmpleado').value = cita.empleado || '';
    
    // Parse inicio para formato datetime-local
    let initStr = '';
    if (cita.inicio) {
      const d = new Date(cita.inicio);
      initStr = new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    }
    document.getElementById('citaInicio').value = initStr;
    document.getElementById('citaDuracion').value = cita.duracionMinutos || cita.duracionMin || '30';
    document.getElementById('btnGuardarCita').textContent = 'Guardar';
    
    if (btnDelete) {
      btnDelete.classList.remove('d-none');
      btnDelete.onclick = async () => {
        if (!confirm('¿Seguro que deseas eliminar esta cita?')) return;
        try {
          await ApiClient.delete('/citas/' + currentEditingCitaId);
          nuevaCitaModal.hide();
          showCitasToast('Cita eliminada');
          await citasCtrl.load();
          await citasCtrl.render();
        } catch (e) {
          showCitasToast('Error eliminando cita');
        }
      };
    }
  } else {
    currentEditingCitaId = null;
    const now = new Date();
    document.getElementById('citaClienteNombre').value = '';
    document.getElementById('citaServicio').value = '';
    document.getElementById('citaEmpleado').value = '';
    document.getElementById('citaInicio').value = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    document.getElementById('citaDuracion').value = '30';
    document.getElementById('btnGuardarCita').textContent = 'Crear';
    if (btnDelete) btnDelete.classList.add('d-none');
  }
  nuevaCitaModal.show();
}

/** Lee el modal, valida campos obligatorios y crea o edita la cita. */
async function guardarCita() {
  const payload = {
    clienteNombre: document.getElementById('citaClienteNombre').value.trim(),
    servicio: document.getElementById('citaServicio').value.trim(),
    empleado: document.getElementById('citaEmpleado').value.trim(),
    empresaNombre: document.getElementById('citaEmpresa').value.trim(),
    inicio: document.getElementById('citaInicio').value,
    duracionMinutos: Number(document.getElementById('citaDuracion').value || 30),
    estado: 'pendiente',
  };

  if (!payload.clienteNombre || !payload.servicio || !payload.inicio) {
    showCitasToast('Completa cliente, servicio y fecha');
    return;
  }

  try {
    if (currentEditingCitaId) {
      await ApiClient.put('/citas/' + currentEditingCitaId, payload);
      nuevaCitaModal.hide();
      showCitasToast('Cita actualizada');
    } else {
      const res = await ApiClient.post('/citas', payload);
      nuevaCitaModal.hide();
      showCitasToast(res && res.id ? ('Cita creada · id: ' + res.id) : 'Cita creada');
    }
    await citasCtrl.load();
    await citasCtrl.render();
  } catch (err) {
    showCitasToast(err.message || 'No se pudo crear la cita');
  }
}

/** Toast de feedback en la esquina inferior derecha. */
function showCitasToast(msg) {
  const el = document.createElement('div');
  el.className = 'toast align-items-center text-bg-primary border-0 position-fixed bottom-0 end-0 m-3';
  el.innerHTML = '<div class="d-flex"><div class="toast-body">' + esc(msg) + '</div><button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button></div>';
  document.body.appendChild(el);
  const t = new bootstrap.Toast(el, { delay: 2200 });
  t.show();
  el.addEventListener('hidden.bs.toast', () => el.remove());
}

/** Escapa HTML para textos insertados en plantillas. */
function esc(s) {
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}
