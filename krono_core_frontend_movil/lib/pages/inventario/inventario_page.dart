import 'package:flutter/material.dart';
import '../../global/models/models.dart';
import '../../global/utils/kons.dart';
import '../../global/widgets/krono_widgets.dart';
import 'inventario_controller.dart';

/// Pantalla principal para la visualización y gestión del inventario de productos.
/// Esta vista muestra un listado completo o filtrado de los productos disponibles.
/// Permite ejecutar acciones de búsqueda por texto, filtrado rápido de productos con stock bajo,
/// importación/exportación de datos en formato CSV, y acceder al formulario modal
/// para la creación, edición o eliminación de un producto individual.
class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  late final InventarioController _controller;

  @override
  void initState() {
    super.initState();
    /// Inicializa el controlador e invoca inmediatamente la carga inicial de productos desde la API.
    _controller = InventarioController();
    _controller.cargarInventario();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final productos = _controller.productosFiltrados;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(KronoSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Cabecera de la sección que incluye el título y las acciones principales (Filtros, CSV, Nuevo Producto).
              Text(
                'Inventario',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  /// Botón para alternar el filtro de stock bajo, mostrando un indicador con la cantidad si existen.
                  Badge(
                    isLabelVisible: _controller.stockBajoCount > 0,
                    label: Text('${_controller.stockBajoCount}'),
                    child: OutlinedButton.icon(
                      onPressed: _controller.toggleFiltroStockBajo,
                      icon: Icon(
                        _controller.filtroStockBajo
                            ? Icons.warning_amber_rounded
                            : Icons.inventory_2,
                      ),
                      label: Text(
                        _controller.filtroStockBajo
                            ? 'Mostrando stock bajo'
                            : 'Stock bajo',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final csv = await _controller.exportarCSV();
                      if (csv != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('CSV exportado correctamente'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Exportar CSV'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _controller.importarCSV,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Importar CSV'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _dialogProducto(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo producto'),
                  ),
                ],
              ),
              /// Muestra un banner informativo debajo de los botones si el filtro de stock bajo está activado.
              if (_controller.filtroStockBajo)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: KronoColors.danger,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Filtrando solo productos con stock bajo (${_controller.productosFiltrados.length} resultados)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: KronoColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              /// Campo de texto interactivo para buscar productos en tiempo real por SKU, nombre o categoría.
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar producto...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _controller.setSearchQuery,
                ),
              ),
              const SizedBox(height: 16),

              /// Área principal de contenido donde se muestra la tabla de productos o un indicador de carga.
              if (_controller.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                KronoCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                'SKU',
                                style: TextStyle(
                                  color: KronoColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'PRODUCTO',
                                style: TextStyle(
                                  color: KronoColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'CATEGORÍA',
                                style: TextStyle(
                                  color: KronoColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'STOCK',
                                style: TextStyle(
                                  color: KronoColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'ESTADO',
                                style: TextStyle(
                                  color: KronoColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'PRECIO',
                                style: TextStyle(
                                  color: KronoColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: 80),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      for (var i = 0; i < productos.length; i++) ...[
                        _Row(
                          p: productos[i],
                          state: _controller.getStockState(productos[i]),
                          onEdit: () =>
                              _dialogProducto(context, p: productos[i]),
                          onDelete: () =>
                              _controller.eliminarProducto(productos[i]),
                        ),
                        if (i < productos.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Abre un modal lateral de tipo [KronoSideSheet] que contiene el formulario 
  /// para registrar un producto nuevo o editar la información de uno ya existente.
  void _dialogProducto(BuildContext context, {Producto? p}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'InventarioSideSheet',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) =>
          _ProductoDialog(controller: _controller, producto: p),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }
}

/// Widget de tipo formulario modal [StatefulWidget] utilizado para recopilar
/// y validar los datos necesarios al momento de crear o editar un producto del inventario.
class _ProductoDialog extends StatefulWidget {
  final InventarioController controller;
  final Producto? producto;

  const _ProductoDialog({required this.controller, this.producto});

  @override
  State<_ProductoDialog> createState() => _ProductoDialogState();
}

class _ProductoDialogState extends State<_ProductoDialog> {
  late final TextEditingController _skuCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _catCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _stockMinCtrl;

  @override
  void initState() {
    super.initState();
    /// Se inicializan los controladores de texto rellenando los campos
    /// con la información del producto proporcionado en caso de tratarse de una edición.
    _skuCtrl = TextEditingController(text: widget.producto?.sku);
    _nombreCtrl = TextEditingController(text: widget.producto?.nombre);
    _catCtrl = TextEditingController(text: widget.producto?.categoria);
    _precioCtrl = TextEditingController(
      text: widget.producto?.precio.toString(),
    );
    _stockCtrl = TextEditingController(text: widget.producto?.stock.toString());
    _stockMinCtrl = TextEditingController(
      text: widget.producto?.stockMin.toString(),
    );
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nombreCtrl.dispose();
    _catCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.producto != null;
    return KronoSideSheet(
      title: isEdit ? 'Editar Producto' : 'Nuevo Producto',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final p = Producto(
              id: widget.producto?.id ?? '',
              sku: _skuCtrl.text,
              nombre: _nombreCtrl.text,
              categoria: _catCtrl.text,
              precio: double.tryParse(_precioCtrl.text) ?? 0.0,
              stock: int.tryParse(_stockCtrl.text) ?? 0,
              stockMin: int.tryParse(_stockMinCtrl.text) ?? 0,
            );
            if (isEdit) {
              await widget.controller.actualizarProducto(p);
            } else {
              await widget.controller.crearProducto(p);
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(isEdit ? 'Guardar' : 'Crear'),
        ),
      ],
      children: [
        TextField(
          controller: _skuCtrl,
          decoration: const InputDecoration(labelText: 'SKU'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nombreCtrl,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _catCtrl,
          decoration: const InputDecoration(labelText: 'Categoría'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _precioCtrl,
          decoration: const InputDecoration(labelText: 'Precio'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _stockCtrl,
          decoration: const InputDecoration(labelText: 'Stock Actual'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _stockMinCtrl,
          decoration: const InputDecoration(labelText: 'Stock Mínimo'),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

/// Representa una fila individual dentro de la tabla del inventario.
/// Este componente se encarga de mostrar la información de un producto particular
/// y dispone de botones de acción rápida para su edición o eliminación.
class _Row extends StatelessWidget {
  final Producto p;
  final ({String label, Color color, IconData icon}) state;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _Row({
    required this.p,
    required this.state,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              p.sku,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              p.nombre,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              p.categoria,
              style: const TextStyle(color: KronoColors.muted, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${p.stock} / ${p.stockMin}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(
                label: state.label,
                color: state.color,
                icon: state.icon,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${p.precio.toStringAsFixed(2)} €',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: KronoColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
