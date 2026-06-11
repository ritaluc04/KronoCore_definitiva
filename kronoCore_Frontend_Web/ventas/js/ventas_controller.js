/**
 * Ventas — ventas_controller.js
 * Controlador del punto de venta (TPV): carrito, totales y registro de ventas.
 */

/**
 * Clase controladora para el módulo de Punto de Venta (TPV / POS).
 * Gestiona el carrito de compras en memoria, el cálculo de totales y el envío de la transacción.
 */
class VentasController {
  constructor(){ this._carrito=[]; this._query=''; this.productos=[]; }
  
  /**
   * Carga el catálogo de productos desde la API.
   */
  async load(){
    try{
      this.productos=await ApiClient.get('/productos');
    }catch(e){
      this.productos=[];
      console.error('Error cargando productos:',e);
      showVentasToast('Error cargando productos: '+(e && e.message?e.message:String(e)),'danger');
    }
  }
  
  get carrito(){ return this._carrito; }
  get query(){ return this._query; }
  
  /**
   * Retorna los productos filtrados por la búsqueda actual.
   */
  get productosFiltrados(){ const q=this._query.toLowerCase(); return this.productos.filter(p=>(p.nombre||'').toLowerCase().includes(q)); }
  
  /** Devuelve la suma total base sin IVA */
  get subtotal(){ return this._carrito.reduce((s,l)=>s+l.producto.precio*l.cantidad,0); }
  
  /** Devuelve el 21% de IVA basado en el subtotal */
  get iva(){ return this.subtotal*0.21; }
  
  /** Devuelve el costo final de la compra */
  get total(){ return this.subtotal+this.iva; }
  
  get isEmpty(){ return this._carrito.length===0; }
  
  updateQuery(v){ this._query=v; this.onChange(); }
  
  /**
   * Añade un producto al carrito. Si ya existe, incrementa su contador.
   */
  addProducto(p){ const i=this._carrito.findIndex(l=>l.producto.id===p.id); if(i>=0) this._carrito[i].cantidad++; else this._carrito.push({producto:p,cantidad:1}); this.onChange(); }
  
  removeLinea(l){ const idx=this._carrito.indexOf(l); if(idx>=0) this._carrito.splice(idx,1); this.onChange(); }
  incrementar(l){ l.cantidad++; this.onChange(); }
  decrementar(l){ if(l.cantidad>1) l.cantidad--; else return this.removeLinea(l); this.onChange(); }
  limpiarCarrito(){ this._carrito.length=0; this.onChange(); }
  
  /**
   * Confirma la transacción con la API, enviando todos los detalles
   * de los productos seleccionados. Si la respuesta es exitosa, se limpia la sesión.
   * @returns {Object} {ok: boolean, id?: string, error?: string}
   */
  async procesarPago(){
    if(this.isEmpty) return;
    const payload = {clienteId:null,clienteNombre:'Mostrador',fecha:new Date().toISOString(),subtotal:this.subtotal,iva:this.iva,total:this.total,detalles:this._carrito.map(l=>({productoId:l.producto.id,productoNombre:l.producto.nombre,cantidad:l.cantidad,precioUnitario:l.producto.precio,subtotal:l.producto.precio*l.cantidad}))};
    this._processing = true;
    try{
      const res = await ApiClient.post('/ventas', payload);
      if(res && res.id){
        this.limpiarCarrito();
        return {ok:true,id:res.id};
      }
      this.limpiarCarrito();
      return {ok:true};
    }catch(e){
      return {ok:false,error:e && e.message? e.message : String(e)};
    }finally{ this._processing = false; }
  }
  onChange(){}
}

// —— Inicialización de la pantalla y enlace de eventos ——
let ventasCtrl; let ventasCobroModal;
async function initVentasScreen(){
  ventasCtrl = new VentasController();
  ventasCtrl.onChange = renderVentasUI;
  ventasCobroModal = new bootstrap.Modal(document.getElementById('ventasCobroModal'));

  document.getElementById('ventasSearch').addEventListener('input', e => ventasCtrl.updateQuery(e.target.value));

  document.querySelectorAll('[data-ventas-tab]').forEach(btn => btn.addEventListener('click', () => {
    const tab = btn.getAttribute('data-ventas-tab');
    const root = document.getElementById('ventasRoot');
    root.classList.toggle('ventas--productos', tab === 'productos');
    root.classList.toggle('ventas--cart', tab === 'carrito');
    document.querySelectorAll('[data-ventas-tab]').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
  }));

  // Manejador del botón confirmar pago (se registra una sola vez)
  const confirmBtn = document.getElementById('ventasConfirmarPago');
  if (confirmBtn) {
    confirmBtn.addEventListener('click', async () => {
      confirmBtn.disabled = true;
      const original = confirmBtn.innerHTML;
      confirmBtn.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Procesando';
      try {
        const res = await ventasCtrl.procesarPago();
        ventasCobroModal.hide();
        if (res && res.ok) {
          showVentasToast(res.id ? ('Venta registrada · ticket #' + res.id) : 'Venta registrada');
        } else {
          showVentasToast('Error: ' + (res && res.error ? res.error : 'Error al procesar'), 'danger');
        }
      } catch (e) {
        showVentasToast('Error en el servidor', 'danger');
      } finally {
        confirmBtn.innerHTML = original;
        confirmBtn.disabled = false;
      }
    });
  }

  await ventasCtrl.load();
  renderVentasUI();
}

// —— Renderizado del catálogo y del carrito en el DOM ——
function renderVentasUI(){ const grid=document.getElementById('ventasProductGrid'); grid.innerHTML=ventasCtrl.productosFiltrados.map(p=>`<button type="button" class="VentasScreen-product" data-product-id="${escAttr(p.id)}"><div class="VentasScreen-productThumb"><span class="material-symbols-outlined">inventory_2</span></div><div class="small fw-semibold" style="font-size:12px;line-height:1.3;min-height:2.6em">${esc(p.nombre)}</div><div class="text-primary fw-bold mt-1">${Number(p.precio||0).toFixed(2)} €</div></button>`).join(''); grid.querySelectorAll('[data-product-id]').forEach(btn=>btn.addEventListener('click',()=>{ const id=btn.getAttribute('data-product-id'); const p=ventasCtrl.productos.find(x=>String(x.id)===String(id)); if(p) ventasCtrl.addProducto(p); })); const cart=document.getElementById('ventasCartInner'); let lines=''; if(ventasCtrl.isEmpty){ lines=htmlEmptyView({icon:'shopping_cart',title:'Carrito vacío',message:'Toca productos para añadir.'}); } else { lines='<div class="VentasScreen-cartList">'+ventasCtrl.carrito.map(l=>`<div class="d-flex flex-row align-items-center py-2 border-bottom"><div class="flex-fill me-2" style="min-width:0"><div class="fw-semibold small">${esc(l.producto.nombre)}</div><div class="text-muted" style="font-size:12px">${Number(l.producto.precio).toFixed(2)} €</div></div><button type="button" class="btn btn-link p-0 text-muted" data-dec="${escAttr(l.producto.id)}"><span class="material-symbols-outlined">remove_circle</span></button><span class="mx-2 small">${l.cantidad}</span><button type="button" class="btn btn-link p-0 text-muted" data-inc="${escAttr(l.producto.id)}"><span class="material-symbols-outlined">add_circle</span></button><span class="small fw-semibold text-end" style="width:64px">${(l.producto.precio*l.cantidad).toFixed(2)} €</span><button type="button" class="btn btn-link p-0 text-muted ms-1" data-remove="${escAttr(l.producto.id)}"><span class="material-symbols-outlined" style="font-size:18px">close</span></button></div>`).join('')+'</div>'; } cart.innerHTML='<div class="fw-bold mb-3">Carrito</div>'+lines+'<hr class="my-3" />'+kvRow('Subtotal',ventasCtrl.subtotal)+kvRow('IVA (21%)',ventasCtrl.iva)+'<div class="mt-1 mb-3">'+kvRow('TOTAL',ventasCtrl.total,true)+'</div>'+'<button type="button" class="btn btn-krono-primary w-100 py-2" id="btnCobrarVentas" '+(ventasCtrl.isEmpty?'disabled':'')+'><span class="material-symbols-outlined me-1 align-middle" style="font-size:20px">payments</span>Cobrar</button>'; cart.querySelectorAll('[data-inc]').forEach(b=>b.addEventListener('click',()=>{ const l=ventasCtrl.carrito.find(x=>String(x.producto.id)===String(b.getAttribute('data-inc'))); if(l) ventasCtrl.incrementar(l); })); cart.querySelectorAll('[data-dec]').forEach(b=>b.addEventListener('click',()=>{ const l=ventasCtrl.carrito.find(x=>String(x.producto.id)===String(b.getAttribute('data-dec'))); if(l) ventasCtrl.decrementar(l); })); cart.querySelectorAll('[data-remove]').forEach(b=>b.addEventListener('click',()=>{ const l=ventasCtrl.carrito.find(x=>String(x.producto.id)===String(b.getAttribute('data-remove'))); if(l) ventasCtrl.removeLinea(l); })); const btnCobrar=document.getElementById('btnCobrarVentas'); if(btnCobrar){ btnCobrar.addEventListener('click',()=>{ document.getElementById('ventasCobroTotal').textContent='Total: '+ventasCtrl.total.toFixed(2)+' €'; ventasCobroModal.show(); }); } }

// —— Utilidades de interfaz ——
function kvRow(k,v,bold){ return '<div class="d-flex flex-row py-1"><span class="'+(bold?'fw-bold':'text-muted')+'" style="font-size:'+(bold?'16px':'13px')+'">'+esc(k)+'</span><span class="flex-fill"></span><span class="fw-semibold" style="font-size:'+(bold?'18px':'13px')+';color:'+(bold?'var(--krono-primary)':'inherit')+'">'+Number(v).toFixed(2)+' €</span></div>'; }
function showVentasToast(msg, type='info'){ const el=document.createElement('div'); el.className='toast align-items-center text-bg-'+(type==='danger'?'danger':'dark')+' border-0 position-fixed bottom-0 end-0 m-3'; el.innerHTML='<div class="d-flex"><div class="toast-body">'+esc(msg)+'</div><button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button></div>'; document.body.appendChild(el); const t=new bootstrap.Toast(el,{delay:2800}); t.show(); el.addEventListener('hidden.bs.toast',()=>el.remove()); }
function esc(s){ return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function escAttr(s){ return esc(String(s)).replace(/"/g,'&quot;'); }
