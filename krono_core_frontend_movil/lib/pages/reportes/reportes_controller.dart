import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/api_client.dart';

/// Controlador responsable de la vista de Reportes y Estadísticas del negocio.
/// Se encarga de conectarse a la API para cargar y calcular las métricas globales
/// (total de clientes, citas, ventas y tareas) y de proporcionar la funcionalidad
/// de exportación de datos a formato CSV. Permite aplicar filtros (fechas, estados, prioridades)
/// antes de realizar la extracción de datos.
class ReportesController extends ChangeNotifier {
  bool _loading = true;
  bool _exporting = false;
  int _clientes = 0;
  int _citas = 0;
  int _ventas = 0;
  int _tareas = 0;
  int _citasConfirmadas = 0;
  int _citasPendientes = 0;
  int _tareasAlta = 0;

  final desdeController = TextEditingController();
  final hastaController = TextEditingController();
  String? estadoCita;
  String? prioridadTarea;

  bool get loading => _loading;
  bool get exporting => _exporting;
  int get clientes => _clientes;
  int get citas => _citas;
  int get ventas => _ventas;
  int get tareas => _tareas;
  int get citasConfirmadas => _citasConfirmadas;
  int get citasPendientes => _citasPendientes;
  int get tareasAlta => _tareasAlta;

  /// Carga el resumen ejecutivo desde las distintas APIs (clientes, citas, ventas, tareas).
  /// Evalúa las respuestas para extraer la cantidad total de cada módulo y filtra las listas
  /// para calcular conteos específicos, como el número de citas confirmadas o tareas de alta prioridad.
  Future<void> cargarResumen() async {
    _loading = true;
    notifyListeners();
    try {
      final clientes = jsonDecode((await ApiClient.get('/clientes')).body) as List<dynamic>;
      final citas = jsonDecode((await ApiClient.get('/citas')).body) as List<dynamic>;
      final ventas = jsonDecode((await ApiClient.get('/ventas')).body) as List<dynamic>;
      final tareas = jsonDecode((await ApiClient.get('/tareas')).body) as List<dynamic>;
      _clientes = clientes.length;
      _citas = citas.length;
      _ventas = ventas.length;
      _tareas = tareas.length;
      _citasConfirmadas = citas.where((c) => c['estado']?.toString() == 'confirmada').length;
      _citasPendientes = citas.where((c) => c['estado']?.toString() == 'pendiente').length;
      _tareasAlta = tareas.where((t) => t['prioridad']?.toString() == 'alta').length;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Construye la solicitud con los filtros activos y recupera el contenido CSV desde el backend.
  /// En dispositivos móviles, el archivo CSV devuelto se copia directamente al portapapeles 
  /// del sistema para permitir al usuario pegarlo en su herramienta preferida (Excel, Sheets, etc.).
  Future<void> copiarCsv(BuildContext context, String endpoint) async {
    _exporting = true;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (desdeController.text.trim().isNotEmpty) params['desde'] = desdeController.text.trim();
      if (hastaController.text.trim().isNotEmpty) params['hasta'] = hastaController.text.trim();
      if (estadoCita != null && estadoCita!.isNotEmpty) params['estado'] = estadoCita!;
      if (prioridadTarea != null && prioridadTarea!.isNotEmpty) params['prioridad'] = prioridadTarea!;

      final uri = params.isEmpty
          ? endpoint
          : '$endpoint?${Uri(queryParameters: params).query}';

      final response = await ApiClient.get(uri);
      await Clipboard.setData(ClipboardData(text: response.body));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV copiado al portapapeles.')),
        );
      }
    } finally {
      _exporting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    desdeController.dispose();
    hastaController.dispose();
    super.dispose();
  }
}
