import 'dart:convert';
import '../../global/models/models.dart';
import '../api_client.dart';

/// Servicio de Facturación y Contabilidad.
/// Controla la lógica de emisión, consulta y cancelación de comprobantes fiscales electrónicos.
/// Interactúa con el endpoint principal de facturación, procesando totales e impuestos (IVA).s emitidas desde la app Flutter.
///
/// RESPONSABILIDADES:
/// - Listar todas las facturas emitidas
/// - Crear nuevas facturas con datos fiscales
/// - Cambiar el estado de una factura (emitida → pagada, etc.)
/// - Eliminar facturas del sistema
/// - Obtener totales de facturación del mes actual
///
/// ENDPOINTS QUE CONSUME:
/// - GET /api/facturas → Listar facturas
/// - POST /api/facturas → Crear factura
/// - PATCH /api/facturas/{id}/estado → Cambiar estado
/// - DELETE /api/facturas/{id} → Eliminar factura
/// - GET /api/facturas/totales-mes → Totales del mes
///
/// Las facturas son independientes de las ventas. Una venta puede
/// generar cero, una o varias facturas. El número de factura es único
/// y sigue el formato F-YYYY-NNNN.
class FacturasService {
  /// GET /api/facturas
  /// Obtiene la lista completa de facturas emitidas.
  /// Cada factura incluye datos fiscales del cliente y de la empresa,
  /// importes con IVA, estado y método de pago.
  ///
  /// @return Lista de facturas parseadas desde JSON
  /// @throws Exception si el backend devuelve un código de error
  Future<List<FacturaModel>> getFacturas() async {
    final response = await ApiClient.get('/facturas');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FacturaModel.fromMap(json)).toList();
    }
    throw Exception('Error al obtener facturas');
  }

  /// POST /api/facturas
  /// Crea una nueva factura con los datos fiscales proporcionados.
  /// El backend genera automáticamente el número de factura único
  /// y asigna la fecha de emisión actual.
  ///
  /// @param data Mapa con los datos de la factura:
  ///   - clienteId, clienteNombre, clienteNif (datos del cliente)
  ///   - baseImponible, ivaPorcentaje, ivaImporte, total (importes)
  ///   - estado (emitida por defecto), metodoPago
  ///   - ventaId (opcional, para vincular con una venta existente)
  ///   - fechaVencimiento (plazo de pago)
  /// @return Factura creada con número asignado
  Future<FacturaModel> crearFactura(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/facturas', data);
    if (response.statusCode == 201) {
      return FacturaModel.fromMap(jsonDecode(response.body));
    }
    throw Exception('Error al crear factura');
  }

  /// PATCH /api/facturas/{id}/estado
  /// Cambia el estado de una factura existente.
  /// Estados disponibles: emitida, pagada, vencida, cancelada.
  /// Si se marca como pagada, el backend registra la fecha de pago automáticamente.
  ///
  /// @param id ID de la factura a modificar
  /// @param estado Nuevo estado (ej: "pagada", "vencida", "cancelada")
  Future<void> cambiarEstado(String id, String estado) async {
    final response = await ApiClient.patch('/facturas/$id/estado', {
      'estado': estado,
    });
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar estado');
    }
  }

  /// DELETE /api/facturas/{id}
  /// Elimina una factura del sistema de forma permanente.
  ///
  /// @param id ID de la factura a eliminar
  Future<void> eliminarFactura(String id) async {
    final response = await ApiClient.delete('/facturas/$id');
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar factura');
    }
  }

  /// GET /api/facturas/totales-mes
  /// Obtiene un resumen de la facturación del mes actual.
  /// Útil para mostrar en el dashboard y en la pantalla de facturas.
  ///
  /// @return Mapa con las claves:
  ///   - totalFacturado: total facturado en el mes
  ///   - totalPendiente: facturas emitidas pero no pagadas
  ///   - totalPagado: facturas ya cobradas
  ///   - numFacturas: número total de facturas del mes
  Future<Map<String, dynamic>> totalesMes() async {
    final response = await ApiClient.get('/facturas/totales-mes');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al obtener totales');
  }
}
