/// =============================================================================
/// kons_app_theme.dart — Construcción del ThemeData global de la app.
/// Aplica tokens de kons.dart a Material 3: tipografía, inputs, botones, etc.
/// =============================================================================

import 'package:flutter/material.dart';
import '../utils/kons.dart';

/// Función constructora del tema global de KronoCore.
/// Recibe [isDarkMode] para decidir qué paleta de colores aplicar manteniendo
/// la coherencia visual en toda la interfaz.
ThemeData buildKronoTheme({bool isDarkMode = false}) {
  final fgColor = isDarkMode ? KronoColors.darkForeground : KronoColors.foreground;
  final bgColor = isDarkMode ? KronoColors.darkBackground : KronoColors.background;
  final surfaceColor = isDarkMode ? KronoColors.darkSurface1 : KronoColors.background;
  final surfaceColor2 = isDarkMode ? KronoColors.darkSurface2 : KronoColors.surface1;
  final borderColor = isDarkMode ? KronoColors.darkBorder : KronoColors.border;
  final mutedColor = isDarkMode ? KronoColors.darkMuted : KronoColors.muted;

  final scheme = (isDarkMode ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
    primary: KronoColors.primary,
    onPrimary: KronoColors.primaryFg,
    secondary: KronoColors.accent,
    onSecondary: isDarkMode ? KronoColors.darkBackground : KronoColors.background,
    surface: surfaceColor,
    onSurface: fgColor,
    surfaceContainerHighest: surfaceColor2,
    outline: borderColor,
    outlineVariant: borderColor,
    error: KronoColors.danger,
    brightness: isDarkMode ? Brightness.dark : Brightness.light,
  );

  /// Ensambla ThemeData con estilos compartidos por toda la interfaz.
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: isDarkMode ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bgColor,
    canvasColor: bgColor,
    cardColor: surfaceColor,
    dividerColor: borderColor,
    fontFamily: 'Roboto', // Fuente principal de la marca.
    
    /// Configuración global de estilos de texto.
    textTheme: TextTheme(
      displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: fgColor),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: fgColor),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: fgColor),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: fgColor),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fgColor),
      bodyLarge: TextStyle(fontSize: 15, color: fgColor),
      bodyMedium: TextStyle(fontSize: 14, color: fgColor),
      bodySmall: TextStyle(fontSize: 12, color: mutedColor),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    
    /// Estilo predeterminado para todas las tarjetas (Cards) de la aplicación.
    cardTheme: CardThemeData(
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(KronoRadius.lg),
      ),
      margin: EdgeInsets.zero,
    ),
    
    /// Estilo de los campos de texto (TextFields / FormFields).
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KronoRadius.md),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KronoRadius.md),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KronoRadius.md),
        borderSide: const BorderSide(color: KronoColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KronoRadius.md),
        borderSide: const BorderSide(color: KronoColors.danger),
      ),
      labelStyle: TextStyle(color: mutedColor),
    ),
    
    /// Estilo de botones principales (Elevated).
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KronoColors.primary,
        foregroundColor: KronoColors.primaryFg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KronoRadius.md)),
      ),
    ),
    
    /// Estilo de botones secundarios (Outlined).
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: fgColor,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KronoRadius.md)),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: KronoColors.primary),
    ),
    
    dividerTheme: DividerThemeData(color: borderColor, thickness: 1, space: 1),

    popupMenuTheme: PopupMenuThemeData(
      color: surfaceColor,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(color: fgColor),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceColor,
      modalBackgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KronoRadius.lg),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KronoRadius.lg),
      ),
    ),

    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      textColor: fgColor,
      iconColor: mutedColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KronoRadius.md),
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
