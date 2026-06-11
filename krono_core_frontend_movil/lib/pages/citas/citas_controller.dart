import 'package:flutter/material.dart';
import '../../data/services/citas_service.dart';
import '../../global/utils/kons.dart';
import '../../global/models/models.dart';

/// Controlador para la gestión de citas y el calendario.
/// Integra con [CitasService] para la persistencia de datos.
class CitasController extends ChangeNotifier {
  final _service = CitasService();

  List<Cita> _allCitas = [];

  bool _isLoading = false;

  DateTime _day = DateTime.now();

  List<Cita> get allCitas => _allCitas;

  bool get isLoading => _isLoading;

  DateTime get day => _day;

  /// Carga inicial de citas desde la API y actualiza [allCitas].
  Future<void> cargarCitas() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allCitas = await _service.getCitas();
    } catch (e) {
      debugPrint("Error cargando citas: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Cita> get dayCitas {
    return _allCitas
        .where(
          (c) =>
              c.inicio.year == _day.year &&
              c.inicio.month == _day.month &&
              c.inicio.day == _day.day,
        )
        .toList();
  }

  /// Avanza la visualización del calendario al día siguiente.
  void nextDay() {
    _day = _day.add(const Duration(days: 1));
    notifyListeners();
  }

  /// Retrocede la visualización del calendario al día anterior.
  void previousDay() {
    _day = _day.subtract(const Duration(days: 1));
    notifyListeners();
  }

  /// Resetea la fecha seleccionada al día de hoy.
  void goToToday() {
    _day = DateTime.now();
    notifyListeners();
  }

  /// Retorna el color asociado al estado de la cita.
  Color getColorFor(CitaEstado e) => switch (e) {
    CitaEstado.confirmada => KronoColors.success,
    CitaEstado.pendiente => KronoColors.warning,
    CitaEstado.cancelada => KronoColors.muted,
    CitaEstado.noShow => KronoColors.danger,
  };

  /// Crea una nueva cita en el backend y recarga la lista.
  Future<void> crearCita(Cita cita) async {
    try {
      await _service.crearCita(cita);
      await cargarCitas();
    } catch (e) {
      debugPrint("Error al crear cita: $e");
    }
  }

  /// Actualiza una cita existente en el backend y recarga la lista.
  Future<void> actualizarCita(Cita cita) async {
    try {
      await _service.actualizarCita(cita);
      await cargarCitas();
    } catch (e) {
      debugPrint("Error al actualizar cita: $e");
    }
  }

  /// Elimina una cita del backend y recarga la lista local.
  Future<void> eliminarCita(String id) async {
    try {
      await _service.eliminarCita(id);
      await cargarCitas();
    } catch (e) {
      debugPrint("Error al eliminar cita: $e");
    }
  }
}
