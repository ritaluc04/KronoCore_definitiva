import 'dart:convert';
import '../../global/models/models.dart';
import '../api_client.dart';

/// SERVICIO: AuthService
/// Servicio encargado de la lógica central de Autenticación y Autorización.
/// Centraliza y orquesta las operaciones de inicio de sesión (login) y registro 
/// de nuevos usuarios. Actúa como puente entre los controladores de vistas de acceso
/// y el `ApiClient`, procesando de forma segura las credenciales y la sesión.
class AuthService {
  
  /// Inicia sesión enviando credenciales a la API.
  /// Si tiene éxito, devuelve un objeto [Usuario] con sus datos y rol.
  Future<Usuario> login(String email, String password) async {
    final response = await ApiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      return Usuario.fromMap(jsonDecode(response.body));
    }

    String message = 'Credenciales incorrectas o error en el servidor';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] != null) {
        message = body['message'].toString();
      }
    } catch (_) {
      /// Ignorar parseo si no es JSON.
    }
    throw Exception(message);
  }

  /// Registra un nuevo usuario en la base de datos PostgreSQL.
  /// Por defecto, los registros desde el móvil se asignan con el rol 'cliente'.
  Future<Usuario> register({
    required String nombre,
    required String email,
    required String password,
    required String telefono,
    required UserRole rol,
    String? empresaNombre,
  }) async {
    final response = await ApiClient.post('/auth/register', {
      'nombre': nombre,
      'email': email,
      'password': password,
      'telefono': telefono,
      'rol': rol.name,
      'empresaNombre': empresaNombre,
    });

    if (response.statusCode == 201) {
      return Usuario.fromMap(jsonDecode(response.body));
    }

    String message = 'Error al crear la cuenta. El email podría estar en uso.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] != null) {
        message = body['message'].toString();
      }
    } catch (_) {
      /// Ignorar parseo si no es JSON.
    }
    throw Exception(message);
  }
}
