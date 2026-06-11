import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../global/models/models.dart';
import '../api_client.dart';

/// Servicio de Productos e Inventario.
/// Administra el catálogo de productos disponibles en el sistema multi-tenant, 
/// manejando el control de stock actual, umbrales de alerta y precios unitarios. desde la app Flutter.
/// Conecta con los endpoints /api/productos del backend Spring Boot.
class ProductosService {
  /// Lista todos los productos del inventario
  Future<List<Producto>> getProductos() async {
    final response = await ApiClient.get('/productos');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Producto.fromMap(json)).toList();
    }
    throw Exception('Error al obtener el inventario');
  }

  Future<Producto> crearProducto(Producto producto) async {
    final response = await ApiClient.post('/productos', producto.toMap());
    if (response.statusCode == 201) {
      return Producto.fromMap(jsonDecode(response.body));
    }
    throw Exception('Error al crear el producto');
  }

  Future<Producto> actualizarProducto(Producto producto) async {
    final response = await ApiClient.put(
      '/productos/${producto.id}',
      producto.toMap(),
    );
    if (response.statusCode == 200) {
      return Producto.fromMap(jsonDecode(response.body));
    }
    throw Exception('Error al actualizar el producto');
  }

  Future<void> eliminarProducto(String id) async {
    final response = await ApiClient.delete('/productos/$id');
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar el producto');
    }
  }

  /// GET /api/productos/stock-bajo
  /// Obtiene los productos cuyo stock actual está por debajo o igual al stock mínimo.
  /// La consulta se realiza en la base de datos (JPQL: WHERE stock <= stockMin).
  /// Se usa desde el dashboard para mostrar alertas de stock bajo.
  Future<List<Producto>> getStockBajo() async {
    final response = await ApiClient.get('/productos/stock-bajo');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Producto.fromMap(json)).toList();
    }
    throw Exception('Error al obtener productos con stock bajo');
  }

  Future<String?> exportarCSV() async {
    try {
      final response = await ApiClient.get('/productos/exportar-csv');
      if (response.statusCode == 200) return response.body;
    } catch (e) {
      debugPrint('Error exportando CSV: $e');
    }
    return null;
  }
}
