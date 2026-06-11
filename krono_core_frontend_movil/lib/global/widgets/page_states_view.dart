/// =============================================================================
/// page_states_view.dart — Vistas reutilizables de estados de pantalla.
/// Carga (LoadingView), vacío (EmptyView) y error (ErrorView) para listas/API.
/// =============================================================================

import 'package:flutter/material.dart';
import '../utils/kons.dart';

/// WIDGET: LoadingView
/// Pantalla de carga centralizada. 
/// Se utiliza mientras se espera la respuesta de una petición asíncrona a la API.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  /// Indicador circular centrado mientras cargan los datos.
  @override
  Widget build(BuildContext context) =>
      const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(strokeWidth: 2.5)));
}

/// WIDGET: EmptyView
/// Se muestra cuando una lista o búsqueda no devuelve resultados.
/// Permite incluir una acción (ej. "Añadir nuevo") para mejorar la experiencia del usuario (UX).
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyView({super.key, required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          /// Contenedor circular decorativo para el icono
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: KronoColors.surface2, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: KronoColors.muted),
          ),
          const SizedBox(height: 16),
          /// Título principal del estado vacío
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          /// Mensaje descriptivo o sugerencia para el usuario
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: KronoColors.muted)),
          /// Botón de acción opcional
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: onAction, icon: const Icon(Icons.add), label: Text(actionLabel!)),
          ]
        ]),
      ),
    );
  }
}

/// WIDGET: ErrorView
/// Se muestra cuando ocurre un fallo inesperado (ej. error de red o 500 del servidor).
/// Incluye un botón de "Reintentar" para facilitar la recuperación del error.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          /// Icono de advertencia en color rojo semántico
          const Icon(Icons.error_outline, color: KronoColors.danger, size: 48),
          const SizedBox(height: 12),
          /// Descripción del error recibido
          Text(message, textAlign: TextAlign.center),
          /// Acción para intentar cargar los datos nuevamente
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ]
        ]),
      ),
    );
  }
}
