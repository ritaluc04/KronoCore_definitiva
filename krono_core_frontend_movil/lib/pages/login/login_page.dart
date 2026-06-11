import 'package:flutter/material.dart';
import '../../global/utils/kons.dart';
import '../../global/models/models.dart';
import 'login_controller.dart';

/// Pantalla unificada de acceso y registro para la aplicación KronoCore.
/// Esta vista proporciona la interfaz principal para que los usuarios puedan autenticarse 
/// en el sistema utilizando su correo electrónico y contraseña. Además, cuenta con un modo 
/// alternativo integrado que permite crear nuevas cuentas con la selección de roles específicos 
/// (Administrador, Jefe de Equipo, Empleado, Cliente) adaptando dinámicamente el formulario.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Estado mutable asociado a [LoginScreen]. 
/// Enlaza la interfaz gráfica con las operaciones y variables definidas en [LoginController].
class _LoginScreenState extends State<LoginScreen> {
  final _controller = LoginController();

  @override
  void dispose() {
    /// Libera los recursos del controlador instanciado cuando la pantalla es destruida
    /// o retirada del árbol de widgets.
    _controller.dispose();
    super.dispose();
  }

  /// Construye la jerarquía visual de la pantalla, que consiste en un diseño centrado
  /// que contiene una tarjeta (card) adaptable con el formulario y sus interacciones.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.textTheme.bodySmall?.color ?? KronoColors.muted;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            /// Limitamos el ancho del formulario para garantizar su correcta visualización 
            /// en dispositivos con pantallas amplias (tablets, web, o desktop).
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(KronoRadius.lg),
                border: Border.all(
                  color: theme.dividerTheme.color ?? KronoColors.border,
                ),
                boxShadow: KronoShadows.sm,
              ),
              child: ListenableBuilder(
                /// [ListenableBuilder] se encarga de escuchar los cambios emitidos por el [_controller] 
                /// para redibujar la UI localmente, como al alternar entre modo login y registro, 
                /// o al cambiar la visibilidad de la contraseña.
                listenable: _controller,
                builder: (context, _) {
                  return Form(
                    key: _controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 28),

                        /// Renderiza de forma condicional los campos extendidos si el usuario
                        /// se encuentra en el modo de registro.
                        if (_controller.isRegisterMode) ...[
                          _buildHintCard(
                            icon: Icons.info_outline,
                            title: 'Registro por rol',
                            text:
                                'Cliente, empleado y jefe usan el mismo formulario, pero cada uno pide datos distintos.',
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_controller.isRegisterMode) ...[
                          /// Campo desplegable para seleccionar el rol del usuario durante su registro.
                          DropdownButtonFormField<UserRole>(
                            initialValue: _controller.rol,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de cuenta',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: UserRole.admin,
                                child: Text('Administrador'),
                              ),
                              DropdownMenuItem(
                                value: UserRole.jefe,
                                child: Text('Jefe de Equipo'),
                              ),
                              DropdownMenuItem(
                                value: UserRole.empleado,
                                child: Text('Empleado'),
                              ),
                              DropdownMenuItem(
                                value: UserRole.cliente,
                                child: Text('Cliente'),
                              ),
                            ],
                            onChanged: (v) =>
                                _controller.setRole(v ?? UserRole.cliente),
                          ),
                          const SizedBox(height: 12),

                          /// Campo de texto obligatorio para el nombre completo del usuario.
                          TextFormField(
                            controller: _controller.nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre completo',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Nombre requerido'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          /// Campo de texto para la asignación de empresa. Este dato
                          /// no se solicita si el rol seleccionado es Cliente.
                          if (_controller.rol != UserRole.cliente)
                            Column(
                              children: [
                                TextFormField(
                                  controller: _controller.companyController,
                                  decoration: const InputDecoration(
                                    labelText: 'Empresa',
                                    prefixIcon: Icon(Icons.business_outlined),
                                  ),
                                  validator: (v) {
                                    if (_controller.rol == UserRole.cliente) {
                                      return null;
                                    }
                                    return (v == null || v.isEmpty)
                                        ? 'Empresa requerida'
                                        : null;
                                  },
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Jefe y empleado deben pertenecer a una empresa existente o nueva segun el caso.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: mutedColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),

                          /// Campo de texto obligatorio para capturar el teléfono del usuario.
                          TextFormField(
                            controller: _controller.phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Teléfono requerido'
                                : null,
                          ),
                          const SizedBox(height: 12),
                        ],

                        /// Campo de texto común para el ingreso del correo electrónico, utilizado
                        /// tanto para iniciar sesión como para el registro.
                        TextFormField(
                          controller: _controller.emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Email no válido'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        /// Campo de texto común para la contraseña, con una funcionalidad 
                        /// que permite revelar u ocultar sus caracteres de manera segura.
                        TextFormField(
                          controller: _controller.passwordController,
                          obscureText: _controller.obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _controller.obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: _controller.toggleObscure,
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Contraseña requerida'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        /// Casilla de verificación requerida para la aceptación legal de términos, 
                        /// desplegada exclusivamente durante la creación de una cuenta.
                        if (_controller.isRegisterMode) ...[
                          Row(
                            children: [
                              Checkbox(
                                value: _controller.acceptTerms,
                                onChanged: _controller.setAcceptTerms,
                                activeColor: KronoColors.primary,
                              ),
                              Expanded(
                                child: Text(
                                  'Acepto los terminos y condiciones de uso',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: mutedColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        /// Botón principal que ejecuta la validación y el proceso de envío.
                        /// Muestra un indicador de carga mientras se procesa la solicitud en el backend.
                        ElevatedButton(
                          onPressed: _controller.loading
                              ? null
                              : () => _controller.submit(context),
                          child: _controller.loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _controller.isRegisterMode
                                      ? 'Crear cuenta'
                                      : 'Iniciar sesión',
                                ),
                        ),
                        const SizedBox(height: 12),

                        /// Widget ubicado en la parte inferior que facilita la navegación rápida
                        /// cambiando entre la vista de iniciar sesión y la de registro.
                        _buildFooterLinks(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Retorna un widget con el logotipo de la aplicación y un bloque de texto que informa
  /// al usuario la finalidad de la pantalla dependiendo del modo en que se encuentre.
  Widget _buildHeader() {
    final fgColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? KronoColors.foreground;
    final mutedColor =
        Theme.of(context).textTheme.bodySmall?.color ?? KronoColors.muted;

    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: KronoColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.schedule, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          _controller.isRegisterMode ? 'Únete a Krono' : 'KronoCore',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: fgColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _controller.isRegisterMode
              ? 'Crea tu cuenta según tu rol'
              : 'Inicia sesión en tu cuenta',
          style: TextStyle(color: mutedColor),
        ),
      ],
    );
  }

  /// Retorna un componente visual estilizado como una tarjeta secundaria (Hint) diseñado
  /// para ofrecer indicaciones y guiar al usuario a través del proceso de registro o inicio de sesión.
  Widget _buildHintCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    final theme = Theme.of(context);
    final surface2 = theme.colorScheme.surfaceContainerHighest;
    final borderColor = theme.dividerTheme.color ?? KronoColors.border;
    final fgColor = theme.textTheme.bodyLarge?.color ?? KronoColors.foreground;
    final mutedColor = theme.textTheme.bodySmall?.color ?? KronoColors.muted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(KronoRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: KronoColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: fgColor),
                ),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(color: mutedColor, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Retorna la sección inferior del formulario que contiene una pregunta y un botón
  /// de texto plano para que el usuario pueda alternar la interfaz entre los diferentes modos.
  Widget _buildFooterLinks() {
    final mutedColor =
        Theme.of(context).textTheme.bodySmall?.color ?? KronoColors.muted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _controller.isRegisterMode
              ? '¿Ya tienes cuenta?'
              : '¿No tienes cuenta?',
          style: TextStyle(color: mutedColor, fontSize: 13),
        ),
        TextButton(
          onPressed: _controller.toggleMode,
          child: Text(
            _controller.isRegisterMode ? 'Inicia sesión' : 'Regístrate',
          ),
        ),
      ],
    );
  }
}
