import 'package:flutter/material.dart';
import '../../global/models/models.dart';
import '../../global/utils/kons.dart';
import '../../data/services/facturas_service.dart';

/// Controlador para la gestión de facturación en la app.
/// Permite listar, crear, modificar y eliminar facturas, así como obtener totales.
class FacturasController extends ChangeNotifier {
  final _service = FacturasService();

  List<FacturaModel> facturas = [];

  bool cargando = false;

  double totalFacturado = 0;

  double totalPendiente = 0;

  double totalPagado = 0;

  /// Carga la lista de facturas y los totales desde la API.
  Future<void> cargarFacturas() async {
    cargando = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getFacturas(),
        _service.totalesMes(),
      ]);

      facturas = results[0] as List<FacturaModel>;
      final totales = results[1] as Map<String, dynamic>;
      totalFacturado = (totales['totalFacturado'] as num?)?.toDouble() ?? 0;
      totalPendiente = (totales['totalPendiente'] as num?)?.toDouble() ?? 0;
      totalPagado = (totales['totalPagado'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      debugPrint("Error cargando facturas: $e");
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  /// Crea una nueva factura utilizando el mapa de [data] y recarga la lista.
  Future<void> crearFactura(Map<String, dynamic> data) async {
    try {
      await _service.crearFactura(data);
      await cargarFacturas();
    } catch (e) {
      debugPrint("Error creando factura: $e");
      rethrow;
    }
  }

  /// Cambia el [estado] de una factura por su [id].
  Future<void> cambiarEstado(String id, String estado) async {
    try {
      await _service.cambiarEstado(id, estado);
      await cargarFacturas();
    } catch (e) {
      debugPrint("Error cambiando estado: $e");
    }
  }

  /// Elimina una factura mediante su [id] y actualiza la lista.
  Future<void> eliminarFactura(String id) async {
    try {
      await _service.eliminarFactura(id);
      await cargarFacturas();
    } catch (e) {
      debugPrint("Error eliminando factura: $e");
    }
  }

  /// Devuelve un color semántico basado en el [estado] de la factura.
  Color getEstadoColor(String estado) => switch (estado) {
    'emitida' => KronoColors.warning,
    'pagada' => KronoColors.success,
    'vencida' => KronoColors.danger,
    'cancelada' => KronoColors.muted,
    _ => KronoColors.muted,
  };

  String getEstadoLabel(String estado) => switch (estado) {
    'emitida' => 'Emitida',
    'pagada' => 'Pagada',
    'vencida' => 'Vencida',
    'cancelada' => 'Cancelada',
    _ => estado,
  };
}
