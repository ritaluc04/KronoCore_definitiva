import 'package:flutter/material.dart';
import '../../global/utils/kons.dart';
import '../../global/widgets/krono_widgets.dart';
import '../../global/widgets/page_states_view.dart';
import 'ventas_controller.dart';

/// Pantalla dedicada al Punto de Venta (TPV).
/// Proveé una interfaz dividida en dos paneles (en pantallas anchas) o pestañas (en móviles):
/// Uno contiene el catálogo de productos interactivo para su búsqueda y adición,
/// mientras que el otro detalla el carrito de compras con opciones para modificar cantidades
/// y proceder al cobro y facturación de la venta.
class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});
  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  late final VentasController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VentasController();
    _controller.cargarProductos();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Despliega un diálogo de tipo SideSheet confirmando el pago.
  /// Si el usuario finaliza la transacción, se procesará mediante el backend
  /// y se mostrará un mensaje o Snackbar con el resultado de la operación.
  void _mostrarDialogoCobro() {
    showKronoSideSheet(
      context,
      title: 'Cobrar',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              final id = await _controller.procesarPago();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      id != null
                          ? 'Venta registrada · ticket #$id'
                          : 'Venta registrada',
                    ),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al registrar venta')),
                );
              }
            }
          },
          child: const Text('Confirmar pago'),
        ),
      ],
      children: [
        Text(
          'Total: ${_controller.total.toStringAsFixed(2)} €',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Confirma que has recibido el pago antes de registrar la venta.',
          style: TextStyle(color: KronoColors.muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final productos = _controller.productosFiltrados;

        final productosPanel = Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(KronoSpacing.lg),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar producto',
                ),
                onChanged: _controller.updateQuery,
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: productos.length,
                itemBuilder: (_, i) {
                  final p = productos[i];
                  return InkWell(
                    onTap: () => _controller.addProducto(p),
                    borderRadius: BorderRadius.circular(KronoRadius.lg),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KronoColors.background,
                        borderRadius: BorderRadius.circular(KronoRadius.lg),
                        border: Border.all(color: KronoColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              color: KronoColors.surface2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: KronoColors.muted,
                            ),
                          ),
                          Text(
                            p.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${p.precio.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              color: KronoColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );

        final carritoPanel = Container(
          color: Theme.of(context).cardColor,
          padding: const EdgeInsets.all(KronoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Carrito',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _controller.isEmpty
                    ? const EmptyView(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Carrito vacío',
                        message: 'Toca productos para añadir.',
                      )
                    : ListView.separated(
                        itemCount: _controller.carrito.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 16),
                        itemBuilder: (context, i) {
                          final l = _controller.carrito[i];
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.producto.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${l.producto.precio.toStringAsFixed(2)} €',
                                      style: const TextStyle(
                                        color: KronoColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _controller.decrementar(l),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${l.cantidad}'),
                              IconButton(
                                onPressed: () => _controller.incrementar(l),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  '${l.subtotal.toStringAsFixed(2)} €',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _controller.removeLinea(l),
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: KronoColors.muted,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              const Divider(),
              _kv('Subtotal', _controller.subtotal),
              _kv('IVA (21%)', _controller.iva),
              const SizedBox(height: 4),
              _kv('TOTAL', _controller.total, bold: true),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: (_controller.isEmpty || _controller.isLoading)
                    ? null
                    : _mostrarDialogoCobro,
                icon: _controller.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payments),
                label: _controller.isLoading
                    ? const Text('Procesando...')
                    : const Text('Cobrar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        );

        /// Si la pantalla es ancha, mostramos ambos paneles; si es compacta,
        /// se utiliza un [DefaultTabController] para dividirlos visualmente.
        return wide
            ? Row(
                children: [
                  Expanded(flex: 5, child: productosPanel),
                  const VerticalDivider(width: 1),
                  SizedBox(width: 380, child: carritoPanel),
                ],
              )
            : DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const Material(
                      color: KronoColors.background,
                      child: TabBar(
                        labelColor: KronoColors.primary,
                        unselectedLabelColor: KronoColors.muted,
                        indicatorColor: KronoColors.primary,
                        tabs: [
                          Tab(text: 'Productos'),
                          Tab(text: 'Carrito'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [productosPanel, carritoPanel],
                      ),
                    ),
                  ],
                ),
              );
      },
    );
  }

  /// Componente interno auxiliar para renderizar pares clave/valor,
  /// que usualmente se utiliza para el desglose del recibo (Subtotal, IVA, Total).
  Widget _kv(String k, double v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(
          k,
          style: TextStyle(
            color: bold ? KronoColors.foreground : KronoColors.muted,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontSize: bold ? 16 : 13,
          ),
        ),
        const Spacer(),
        Text(
          '${v.toStringAsFixed(2)} €',
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            fontSize: bold ? 18 : 13,
            color: bold ? KronoColors.primary : KronoColors.foreground,
          ),
        ),
      ],
    ),
  );
}
