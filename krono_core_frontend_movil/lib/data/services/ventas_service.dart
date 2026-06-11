import 'dart:convert';
import '../../global/models/models.dart';
import '../api_client.dart';

/// Servicio de Ventas (Punto de Venta - TPV).
/// Orquesta la creación de nuevas transacciones en el mostrador, consolidando 
/// las líneas del carrito y registrando el cobro final en la base de datos.historial de ventas desde /api/ventas
class VentasService {
  Future<List<Venta>> getVentas() async {
    final response = await ApiClient.get('/ventas');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => Venta.fromMap(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al obtener las ventas');
  }
}
