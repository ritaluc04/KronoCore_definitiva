/// =============================================================================
/// session.dart — Estado global de autenticación (singleton) con JWT.
///
/// GESTIONA:
/// - Usuario actual, Access Token y Refresh Token en memoria
/// - Login con JWT (loginWithJwt)
/// - Refresco automático del token (refreshAccessToken)
/// - Soporte multi-empresa para admin (adminEmpresaId)
/// - Notificación de cambios mediante ChangeNotifier
///
/// Singleton: SessionController.instance accede desde toda la app.
/// GoRouter usa refreshListenable para reaccionar a cambios de sesión.
/// =============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// CONTROLADOR: SessionController
/// Gestiona el estado de la sesión del usuario de forma global (Singleton).
/// Soporta JWT (Access + Refresh Token) para autenticación segura.
class SessionController extends ChangeNotifier {
  static final SessionController instance = SessionController._();
  SessionController._();

  Usuario? _user;
  String? _accessToken;
  String? _refreshToken;
  int? _adminEmpresaId;

  Usuario? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuth => _user != null;
  int? get adminEmpresaId => _adminEmpresaId;

  void setAdminEmpresaId(int? id) {
    _adminEmpresaId = id;
    notifyListeners();
  }

  /// Inicia sesión con JWT desde la respuesta del backend.
  /// Guarda el usuario y los tokens en memoria.
  void loginWithJwt({
    required String accessToken,
    required String refreshToken,
    required String id,
    required String nombre,
    required String email,
    required UserRole rol,
    String? empresaNombre,
    int? empresaId,
    String? avatar,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _user = Usuario(
      id: id,
      nombre: nombre,
      email: email,
      rol: rol,
      empresaNombre: empresaNombre,
      empresaId: empresaId,
      avatar: avatar,
    );
    notifyListeners();
  }

  /// Refresca el Access Token usando el Refresh Token.
  /// Se llama automáticamente desde ApiClient al recibir 401.
  Future<void> refreshAccessToken() async {
    if (_refreshToken == null) throw Exception('No hay refresh token');

    const String baseUrl =
        'https://kronobackend-ctach7cya4cxb9d8.spaincentral-01.azurewebsites.net/api';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _accessToken = data['accessToken'] as String?;
        _refreshToken = data['refreshToken'] as String?;
      } else {
        logout();
        throw Exception('Sesión expirada');
      }
    } catch (e) {
      logout();
      rethrow;
    }
  }

  /// Login legacy (sin JWT, para modo demo y compatibilidad).
  void login({
    required String email,
    required UserRole rol,
    String? nombre,
    String? id,
    String? empresaNombre,
    int? empresaId,
    String? avatar,
  }) {
    _user = Usuario(
      id: id ?? 'u-${rol.name}',
      nombre:
          nombre ??
          switch (rol) {
            UserRole.admin => 'Admin Kronos',
            UserRole.jefe => 'Jefa de salon',
            UserRole.empleado => 'Empleado Demo',
            UserRole.cliente => 'Cliente Demo',
          },
      email: email,
      rol: rol,
      empresaNombre: empresaNombre,
      empresaId: empresaId,
      avatar: avatar,
    );
    notifyListeners();
  }

  void logout() {
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
  }
}
