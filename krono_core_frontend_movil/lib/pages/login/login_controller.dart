import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../global/utils/session.dart';
import '../../global/models/models.dart';
import '../../data/services/auth_service.dart';

/// Controlador responsable de la lógica de autenticación y registro de la aplicación.
/// Este controlador gestiona el estado del formulario de inicio de sesión y registro,
/// mantiene las variables de los campos de texto, realiza validaciones básicas de formato
/// e invoca al servicio correspondiente ([AuthService]) para comunicarse con el backend.
/// También se encarga de manejar el cambio entre el modo de ingreso y el modo de creación de cuenta,
/// así como de la visibilidad de las contraseñas y la aceptación de los términos de uso.
class LoginController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final companyController = TextEditingController();

  /// Rol elegido en el flujo de registro.
  UserRole rol = UserRole.cliente;

  bool loading = false;

  bool isRegisterMode = false;

  bool obscurePassword = true;

  bool acceptTerms = false;

  /// Alterna entre modo inicio de sesión y modo registro.
  void toggleMode() {
    isRegisterMode = !isRegisterMode;
    notifyListeners();
  }

  /// Muestra u oculta la contraseña en el campo correspondiente.
  void toggleObscure() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  /// Actualiza el rol seleccionado en el registro.
  void setRole(UserRole value) {
    rol = value;
    notifyListeners();
  }

  /// Marca o desmarca la aceptación de términos y condiciones.
  void setAcceptTerms(bool? value) {
    acceptTerms = value ?? false;
    notifyListeners();
  }

  /// Valida los campos del formulario actual, ejecuta el flujo de inicio de sesión
  /// o de registro mediante el [AuthService], y si tiene éxito, establece la sesión global 
  /// del usuario en [SessionController] y redirige a la ruta correspondiente según su rol.
  Future<void> submit(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    if (isRegisterMode && !acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los terminos')),
      );
      return;
    }

    loading = true;
    notifyListeners();

    try {
      if (isRegisterMode) {
        final nombre = nameController.text.trim();
        final email = emailController.text.trim();
        final password = passwordController.text;
        final telefono = phoneController.text.trim();
        final empresa = companyController.text.trim();

        if (nombre.isEmpty) {
          throw Exception('El nombre es obligatorio');
        }
        if (!email.contains('@')) {
          throw Exception('El email no es válido');
        }
        if (password.length < 6) {
          throw Exception('La contraseña debe tener al menos 6 caracteres');
        }
        if (telefono.isEmpty) {
          throw Exception('El teléfono es obligatorio');
        }
        if (rol != UserRole.cliente && empresa.isEmpty) {
          throw Exception('La empresa es obligatoria para jefe y empleado');
        }

        await _authService.register(
          nombre: nombre,
          email: email,
          password: password,
          telefono: telefono,
          rol: rol,
          empresaNombre: empresa.isEmpty ? null : empresa,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cuenta creada. Revisa tu correo para confirmar tu cuenta antes de iniciar sesión.',
              ),
            ),
          );
        }
        isRegisterMode = false;
        return;
      } else {
        final user = await _authService.login(
          emailController.text,
          passwordController.text,
        );

        SessionController.instance.login(
          email: user.email,
          rol: user.rol,
          nombre: user.nombre,
          id: user.id,
          empresaNombre: user.empresaNombre,
          empresaId: user.empresaId,
          avatar: user.avatar,
        );

        final dest = user.rol == UserRole.cliente
            ? '/area-cliente'
            : '/dashboard';
        if (context.mounted) {
          context.go(dest);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Libera correctamente los recursos de memoria ocupados por los [TextEditingController]
  /// cuando el controlador es destruido o la pantalla se cierra.
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    companyController.dispose();
    super.dispose();
  }
}
