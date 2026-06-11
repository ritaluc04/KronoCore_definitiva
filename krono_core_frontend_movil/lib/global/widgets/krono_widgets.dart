/// =============================================================================
/// krono_widgets.dart — Componentes UI reutilizables de KronoCore.
/// Tarjetas, métricas del dashboard, chips de estado y avatares con iniciales.
/// =============================================================================

import 'package:flutter/material.dart';
import '../utils/kons.dart';

/// WIDGET: KronoCard
/// La tarjeta base de toda la aplicación.
/// Centraliza el diseño de bordes, sombras y colores de fondo para mantener la consistencia.
class KronoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  
  const KronoCard({super.key, required this.child, this.padding = const EdgeInsets.all(KronoSpacing.lg)});

  /// Contenedor con borde, sombra suave y padding configurable.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        /// Utiliza el color definido en el tema (soporta modo claro/oscuro automáticamente)
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(KronoRadius.lg),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? KronoColors.border),
        boxShadow: KronoShadows.sm,
      ),
      child: Material(
        color: Colors.transparent, // Permite que los efectos de "Ink" (taps) se vean correctamente
        child: child,
      ),
    );
  }
}

/// Dialogo base para formularios. Evita overflow en ventanas pequeñas al
/// limitar ancho/alto y mover el contenido a un scroll interno.
class KronoDialog extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget> actions;
  final double maxWidth;

  const KronoDialog({
    super.key,
    required this.title,
    required this.children,
    required this.actions,
    this.maxWidth = 460,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * .88;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel lateral (Side Sheet) para formularios y detalles.
/// Es una alternativa más moderna y espaciosa a los diálogos centrados.
class KronoSideSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget> actions;

  const KronoSideSheet({
    super.key,
    required this.title,
    required this.children,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        elevation: 16,
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(KronoRadius.lg),
        ),
        child: SizedBox(
          width: 480, // Ancho optimizado para formularios
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Cabecera del Panel
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              /// Contenido con Scroll
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              const Divider(height: 1),

              /// Acciones al pie
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions
                      .map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: a,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Función utilitaria para mostrar el panel lateral.
Future<T?> showKronoSideSheet<T>(
  BuildContext context, {
  required String title,
  required List<Widget> children,
  required List<Widget> actions,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'KronoSideSheet',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) => KronoSideSheet(
      title: title,
      actions: actions,
      children: children,
    ),
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
        ),
        child: child,
      );
    },
  );
}

/// WIDGET: MetricCard
/// Utilizado en el Dashboard para mostrar indicadores clave (KPIs).
/// Incluye un título, el valor principal y un "delta" (crecimiento/descenso).
class MetricCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String delta;
  final IconData icon;
  final Color color;

  const MetricCard({
    super.key, 
    required this.titulo, 
    required this.valor, 
    required this.delta, 
    required this.icon, 
    this.color = KronoColors.primary
  });

  @override
  Widget build(BuildContext context) {
    final positivo = !delta.startsWith('-');
    
    return KronoCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          /// Icono con fondo suave
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12), 
              borderRadius: BorderRadius.circular(KronoRadius.md)
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          /// Badge de tendencia
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (positivo ? KronoColors.success : KronoColors.danger).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(KronoRadius.pill),
            ),
            child: Text(
              delta, 
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.w600, 
                color: positivo ? KronoColors.success : KronoColors.danger
              )
            ),
          ),
        ]),
        const SizedBox(height: KronoSpacing.lg),
        Text(
          titulo, 
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? KronoColors.muted, fontSize: 12)
        ),
        const SizedBox(height: 4),
        Text(
          valor, 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color ?? KronoColors.foreground)
        ),
      ]),
    );
  }
}

/// WIDGET: StatusChip
/// Etiqueta visual para estados (Confirmado, Pendiente, etc.) o categorías.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusChip({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(KronoRadius.pill),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
        Text(
          label, 
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)
        ),
      ]),
    );
  }
}

/// WIDGET: AvatarCircle
/// Genera un círculo con las iniciales del nombre de forma determinista.
/// El color de fondo se calcula basándose en el nombre para que siempre sea el mismo para cada usuario.
class AvatarCircle extends StatelessWidget {
  final String name;
  final double size;

  const AvatarCircle({super.key, required this.name, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ');
    final initials = (parts.length > 1 
      ? '${parts.first[0]}${parts.last[0]}' 
      : (parts.first.isNotEmpty ? parts.first[0] : '?')).toUpperCase();
    
    final hue = name.codeUnits.fold<int>(0, (a, b) => a + b) % 360;
    
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: HSLColor.fromAHSL(1, hue.toDouble(), .35, .55).toColor(),
      ),
      alignment: Alignment.center,
      child: Text(
        initials, 
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: size * .38)
      ),
    );
  }
}
