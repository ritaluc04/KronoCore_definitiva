import 'dart:convert';
import '../../global/models/models.dart';
import '../api_client.dart';

/// Servicio del módulo CRM (Customer Relationship Management).
/// Responsable de encapsular las operaciones de datos referentes a los perfiles de clientes.
/// Ofrece funciones para el alta, consulta exhaustiva, búsqueda, filtrado y modificación de perfiles. de clientes (CRM).
/// Permite realizar operaciones de lectura, creación, actualización y borrado en PostgreSQL.
class ClientesService {
  
  /// Obtiene la lista completa de clientes registrados en el sistema.
  Future<List<Cliente>> getClientes() async {
    final response = await ApiClient.get('/clientes');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Cliente.fromMap(json)).toList();
    }
    throw Exception('Error al obtener la lista de clientes');
  }

  /// Registra un nuevo cliente con sus datos de contacto y etiquetas.
  Future<Cliente> crearCliente(Cliente cliente) async {
    final response = await ApiClient.post('/clientes', cliente.toMap());
    if (response.statusCode == 201) {
      return Cliente.fromMap(jsonDecode(response.body));
    }
    throw Exception('Error al registrar nuevo cliente');
  }

  /// Actualiza la información de un cliente existente.
  Future<Cliente> actualizarCliente(Cliente cliente) async {
    final response = await ApiClient.put('/clientes/${cliente.id}', cliente.toMap());
    if (response.statusCode == 200) {
      return Cliente.fromMap(jsonDecode(response.body));
    }
    throw Exception('Error al actualizar datos del cliente');
  }

  /// Elimina un cliente de la base de datos.
  Future<void> eliminarCliente(String id) async {
    final response = await ApiClient.delete('/clientes/$id');
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar cliente');
    }
  }
}
