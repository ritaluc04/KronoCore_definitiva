import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/api_client.dart';
import '../../data/services/citas_service.dart';
import '../../data/services/productos_service.dart';
import '../../data/services/tareas_service.dart';
import '../../data/services/ventas_service.dart';
import '../../global/models/models.dart';

/// CONTROLADOR: DashboardController
/// Orquesta la vista resumen del Dashboard en la app Flutter.
///
/// DATOS QUE GESTIONA:
/// - Métricas del negocio: ventas hoy, ventas mes, citas hoy, stock bajo
/// - Tareas activas y de alta prioridad
/// - Feed de actividad reciente (ventas, citas, alertas, tareas)
/// - Datos para el gráfico de ventas semanal (fl_chart)
/// - Lista detallada de productos con stock bajo
///
/// FUENTES DE DATOS:
/// - GET /api/dashboard/resumen → Métricas principales
/// - GET /api/citas → Citas para feed y conteo
/// - GET /api/ventas → Ventas para feed y gráfico
/// - GET /api/tareas → Tareas para conteo y feed
///
/// FLUJO:
/// 1. Al crear el controlador, se ejecuta _loadData() automáticamente
/// 2. Carga el resumen del dashboard desde el endpoint dedicado
/// 3. Complementa con datos de citas, ventas y tareas
/// 4. Construye el feed de actividad combinando todas las fuentes
/// 5. Calcula los datos para el gráfico de ventas semanal
/// 6. Notifica a la UI para que se reconstruya (notifyListeners)

class DashboardController extends ChangeNotifier {
  final _citasService = CitasService();
  final _productosService = ProductosService();
  final _tareasService = TareasService();
  final _ventasService = VentasService();

  List<ActividadItem> actividad = [];
  List<double> ventasSemana = List.filled(7, 0.0);
  int totalCitas = 0;
  int citasPendientes = 0;
  int citasConfirmadas = 0;
  int totalClientes = 0;
  int stockAlertas = 0;
  int tareasActivas = 0;
  int tareasAltaPrioridad = 0;
  double ventasMes = 0.0;

  List<Map<String, dynamic>> productosStockBajo = [];

  String ventasHoy = '0 €';
  String get citasHoy => totalCitas.toString();
  String get stockAlertasLabel => stockAlertas.toString();
  String get tareasActivasLabel => tareasActivas.toString();
  String get tareasAltaPrioridadLabel => tareasAltaPrioridad.toString();
  String get ventasMesLabel => '${ventasMes.toStringAsFixed(2)} €';
  bool get hayStockBajo => productosStockBajo.isNotEmpty;

  DashboardController() {
    _loadData();
  }

  /// Carga todos los datos del dashboard desde el backend.
  ///
  /// PROCESO:
  /// 1. Obtiene el resumen desde GET /api/dashboard/resumen
  /// 2. Carga citas, tareas y ventas para el feed y gráfico
  /// 3. Filtra citas de hoy, tareas activas y de alta prioridad
  /// 4. Construye el feed de actividad combinando las fuentes
  /// 5. Calcula ventas por día para el gráfico semanal
  Future<void> _loadData() async {
    try {
      final resResp = await ApiClient.get('/dashboard/resumen');
      Map<String, dynamic> resumen = {};
      if (resResp.statusCode == 200) {
        resumen = jsonDecode(resResp.body) as Map<String, dynamic>;
      }

      final citas = await _citasService.getCitas();
      final tareas = await _tareasService.getTareas();
      final ventas = await _ventasService.getVentas();
      final productosBajo = await _productosService.getStockBajo();

      final hoy = DateTime.now();

      /// 3. Procesar métricas del resumen
      ventasHoy = '${(resumen['ventasHoy'] as num?)?.toDouble() ?? 0.0} €';
      ventasMes = (resumen['ventasMes'] as num?)?.toDouble() ?? 0.0;
      totalClientes = (resumen['totalClientes'] as num?)?.toInt() ?? 0;

      /// Productos con stock bajo (desde el servicio de productos, más preciso)
      stockAlertas = productosBajo.length;
      productosStockBajo = productosBajo
          .map(
            (p) => <String, dynamic>{
              'id': p.id,
              'nombre': p.nombre,
              'stock': p.stock,
              'stockMin': p.stockMin,
            },
          )
          .toList();

      /// 4. Calcular métricas a partir de los datos complementarios
      totalCitas = citas
          .where(
            (c) =>
                c.inicio.year == hoy.year &&
                c.inicio.month == hoy.month &&
                c.inicio.day == hoy.day,
          )
          .length;
      citasPendientes = citas
          .where((c) => c.estado == CitaEstado.pendiente)
          .length;
      citasConfirmadas = citas
          .where((c) => c.estado == CitaEstado.confirmada)
          .length;
      tareasActivas = tareas
          .where((t) => t.estado != TareaEstado.finalizado)
          .length;
      tareasAltaPrioridad = tareas
          .where((t) => t.prioridad == TareaPrioridad.alta)
          .length;

      /// 5. Construir feed de actividad reciente
      actividad = [
        ...ventas
            .take(3)
            .map(
              (v) => ActividadItem(
                texto:
                    'Venta: ${v.clienteNombre} · ${v.total.toStringAsFixed(2)} €',
                cuando: v.fecha,
                icono: 'point_of_sale',
              ),
            ),
        ...citas
            .take(3)
            .map(
              (c) => ActividadItem(
                texto: 'Cita: ${c.clienteNombre} · ${c.servicio}',
                cuando: c.inicio,
                icono: 'event',
              ),
            ),
        ...productosStockBajo
            .take(2)
            .map(
              (p) => ActividadItem(
                texto: 'Stock bajo: ${p['nombre'] ?? ''}',
                cuando: hoy.subtract(const Duration(hours: 1)),
                icono: 'inventory_2',
              ),
            ),
        ...tareas
            .take(2)
            .map(
              (t) => ActividadItem(
                texto: 'Tarea: ${t.titulo}',
                cuando: hoy.subtract(const Duration(hours: 2)),
                icono: 'task_alt',
              ),
            ),
      ];

      /// 6. Calcular datos para el gráfico de ventas semanal (L a D)
      ventasSemana = List<double>.filled(7, 0);
      for (final v in ventas) {
        final dayIndex = v.fecha.weekday - 1; // Lunes=0, Domingo=6
        if (dayIndex >= 0 && dayIndex < ventasSemana.length) {
          ventasSemana[dayIndex] += v.total;
        }
      }
    } catch (e) {
      debugPrint("Error cargando dashboard: $e");
    }
    notifyListeners();
  }

  /// Fuerza una recarga completa de todos los datos del dashboard.
  Future<void> refresh() async {
    await _loadData();
  }
}
