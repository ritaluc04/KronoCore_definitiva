import 'package:flutter/material.dart';
import '../../data/services/productos_service.dart';
import '../../global/models/models.dart';
import '../../global/utils/kons.dart';

/// Controlador responsable de la lógica de negocio y el estado del módulo de Inventario.
/// 
/// Este controlador gestiona la carga de la lista de productos desde el backend y mantiene
/// el estado local para operaciones de filtrado en tiempo real (por nombre, SKU o categoría).
/// También proporciona utilidades para filtrar productos con stock crítico (bajo) y calcular
/// visualmente el nivel de inventario (Alto, Medio o Bajo). Además, orquesta las operaciones
/// CRUD (crear, leer, actualizar, eliminar) delegándolas en [ProductosService], y provee
/// funciones para exportar o importar inventarios en formato CSV.
class InventarioController extends ChangeNotifier {
  final _service = ProductosService();

  List<Producto> _productos = [];
  
  bool _isLoading = false;
  
  String _searchQuery = '';
  
  bool _filtroStockBajo = false;

  List<Producto> get productos => _productos;
  
  bool get isLoading => _isLoading;
  
  bool get filtroStockBajo => _filtroStockBajo;

  int get stockBajoCount =>
      _productos.where((p) => p.stock <= p.stockMin).length;

  String get searchQuery => _searchQuery;

  List<Producto> get productosFiltrados {
    var result = _productos;
    if (_filtroStockBajo) {
      result = result.where((p) => p.stock <= p.stockMin).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (p) =>
                p.nombre.toLowerCase().contains(q) ||
                p.sku.toLowerCase().contains(q) ||
                p.categoria.toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }

  /// Actualiza la consulta de búsqueda y notifica a la UI
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Activa/desactiva el filtro de solo productos con stock bajo
  void toggleFiltroStockBajo() {
    _filtroStockBajo = !_filtroStockBajo;
    notifyListeners();
  }

  /// Exporta el inventario a CSV usando el servicio (backend)
  Future<String?> exportarCSV() async {
    return await _service.exportarCSV();
  }

  /// Carga el inventario completo desde el backend
  Future<void> cargarInventario() async {
    _isLoading = true;
    notifyListeners();
    try {
      _productos = await _service.getProductos();
    } catch (e) {
      debugPrint("Error cargando inventario: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Determina el estado visual del stock de un producto.
  /// Devuelve un record con etiqueta, color e icono.
  ({String label, Color color, IconData icon}) getStockState(Producto p) {
    if (p.stock <= p.stockMin) {
      return (
        label: 'Bajo',
        color: KronoColors.danger,
        icon: Icons.warning_amber_rounded,
      );
    }
    if (p.stock <= p.stockMin * 2) {
      return (
        label: 'Medio',
        color: KronoColors.warning,
        icon: Icons.timelapse,
      );
    }
    return (
      label: 'Alto',
      color: KronoColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  /// Inicia el proceso de importación de un archivo CSV para actualizar el inventario de manera masiva.
  /// Actualmente es un método base (placeholder) pendiente de implementación completa.
  Future<void> importarCSV() async {
    debugPrint("Iniciando importación CSV...");
  }

  /// Crea un nuevo registro de producto enviándolo al backend. 
  /// Tras la creación exitosa, vuelve a cargar todo el inventario para reflejar el cambio.
  Future<void> crearProducto(Producto p) async {
    try {
      await _service.crearProducto(p);
      await cargarInventario();
    } catch (e) {
      debugPrint("Error al crear producto: $e");
    }
  }

  /// Envía al backend los datos modificados de un producto existente para su actualización.
  /// Una vez actualizado, recarga la lista para sincronizar el estado local.
  Future<void> actualizarProducto(Producto p) async {
    try {
      await _service.actualizarProducto(p);
      await cargarInventario();
    } catch (e) {
      debugPrint("Error al actualizar producto: $e");
    }
  }

  /// Elimina definitivamente el producto especificado a través del servicio backend.
  /// Posteriormente recarga la vista para removerlo de la lista.
  Future<void> eliminarProducto(Producto p) async {
    try {
      await _service.eliminarProducto(p.id);
      await cargarInventario();
    } catch (e) {
      debugPrint("Error al eliminar producto: $e");
    }
  }
}
