import 'dart:convert';
import '../../global/models/models.dart';
import '../api_client.dart';


/// SERVICIO: EmpresasService
/// Proporciona métodos para interactuar con los datos de las empresas en el backend.
class EmpresasService {
  
  /// Busca empresas que coincidan con el término de búsqueda [q].
  /// Útil para el registro de empleados o jefes que deben asociarse a una empresa.
  Future<List<Empresa>> buscar(String q) async {
    final response = await ApiClient.get('/empresas?q=${Uri.encodeComponent(q)}');
    
    /// Si la respuesta es exitosa (200 OK), procesa el JSON.
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      /// Mapea la lista de mapas JSON a una lista de objetos de tipo Empresa.
      return data.map((json) => Empresa.fromMap(json)).toList();
    }
    
    /// Si ocurre un error, lanza una excepción con un mensaje descriptivo.
    throw Exception('Error al buscar empresas');
  }
}
