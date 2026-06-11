import 'package:flutter/material.dart';
import 'dart:convert';
import '../../data/services/productos_service.dart';
import '../../data/api_client.dart';
import '../../global/models/models.dart';

/// Controlador responsable de la gestión de estado del módulo de Punto de Venta (TPV).
/// 
/// Este controlador maneja la lógica para cargar el catálogo de productos desde el backend,
/// proporciona capacidades de filtrado en tiempo real por nombre o SKU, y administra el estado
/// del carrito de compras (añadir, remover, incrementar y decrementar artículos). 
/// Además, calcula de forma automática el subtotal, el IVA (21% estándar) y el total a pagar, 
/// y orquesta el proceso final de cobro, enviando la transacción al servidor, actualizando 
/// el inventario y limpiando el carrito para la siguiente venta.
class VentasController extends ChangeNotifier {
  final _service = ProductosService();

  final List<CarritoLinea> _carrito = [];
  
  List<Producto> _allProductos = [];
  
  bool _isLoading = false;
  
  String _query = '';

  List<CarritoLinea> get carrito => _carrito;
  
  bool get isLoading => _isLoading;
  
  String get query => _query;

  /// Carga asíncronamente el catálogo completo de productos desde el backend.
  Future<void> cargarProductos() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allProductos = await _service.getProductos();
    } catch (e) {
      debugPrint("Error cargando productos para venta: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Producto> get productosFiltrados {
    if (_query.isEmpty) return _allProductos;
    final q = _query.toLowerCase();
    return _allProductos
        .where(
          (p) =>
              p.nombre.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q),
        )
        .toList();
  }

  double get subtotal => _carrito.fold(0, (s, l) => s + l.subtotal);
  double get iva => subtotal * 0.21;
  double get total => subtotal + iva;
  
  bool get isEmpty => _carrito.isEmpty;

  /// Actualiza el valor de búsqueda y notifica para refrescar los productos filtrados.
  void updateQuery(String v) {
    _query = v;
    notifyListeners();
  }

  /// --- Operaciones del carrito de compra ---

  /// Añade un producto seleccionado al carrito. 
  /// Si el producto ya se encontraba en el carrito, se incrementa su cantidad.
  void addProducto(Producto p) {
    final i = _carrito.indexWhere((l) => l.producto.id == p.id);
    if (i >= 0) {
      _carrito[i].cantidad++;
    } else {
      _carrito.add(CarritoLinea(producto: p));
    }
    notifyListeners();
  }

  /// Elimina por completo una línea del carrito independientemente de su cantidad.
  void removeLinea(CarritoLinea l) {
    _carrito.remove(l);
    notifyListeners();
  }

  /// Incrementa en una unidad la cantidad de un producto específico en el carrito.
  void incrementar(CarritoLinea l) {
    l.cantidad++;
    notifyListeners();
  }

  /// Decrementa la cantidad del producto en el carrito.
  /// Si la cantidad desciende a cero, el producto es removido del carrito.
  void decrementar(CarritoLinea l) {
    if (l.cantidad > 1) {
      l.cantidad--;
    } else {
      _carrito.remove(l);
    }
    notifyListeners();
  }

  /// Vacía todas las líneas del carrito, regresándolo a estado inicial.
  void limpiarCarrito() {
    _carrito.clear();
    notifyListeners();
  }

  /// Finaliza la compra ensamblando la transacción y enviándola a la API.
  /// Si tiene éxito, se procesa la venta, se actualiza el stock local recargando los productos
  /// y se retorna el ID de la transacción recién creada.
  Future<String?> procesarPago() async {
    if (_carrito.isEmpty) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final payload = {
        'clienteId': null,
        'clienteNombre': 'Mostrador',
        'fecha': DateTime.now().toIso8601String(),
        'subtotal': subtotal,
        'iva': iva,
        'total': total,
        'detalles': _carrito
            .map(
              (l) => {
                'productoId': l.producto.id,
                'productoNombre': l.producto.nombre,
                'cantidad': l.cantidad,
                'precioUnitario': l.producto.precio,
                'subtotal': l.subtotal,
              },
            )
            .toList(),
      };

      final response = await ApiClient.post('/ventas', payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> body = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {};
        final id = body['id']?.toString();

        limpiarCarrito();
        /// Se vuelve a recargar el listado desde el backend para sincronizar el stock disponible.
        await cargarProductos(); 
        debugPrint('Venta registrada id: $id');
        return id;
      } else {
        throw Exception('Error al registrar la venta');
      }
    } catch (e) {
      debugPrint("Error al procesar pago: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
