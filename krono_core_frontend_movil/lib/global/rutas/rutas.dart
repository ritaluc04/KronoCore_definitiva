/// =============================================================================
/// rutas.dart — Definición centralizada de rutas y guardias de navegación.
/// Usa go_router para login, panel de staff, área de cliente y redirecciones
/// según autenticación y rol (RBAC) mediante SessionController.
/// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/session.dart';
import '../layout/app_layout.dart';
import '../models/models.dart';
import '../../pages/login/login_page.dart';
import '../../pages/dashboard/dashboard_page.dart';
import '../../pages/clientes/clientes_page.dart';
import '../../pages/citas/citas_page.dart';
import '../../pages/inventario/inventario_page.dart';
import '../../pages/ventas/ventas_page.dart';
import '../../pages/facturas/facturas_page.dart';
import '../../pages/gastos/gastos_page.dart';
import '../../pages/board/board_page.dart';
import '../../pages/reportes/reportes_page.dart';
import '../../pages/ajustes/ajustes_page.dart';
import '../../pages/area_clientes/area_clientes_page.dart';

/// Configuración principal de navegación y rutas de la aplicación.
/// Utiliza el paquete go_router para la gestión de navegación.
GoRouter buildRouter() {
  return GoRouter(
    /// Ruta inicial al abrir la aplicación.
    initialLocation: '/login',
    /// Escucha cambios en el estado de la sesión para activar redirecciones si es necesario.
    refreshListenable: SessionController.instance,
    /// Lógica de redirección basada en el estado de autenticación y roles de usuario.
    /// Evalúa en cada navegación si el usuario puede acceder a la ruta solicitada.
    redirect: (ctx, state) {
      final auth = SessionController.instance.isAuth;
      final goingToLogin = state.matchedLocation == '/login';
      final current = state.matchedLocation;

      /// Si no está autenticado y no va al login, redirigir a login.
      if (!auth && !goingToLogin) return '/login';

      /// Si ya está autenticado e intenta ir al login, redirigir según su rol.
      if (auth && goingToLogin) {
        final rol = SessionController.instance.user!.rol;
        return rol == UserRole.cliente ? '/area-cliente' : '/dashboard';
      }

      /// Restricciones de acceso para el rol cliente.
      if (auth) {
        final rol = SessionController.instance.user!.rol;
        if (rol == UserRole.cliente &&
            !current.startsWith('/area-cliente') &&
            current != '/ajustes') {
          /// El cliente entra primero en su area de citas; desde ahi puede navegar al resto de su zona.
          return '/area-cliente';
        }
      }
      return null;
    },
    /// Definición del árbol de rutas.
    routes: [
      /// Ruta de inicio de sesión.
      GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),

      /// ShellRoute permite envolver varias rutas bajo un mismo layout (AppShell).
      ShellRoute(
        builder: (ctx, state, child) =>
            AppShell(currentRoute: state.matchedLocation, child: child),
        routes: [
          /// Rutas principales del panel de administración/empleado.
          GoRoute(
            path: '/dashboard',
            builder: (ctx, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/clientes',
            builder: (ctx, state) => const ClientesScreen(),
            routes: [
              /// Ruta anidada: detalle de un cliente concreto por ID en la URL.
              GoRoute(
                path: ':id',
                builder: (ctx, state) =>
                    ClienteDetalleScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/citas', builder: (ctx, state) => const CitasScreen()),
          GoRoute(
            path: '/inventario',
            builder: (ctx, state) => const InventarioScreen(),
          ),
          GoRoute(
            path: '/ventas',
            builder: (ctx, state) => const VentasScreen(),
          ),
          GoRoute(
            path: '/facturas',
            builder: (ctx, state) => const FacturasScreen(),
          ),
          GoRoute(
            path: '/gastos',
            builder: (ctx, state) => const GastosScreen(),
          ),
          GoRoute(path: '/board', builder: (ctx, state) => const BoardScreen()),
          GoRoute(
            path: '/reportes',
            builder: (ctx, state) => const ReportesScreen(),
          ),

          /// Configuración y administración.
          GoRoute(
            path: '/ajustes',
            builder: (ctx, state) => const AjustesScreen(),
            routes: [
              /// Subruta restringida a administradores: gestión de usuarios.
              GoRoute(
                path: 'usuarios',
                builder: (ctx, state) => const UsuariosAdminScreen(),
              ),
            ],
          ),

          /// Rutas específicas para el Área de Clientes.
          GoRoute(
            path: '/area-cliente',
            builder: (ctx, state) => const MisCitasScreen(),
            routes: [
              /// Formulario para que el cliente solicite una nueva cita.
              GoRoute(
                path: 'solicitar',
                builder: (ctx, state) => const SolicitarCitaScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    /// Manejador de errores para rutas no encontradas (Página 404).
    errorBuilder: (_, s) =>
        Scaffold(body: Center(child: Text('404 · ${s.matchedLocation}'))),
  );
}
