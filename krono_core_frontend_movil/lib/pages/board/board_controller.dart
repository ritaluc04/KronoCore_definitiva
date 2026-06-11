import 'dart:convert';
import 'package:flutter/material.dart';
import '../../global/utils/kons.dart';
import '../../global/models/models.dart';
import '../../data/services/tareas_service.dart';
import '../../data/api_client.dart';

/// Controlador para la gestión del tablero (Board) de tareas.
/// Permite CRUD completo de tareas y gestión dinámica de columnas.
class BoardController extends ChangeNotifier {
  final _service = TareasService();
  
  List<Tarea> tareas = [];

  List<Usuario> usuariosEmpresa = [];

  bool cargando = false;

  final List<({TareaEstado estado, String label, Color color})> columnas = [
    (estado: TareaEstado.pendiente, label: 'Pendiente', color: KronoColors.muted),
    (estado: TareaEstado.enProceso, label: 'En proceso', color: KronoColors.info),
    (estado: TareaEstado.finalizado, label: 'Finalizado', color: KronoColors.success),
  ];

  /// Constructor por defecto, inicializa la lista de tareas.
  BoardController() {
    tareas = [];
  }

  /// Obtiene todas las tareas desde la API y actualiza el estado de carga.
  Future<void> cargarTareas() async {
    cargando = true;
    notifyListeners();
    try {
      tareas = await _service.getTareas();
      await cargarUsuariosEmpresa();
    } catch (e) {
      debugPrint("Error API Tareas: $e");
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  /// Obtiene los usuarios de la empresa desde la API y los almacena en [usuariosEmpresa].
  Future<void> cargarUsuariosEmpresa() async {
    try {
      final res = await ApiClient.get('/usuarios');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        usuariosEmpresa = data.map((u) => Usuario.fromMap(u)).toList();
      }
    } catch (e) {
      debugPrint("Error al cargar usuarios: $e");
    }
  }

  /// Devuelve el color asociado a la prioridad de una tarea.
  Color getPrioridadColor(TareaPrioridad p) => switch (p) {
    TareaPrioridad.alta => KronoColors.danger,
    TareaPrioridad.media => KronoColors.warning,
    TareaPrioridad.baja => KronoColors.success,
  };

  /// Cambia el estado de una tarea (Drag & Drop) e informa a la API.
  /// Si la actualización falla, se revierte el estado local para mantener consistencia.
  Future<void> moverTarea(Tarea tarea, TareaEstado nuevoEstado) async {
    if (tarea.estado == nuevoEstado) return;
    
    final estadoAnterior = tarea.estado;
    tarea.estado = nuevoEstado;
    notifyListeners();

    try {
      await _service.actualizarTarea(tarea);
    } catch (e) {
      debugPrint("Error al mover tarea: $e");
      /// Revertir en caso de error de red (rollback local).
      tarea.estado = estadoAnterior;
      notifyListeners();
    }
  }

  /// Crea una nueva tarea en el backend y la añade a la lista local.
  Future<void> agregarTarea(Tarea nueva) async {
    try {
      final creada = await _service.crearTarea(nueva);
      tareas.add(creada);
    } catch (e) {
      debugPrint("Error al crear tarea: $e");
    }
    notifyListeners();
  }

  /// Edita una tarea existente en el backend y actualiza la lista local.
  Future<void> editarTarea(Tarea editada) async {
    try {
      await _service.actualizarTarea(editada);
      final index = tareas.indexWhere((t) => t.id == editada.id);
      if (index != -1) tareas[index] = editada;
    } catch (e) {
      debugPrint("Error al editar tarea: $e");
    }
    notifyListeners();
  }

  /// Elimina una tarea del backend y de la lista local usando su [id].
  Future<void> eliminarTarea(String id) async {
    try {
      await _service.eliminarTarea(id);
      tareas.removeWhere((t) => t.id == id);
    } catch (e) {
      debugPrint("Error al eliminar tarea: $e");
    }
    notifyListeners();
  }

  /// Agrega una nueva columna al tablero con el [nombre] y [estado] especificados.
  void agregarColumna(String nombre, TareaEstado estado) {
    columnas.add((estado: estado, label: nombre, color: KronoColors.primary));
    notifyListeners();
  }

  /// Elimina la columna en la posición [index] si hay más de una.
  void eliminarColumna(int index) {
    if (columnas.length > 1) {
      columnas.removeAt(index);
      notifyListeners();
    }
  }

  List<Tarea> getTareasPorEstado(TareaEstado estado) {
    return tareas.where((t) => t.estado == estado).toList();
  }

  /// Placeholder para la lógica de filtrado de tareas.
  void filtrar() {
    /// Aquí iría la lógica de filtrado por prioridad, asignado, etc.
    debugPrint("Lógica de filtrado no implementada aún");
    notifyListeners();
  }
}
