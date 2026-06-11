import 'package:flutter/material.dart';
import '../../global/utils/kons.dart';
import '../../global/widgets/krono_widgets.dart';
import 'reportes_controller.dart';

/// Pantalla del módulo de informes y exportación de datos.
/// Muestra tarjetas con métricas resumidas que evalúan el rendimiento del negocio
/// y ofrece herramientas para la exportación de información detallada en CSV, 
/// incluyendo la posibilidad de aplicar filtros específicos antes de la descarga.
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  late final ReportesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReportesController();
    /// Carga inicial automática de todos los totales desde los endpoints de la API.
    _controller.cargarResumen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        /// Despliega un indicador de carga mientras el controlador finaliza 
        /// de resolver todas las solicitudes asíncronas para las métricas.
        if (_controller.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(KronoSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informes y exportación',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Resumen ejecutivo y exportación rápida para entregar análisis reales en el TFG.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              /// Tarjetas superiores principales que resumen las operaciones globales del negocio.
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _Metric(
                    title: 'Clientes',
                    value: _controller.clientes.toString(),
                    icon: Icons.people_outline,
                  ),
                  _Metric(
                    title: 'Citas',
                    value: _controller.citas.toString(),
                    icon: Icons.event_outlined,
                  ),
                  _Metric(
                    title: 'Ventas',
                    value: _controller.ventas.toString(),
                    icon: Icons.point_of_sale_outlined,
                  ),
                  _Metric(
                    title: 'Tareas',
                    value: _controller.tareas.toString(),
                    icon: Icons.view_kanban_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              /// Indicadores secundarios mediante "chips" que muestran datos de mayor nivel de detalle, 
              /// como citas por estados específicos y urgencia de tareas.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(
                    label: 'Confirmadas ${_controller.citasConfirmadas}',
                    color: KronoColors.success,
                    icon: Icons.check_circle_outline,
                  ),
                  StatusChip(
                    label: 'Pendientes ${_controller.citasPendientes}',
                    color: KronoColors.warning,
                    icon: Icons.schedule,
                  ),
                  StatusChip(
                    label: 'Alta prioridad ${_controller.tareasAlta}',
                    color: KronoColors.danger,
                    icon: Icons.flag_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              /// Sección de filtros configurables que se enviarán como parámetros de búsqueda 
              /// al momento de invocar los endpoints de exportación CSV.
              KronoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtros de exportación',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 170,
                          child: TextField(
                            controller: _controller.desdeController,
                            decoration: const InputDecoration(
                              labelText: 'Desde (yyyy-mm-dd)',
                              prefixIcon: Icon(Icons.date_range),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          child: TextField(
                            controller: _controller.hastaController,
                            decoration: const InputDecoration(
                              labelText: 'Hasta (yyyy-mm-dd)',
                              prefixIcon: Icon(Icons.event_available),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String?>(
                            initialValue: _controller.estadoCita,
                            decoration: const InputDecoration(
                              labelText: 'Estado cita',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Todos'),
                              ),
                              DropdownMenuItem(
                                value: 'pendiente',
                                child: Text('Pendiente'),
                              ),
                              DropdownMenuItem(
                                value: 'confirmada',
                                child: Text('Confirmada'),
                              ),
                              DropdownMenuItem(
                                value: 'cancelada',
                                child: Text('Cancelada'),
                              ),
                              DropdownMenuItem(
                                value: 'noShow',
                                child: Text('No show'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _controller.estadoCita = v),
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String?>(
                            initialValue: _controller.prioridadTarea,
                            decoration: const InputDecoration(
                              labelText: 'Prioridad tarea',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Todas'),
                              ),
                              DropdownMenuItem(
                                value: 'baja',
                                child: Text('Baja'),
                              ),
                              DropdownMenuItem(
                                value: 'media',
                                child: Text('Media'),
                              ),
                              DropdownMenuItem(
                                value: 'alta',
                                child: Text('Alta'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _controller.prioridadTarea = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              /// Sección de acciones de exportación: una botonera que invoca la copia 
              /// de los datos transformados a CSV directamente en el portapapeles del dispositivo.
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _controller.exporting
                        ? null
                        : () => _controller.copiarCsv(
                            context,
                            '/reportes/clientes',
                          ),
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Exportar clientes'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _controller.exporting
                        ? null
                        : () =>
                              _controller.copiarCsv(context, '/reportes/citas'),
                    icon: const Icon(Icons.event_note_outlined),
                    label: const Text('Exportar citas'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _controller.exporting
                        ? null
                        : () => _controller.copiarCsv(
                            context,
                            '/reportes/ventas',
                          ),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Exportar ventas'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _controller.exporting
                        ? null
                        : () => _controller.copiarCsv(
                            context,
                            '/reportes/tareas',
                          ),
                    icon: const Icon(Icons.view_kanban_outlined),
                    label: const Text('Exportar tareas'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Al exportar, el CSV se copia al portapapeles para que lo pegues directamente en Excel o Google Sheets.',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget reutilizable diseñado como una tarjeta compacta que exhibe 
/// una métrica numérica resaltada junto a un icono representativo del tipo de dato.
class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _Metric({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: KronoCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: KronoColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: KronoColors.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
