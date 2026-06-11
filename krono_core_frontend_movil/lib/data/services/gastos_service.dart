import 'dart:convert';
import '../../global/models/models.dart';
import '../api_client.dart';

/// Servicio de Gestión de Gastos Operativos.
/// Maneja el registro centralizado de salidas de dinero (compras a proveedores, pago de servicios).
/// Permite realizar operaciones CRUD sobre los gastos, así como clasificarlos adecuadamente. desde la app Flutter.
///
/// RESPONSABILIDADES:
/// - CRUD completo de gastos (crear, leer, actualizar, eliminar)
/// - Obtener totales de gastos del mes actual
/// - Los gastos pueden marcarse como fiscalmente deducibles
/// - Categorías disponibles: alquiler, suministros, proveedores, marketing, otros
///
/// ENDPOINTS QUE CONSUME:
/// - GET /api/gastos → Listar todos los gastos
/// - POST /api/gastos → Crear un nuevo gasto
/// - PUT /api/gastos/{id} → Actualizar un gasto existente
/// - DELETE /api/gastos/{id} → Eliminar un gasto
/// - GET /api/gastos/totales-mes → Totales de gastos del mes
///
/// Cada gasto registra: categoría, descripción, proveedor, importe,
/// IVA (porcentaje e importe), total, método de pago y si es deducible.
class GastosService {
  /// GET /api/gastos
  /// Obtiene la lista completa de gastos registrados.
  /// Cada gasto incluye su categoría, proveedor, importe con IVA,
  /// método de pago y el indicador de si es deducible fiscalmente.
  ///
  /// @return Lista de gastos parseados desde JSON
  /// @throws Exception si el backend devuelve un código de error
  Future<List<GastoModel>> getGastos() async {
    final response = await ApiClient.get('/gastos');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => GastoModel.fromMap(json)).toList();
    }
    throw Exception('Error al obtener gastos');
  }

  /// POST /api/gastos
  /// Registra un nuevo gasto en el sistema.
  /// El importe, IVA y total deben calcularse en el frontend
  /// antes de enviar la petición.
  ///
  /// @param data Mapa con los datos del gasto:
  ///   - categoria: alquiler, suministros, proveedores, marketing, otros
  ///   - descripcion: detalle del gasto
  ///   - proveedor: nombre del proveedor (opcional)
  ///   - importe: base imponible
  ///   - ivaPorcentaje, ivaImporte, total: importes con IVA
  ///   - metodoPago: efectivo, tarjeta, transferencia
  ///   - deducible: true si es fiscalmente deducible
  ///   - fecha: fecha del gasto en formato ISO 8601
  /// @return Gasto creado con ID asignado
  Future<GastoModel> crearGasto(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/gastos', data);
    if (response.statusCode == 201) {
      return GastoModel.fromMap(jsonDecode(response.body));
    }
    throw Exception('Error al crear gasto');
  }

  /// PUT /api/gastos/{id}
  /// Actualiza un gasto existente con los nuevos datos proporcionados.
  /// Permite modificar todos los campos: categoría, importe, proveedor, etc.
  ///
  /// @param id ID del gasto a actualizar
  /// @param data Nuevos datos del gasto (mismo formato que en crear)
  /// @return Gasto actualizado
  Future<GastoModel> actualizarGasto(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient.put('/gastos/$id', data);
    if (response.statusCode == 200) {
      return GastoModel.fromMap(jsonDecode(response.body));
    }
    throw Exception('Error al actualizar gasto');
  }

  /// DELETE /api/gastos/{id}
  /// Elimina un gasto del sistema de forma permanente.
  ///
  /// @param id ID del gasto a eliminar
  Future<void> eliminarGasto(String id) async {
    final response = await ApiClient.delete('/gastos/$id');
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar gasto');
    }
  }

  /// GET /api/gastos/totales-mes
  /// Obtiene el resumen de gastos del mes actual.
  /// Se usa en el dashboard para calcular la rentabilidad
  /// (facturación - gastos) y en la pantalla de gastos.
  ///
  /// @return Mapa con las claves:
  ///   - totalGastos: suma de todos los gastos del mes
  ///   - totalDeducible: suma de gastos marcados como deducibles
  ///   - numGastos: número total de gastos registrados en el mes
  Future<Map<String, dynamic>> totalesMes() async {
    final response = await ApiClient.get('/gastos/totales-mes');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al obtener totales de gastos');
  }
}
