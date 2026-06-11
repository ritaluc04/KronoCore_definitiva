/*
pi_client.dart — Cliente HTTP principal (`ApiClient`) responsable de centralizar y gestionar todas las
comunicaciones con la API REST del backend. Maneja automáticamente los tiempos de espera,
la serialización de datos y la conversión de formatos, proveyendo métodos estáticos
estandarizados (`get`, `post`, `put`, `delete`) para que los utilicen el resto de servicios.

 RESPONSABILIDADES:
 - Resuelve la URL base del backend según la plataforma (web, desktop, Android)
 - Añade cabeceras JWT Bearer automáticamente
- Añade cabeceras de contexto multi-tenant (X-Empresa-Id, X-User-Rol)
- Auto-refresh del token cuando expira (detecta 401 y reintenta)
- Métodos HTTP: get(), post(), put(), patch(), delete()
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../global/utils/session.dart';
import '../global/models/models.dart';

/// CLASE: ApiClient
/// Centraliza todas las peticiones HTTP de la aplicación.
///
/// URL base dinámica según la plataforma:
/// - Web, Desktop y móvil: apunta al backend de Azure.
/// - Si necesitas desarrollo local, reemplaza solo esta URL o usa tu propia configuración.
class ApiClient {
  static const String _remoteBaseUrl =
      'https://kronobackend-ctach7cya4cxb9d8.spaincentral-01.azurewebsites.net/api';

  /// URL base del backend usada por toda la app.
  static String get baseUrl => _remoteBaseUrl;

  /// Construye las cabeceras JSON con JWT Bearer + contexto multi-tenant.
  ///
  /// Cabeceras incluidas:
  /// - Content-Type y Accept: application/json
  /// - Authorization: Bearer `<access_token>` (JWT)
  /// - X-User-Rol: rol del usuario (soporte legacy)
  /// - X-Empresa-Id: ID de empresa (soporte legacy)
  static Map<String, String> _jsonHeaders() {
    final u = SessionController.instance.user;
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    /// Token JWT de acceso
    final token = SessionController.instance.accessToken;
    if (token != null) {
      h['Authorization'] = 'Bearer $token';
    }

    /// Contexto multi-tenant (soporte legacy, JWT ya lleva rol y empresaId)
    if (u != null) {
      h['X-User-Rol'] = u.rol.name;
      if (u.empresaId != null &&
          u.rol != UserRole.cliente &&
          u.rol != UserRole.admin) {
        h['X-Empresa-Id'] = u.empresaId.toString();
      }
      if (u.rol == UserRole.admin &&
          SessionController.instance.adminEmpresaId != null) {
        h['X-Empresa-Id'] = SessionController.instance.adminEmpresaId
            .toString();
      }
    }
    return h;
  }

  /// Realiza una petición GET al endpoint especificado.
  /// Si recibe 401, intenta refrescar el token y reintenta automáticamente.
  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var response = await http.get(url, headers: _jsonHeaders());
    if (response.statusCode == 401 &&
        SessionController.instance.refreshToken != null) {
      await SessionController.instance.refreshAccessToken();
      response = await http.get(url, headers: _jsonHeaders());
    }
    return response;
  }

  /// Realiza una petición POST con datos JSON.
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var response = await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 401 &&
        SessionController.instance.refreshToken != null) {
      await SessionController.instance.refreshAccessToken();
      response = await http.post(
        url,
        headers: _jsonHeaders(),
        body: jsonEncode(data),
      );
    }
    return response;
  }

  /// Realiza una petición PUT con datos JSON (actualización completa).
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var response = await http.put(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 401 &&
        SessionController.instance.refreshToken != null) {
      await SessionController.instance.refreshAccessToken();
      response = await http.put(
        url,
        headers: _jsonHeaders(),
        body: jsonEncode(data),
      );
    }
    return response;
  }

  /// Realiza una petición PATCH con datos JSON (actualización parcial).
  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var response = await http.patch(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 401 &&
        SessionController.instance.refreshToken != null) {
      await SessionController.instance.refreshAccessToken();
      response = await http.patch(
        url,
        headers: _jsonHeaders(),
        body: jsonEncode(data),
      );
    }
    return response;
  }

  /// Realiza una petición DELETE al endpoint especificado.
  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var response = await http.delete(url, headers: _jsonHeaders());
    if (response.statusCode == 401 &&
        SessionController.instance.refreshToken != null) {
      await SessionController.instance.refreshAccessToken();
      response = await http.delete(url, headers: _jsonHeaders());
    }
    return response;
  }
}
