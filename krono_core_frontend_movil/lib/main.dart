/// =============================================================================
/// main.dart — Punto de arranque de la aplicación móvil KronoCore.
/// Inicializa Flutter, el formato de fechas en español, el proveedor de tema
/// y monta el widget raíz con MaterialApp.router y navegación declarativa.
/// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

/// Importaciones de configuración global: Rutas, Tema y Controlador de Estado.
import 'global/rutas/rutas.dart';
import 'global/theme/kons_app_theme.dart';
import 'global/theme/theme_controller.dart';

/// Punto de entrada principal de la aplicación KronoCore.
/// Aquí se inicializan servicios críticos y se arranca el árbol de widgets.
void main() async {
  /// Asegura que los bindings de Flutter estén listos antes de ejecutar código asíncrono.
  WidgetsFlutterBinding.ensureInitialized();
  
  /// Inicializa el formato de fechas en español para toda la app (utilizado por el paquete intl).
  await initializeDateFormatting('es', null);
  
  runApp(
    /// Provee el controlador de tema a toda la jerarquía de widgets usando el patrón Provider.
    ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: const KronoCoreApp(),
    ),
  );
}

/// WIDGET: KronoCoreApp
/// Configura la aplicación a nivel global, incluyendo temas, navegación e internacionalización.
class KronoCoreApp extends StatelessWidget {
  const KronoCoreApp({super.key});

  /// Construye MaterialApp.router con tema, rutas e idioma español por defecto.
  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    
    final router = buildRouter();

    return MaterialApp.router(
      title: 'KronoCore',
      debugShowCheckedModeBanner: false,
      
      /// Aplica el tema dinámico basado en el estado del controlador.
      theme: buildKronoTheme(isDarkMode: themeController.isDarkMode),
      
      /// Inyecta la configuración de navegación para manejar el ruteo.
      routerConfig: router,
      
      /// Configuración de internacionalización: Define los idiomas soportados y sus delegados.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'), 
        Locale('en')
      ],
      locale: const Locale('es'), /// Forzamos el idioma español por defecto para esta versión.
    );
  }
}
