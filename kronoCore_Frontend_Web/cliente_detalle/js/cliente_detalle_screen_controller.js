/**
 * Controlador de la pantalla Cliente detalle.
 * Lee el id por query string, carga el cliente, renderiza la ficha y enlaza edición/eliminación.
 */

/**
 * Punto de entrada: obtiene ?id=, carga GET /clientes/:id y construye la UI con pestañas y modales.
 */
async function initClienteDetalleScreen() {
  const id = new URLSearchParams(window.location.search).get('id');
  const root = document.getElementById('clienteDetalleRoot');
  if (!root) return;
  root.innerHTML = htmlLoadingView();
  try {
    const c = await ApiClient.get(`/clientes/${id}`);
    const tags = (c.etiquetas || []).map((e) => htmlStatusChip(e, 'var(--krono-accent)')).join('');
    root.innerHTML =
      htmlKronoCard('<div class="d-flex flex-row flex-wrap align-items-center gap-3">' + htmlAvatarCircle(clienteFullName(c), 64) + '<div class="flex-fill"><h3 class="krono-headline-small mb-1">' + esc(clienteFullName(c)) + '</h3><p class="text-muted mb-2">' + esc(c.email || '') + ' · ' + esc(c.telefono || '') + '</p><div class="d-flex flex-wrap gap-1">' + tags + '</div></div><button type="button" class="btn btn-krono-outlined" id="btnEditClient"><span class="material-symbols-outlined me-1" style="font-size:18px">edit</span>Editar</button><button type="button" class="btn btn-krono-outlined text-danger" id="btnDeleteClient"><span class="material-symbols-outlined me-1" style="font-size:18px">delete</span>Eliminar</button></div>') +
      '<div class="ClienteDetalleScreen-tabs mt-3"><ul class="nav nav-tabs px-2 pt-2 mb-0" role="tablist"><li class="nav-item"><button class="nav-link active" data-bs-toggle="tab" data-bs-target="#tabDatos" type="button">Datos</button></li><li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabHistorial" type="button">Historial</button></li><li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabCompras" type="button">Compras</button></li><li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#tabNotas" type="button">Notas</button></li></ul><div class="tab-content"><div class="tab-pane fade show active ClienteDetalleScreen-tabPane" id="tabDatos"><p class="ClienteDetalleScreen-kv-label">Email</p><p class="mb-0">' + esc(c.email || '') + '</p></div><div class="tab-pane fade ClienteDetalleScreen-tabPane" id="tabHistorial"><p class="text-muted mb-0">Sin historial reciente.</p></div><div class="tab-pane fade ClienteDetalleScreen-tabPane" id="tabCompras"><p class="text-muted mb-0">Sin compras registradas.</p></div><div class="tab-pane fade ClienteDetalleScreen-tabPane" id="tabNotas"><textarea class="form-control krono-form-control" rows="8" placeholder="Notas internas sobre el cliente..."></textarea></div></div></div>';
    const btnDelete = document.getElementById('btnDeleteClient');
    if (btnDelete) {
      btnDelete.addEventListener('click', () => {
        const modalEl = document.getElementById('deleteClientModal');
        const modal = new bootstrap.Modal(modalEl);
        
        const confirmBtn = document.getElementById('btnConfirmDelete');
        const handleConfirm = async () => {
          confirmBtn.disabled = true;
          try {
            await ApiClient.delete(`/clientes/${id}`);
            modal.hide();
            window.location.href = '../clientes/clientes.html';
          } catch (err) {
            console.error(err);
            if (typeof showToast === 'function') showToast('Error eliminando: ' + String(err.message || err));
            confirmBtn.disabled = false;
          }
        };
        
        // Evita listeners duplicados al reabrir el modal: clona el botón de confirmar
        const newConfirmBtn = confirmBtn.cloneNode(true);
        confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);
        newConfirmBtn.addEventListener('click', handleConfirm);
        
        modal.show();
      });
    }

    const btnEdit = document.getElementById('btnEditClient');
    if (btnEdit) {
      btnEdit.addEventListener('click', () => {
        const modalEl = document.getElementById('editClientModal');
        if(!modalEl) return;
        const modal = new bootstrap.Modal(modalEl);
        
        document.getElementById('ecNombre').value = (c.nombre || '') + (c.apellidos ? ' ' + c.apellidos : '');
        document.getElementById('ecEmail').value = c.email || '';
        document.getElementById('ecTelefono').value = c.telefono || '';
        
        const confirmBtn = document.getElementById('btnConfirmEdit');
        const handleConfirm = async () => {
          confirmBtn.disabled = true;
          const fullName = document.getElementById('ecNombre').value.trim();
          const names = fullName.split(' ');
          const payload = {
            nombre: names.length > 0 ? names[0] : '',
            apellidos: names.length > 1 ? names.slice(1).join(' ') : '',
            email: document.getElementById('ecEmail').value.trim(),
            telefono: document.getElementById('ecTelefono').value.trim()
          };
          try {
            await ApiClient.put(`/clientes/${id}`, payload);
            modal.hide();
            initClienteDetalleScreen();
          } catch (err) {
            console.error(err);
            if (typeof showToast === 'function') showToast('Error editando: ' + String(err.message || err));
            confirmBtn.disabled = false;
          }
        };
        
        const newConfirmBtn = confirmBtn.cloneNode(true);
        confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);
        newConfirmBtn.addEventListener('click', handleConfirm);
        
        modal.show();
      });
    }

    document.title = 'KronoCore · ' + clienteFullName(c);
  } catch (e) {
    root.innerHTML = htmlErrorView(String(e.message || e), 'retryClienteDetalle');
    document.getElementById('retryClienteDetalle')?.addEventListener('click', () => initClienteDetalleScreen());
    if (typeof showToast === 'function') showToast('Error cargando cliente: ' + String(e.message || e));
  }
}

/** Escapa HTML para textos interpolados en plantillas dinámicas. */
function esc(s){return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');}
