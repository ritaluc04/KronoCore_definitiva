import 'package:flutter/material.dart';
import '../../global/utils/session.dart';
import '../../global/models/models.dart';

/// Controlador de la pantalla de ajustes.
/// Lee el usuario de [SessionController] y expone el estado
/// de las preferencias (idioma, zona horaria, notificaciones)
/// y la edición del perfil.
class AjustesController extends ChangeNotifier {
  final user = SessionController.instance.user!;
  late final bool isAdmin;

  late final TextEditingController nombreController;
  late final TextEditingController emailController;

  String idioma = 'es';

  String zonaHoraria = 'Europe/Madrid';

  bool notificacionesEmail = true;
  bool notificacionesPush = false;

  List<(String, String, UserRole, bool)> usuarios = [
    ('Marta Vidal', 'marta@krono.dev', UserRole.jefe, true),
    ('David López', 'david@krono.dev', UserRole.empleado, true),
    ('Carla Ruiz', 'carla@krono.dev', UserRole.empleado, true),
    ('Pedro Bel', 'pedro@krono.dev', UserRole.empleado, false),
  ];

  /// Inicializa los controladores de texto con los datos de la sesión activa
  /// y determina si el usuario tiene permisos de administrador.
  AjustesController() {
    isAdmin = user.rol == UserRole.admin;
    nombreController = TextEditingController(text: user.nombre);
    emailController = TextEditingController(text: user.email);
  }

  /// Simula el guardado del perfil mostrando un SnackBar de confirmación.
  /// Aquí iría la llamada real al endpoint de actualización de perfil.
  void guardarPerfil(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    notifyListeners();
  }

  /// Cambia el idioma seleccionado y notifica a la UI.
  void setIdioma(String? value) {
    if (value != null) {
      idioma = value;
      notifyListeners();
    }
  }

  /// Cambia la zona horaria seleccionada y notifica a la UI.
  void setZonaHoraria(String? value) {
    if (value != null) {
      zonaHoraria = value;
      notifyListeners();
    }
  }

  /// Activa o desactiva las notificaciones por email.
  void toggleNotificacionesEmail(bool value) {
    notificacionesEmail = value;
    notifyListeners();
  }

  /// Activa o desactiva las notificaciones push.
  void toggleNotificacionesPush(bool value) {
    notificacionesPush = value;
    notifyListeners();
  }

  /// Placeholder para la lógica de invitación de usuarios (solo admin).
  void invitarUsuario() {
    debugPrint("Invitando usuario...");
  }

  /// Libera los controladores de texto al destruir el controlador.
  @override
  void dispose() {
    nombreController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
