import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../global/models/models.dart';
import '../../global/utils/kons.dart';
import '../../global/widgets/krono_widgets.dart';
import 'area_clientes_controller.dart';

/// Pantalla del área cliente: listado de sus citas y compras recientes.
class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  late final AreaClientesController _controller;

  @override
  void initState() {
    super.initState();
    // Inicializa el controlador y lanza la carga de datos en cuanto monta el widget.
    _controller = AreaClientesController();
    _controller.cargarMisCitas();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final f = DateFormat('EEE d MMM · HH:mm', 'es');

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        // Muestra spinner mientras se obtienen los datos del servidor.
        if (_controller.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final misCitas = _controller.misCitas;
        final misCompras = _controller.misCompras;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(KronoSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mis citas',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Próximas reservas y solicitudes',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              // Mini resumen con contadores de citas y compras.
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MiniSummary(
                    title: 'Citas',
                    value: misCitas.length.toString(),
                    icon: Icons.event,
                  ),
                  _MiniSummary(
                    title: 'Compras',
                    value: misCompras.length.toString(),
                    icon: Icons.shopping_bag_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tarjeta por cada cita: servicio, fecha, estado y botón de cancelar.
              for (final c in misCitas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: KronoCard(
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: KronoColors.primary.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.event,
                            color: KronoColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.servicio,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                f.format(c.inicio),
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Color del chip según el estado de la cita.
                        StatusChip(
                          label: c.estado.name,
                          color: c.estado == CitaEstado.confirmada
                              ? KronoColors.success
                              : c.estado == CitaEstado.pendiente
                              ? KronoColors.warning
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _controller.cancelarCita(c),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Compras recientes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              // Tabla con el historial de compras del cliente.
              KronoCard(
                padding: EdgeInsets.zero,
                child: _ComprasTable(items: misCompras),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tarjeta de resumen compacta con icono, etiqueta y cifra destacada.
class _MiniSummary extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniSummary({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: KronoColors.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: KronoColors.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tabla de compras recientes del cliente.
/// Expande cada venta en sus líneas de detalle (producto, importe, fecha).
class _ComprasTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _ComprasTable({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Todavía no hay compras registradas.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    // Cada venta puede tener varias líneas de detalle; se aplana en filas de tabla.
    final rows = items.expand((venta) {
      final fecha = venta['fecha'] != null
          ? DateTime.tryParse(venta['fecha'].toString())
          : null;
      final detalles = (venta['detalles'] as List<dynamic>? ?? const []);
      return detalles.map((d) {
        final detalle = Map<String, dynamic>.from(d as Map<dynamic, dynamic>);
        final subtotal = (detalle['subtotal'] as num?)?.toDouble() ?? 0;
        return TableRow(
          children: [
            _cell(detalle['productoNombre']?.toString() ?? 'Producto'),
            _cell('€ ${subtotal.toStringAsFixed(2)}'),
            _cell(
              fecha != null
                  ? DateFormat('dd MMM yyyy · HH:mm', 'es').format(fecha)
                  : '—',
            ),
          ],
        );
      });
    }).toList();

    return Table(
      border: TableBorder.symmetric(
        inside: BorderSide(color: scheme.outline),
        outside: BorderSide(color: scheme.outline),
      ),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(2),
      },
      children: [
        // Fila de cabecera de la tabla.
        TableRow(
          decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
          children: [
            _header(context, 'Producto'),
            _header(context, 'Importe'),
            _header(context, 'Fecha'),
          ],
        ),
        ...rows,
      ],
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.all(14),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _cell(String text) => Padding(
    padding: const EdgeInsets.all(14),
    child: Text(text, style: const TextStyle(fontSize: 13)),
  );
}

/// Pantalla con el asistente de 5 pasos para solicitar una nueva cita.
/// Empresa → Servicio → Día → Hora → Confirmación.
class SolicitarCitaScreen extends StatefulWidget {
  const SolicitarCitaScreen({super.key});

  @override
  State<SolicitarCitaScreen> createState() => _SolicitarCitaScreenState();
}

class _SolicitarCitaScreenState extends State<SolicitarCitaScreen> {
  late final AreaClientesController _controller;

  final _empresaSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AreaClientesController();
    _controller.cargarMisCitas();
  }

  @override
  void dispose() {
    _empresaSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fDay = DateFormat('EEEE d MMMM', 'es');
    final fHour = DateFormat('HH:mm', 'es');

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(KronoSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solicitar cita',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Busca primero la empresa, luego el servicio y la hora disponible.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Stepper(
                currentStep: _controller.step,
                onStepContinue: _controller.nextStep,
                onStepCancel: _controller.prevStep,
                // Botones personalizados: desactiva "Continuar" si falta día u hora,
                // y cambia el label a "Solicitar" en el paso final.
                controlsBuilder: (ctx, d) => Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: _controller.step == 4
                            ? () => _controller.enviarSolicitud(context)
                            : ((_controller.step == 2 &&
                                      _controller.selectedDay == null) ||
                                  (_controller.step == 3 &&
                                      _controller.selectedHour == null))
                            ? null
                            : d.onStepContinue,
                        child: Text(
                          _controller.step == 4 ? 'Solicitar' : 'Continuar',
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_controller.step > 0)
                        TextButton(
                          onPressed: d.onStepCancel,
                          child: const Text('Atrás'),
                        ),
                    ],
                  ),
                ),
                steps: [
                  // Paso 1 — Buscar y seleccionar empresa.
                  Step(
                    title: const Text('Empresa'),
                    isActive: _controller.step >= 0,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _empresaSearchController,
                          decoration: const InputDecoration(
                            labelText: 'Buscar empresa',
                            prefixIcon: Icon(Icons.search),
                            helperText:
                                'Escribe el nombre del negocio para encontrarlo',
                          ),
                          onChanged: _controller.buscarEmpresas,
                        ),
                        const SizedBox(height: 12),
                        // Muestra la empresa seleccionada con un estilo destacado.
                        if (_controller.empresaSeleccionada != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: .3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: .2),
                              ),
                            ),
                            child: Text(
                              'Seleccionada: ${_controller.empresaSeleccionada!.nombre}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        // Lista de resultados de búsqueda como tarjetas seleccionables.
                        if (_controller.empresas.isNotEmpty)
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              ..._controller.empresas.map(
                                (e) => Card(
                                  elevation: 0,
                                  color: Theme.of(context).colorScheme.surface,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.business_outlined,
                                      ),
                                      title: Text(e.nombre),
                                      subtitle: Text(
                                        e.telefono ?? 'Sin telefono',
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        _empresaSearchController.text =
                                            e.nombre;
                                        _controller.seleccionarEmpresa(e);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Paso 2 — Elegir el tipo de servicio mediante chips.
                  Step(
                    title: const Text('Servicio'),
                    isActive: _controller.step >= 1,
                    content: Wrap(
                      spacing: 8,
                      children:
                          ['Corte', 'Color', 'Tratamiento', 'Corte + barba']
                              .map(
                                (s) => ChoiceChip(
                                  label: Text(s),
                                  selected: _controller.servicio == s,
                                  onSelected: (_) => _controller.setServicio(s),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  // Paso 3 — Elegir día entre los próximos 14 disponibles.
                  Step(
                    title: const Text('Día disponible'),
                    isActive: _controller.step >= 2,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selecciona un día libre:',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _controller.availableDays
                              .map(
                                (d) => ChoiceChip(
                                  label: Text(fDay.format(d)),
                                  selected:
                                      _controller.selectedDay?.day == d.day,
                                  onSelected: (_) => _controller.selectDay(d),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  // Paso 4 — Elegir franja horaria libre del día elegido.
                  Step(
                    title: const Text('Hora disponible'),
                    isActive: _controller.step >= 3,
                    content: _controller.selectedDay == null
                        ? const Text('Primero selecciona un día')
                        : _controller.availableHours.isEmpty
                        ? const Text('Consultando disponibilidad...')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Horas libres para el ${fDay.format(_controller.selectedDay!)}:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _controller.availableHours
                                    .map(
                                      (h) => ChoiceChip(
                                        label: Text(fHour.format(h)),
                                        selected: _controller.selectedHour == h,
                                        onSelected: (_) =>
                                            _controller.selectHour(h),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                  ),
                  // Paso 5 — Resumen de la solicitud antes de confirmar.
                  Step(
                    title: const Text('Confirmar'),
                    isActive: _controller.step >= 4,
                    content: KronoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Empresa: ${_controller.empresaSeleccionada?.nombre ?? 'Sin seleccionar'}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Servicio: ${_controller.servicio}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _controller.selectedHour != null
                                ? 'Cuándo: ${fDay.format(_controller.selectedHour!)} a las ${fHour.format(_controller.selectedHour!)}'
                                : 'Revisa los pasos anteriores',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
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
