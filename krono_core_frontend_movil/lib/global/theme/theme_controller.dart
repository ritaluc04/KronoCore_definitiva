/// =============================================================================
/// theme_controller.dart — Estado reactivo del modo claro/oscuro.
/// Persiste la preferencia en SharedPreferences y notifica a MaterialApp.
/// =============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controlador encargado de gestionar el estado del tema (Claro/Oscuro) en la aplicación.
/// Persiste la preferencia en SharedPreferences para mantenerla entre sesiones.
class ThemeController extends ChangeNotifier {
  static const String _key = 'krono_dark_mode';

  bool _isDarkMode = false;
  bool _initialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get initialized => _initialized;

  /// Inicializa el controlador cargando la preferencia guardada.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_key) ?? false;
    _initialized = true;
    notifyListeners();
  }

  /// Alterna entre modo claro y oscuro y guarda la preferencia.
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDarkMode);
    notifyListeners();
  }

  /// Permite establecer un valor específico y lo persiste.
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDarkMode);
    notifyListeners();
  }
}
