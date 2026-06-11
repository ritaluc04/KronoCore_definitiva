/// =============================================================================
/// kons.dart — Design tokens de KronoCore (colores, espaciado, radios, sombras).
/// Centraliza constantes visuales reutilizadas por el tema y los widgets.
/// =============================================================================

import 'package:flutter/material.dart';

/// KronoCore design tokens — Define la paleta de colores, espaciados y radios.
/// Se han organizado para soportar temas Claro (Light) y Oscuro (Dark).
class KronoColors {
  /// --- Colores de Marca (Compartidos) ---
  static const primary = Color(0xFF1D4ED8);       // Azul Krono
  static const primaryFg = Colors.white;
  static const primarySoft = Color(0xFFE0E7FF);

  /// --- Tema Claro (Light Mode) ---
  static const background = Color(0xFFFFFFFF);    // Fondo principal
  static const surface1 = Color(0xFFFAFBFC);      // Superficie secundaria
  static const surface2 = Color(0xFFF1F5F9);      // Superficie terciaria
  static const border = Color(0xFFE2E8F0);         // Color de bordes y divisores
  static const foreground = Color(0xFF0F172A);    // Texto principal (Slate 900)
  static const muted = Color(0xFF64748B);         // Texto secundario/deshabilitado

  /// --- Tema Oscuro (Dark Mode) ---
  /// La paleta oscura usa azules fríos y grises suaves para dar más contraste
  /// sin llegar a un negro puro, que suele cansar más a la vista.
  static const darkBackground = Color(0xFF0B1220); // Fondo principal oscuro
  static const darkSurface1 = Color(0xFF111A2E);    // Superficie secundaria
  static const darkSurface2 = Color(0xFF182338);    // Superficie terciaria
  static const darkBorder = Color(0xFF2C3A56);      // Bordes en modo oscuro
  static const darkForeground = Color(0xFFF3F7FF);   // Texto principal
  static const darkMuted = Color(0xFF9AA8C3);       // Texto secundario

  /// --- Colores Semánticos (Estados) ---
  static const accent = Color(0xFF22D3EE);
  static const success = Color(0xFF16A34A);       // Éxito / Completado
  static const warning = Color(0xFFF59E0B);       // Alertas / Pendiente
  static const danger  = Color(0xFFDC2626);       // Error / Crítico
  static const info    = Color(0xFF3B82F6);       // Información
}

/// Definición de espaciados estándar para márgenes y paddings.
class KronoSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

/// Definición de radios de borde consistentes.
class KronoRadius {
  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const pill = 9999.0;
}

/// Sombras predefinidas para elevar elementos visualmente.
class KronoShadows {
  static const sm = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const md = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 12, offset: Offset(0, 4)),
  ];
}
