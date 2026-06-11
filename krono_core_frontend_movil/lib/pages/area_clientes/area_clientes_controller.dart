import 'package:flutter/material.dart';
import 'dart:convert';
import '../../data/api_client.dart';
import '../../data/services/citas_service.dart';
import '../../data/services/empresas_service.dart';
import '../../global/models/models.dart';
import '../../global/utils/session.dart';

/// Controlador del área de clientes.
/// Gestiona la carga de citas y compras del cliente autenticado,
/// y el flujo de 5 pasos para solicitar una nueva cita.
class AreaClientesController extends ChangeNotifier {
  final _citasService = CitasService();
  final _empresasService = EmpresasService();

  List<Cita> _misCitas = [];
  List<Map<String, dynamic>> _misCompras = [];
  bool _isLoading = false;

  List<Empresa> _empresas = [];

  /// Empresa seleccionada en el paso 1 del stepper.
  Empresa? _empresaSeleccionada;

  List<Cita> get misCitas => _misCitas;
  List<Map<String, dynamic>> get misCompras => _misCompras;
  bool get isLoading => _isLoading;
  List<Empresa> get empresas => _empresas;
  Empresa? get empresaSeleccionada => _empresaSeleccionada;

  /// Carga las citas del cliente en sesión filtrando por nombre/email.
  /// Si el filtro no encuentra coincidencias, muestra las 4 más recientes.
  /// También carga las compras del cliente en paralelo.
  Future<void> cargarMisCitas() async {
    _isLoading = true;
    notifyListeners();
    try {
      final all = await _citasService.getCitas();
      final user = SessionController.instance.user;
      final name = user?.nombre.toLowerCase() ?? '';
      final email = user?.email.toLowerCase() ?? '';
      final filtered = all.where((c) {
        final cliente = c.clienteNombre.toLowerCase();
        return name.isEmpty
            ? true
            : cliente.contains(name) || cliente.contains(email);
      }).toList();
      _misCitas = filtered.isEmpty
          ? all.take(4).toList()
          : filtered.take(4).toList();

      _misCompras = await _loadMisCompras(user);
    } catch (e) {
      debugPrint("Error cargando mis citas: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga las ventas desde la API y las filtra por nombre/email del cliente en sesión.
  /// Si no hay coincidencias devuelve las 10 primeras ventas como fallback.
  Future<List<Map<String, dynamic>>> _loadMisCompras(Usuario? user) async {
    try {
      final response = await ApiClient.get('/ventas');
      final ventas = jsonDecode(response.body) as List<dynamic>;
      final name = user?.nombre.toLowerCase() ?? '';
      final email = user?.email.toLowerCase() ?? '';
      final filtered = ventas.where((v) {
        final cliente = (v['clienteNombre'] ?? '').toString().toLowerCase();
        return name.isEmpty
            ? true
            : cliente.contains(name) ||
                  cliente.contains(email) ||
                  cliente == 'mostrador';
      }).toList();
      final source = filtered.isEmpty ? ventas : filtered;
      return source
          .map((v) => Map<String, dynamic>.from(v as Map))
          .take(10)
          .toList();
    } catch (e) {
      debugPrint("Error cargando compras: $e");
      return [];
    }
  }

  /// Busca empresas por nombre para el paso 1 del stepper.
  /// Si la consulta está vacía, limpia los resultados y la selección.
  Future<void> buscarEmpresas(String q) async {
    if (q.trim().isEmpty) {
      _empresas = [];
      _empresaSeleccionada = null;
      notifyListeners();
      return;
    }
    try {
      _empresas = await _empresasService.buscar(q.trim());
      notifyListeners();
    } catch (e) {
      debugPrint("Error buscando empresas: $e");
    }
  }

  /// Guarda la empresa elegida en el paso 1 y notifica a la UI.
  void seleccionarEmpresa(Empresa empresa) {
    _empresaSeleccionada = empresa;
    notifyListeners();
  }

  /// Elimina la cita del servidor y la quita de la lista local sin recargar todo.
  void cancelarCita(Cita cita) async {
    try {
      await _citasService.eliminarCita(cita.id);
      _misCitas.removeWhere((c) => c.id == cita.id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error al cancelar cita: $e");
    }
  }

  // ──────────────────────────────────────────
  //  Lógica del asistente de solicitud de cita
  // ──────────────────────────────────────────

  int step = 0;

  String servicio = 'Corte';

  DateTime? _selectedDay;
  DateTime? _selectedHour;
  List<DateTime> _availableHours = [];

  DateTime? get selectedDay => _selectedDay;
  DateTime? get selectedHour => _selectedHour;

  List<DateTime> get availableHours => _availableHours;

  List<DateTime> get availableDays {
    final now = DateTime.now();
    return List.generate(
      14,
      (i) => DateTime(now.year, now.month, now.day + i + 1),
    );
  }

  /// Mueve el stepper al paso [value] acotado entre 0 y 4.
  void setStep(int value) {
    step = value.clamp(0, 4);
    notifyListeners();
  }

  /// Avanza al siguiente paso del asistente si no se ha llegado al final.
  void nextStep() {
    if (step < 4) {
      step++;
      notifyListeners();
    }
  }

  /// Retrocede un paso en el asistente.
  void prevStep() {
    if (step > 0) {
      step--;
      notifyListeners();
    }
  }

  /// Actualiza el servicio seleccionado en el paso 2.
  void setServicio(String value) {
    servicio = value;
    notifyListeners();
  }

  /// Guarda el día elegido, reinicia la hora y lanza la consulta de horas libres.
  void selectDay(DateTime day) async {
    _selectedDay = day;
    _selectedHour = null;
    _availableHours = [];
    notifyListeners();

    _availableHours = await getAvailableHours(day);
    notifyListeners();
  }

  /// Consulta la API de citas y devuelve las horas libres del [day] elegido.
  /// Las horas base son 9, 10, 11, 12, 16, 17, 18, 19. Se descartan las ocupadas.
  Future<List<DateTime>> getAvailableHours(DateTime day) async {
    final horasBase = [9, 10, 11, 12, 16, 17, 18, 19];

    try {
      final todas = await _citasService.getCitas();
      final ocupadas = todas
          .where(
            (c) =>
                c.inicio.year == day.year &&
                c.inicio.month == day.month &&
                c.inicio.day == day.day,
          )
          .map((c) => c.inicio.hour)
          .toList();

      return horasBase
          .where((h) => !ocupadas.contains(h))
          .map((h) => DateTime(day.year, day.month, day.day, h))
          .toList();
    } catch (e) {
      debugPrint("Error al obtener horas disponibles: $e");
      return [];
    }
  }

  /// Marca la franja horaria elegida en el paso 4.
  void selectHour(DateTime hour) {
    _selectedHour = hour;
    notifyListeners();
  }

  /// Crea la cita en el backend con estado 'pendiente', muestra feedback
  /// al usuario y reinicia el flujo del asistente al paso 0.
  Future<void> enviarSolicitud(BuildContext context) async {
    if (_selectedHour == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final nueva = Cita(
        id: '', // El backend asigna el ID.
        clienteId: SessionController.instance.user?.id ?? 'CLIENTE_ID_SESION',
        clienteNombre:
            SessionController.instance.user?.nombre ?? 'Cliente Actual',
        empleado: 'Por asignar',
        empresaNombre: _empresaSeleccionada?.nombre,
        inicio: _selectedHour!,
        duracion: const Duration(minutes: 60),
        servicio: servicio,
        estado: CitaEstado.pendiente,
      );

      await _citasService.crearCita(nueva);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada con éxito')),
        );
      }

      // Reinicia el asistente y recarga las citas del cliente.
      step = 0;
      _selectedDay = null;
      _selectedHour = null;
      await cargarMisCitas();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar solicitud')),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
