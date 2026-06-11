/// =============================================================================
/// app_layout.dart — Shell responsive de la aplicación autenticada.
/// Envuelve las pantallas internas con sidebar (escritorio) o barra inferior
/// (móvil), filtrando menús según el rol del usuario conectado.
/// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/api_client.dart';
import '../utils/session.dart';
import '../utils/kons.dart';
import '../models/models.dart';

/// CLASE: NavItem
/// Estructura de datos para definir los elementos de navegación en el menú.
class NavItem {
  final String label; // Texto a mostrar.
  final IconData icon; // Icono descriptivo.
  final String route; // Ruta a la que navega.
  final Set<UserRole> roles; // Roles que tienen permiso para ver este item.
  const NavItem(this.label, this.icon, this.route, this.roles);
}

/// Conjuntos de roles predefinidos para facilitar la asignación de permisos.
const _allStaff = {UserRole.admin, UserRole.jefe, UserRole.empleado};
const _admin = {UserRole.admin};
const _adminJefe = {UserRole.admin, UserRole.jefe};
const _cliente = {UserRole.cliente};

/// LISTA: navItems
/// Plantilla base (Shell) que envuelve las pantallas principales de la aplicación.
/// Implementa la estructura general de navegación a través de un `Scaffold` que incluye 
/// la barra superior (AppBar) interactiva y el menú lateral (Drawer) de enrutamiento, 
/// garantizando una experiencia visual consistente y una transición fluida entre vistas. inferior.
const navItems = <NavItem>[
  NavItem('Dashboard', Icons.dashboard_outlined, '/dashboard', _allStaff),
  NavItem('Clientes', Icons.people_outline, '/clientes', _allStaff),
  NavItem('Citas', Icons.event_outlined, '/citas', _allStaff),
  NavItem('Inventario', Icons.inventory_2_outlined, '/inventario', _adminJefe),
  NavItem('Ventas', Icons.point_of_sale_outlined, '/ventas', _allStaff),
  NavItem('Facturas', Icons.description_outlined, '/facturas', _allStaff),
  NavItem('Gastos', Icons.receipt_long_outlined, '/gastos', _allStaff),
  NavItem('Board', Icons.view_kanban_outlined, '/board', _allStaff),
  NavItem('Informes', Icons.bar_chart_outlined, '/reportes', _allStaff),
  NavItem('Ajustes', Icons.settings_outlined, '/ajustes', {
    ..._allStaff,
    UserRole.cliente,
  }),
  NavItem(
    'Usuarios',
    Icons.admin_panel_settings_outlined,
    '/ajustes/usuarios',
    _admin,
  ),
  /// Items de navegación para clientes (tanto móvil como escritorio)
  NavItem('Mis citas', Icons.event_outlined, '/area-cliente', _cliente),
  NavItem(
    'Solicitar cita',
    Icons.add_circle_outline,
    '/area-cliente/solicitar',
    _cliente,
  ),
];

/// WIDGET: AppShell
/// El "contenedor principal" de la aplicación que decide si mostrar la versión Desktop o Mobile
/// dependiendo del ancho de la pantalla (Responsive Design).
class AppShell extends StatelessWidget {
  final Widget child; // El contenido de la página actual.
  final String currentRoute; // La ruta actual para resaltar el menú activo.
  const AppShell({super.key, required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return isWide
        ? _DesktopShell(currentRoute: currentRoute, child: child)
        : _MobileShell(currentRoute: currentRoute, child: child);
  }
}

/// WIDGET PRIVADO: _DesktopShell
/// Layout diseñado para pantallas grandes. Incluye una barra lateral (Sidebar) fija.
class _DesktopShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  const _DesktopShell({required this.child, required this.currentRoute});

  /// Layout de escritorio: sidebar fija + cabecera + área de contenido.
  @override
  Widget build(BuildContext context) {
    final user = SessionController.instance.user!;
    final visible = navItems.where((n) => n.roles.contains(user.rol)).toList();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;
    final surface = scheme.surface;
    final fg = scheme.onSurface;

    return Scaffold(
      backgroundColor: bg,
      body: Row(
        children: [
          /// Sidebar: Barra lateral de navegación
          Material(
            color: surface,
            child: SizedBox(
              width: 240,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Logo y Nombre de la App
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: KronoColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.schedule,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'KronoCore',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                  ),
                  /// Lista de items de navegación
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        for (final item in visible)
                          _SidebarItem(
                            item: item,
                            active: _isRouteActive(currentRoute, item.route),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  /// Botón de Cerrar Sesión en la parte inferior del menú
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: KronoColors.danger,
                      ),
                      title: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: KronoColors.danger),
                      ),
                      onTap: () {
                        SessionController.instance.logout();
                        context.go('/login');
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(KronoRadius.md),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          /// Área de contenido principal (Derecha)
          Expanded(
            child: Column(
              children: [
                /// Cabecera superior (Breadcrumbs + Perfil)
                _DesktopHeader(currentRoute: currentRoute),
                const Divider(height: 1),
                /// El contenido cambiante (las páginas)
                Expanded(
                  child: Container(color: bg, child: child),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// WIDGET PRIVADO: _SidebarItem
/// Representa un botón individual dentro de la barra lateral.
class _SidebarItem extends StatelessWidget {
  final NavItem item;
  final bool active; // Indica si el usuario está en esta ruta actualmente.
  const _SidebarItem({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? KronoColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(KronoRadius.md),
        child: InkWell(
          onTap: () => context.go(item.route),
          borderRadius: BorderRadius.circular(KronoRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            /// Indicador visual lateral para el item activo
            decoration: active
                ? const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: KronoColors.primary, width: 3),
                    ),
                  )
                : null,
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: active ? KronoColors.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: TextStyle(
                    color: active ? KronoColors.primary : fg,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// WIDGET PRIVADO: _DesktopHeader
/// Cabecera superior para la versión Desktop. Muestra la ruta actual (breadcrumbs) y el usuario.
class _DesktopHeader extends StatelessWidget {
  final String currentRoute;
  const _DesktopHeader({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final user = SessionController.instance.user!;
    final crumbs = currentRoute.split('/').where((s) => s.isNotEmpty).toList();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    return Container(
      height: 64,
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          /// Breadcrumbs: Muestra dónde se encuentra el usuario en la jerarquía.
          Row(
            children: [
              for (var i = 0; i < crumbs.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right, size: 16, color: muted),
                  ),
                Text(
                  _pretty(crumbs[i]),
                  style: TextStyle(
                    color: i == crumbs.length - 1 ? fg : muted,
                    fontWeight: i == crumbs.length - 1
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          /// Buscador global rápido.
          const SizedBox(
            width: 280,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar  ⌘K',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _showNotifications(context),
            icon: const Badge(child: Icon(Icons.notifications_outlined)),
          ),
          const SizedBox(width: 4),
          /// Perfil de usuario (Avatar y Nombre)
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: KronoColors.primary,
                child: Text(
                  user.nombre[0],
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.nombre,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  Text(
                    user.rol.label,
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _pretty(String s) => s[0].toUpperCase() + s.substring(1);
}

/// WIDGET PRIVADO: _MobileShell
/// Layout diseñado para móviles. Incluye AppBar y BottomNavigationBar.
class _MobileShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  const _MobileShell({required this.child, required this.currentRoute});

  /// Layout móvil: AppBar, contenido y BottomNavigationBar según rol.
  @override
  Widget build(BuildContext context) {
    final user = SessionController.instance.user!;
    final isCliente = user.rol == UserRole.cliente;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final tabs = isCliente
        ? const [
            NavItem('Mis citas', Icons.event_outlined, '/area-cliente', {
              UserRole.cliente,
            }),
            NavItem(
              'Solicitar',
              Icons.add_circle_outline,
              '/area-cliente/solicitar',
              {UserRole.cliente},
            ),
            NavItem('Ajustes', Icons.settings_outlined, '/ajustes', {
              UserRole.cliente,
            }),
          ]
        : const [
            NavItem(
              'Dashboard',
              Icons.dashboard_outlined,
              '/dashboard',
              _allStaff,
            ),
            NavItem('Citas', Icons.event_outlined, '/citas', _allStaff),
            NavItem('TPV', Icons.point_of_sale_outlined, '/ventas', _allStaff),
            NavItem('Board', Icons.view_kanban_outlined, '/board', _allStaff),
            NavItem(
              'Informes',
              Icons.bar_chart_outlined,
              '/reportes',
              _allStaff,
            ),
            NavItem(
              'Más',
              Icons.menu,
              '__more',
              _allStaff,
            ), // Botón para ver opciones ocultas en móvil.
          ];

    final activeIdx = _bestMatchIndex(currentRoute, tabs);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_titleFor(currentRoute)),
        actions: [
          IconButton(
            onPressed: () => _showNotifications(context),
            icon: const Badge(child: Icon(Icons.notifications_outlined)),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: activeIdx,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: KronoColors.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        showUnselectedLabels: true,
        onTap: (i) {
          final r = tabs[i].route;
          if (r == '__more') {
            /// Si pulsa 'Más', abre un menú desplegable inferior.
            showModalBottomSheet(
              context: context,
              builder: (_) => const _MoreSheet(),
            );
          } else {
            context.go(r);
          }
        },
        items: [
          for (final t in tabs)
            BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }

  String _titleFor(String route) {
    final found = navItems.firstWhere(
      (n) => route.startsWith(n.route),
      orElse: () => navItems.first,
    );
    return found.label;
  }
}

/// WIDGET PRIVADO: _MoreSheet
/// Menú inferior que aparece en móvil para acceder a las opciones que no caben en la BottomBar.
class _MoreSheet extends StatelessWidget {
  const _MoreSheet();
  @override
  Widget build(BuildContext context) {
    final user = SessionController.instance.user!;
    final extras = navItems.where(
      (n) =>
          n.roles.contains(user.rol) &&
          ![
            '/dashboard',
            '/citas',
            '/ventas',
            '/board',
            '/reportes',
          ].contains(n.route),
    );
    return SafeArea(
      child: Material(
        color: Theme.of(context).canvasColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in extras)
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                onTap: () {
                  Navigator.pop(context);
                  context.go(item.route);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: KronoColors.danger),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: KronoColors.danger),
              ),
              onTap: () {
                Navigator.pop(context);
                SessionController.instance.logout();
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

bool _isRouteActive(String currentRoute, String itemRoute) {
  return currentRoute == itemRoute || currentRoute.startsWith('$itemRoute/');
}

int _bestMatchIndex(String currentRoute, List<NavItem> tabs) {
  int bestIdx = 0;
  int bestLen = 0;
  for (var i = 0; i < tabs.length; i++) {
    final r = tabs[i].route;
    if (currentRoute == r || currentRoute.startsWith('$r/')) {
      if (r.length > bestLen) {
        bestLen = r.length;
        bestIdx = i;
      }
    }
  }
  return bestIdx;
}

void _showNotifications(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _NotificationsSheet(),
  );
}

Future<List<Notificacion>> _loadStockNotifications() async {
  try {
    final response = await ApiClient.get('/productos');
    if (response.statusCode != 200) {
      throw Exception('Error al cargar productos');
    }

    final List<dynamic> raw = jsonDecode(response.body) as List<dynamic>;
    final stockProducts = raw
        .map((item) => Producto.fromMap(item as Map<String, dynamic>))
        .where((p) => p.stock <= p.stockMin)
        .toList();

    return stockProducts
        .map(
          (p) => Notificacion(
            id: 'stock-${p.id}',
            titulo: 'Stock bajo: ${p.nombre}',
            mensaje: 'Tiene ${p.stock} / ${p.stockMin} unidades en inventario.',
            fecha: DateTime.now(),
          ),
        )
        .toList();
  } catch (e) {
    debugPrint('No se pudieron cargar notificaciones de stock: $e');
    return Notificacion.dummyData;
  }
}

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  late final Future<List<Notificacion>> _notisFuture;

  @override
  void initState() {
    super.initState();
    _notisFuture = _loadStockNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Notificaciones',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: FutureBuilder<List<Notificacion>>(
                future: _notisFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notis = snapshot.data ?? [];
                  if (notis.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay alertas de stock.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: KronoColors.muted,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: notis.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final n = notis[i];
                      final mutedColor =
                          theme.textTheme.bodySmall?.color ?? KronoColors.muted;
                      final surface2Color =
                          theme.cardTheme.color ?? KronoColors.darkSurface2;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: n.leida
                              ? surface2Color
                              : KronoColors.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.notifications,
                            color: n.leida ? mutedColor : KronoColors.primary,
                          ),
                        ),
                        title: Text(
                          n.titulo,
                          style: TextStyle(
                            fontWeight: n.leida
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(n.mensaje),
                        trailing: Text(
                          '${n.fecha.hour.toString().padLeft(2, '0')}:${n.fecha.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 12, color: mutedColor),
                        ),
                        onTap: () {},
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
