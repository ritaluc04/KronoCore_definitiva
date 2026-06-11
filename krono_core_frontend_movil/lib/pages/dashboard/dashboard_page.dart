import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../global/utils/kons.dart';
import '../../global/widgets/krono_widgets.dart';
import 'dashboard_controller.dart';

/// PÁGINA: DashboardScreen
/// Pantalla principal de resumen para administradores y empleados.
/// Muestra métricas clave, gráficos de ventas y un feed de actividad reciente.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// Estado de [DashboardScreen]: carga métricas y gráficos vía [DashboardController].
class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    /// Inicialización del controlador que gestiona los datos del dashboard.
    _controller = DashboardController();
  }

  @override
  void dispose() {
    /// Limpieza del controlador al cerrar la pantalla.
    _controller.dispose();
    super.dispose();
  }

  /// Construye el resumen: saludo, tarjetas de métricas, gráfico y actividad.
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    final mutedColor =
        Theme.of(context).textTheme.bodySmall?.color ?? KronoColors.muted;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(KronoSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Saludo inicial.
              Text(
                'Buenos días 👋',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Resumen operativo de hoy',
                style: TextStyle(color: mutedColor),
              ),
              const SizedBox(height: KronoSpacing.xl),

              /// Sección de Métricas (Tarjetas de resumen rápido).
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 240,
                    child: MetricCard(
                      titulo: 'Ventas hoy',
                      valor: _controller.ventasHoy,
                      delta: '+0%',
                      icon: Icons.point_of_sale,
                      color: KronoColors.primary,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: MetricCard(
                      titulo: 'Ventas del mes',
                      valor: _controller.ventasMesLabel,
                      delta: '',
                      icon: Icons.trending_up,
                      color: KronoColors.accent,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: MetricCard(
                      titulo: 'Citas hoy',
                      valor: _controller.citasHoy,
                      delta: '+0',
                      icon: Icons.event,
                      color: KronoColors.accent,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: MetricCard(
                      titulo: 'Stock alertas',
                      valor: _controller.stockAlertasLabel,
                      delta: '-1',
                      icon: Icons.inventory_2,
                      color: KronoColors.warning,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: MetricCard(
                      titulo: 'Tareas activas',
                      valor: _controller.tareasActivasLabel,
                      delta: '+0',
                      icon: Icons.task_alt,
                      color: KronoColors.success,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: MetricCard(
                      titulo: 'Alta prioridad',
                      valor: _controller.tareasAltaPrioridadLabel,
                      delta: '+0',
                      icon: Icons.flag,
                      color: KronoColors.danger,
                    ),
                  ),
                ],
              ),
              /// Tarjeta de alerta de stock bajo (detalle expandible)
              if (_controller.hayStockBajo)
                Padding(
                  padding: const EdgeInsets.only(top: KronoSpacing.xl),
                  child: KronoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 20,
                              color: KronoColors.danger,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Productos con stock bajo',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color ??
                                    KronoColors.foreground,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...(_controller.productosStockBajo.take(5).map((p) {
                          final nombre = p['nombre'] as String? ?? '';
                          final stock = p['stock'] as num? ?? 0;
                          final stockMin = p['stockMin'] as num? ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    nombre,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color ??
                                          KronoColors.foreground,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$stock / $stockMin',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: KronoColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: KronoSpacing.xl),

              /// Sección combinada: Gráfico de Ventas y Feed de Actividad.
              Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Gráfico de línea con la tendencia de ventas.
                  Expanded(
                    flex: wide ? 2 : 1,
                    child: KronoCard(
                      child: _VentasChart(
                        ventas: _controller.ventasSemana,
                        citasConfirmadas: _controller.citasConfirmadas,
                        tareasAltaPrioridad: _controller.tareasAltaPrioridad,
                      ),
                    ),
                  ),
                  SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                  /// Lista de actividad reciente del negocio.
                  Expanded(
                    flex: 1,
                    child: KronoCard(
                      child: _ActivityFeed(items: _controller.actividad),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// WIDGET PRIVADO: _VentasChart
/// Representa el gráfico estadístico de las ventas de los últimos 7 días.
class _VentasChart extends StatelessWidget {
  final List<double> ventas;
  final int citasConfirmadas;
  final int tareasAltaPrioridad;
  const _VentasChart({
    required this.ventas,
    required this.citasConfirmadas,
    required this.tareasAltaPrioridad,
  });

  /// Dibuja título, chips de estado y el gráfico de líneas semanal.
  @override
  Widget build(BuildContext context) {
    final fgColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? KronoColors.foreground;
    final mutedColor =
        Theme.of(context).textTheme.bodySmall?.color ?? KronoColors.muted;
    final borderColor =
        Theme.of(context).dividerTheme.color ?? KronoColors.border;
    final dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final spots = [
      for (var i = 0; i < ventas.length; i++) FlSpot(i.toDouble(), ventas[i]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ventas (últimos 7 días)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: fgColor,
              ),
            ),
            const Spacer(),
            const StatusChip(
              label: '+18% vs prev.',
              color: KronoColors.success,
              icon: Icons.trending_up,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            StatusChip(
              label: 'Confirmadas $citasConfirmadas',
              color: KronoColors.success,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(width: 8),
            StatusChip(
              label: 'Tareas altas $tareasAltaPrioridad',
              color: KronoColors.danger,
              icon: Icons.flag_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        /// Configuración del gráfico de líneas.
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: borderColor, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}€',
                      style: TextStyle(fontSize: 10, color: mutedColor),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        dias[v.toInt()],
                        style: TextStyle(fontSize: 11, color: mutedColor),
                      ),
                    ),
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: KronoColors.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: KronoColors.primary.withValues(alpha: .12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// WIDGET PRIVADO: _ActivityFeed
/// Muestra una lista cronológica de eventos ocurridos en el sistema.
class _ActivityFeed extends StatelessWidget {
  final List items;
  const _ActivityFeed({required this.items});

  /// Lista cronológica de eventos recientes del negocio.
  @override
  Widget build(BuildContext context) {
    final f = DateFormat('HH:mm');
    final fgColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? KronoColors.foreground;
    final mutedColor =
        Theme.of(context).textTheme.bodySmall?.color ?? KronoColors.muted;
    final surfaceColor =
        Theme.of(context).cardTheme.color ?? KronoColors.darkSurface2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividad reciente',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: fgColor,
          ),
        ),
        const SizedBox(height: 12),
        for (final it in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Icono del tipo de actividad.
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.circle_notifications_outlined,
                    size: 16,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(width: 10),
                /// Texto descriptivo de la actividad.
                Expanded(
                  child: Text(
                    it.texto,
                    style: TextStyle(fontSize: 13, color: fgColor),
                  ),
                ),
                /// Hora de ocurrencia.
                Text(
                  f.format(it.cuando),
                  style: TextStyle(fontSize: 11, color: mutedColor),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
