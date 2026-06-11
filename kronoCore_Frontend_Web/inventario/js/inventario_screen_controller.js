/**
 * screen_controller.js — Controlador de las pantallas de Inventario y Citas (web).
 * Archivo compartido por clientes, inventario, citas y otros módulos.
 * Gestiona la carga, renderizado y CRUD de datos mediante la API REST.
 */

// ============================ INVENTARIO ============================

/** Estado del módulo de inventario */
let inventarioState = { productos: [], cargando: false, busqueda: '', filtroStockBajo: false, productoEditando: null };

async function initInventarioScreen() {
  const wrap = document.getElementById('inventarioTableWrap');
  if (!wrap) return;
  inventarioState.cargando = true; wrap.innerHTML = htmlLoadingView();
  try { inventarioState.productos = await ApiClient.get('/productos') || []; renderInventarioTable(wrap); }
  catch (e) { wrap.innerHTML = htmlErrorView(String(e.message || e), 'retryInventario'); document.getElementById('retryInventario')?.addEventListener('click', () => initInventarioScreen()); }
  finally { inventarioState.cargando = false; }
  document.getElementById('searchProducto')?.addEventListener('input', (e) => { inventarioState.busqueda = e.target.value; renderInventarioTable(wrap); });
  document.getElementById('btnNuevoProducto')?.addEventListener('click', openNewProducto);
  document.getElementById('btnGuardarProducto')?.addEventListener('click', saveProducto);
  document.getElementById('btnFiltrarStockBajo')?.addEventListener('click', () => { inventarioState.filtroStockBajo = !inventarioState.filtroStockBajo; renderInventarioTable(wrap); });
  document.getElementById('btnExportarCSV')?.addEventListener('click', async () => { try { const resp = await fetch(ApiClient.baseUrl + '/productos/exportar-csv', { headers: { 'Authorization': 'Bearer ' + SessionController.instance.accessToken } }); const blob = await resp.blob(); const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = 'productos.csv'; a.click(); } catch (e) { alert('Error al exportar: ' + e.message); } });
}

function renderInventarioTable(mount) {
  if (!mount) return;
  let prods = inventarioState.productos;
  if (inventarioState.filtroStockBajo) prods = prods.filter(p => (p.stock || 0) <= (p.stockMin || 0));
  if (inventarioState.busqueda.trim()) { const q = inventarioState.busqueda.toLowerCase(); prods = prods.filter(p => (p.sku || '').toLowerCase().includes(q) || (p.nombre || '').toLowerCase().includes(q) || (p.categoria || '').toLowerCase().includes(q)); }
  if (!prods.length) { mount.innerHTML = htmlEmptyView({ icon: 'inventory_2', title: 'Sin productos', message: 'No hay productos en el inventario.', actionLabel: 'Nuevo producto', onActionId: 'emptyNewProducto' }); document.getElementById('emptyNewProducto')?.addEventListener('click', openNewProducto); return; }
  const rows = prods.map(p => { const stockState = p.stock <= (p.stockMin || 0) ? { label: 'Bajo', color: 'var(--krono-danger)' } : p.stock <= (p.stockMin || 0) * 2 ? { label: 'Medio', color: 'var(--krono-warning)' } : { label: 'Alto', color: 'var(--krono-success)' };
    return `<div class="d-flex flex-row align-items-center py-2 px-3 border-bottom"><div style="width:80px" class="small text-muted">${esc(p.sku || '-')}</div><div class="flex-fill fw-semibold">${esc(p.nombre || '')}</div><div style="width:100px" class="small text-muted">${esc(p.categoria || '')}</div><div style="width:80px" class="text-center">${p.stock || 0} / ${p.stockMin || 0}</div><div style="width:100px" class="text-center">${htmlStatusChip(stockState.label, stockState.color)}</div><div style="width:80px" class="text-end fw-semibold">${Number(p.precio || 0).toFixed(2)} €</div><div style="width:80px" class="text-end"><button class="btn btn-sm btn-outline-secondary me-1" onclick="openEditProducto('${p.id}')"><span class="material-symbols-outlined" style="font-size:16px">edit</span></button><button class="btn btn-sm btn-outline-danger" onclick="eliminarProducto('${p.id}')"><span class="material-symbols-outlined" style="font-size:16px">delete</span></button></div></div>`;
  }).join('');
  mount.innerHTML = `<div class="KronoCard KronoCard--padding-zero"><div class="d-flex flex-row align-items-center py-2 px-3 border-bottom small text-muted fw-semibold"><div style="width:80px">SKU</div><div class="flex-fill">PRODUCTO</div><div style="width:100px">CATEGORÍA</div><div style="width:80px" class="text-center">STOCK</div><div style="width:100px" class="text-center">ESTADO</div><div style="width:80px" class="text-end">PRECIO</div><div style="width:80px"></div></div>${rows}</div>`;
}

function openNewProducto() { document.getElementById('prodId').value = ''; document.getElementById('productoModalTitle').textContent = 'Nuevo Producto'; document.getElementById('prodSku').value = ''; document.getElementById('prodNombre').value = ''; document.getElementById('prodCat').value = ''; document.getElementById('prodPrecio').value = ''; document.getElementById('prodStock').value = ''; document.getElementById('prodStockMin').value = ''; inventarioState.productoEditando = null; new bootstrap.Modal(document.getElementById('productoModal')).show(); }

function openEditProducto(id) { const p = inventarioState.productos.find(x => String(x.id) === String(id)); if (!p) return; inventarioState.productoEditando = p; document.getElementById('prodId').value = p.id; document.getElementById('productoModalTitle').textContent = 'Editar Producto'; document.getElementById('prodSku').value = p.sku || ''; document.getElementById('prodNombre').value = p.nombre || ''; document.getElementById('prodCat').value = p.categoria || ''; document.getElementById('prodPrecio').value = p.precio || ''; document.getElementById('prodStock').value = p.stock || ''; document.getElementById('prodStockMin').value = p.stockMin || ''; new bootstrap.Modal(document.getElementById('productoModal')).show(); }

async function saveProducto() { const payload = { sku: document.getElementById('prodSku')?.value || '', nombre: document.getElementById('prodNombre')?.value || '', categoria: document.getElementById('prodCat')?.value || '', precio: parseFloat(document.getElementById('prodPrecio')?.value) || 0, stock: parseInt(document.getElementById('prodStock')?.value) || 0, stockMin: parseInt(document.getElementById('prodStockMin')?.value) || 0, activo: true }; if (!payload.nombre) { alert('El nombre es obligatorio'); return; }
  try { if (inventarioState.productoEditando) await ApiClient.put('/productos/' + inventarioState.productoEditando.id, payload); else await ApiClient.post('/productos', payload); bootstrap.Modal.getInstance(document.getElementById('productoModal'))?.hide(); initInventarioScreen(); } catch (e) { alert('Error: ' + e.message); } }

async function eliminarProducto(id) { if (!confirm('¿Eliminar este producto?')) return; try { await ApiClient.delete('/productos/' + id); initInventarioScreen(); } catch (e) { alert('Error: ' + e.message); } }

// ============================ CITAS ============================
let citasState = { citas: [], day: new Date(), cargando: false };

async function initCitasScreen() {
  const wrap = document.getElementById('citasListWrap');
  if (!wrap) return;
  citasState.cargando = true; wrap.innerHTML = htmlLoadingView();
  try { citasState.citas = await ApiClient.get('/citas') || []; renderCitasTimeline(wrap); } catch (e) { wrap.innerHTML = htmlErrorView(String(e.message || e), 'retryCitas'); }
  finally { citasState.cargando = false; }
  document.getElementById('btnPrevDay')?.addEventListener('click', () => { citasState.day.setDate(citasState.day.getDate() - 1); citasState.day = new Date(citasState.day); renderCitasTimeline(wrap); });
  document.getElementById('btnNextDay')?.addEventListener('click', () => { citasState.day.setDate(citasState.day.getDate() + 1); citasState.day = new Date(citasState.day); renderCitasTimeline(wrap); });
  document.getElementById('btnToday')?.addEventListener('click', () => { citasState.day = new Date(); renderCitasTimeline(wrap); });
}

function renderCitasTimeline(mount) {
  if (!mount) return;
  const hoy = citasState.day;
  const dayCitas = citasState.citas.filter(c => { const d = new Date(c.inicio); return d.getFullYear() === hoy.getFullYear() && d.getMonth() === hoy.getMonth() && d.getDate() === hoy.getDate(); });
  const fmt = new Intl.DateTimeFormat('es-ES', { weekday: 'long', day: 'numeric', month: 'long' });
  const titleHtml = `<div class="d-flex align-items-center mb-3"><button class="btn btn-sm btn-outline-secondary me-2" id="btnPrevDay"><span class="material-symbols-outlined">chevron_left</span></button><span class="fw-semibold">${fmt.format(hoy)}</span><button class="btn btn-sm btn-outline-secondary ms-2 me-2" id="btnNextDay"><span class="material-symbols-outlined">chevron_right</span></button><button class="btn btn-sm btn-outline-secondary" id="btnToday">Hoy</button></div>`;
  if (!dayCitas.length) { mount.innerHTML = titleHtml + htmlEmptyView({ icon: 'event', title: 'Sin citas', message: 'No hay citas para este día.' }); return; }
  const listHtml = dayCitas.map(c => { const estadoColor = citasEstadoColor(c.estado); const inicio = new Date(c.inicio); const fin = new Date(inicio.getTime() + (c.duracionMinutos || 30) * 60000);
    return `<div class="d-flex flex-row align-items-center py-2 px-3 border-bottom"><div class="me-3" style="border-left:4px solid ${estadoColor}; padding-left:12px"><div class="fw-semibold">${esc(c.clienteNombre || '')}</div><div class="small text-muted">${esc(c.servicio || '')} · ${esc(c.empleado || '')}</div></div><div class="flex-fill"></div><div class="text-end me-3"><div class="small">${inicio.toLocaleTimeString('es-ES', { hour:'2-digit', minute:'2-digit' })} - ${fin.toLocaleTimeString('es-ES', { hour:'2-digit', minute:'2-digit' })}</div><div>${htmlStatusChip(c.estado || 'pendiente', estadoColor)}</div></div></div>`;
  }).join('');
  mount.innerHTML = titleHtml + `<div class="KronoCard KronoCard--padding-zero">${listHtml}</div>`;
}

function citasEstadoColor(e) { const m = { confirmada: 'var(--krono-success)', pendiente: 'var(--krono-warning)', cancelada: 'var(--krono-muted)', noShow: 'var(--krono-danger)' }; return m[e] || 'var(--krono-muted)'; }

// ============================ HELPERS ============================
function esc(s) { return String(s).replace(/&/g, '&').replace(/</g, '<').replace(/>/g, '>'); }