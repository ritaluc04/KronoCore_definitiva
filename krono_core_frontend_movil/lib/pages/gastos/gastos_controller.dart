import 'package:flutter/material.dart';
import '../../global/models/models.dart';
import '../../data/services/gastos_service.dart';

/// Controlador para la gestión de gastos en la app.
/// Permite listar, crear, modificar y eliminar gastos, así como obtener el total.
class GastosController extends ChangeNotifier {
  final _service = GastosService();

  List<GastoModel> gastos = [];

  bool cargando = false;

  double totalGastos = 0;

  double totalDeducible = 0;

  /// Carga la lista de gastos y los totales desde la API.
  Future<void> cargarGastos() async {
    cargando = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getGastos(),
        _service.totalesMes(),
      ]);

      gastos = results[0] as List<GastoModel>;
      final totales = results[1] as Map<String, dynamic>;
      totalGastos = (totales['totalGastos'] as num?)?.toDouble() ?? 0;
      totalDeducible = (totales['totalDeducible'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      debugPrint("Error cargando gastos: $e");
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  /// Crea un nuevo gasto y recarga la lista.
  Future<void> crearGasto(Map<String, dynamic> data) async {
    try {
      await _service.crearGasto(data);
      await cargarGastos();
    } catch (e) {
      debugPrint("Error creando gasto: $e");
      rethrow;
    }
  }

  /// Actualiza un gasto existente mediante su [id] y recarga la lista.
  Future<void> actualizarGasto(String id, Map<String, dynamic> data) async {
    try {
      await _service.actualizarGasto(id, data);
      await cargarGastos();
    } catch (e) {
      debugPrint("Error actualizando gasto: $e");
    }
  }

  /// Elimina un gasto por su [id] y actualiza la lista.
  Future<void> eliminarGasto(String id) async {
    try {
      await _service.eliminarGasto(id);
      await cargarGastos();
    } catch (e) {
      debugPrint("Error eliminando gasto: $e");
    }
  }

  String getCategoriaIcon(String categoria) => switch (categoria) {
    'alquiler' => 'home',
    'suministros' => 'bolt',
    'proveedores' => 'inventory_2',
    'marketing' => 'campaign',
    _ => 'more_horiz',
  };

  String getCategoriaLabel(String categoria) => switch (categoria) {
    'alquiler' => 'Alquiler',
    'suministros' => 'Suministros',
    'proveedores' => 'Proveedores',
    'marketing' => 'Marketing',
    _ => 'Otros',
  };
}
