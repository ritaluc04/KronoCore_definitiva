import 'dart:convert';
import '../../global/models/models.dart';
import '../api_client.dart';

/// Servicio de Tareas y Gestión Kanban.
/// Proporciona los accesos necesarios para manipular las tarjetas del tablero:
/// obtener lista, mover tareas entre columnas de estado, y actualizar su información.de trabajo del equipo mediante el tablero Kanban.
///
/// RESPONSABILIDADES:
/// - CRUD completo de tareas (crear, leer, actualizar, eliminar)
/// - Comunicación con los endpoints /api/tareas del backend Spring Boot
/// - Serialización JSON usando los métodos fromMap()/toMap() del modelo Tarea
///
/// CADA TAREA TIENE:
/// - título: nombre descriptivo de la tarea
/// - descripción: detalles de lo que hay que hacer
/// - asignado: persona responsable
/// - prioridad: baja, media, alta (con colores visuales)
/// - estado: pendiente, enProceso, finalizado (columnas del Kanban)
/// - fechaLimite: fecha tope (opcional)
/// - imagenUrl y color: personalización visual (opcional)
///
/// Las tareas se organizan en 3 columnas por defecto que el frontend
/// gestiona filtrando por el campo 'estado'.
class TareasService {
  /// GET /api/tareas
  /// Obtiene la lista completa de todas las tareas del equipo.
  /// El frontend se encarga de agruparlas por estado (columnas Kanban).
  ///
  /// @return Lista de tareas parseadas desde JSON
  /// @throws Exception si el backend devuelve un código de error
  Future<List<Tarea>> getTareas() async {
    final response = await ApiClient.get('/tareas');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Tarea.fromMap(json)).toList();
    }
    throw Exception('Error al obtener la lista de tareas');
  }

  /// POST /api/tareas
  /// Registra una nueva tarea en el tablero Kanban.
  /// La tarea se crea con el estado especificado y aparece en la columna correspondiente.
  ///
  /// @param tarea Objeto Tarea con todos los campos requeridos (título, prioridad, estado)
  /// @return Tarea creada con ID asignado por el backend
  Future<Tarea> crearTarea(Tarea tarea) async {
    final response = await ApiClient.post('/tareas', tarea.toMap());
    if (response.statusCode == 201) {
      return Tarea.fromMap(jsonDecode(response.body));
    }
    throw Exception('Error al crear la tarea');
  }

  /// PUT /api/tareas/{id}
  /// Actualiza los datos de una tarea existente.
  /// Se usa tanto para editar campos como para mover la tarea entre columnas
  /// (cambiando el estado de pendiente a enProceso, por ejemplo).
  ///
  /// @param tarea Objeto Tarea con los campos actualizados y el ID de la tarea a modificar
  /// @return Tarea actualizada
  Future<Tarea> actualizarTarea(Tarea tarea) async {
    final response = await ApiClient.put('/tareas/${tarea.id}', tarea.toMap());
    if (response.statusCode == 200) {
      return Tarea.fromMap(jsonDecode(response.body));
    }
    throw Exception('Error al actualizar la tarea');
  }

  /// DELETE /api/tareas/{id}
  /// Elimina una tarea del tablero de forma permanente.
  ///
  /// @param id ID de la tarea a eliminar
  /// @throws Exception si el backend no devuelve 204 (No Content)
  Future<void> eliminarTarea(String id) async {
    final response = await ApiClient.delete('/tareas/$id');
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar la tarea');
    }
  }
}
