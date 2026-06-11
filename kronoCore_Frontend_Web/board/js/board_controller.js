/**
 * board_controller.js — Controlador del tablero Kanban (Board).
 * 
 * RESPONSABILIDADES:
 * - Cargar tareas desde el backend y organizarlas por columnas
 * - Renderizar el tablero con 3 columnas: Pendiente, En Proceso, Finalizado
 * - Permitir crear nuevas tareas con título, descripción, asignado, prioridad
 * - Permitir mover tareas entre columnas (cambiar estado)
 * - Permitir editar y eliminar tareas existentes
 * - Gestionar columnas dinámicas (crear/eliminar columnas personalizadas)
 * 
 * FLUJO:
 * 1. Cargar todas las tareas desde GET /api/tareas
 * 2. Agrupar tareas por estado en columnas
 * 3. Renderizar cada columna con sus tarjetas
 * 4. Al arrastrar una tarjeta, cambiar el estado de la tarea
 * 5. Al editar, abrir modal con formulario pre-rellenado
 * 
 * CADA TAREA MUESTRA:
 * - Título de la tarea
 * - Descripción (truncada a 2 líneas)
 * - Prioridad con color (rojo=alta, amarillo=media, verde=baja)
 * - Avatar de la persona asignada
 * - Color personalizado (opcional)
 * - Imagen (opcional, desde URL)
 */

/** Estado compartido del tablero Kanban */
let boardState = {
  tareas: [],           // Todas las tareas cargadas desde el backend
  columnas: [           // Columnas por defecto del tablero
    { estado: 'pendiente', label: 'Pendiente', color: 'var(--krono-muted)' },
    { estado: 'enProceso', label: 'En proceso', color: 'var(--krono-info)' },
    { estado: 'finalizado', label: 'Finalizado', color: 'var(--krono-success)' },
  ],
  cargando: false,      // Indicador de carga
  error: null,
};

/** Carga empleados desde la API y llena los selects de asignados */
async function cargarEmpleadosSelects() {
  const selects = ['taskAsignado', 'editTaskAsignado'];
  try {
    const usuarios = await ApiClient.get('/usuarios');
    const empleados = usuarios.filter(u => u.rol === 'jefe' || u.rol === 'empleado');
    selects.forEach(id => {
      const sel = document.getElementById(id);
      if (!sel) return;
      sel.innerHTML = '<option value="">Sin asignar</option>';
      empleados.forEach(u => {
        const opt = document.createElement('option');
        opt.value = u.nombre;
        opt.textContent = u.nombre;
        sel.appendChild(opt);
      });
    });
  } catch (e) {
    console.warn('No se pudieron cargar empleados:', e);
  }
}

/**
 * Inicializa la pantalla del Board.
 * Carga las tareas desde la API y renderiza el tablero Kanban.
 */
async function initBoardScreen() {
  const mount = document.getElementById('boardMount');
  boardState.cargando = true;
  boardState.error = null;
  renderBoard(mount);

  await cargarEmpleadosSelects();

  try {
    const tareas = await ApiClient.get('/tareas');
    boardState.tareas = tareas || [];
  } catch (e) {
    console.error('Error cargando tareas:', e);
    boardState.tareas = [];
    boardState.error = String(e.message || e);
  } finally {
    boardState.cargando = false;
    renderBoard(mount);
  }

  document.getElementById('boardBtnNuevaColumna')?.addEventListener('click', () => {
    const modal = new bootstrap.Modal(document.getElementById('columnModal'));
    modal.show();
  });

  document.getElementById('btnSaveColumn')?.addEventListener('click', saveNewColumn);
  document.getElementById('btnSaveTask')?.addEventListener('click', saveNewTask);
  document.getElementById('btnUpdateTask')?.addEventListener('click', updateTask);
  document.getElementById('btnDeleteTask')?.addEventListener('click', deleteTask);
}

function renderBoardLegacy(mount) {
  if (!mount) return;
  if (boardState.cargando) { mount.innerHTML = htmlLoadingView(); return; }

  const columnasHtml = boardState.columnas.map((col, colIndex) => {
    const tareasCol = boardState.tareas.filter(t => t.estado === col.estado);
    const tarjetasHtml = tareasCol.map(tarea => {
      const prioridadColor = getColorForPrioridad(tarea.prioridad);
      const imagenHtml = (tarea.imagenUrl && tarea.imagenUrl.trim())
        ? `<img src="${esc(tarea.imagenUrl)}" class="board-card-img" alt="Imagen tarea" onerror="this.style.display='none'" />`
        : '';
      const colorDot = (tarea.color && tarea.color.trim())
        ? `<span class="board-card-color" style="background-color:${esc(tarea.color)}"></span>`
        : '';
      return `
        <div class="board-card" draggable="true" data-tarea-id="${tarea.id}" 
             ondragstart="handleDragStart(event, '${tarea.id}')" onclick="openEditTask('${tarea.id}')">
          ${imagenHtml}
          <div class="board-card-header">
            <span class="board-card-title">${esc(tarea.titulo || 'Sin título')}</span>${colorDot}
          </div>
          ${tarea.descripcion ? `<p class="board-card-desc">${esc(tarea.descripcion)}</p>` : ''}
          <div class="board-card-footer">
            <span class="StatusChip" style="background:${getPrioridadBg(prioridadColor)};color:${prioridadColor}">${getPrioridadLabel(tarea.prioridad)}</span>
            <span class="board-card-avatar">${htmlAvatarCircle(tarea.asignado || 'Sin asignar', 22)}</span>
          </div>
        </div>`;
    }).join('');

    return `
      <div class="board-column" data-estado="${col.estado}" 
           ondragover="handleDragOver(event)" ondrop="handleDrop(event, '${col.estado}')">
        <div class="board-column-header">
          <span class="board-column-dot" style="background-color:${col.color}"></span>
          <span class="board-column-title">${col.label}</span>
          <span class="board-column-count">· ${tareasCol.length}</span>
          <button class="board-column-add" onclick="openNewTask('${col.estado}')">
            <span class="material-symbols-outlined">add</span>
          </button>
        </div>
        <div class="board-column-body">${tarjetasHtml}</div>
      </div>`;
  }).join('');

  mount.innerHTML = `<div class="board-container d-flex flex-row gap-3 overflow-auto h-100">${columnasHtml}</div>`;
}

function openNewTask(estado) {
  document.getElementById('taskEstado').value = estado;
  document.getElementById('taskEstadoText').value = getEstadoLabel(estado);
  document.getElementById('taskTitulo').value = '';
  document.getElementById('taskDescripcion').value = '';
  document.getElementById('taskImagenUrl').value = '';
  document.getElementById('taskColor').value = '#1d4ed8';
  new bootstrap.Modal(document.getElementById('taskModal')).show();
}

function openEditTask(id) {
  const tarea = boardState.tareas.find(t => String(t.id) === String(id));
  if (!tarea) return;
  document.getElementById('editTaskId').value = tarea.id;
  document.getElementById('editTaskTitulo').value = tarea.titulo || '';
  document.getElementById('editTaskDescripcion').value = tarea.descripcion || '';
  document.getElementById('editTaskImagenUrl').value = tarea.imagenUrl || '';
  document.getElementById('editTaskColor').value = tarea.color || '#1d4ed8';
  document.getElementById('editTaskAsignado').value = tarea.asignado || '';
  document.getElementById('editTaskPrioridad').value = tarea.prioridad || 'media';
  document.getElementById('editTaskEstado').value = tarea.estado || 'pendiente';
  new bootstrap.Modal(document.getElementById('taskEditModal')).show();
}

async function saveNewTask() {
  const estado = document.getElementById('taskEstado').value;
  const payload = {
    titulo: document.getElementById('taskTitulo').value.trim(),
    descripcion: document.getElementById('taskDescripcion').value.trim(),
    asignado: document.getElementById('taskAsignado')?.value || '',
    imagenUrl: document.getElementById('taskImagenUrl').value.trim(),
    color: document.getElementById('taskColor').value,
    prioridad: document.getElementById('taskPrioridad')?.value || 'media',
    estado: estado || 'pendiente',
    fechaLimite: null,
  };
  if (!payload.titulo) { alert('El título es obligatorio'); return; }
  try {
    await ApiClient.post('/tareas', payload);
    bootstrap.Modal.getInstance(document.getElementById('taskModal'))?.hide();
    initBoardScreen();
  } catch (e) { alert('Error al crear tarea: ' + String(e.message || e)); }
}

async function updateTask() {
  const id = document.getElementById('editTaskId').value;
  const payload = {
    titulo: document.getElementById('editTaskTitulo').value.trim(),
    descripcion: document.getElementById('editTaskDescripcion').value.trim(),
    asignado: document.getElementById('editTaskAsignado').value,
    imagenUrl: document.getElementById('editTaskImagenUrl').value.trim(),
    color: document.getElementById('editTaskColor').value,
    prioridad: document.getElementById('editTaskPrioridad').value,
    estado: document.getElementById('editTaskEstado').value,
  };
  if (!payload.titulo) { alert('El título es obligatorio'); return; }
  try {
    await ApiClient.put('/tareas/' + id, payload);
    bootstrap.Modal.getInstance(document.getElementById('taskEditModal'))?.hide();
    initBoardScreen();
  } catch (e) { alert('Error al actualizar tarea: ' + String(e.message || e)); }
}

function saveNewColumn() {
  const nombre = document.getElementById('columnNombre').value.trim();
  if (!nombre) return;
  boardState.columnas.push({ estado: 'pendiente', label: nombre, color: 'var(--krono-primary)' });
  bootstrap.Modal.getInstance(document.getElementById('columnModal'))?.hide();
  renderBoard(document.getElementById('boardMount'));
}

async function moveTask(tareaId, nuevoEstado) {
  const tarea = boardState.tareas.find(t => String(t.id) === String(tareaId));
  if (!tarea || tarea.estado === nuevoEstado) return;
  tarea.estado = nuevoEstado;
  renderBoard(document.getElementById('boardMount'));
  try {
    await ApiClient.put('/tareas/' + tareaId, {
      titulo: tarea.titulo, descripcion: tarea.descripcion || '', asignado: tarea.asignado || '',
      imagenUrl: tarea.imagenUrl || '', color: tarea.color || '', prioridad: tarea.prioridad || 'media', estado: nuevoEstado,
    });
  } catch (e) { console.error('Error al mover tarea:', e); }
}

function handleDragStart(event, tareaId) { event.dataTransfer.setData('text/plain', tareaId); event.dataTransfer.effectAllowed = 'move'; }
function handleDragOver(event) { event.preventDefault(); event.dataTransfer.dropEffect = 'move'; }
function handleDrop(event, nuevoEstado) { event.preventDefault(); const id = event.dataTransfer.getData('text/plain'); if (id) moveTask(id, nuevoEstado); }

function getColorForPrioridad(prioridad) {
  const colors = { alta: 'var(--krono-danger)', media: 'var(--krono-warning)', baja: 'var(--krono-success)' };
  return colors[prioridad] || 'var(--krono-muted)';
}

function getPrioridadLabel(prioridad) {
  const labels = { alta: 'Alta', media: 'Media', baja: 'Baja' };
  return labels[prioridad] || prioridad || 'Media';
}

function getPrioridadBg(color) {
  const map = {
    'var(--krono-danger)': 'rgba(220,38,38,0.12)',
    'var(--krono-warning)': 'rgba(245,158,11,0.12)',
    'var(--krono-success)': 'rgba(22,163,74,0.12)',
    'var(--krono-muted)': 'rgba(100,116,139,0.12)',
  };
  return map[color] || 'rgba(29,78,216,0.12)';
}

function getEstadoLabel(estado) {
  const labels = { pendiente: 'Pendiente', enProceso: 'En proceso', finalizado: 'Finalizado' };
  return labels[estado] || estado || 'Pendiente';
}

function renderBoard(mount) {
  if (!mount) return;
  if (boardState.cargando) {
    mount.innerHTML = htmlLoadingView();
    return;
  }
  if (boardState.error) {
    mount.innerHTML = htmlErrorView(
      'Error al cargar tareas: ' + boardState.error,
      'retryBoard',
    );
    document
      .getElementById('retryBoard')
      ?.addEventListener('click', () => initBoardScreen());
    return;
  }

  const columnasHtml = boardState.columnas.map((col) => {
    const estado = escAttr(col.estado);
    const tareasCol = boardState.tareas.filter((t) => t.estado === col.estado);
    const tarjetasHtml = tareasCol.map((tarea) => {
      const prioridadColor = getColorForPrioridad(tarea.prioridad);
      const tareaId = escAttr(tarea.id);
      const imagenHtml = (tarea.imagenUrl && tarea.imagenUrl.trim())
        ? `<img src="${escAttr(tarea.imagenUrl)}" class="BoardScreen-cardImg" alt="Imagen tarea" onerror="this.style.display='none'" />`
        : '';
      const colorDot = (tarea.color && tarea.color.trim())
        ? `<span class="BoardScreen-cardColor" style="background-color:${escAttr(tarea.color)}"></span>`
        : '';

      return `
        <div class="BoardScreen-card KronoCard" draggable="true" data-tarea-id="${tareaId}"
             ondragstart="handleDragStart(event, '${tareaId}')" onclick="openEditTask('${tareaId}')">
          ${imagenHtml}
          <div class="BoardScreen-cardHeader">
            <span class="BoardScreen-cardTitle">${esc(tarea.titulo || 'Sin título')}</span>${colorDot}
          </div>
          ${tarea.descripcion ? `<p class="BoardScreen-cardDesc">${esc(tarea.descripcion)}</p>` : ''}
          <div class="BoardScreen-cardFooter">
            <span class="StatusChip" style="background:${getPrioridadBg(prioridadColor)};color:${prioridadColor}">${getPrioridadLabel(tarea.prioridad)}</span>
            <span class="BoardScreen-cardAvatar">${htmlAvatarCircle(tarea.asignado || 'Sin asignar', 22)}</span>
          </div>
        </div>`;
    }).join('');

    return `
      <div class="BoardScreen-column" data-estado="${estado}"
           ondragover="handleDragOver(event)" ondrop="handleDrop(event, '${estado}')">
        <div class="BoardScreen-colHead">
          <span class="BoardScreen-dot" style="background-color:${col.color}"></span>
          <span class="BoardScreen-columnTitle">${esc(col.label)}</span>
          <span class="BoardScreen-columnCount">· ${tareasCol.length}</span>
          <button type="button" class="BoardScreen-columnAdd" onclick="openNewTask('${estado}')" aria-label="Nueva tarea">
            <span class="material-symbols-outlined">add</span>
          </button>
          <button type="button" class="btn btn-link p-0 text-danger ms-1" onclick="deleteColumn(${boardState.columnas.indexOf(col)})" aria-label="Eliminar columna" title="Eliminar columna">
            <span class="material-symbols-outlined" style="font-size:18px">delete</span>
          </button>
        </div>
        <div class="BoardScreen-columnBody">${tarjetasHtml || '<p class="BoardScreen-emptyColumn">Sin tareas</p>'}</div>
      </div>`;
  }).join('');

  mount.innerHTML = `<div class="BoardScreen-columns">${columnasHtml}</div>`;
}

/** Elimina una tarea por ID desde la API y recarga el tablero */
async function deleteTask() {
  const id = document.getElementById('editTaskId').value;
  if (!id) return;
  if (!confirm('¿Eliminar esta tarea?')) return;
  try {
    await ApiClient.delete('/tareas/' + id);
    bootstrap.Modal.getInstance(document.getElementById('taskEditModal'))?.hide();
    initBoardScreen();
  } catch (e) {
    alert('Error al eliminar tarea: ' + String(e.message || e));
  }
}

/** Elimina una columna del tablero (solo visual) */
function deleteColumn(colIndex) {
  if (boardState.columnas.length <= 1) return;
  if (!confirm('¿Eliminar esta columna y todas sus tareas visibles?')) return;
  boardState.columnas.splice(colIndex, 1);
  renderBoard(document.getElementById('boardMount'));
}

function esc(s) {
  return String(s ?? '').replace(/&/g, '&').replace(/</g, '<').replace(/>/g, '>');
}

function escAttr(s) {
  return esc(s).replace(/"/g, '"').replace(/'/g, '&#39;');
}
