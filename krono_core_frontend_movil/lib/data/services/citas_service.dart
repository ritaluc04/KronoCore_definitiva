import 'dart:convert';
import '../../global/models/models.dart';
import '../api_client.dart';

/// Servicio de Citas y Agenda.
/// Encapsula toda la lógica de comunicación con la API REST para gestionar la agenda.
/// Provee métodos para obtener la lista de citas, crear nuevas reservas, actualizarlas y eliminarlas,
/// manejando la serialización de datos y mapeando las respuestas al modelo interno. desde Flutter (endpoints /api/citas)
class CitasService {
  Future<List<Cita>> getCitas() async {
    final response = await ApiClient.get('/citas');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Cita.fromMap(json)).toList();
    }
    throw Exception('Error al obtener citas');
  }

  Future<Cita> crearCita(Cita cita) async {
    final response = await ApiClient.post('/citas', cita.toMap());
    if (response.statusCode == 201) {
      return Cita.fromMap(jsonDecode(response.body));
    }
    throw Exception('Error al crear cita');
  }

  Future<Cita> actualizarCita(Cita cita) async {
    final response = await ApiClient.put('/citas/${cita.id}', cita.toMap());
    if (response.statusCode == 200) {
      return Cita.fromMap(jsonDecode(response.body));
    }
    throw Exception('Error al actualizar cita');
  }

  Future<void> eliminarCita(String id) async {
    final response = await ApiClient.delete('/citas/$id');
    if (response.statusCode != 204) throw Exception('Error al eliminar cita');
  }
}
