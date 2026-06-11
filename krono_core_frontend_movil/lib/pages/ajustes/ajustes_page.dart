import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../global/utils/session.dart';
import '../../global/utils/kons.dart';
import '../../global/widgets/krono_widgets.dart';
import '../../global/models/models.dart';
import '../../global/theme/theme_controller.dart';
import 'dart:convert';
import '../../data/api_client.dart';

/// Pantalla de ajustes de la cuenta. Muestra el perfil del usuario,
/// opciones de seguridad, preferencias (idioma, tema, notificaciones)
/// y, si el usuario es admin, acceso directo a la gestión de usuarios.
class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = SessionController.instance.user!;
    final isAdmin = user.rol == UserRole.admin;
    // Leemos el ThemeController del árbol de providers para el switch de modo oscuro.
    final themeController = Provider.of<ThemeController>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KronoSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ajustes', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text(
            'Gestiona tu cuenta y preferencias',
            style: TextStyle(color: KronoColors.muted),
          ),
          const SizedBox(height: 24),
          // Tarjeta de perfil: muestra avatar, nombre, email, rol y campos editables.
          KronoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perfil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    AvatarCircle(name: user.nombre, size: 64),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(color: KronoColors.muted),
                        ),
                        const SizedBox(height: 8),
                        StatusChip(
                          label: user.rol.label,
                          color: KronoColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: user.nombre,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: user.email,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Perfil actualizado')),
                    ),
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tarjeta de seguridad: accesos rápidos a contraseña, sesiones y 2FA.
          const KronoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seguridad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lock_outline),
                  title: Text('Cambiar contraseña'),
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.devices_other),
                  title: Text('Sesiones activas'),
                  subtitle: Text('2 dispositivos'),
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.shield_outlined),
                  title: Text('Autenticación en dos pasos'),
                  subtitle: Text('Desactivada'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tarjeta de preferencias: idioma, zona horaria, modo oscuro y notificaciones.
          KronoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preferencias',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField(
                        decoration: const InputDecoration(labelText: 'Idioma'),
                        initialValue: 'es',
                        items: const [
                          DropdownMenuItem(value: 'es', child: Text('Español')),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                        ],
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField(
                        decoration: const InputDecoration(
                          labelText: 'Zona horaria',
                        ),
                        initialValue: 'Europe/Madrid',
                        items: const [
                          DropdownMenuItem(
                            value: 'Europe/Madrid',
                            child: Text('Europe/Madrid'),
                          ),
                        ],
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Switch que llama a ThemeController para alternar claro/oscuro.
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: themeController.isDarkMode,
                  onChanged: (val) => themeController.toggleTheme(),
                  title: const Text('Modo Oscuro'),
                  secondary: Icon(
                    themeController.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: true,
                  onChanged: (_) {},
                  title: const Text('Notificaciones por email'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: false,
                  onChanged: (_) {},
                  title: const Text('Notificaciones push'),
                ),
              ],
            ),
          ),
          // Sección exclusiva para administradores: acceso a gestión de usuarios.
          if (isAdmin) ...[
            const SizedBox(height: 16),
            KronoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Usuarios del equipo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/ajustes/usuarios'),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Gestionar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Solo administradores. Crea, desactiva o cambia el rol de usuarios.',
                    style: TextStyle(color: KronoColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pantalla de administración de usuarios del sistema.
/// Solo accesible para el rol admin. Permite listar, editar,
/// eliminar e invitar usuarios vinculados a una empresa.
class UsuariosAdminScreen extends StatefulWidget {
  const UsuariosAdminScreen({super.key});
  @override
  State<UsuariosAdminScreen> createState() => _UsuariosAdminScreenState();
}

class _UsuariosAdminScreenState extends State<UsuariosAdminScreen> {
  List<dynamic> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    // Esperamos al primer frame para poder mostrar el selector de empresa
    // antes de cargar los usuarios.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requireAdminEmpresaSelection(context);
      _loadUsers();
    });
  }

  /// Carga la lista de usuarios desde /api/usuarios y actualiza el estado.
  Future<void> _loadUsers() async {
    setState(() => loading = true);
    try {
      final res = await ApiClient.get('/usuarios');
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        setState(() {
          users = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Muestra un side sheet para que el admin elija la empresa sobre la que
  /// quiere gestionar usuarios. Almacena la elección en [SessionController].
  Future<void> _requireAdminEmpresaSelection(BuildContext context) async {
    final empresas = <Map<String, dynamic>>[];
    try {
      final res = await ApiClient.get('/empresas');
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final dynamic body = jsonDecode(res.body);
        if (body is List) {
          empresas.addAll(List<Map<String, dynamic>>.from(body));
        }
      }
    } catch (e) {
      debugPrint('Error cargando empresas: $e');
    }

    int selectedEmpresaId = SessionController.instance.adminEmpresaId ?? -1;

    await showKronoSideSheet(
      context,
      title: 'Selecciona empresa',
      actions: [
        StatefulBuilder(
          builder: (context, setStateAction) => ElevatedButton(
            onPressed: selectedEmpresaId >= 0
                ? () {
                    SessionController.instance.setAdminEmpresaId(
                      selectedEmpresaId,
                    );
                    Navigator.of(context).pop();
                  }
                : null,
            child: const Text('Continuar'),
          ),
        ),
      ],
      children: [
        const Text(
          'Para gestionar usuarios como admin, elige la empresa o clientes.',
          style: TextStyle(color: KronoColors.muted),
        ),
        const SizedBox(height: 16),
        StatefulBuilder(
          builder: (context, setStateSheet) {
            return RadioGroup<int>(
              groupValue: selectedEmpresaId,
              onChanged: (value) {
                if (value != null) {
                  setStateSheet(() => selectedEmpresaId = value);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<int>(
                    title: const Text('Clientes (sin empresa)'),
                    value: 0,
                  ),
                  for (final empresa in empresas) ...[
                    RadioListTile<int>(
                      title: Text(empresa['nombre']?.toString() ?? 'Empresa'),
                      subtitle: Text('ID ${empresa['id'] ?? ''}'),
                      value:
                          int.tryParse(empresa['id']?.toString() ?? '') ?? -1,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Abre el side sheet de edición para un usuario concreto.
  /// Permite cambiar su rol, empresa y estado de verificación.
  void _showEdit(Map<String, dynamic> user) {
    UserRole role;
    try {
      role = UserRole.values.firstWhere(
        (e) =>
            e.name.toUpperCase() ==
            (user['rol']?.toString().toUpperCase() ?? 'EMPLEADO'),
      );
    } catch (_) {
      role = UserRole.empleado;
    }

    bool active = user['verificado'] ?? false;
    String empresaId = user['empresa']?['id']?.toString() ?? '';

    showKronoSideSheet(
      context,
      title: 'Editar Usuario',
      actions: [
        StatefulBuilder(
          builder: (context, setStateAction) => Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final payload = {
                      'rol': role.name.toUpperCase(),
                      'verificado': active,
                      'empresaId': int.tryParse(empresaId),
                    };
                    await ApiClient.put('/usuarios/${user['id']}', payload);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario actualizado')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ],
      children: [
        StatefulBuilder(
          builder: (c, setS) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<UserRole>(
                initialValue: role,
                items: const [
                  DropdownMenuItem(
                    value: UserRole.empleado,
                    child: Text('Empleado'),
                  ),
                  DropdownMenuItem(value: UserRole.jefe, child: Text('Jefe')),
                  DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                ],
                onChanged: (v) => setS(() => role = v ?? UserRole.empleado),
                decoration: const InputDecoration(labelText: 'Rol'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: empresaId,
                decoration: const InputDecoration(labelText: 'ID de Empresa'),
                onChanged: (v) => empresaId = v,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: active,
                onChanged: (v) => setS(() => active = v ?? false),
                title: const Text('Activo / Verificado'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Muestra un diálogo de confirmación y elimina el usuario si el admin confirma.
  /// Gestiona tanto el éxito (204/200) como los posibles errores del backend.
  Future<void> _confirmDeleteUser(BuildContext context, dynamic userId) async {
    if (userId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text(
            '¿Eliminar este usuario? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final resp = await ApiClient.delete('/usuarios/${userId.toString()}');
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        if (!context.mounted) return;
        _loadUsers();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
      } else {
        final Map<String, dynamic> body = resp.body.isNotEmpty
            ? jsonDecode(resp.body)
            : {};
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al eliminar: ${body['message'] ?? resp.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionController.instance.user;
    final isAdmin = user?.rol == UserRole.admin;
    final isJefe = user?.rol == UserRole.jefe;
    final isManager = isAdmin || isJefe;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(KronoSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Usuarios',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              // El botón de invitar solo aparece para admin y jefe.
              if (isManager)
                ElevatedButton.icon(
                  onPressed: () =>
                      _showInviteDialog(context).then((_) => _loadUsers()),
                  icon: const Icon(Icons.add),
                  label: const Text('Invitar usuario'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (users.isEmpty)
            const Text("No hay usuarios registrados")
          else
            // Lista de usuarios con avatar, nombre, empresa, rol, estado y acciones.
            KronoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < users.length; i++) ...[
                    ListTile(
                      leading: AvatarCircle(name: users[i]['nombre'] ?? 'U'),
                      title: Text(
                        users[i]['nombre'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(users[i]['email'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (users[i]['empresaNombre'] != null)
                            StatusChip(
                              label: users[i]['empresaNombre'],
                              color: KronoColors.muted,
                            ),
                          const SizedBox(width: 8),
                          StatusChip(
                            label: users[i]['rol'] ?? 'EMPLEADO',
                            color: KronoColors.primary,
                          ),
                          const SizedBox(width: 8),
                          // Chip verde si el usuario está verificado, amarillo si está pendiente.
                          StatusChip(
                            label: (users[i]['verificado'] ?? false)
                                ? 'Activo'
                                : 'Pendiente',
                            color: (users[i]['verificado'] ?? false)
                                ? KronoColors.success
                                : KronoColors.warning,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showEdit(users[i]),
                            icon: const Icon(
                              Icons.edit,
                              color: KronoColors.muted,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _confirmDeleteUser(context, users[i]['id']),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < users.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Muestra el side sheet de invitación de un nuevo usuario al equipo.
/// Recoge email y rol, llama a POST /invitaciones/empleado y muestra
/// el enlace de invitación si el backend lo devuelve.
Future<void> _showInviteDialog(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  String email = '';
  UserRole role = UserRole.empleado;
  bool active = true;
  bool sending = false;
  String? link;

  return showKronoSideSheet(
    context,
    title: 'Invitar usuario',
    actions: [
      StatefulBuilder(
        builder: (context, setState) => Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      formKey.currentState?.save();
                      setState(() => sending = true);
                      try {
                        final payload = <String, dynamic>{'email': email};
                        // Incluye el empresaId del admin o del usuario en sesión.
                        final empresaId =
                            SessionController.instance.adminEmpresaId ??
                            SessionController.instance.user?.empresaId;
                        if (empresaId != null) {
                          payload['empresaId'] = empresaId;
                        }
                        final resp = await ApiClient.post(
                          '/invitaciones/empleado',
                          payload,
                        );
                        if (!context.mounted) return;
                        final currentContext = context;
                        if (resp.statusCode == 201 || resp.statusCode == 200) {
                          final Map<String, dynamic> body = resp.body.isNotEmpty
                              ? jsonDecode(resp.body)
                              : {};
                          link = body['link']?.toString();
                          setState(() => sending = false);
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            SnackBar(
                              content: Text('Invitación enviada a $email'),
                            ),
                          );
                        } else {
                          final Map<String, dynamic> err = resp.body.isNotEmpty
                              ? jsonDecode(resp.body)
                              : {'message': 'Error'};
                          setState(() => sending = false);
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: ${err['message'] ?? 'Error al enviar'}',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        final currentContext = context;
                        setState(() => sending = false);
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    },
              // Muestra spinner mientras se envía la invitación.
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    ],
    children: [
      StatefulBuilder(
        builder: (c, setState) => Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                onSaved: (v) {},
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (v) => email = v ?? '',
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                initialValue: role,
                items: const [
                  DropdownMenuItem(
                    value: UserRole.empleado,
                    child: Text('Empleado'),
                  ),
                  DropdownMenuItem(value: UserRole.jefe, child: Text('Jefe')),
                  DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                ],
                onChanged: (v) => role = v ?? UserRole.empleado,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: active,
                onChanged: (v) => setState(() => active = v ?? true),
                title: const Text('Activo'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              // Si el backend devuelve un enlace de invitación, se muestra seleccionable.
              if (link != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SelectableText(
                    'Enlace: $link',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: KronoColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}
