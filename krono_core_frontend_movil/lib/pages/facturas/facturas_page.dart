import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/api_client.dart';
import '../../global/utils/kons.dart';
import '../../global/widgets/krono_widgets.dart';
import '../../global/widgets/page_states_view.dart';
import '../../global/models/models.dart';
import 'facturas_controller.dart';

/// Pantalla principal de facturación.
/// Muestra un resumen de totales facturados, pagados y pendientes, 
/// así como una tabla de facturas con opciones para crear nuevas.
class FacturasScreen extends StatefulWidget {
  const FacturasScreen({super.key});
  @override
  State<FacturasScreen> createState() => _FacturasScreenState();
}

class _FacturasScreenState extends State<FacturasScreen> {
  late final FacturasController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FacturasController();
    _controller.cargarFacturas();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(KronoSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Cabecera
              Row(
                children: [
                  Text(
                    'Facturación',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _showFacturaDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nueva factura'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// Resumen de totales
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildMetric(
                    'Facturado',
                    '${_controller.totalFacturado.toStringAsFixed(2)} €',
                    KronoColors.primary,
                  ),
                  _buildMetric(
                    'Pendiente',
                    '${_controller.totalPendiente.toStringAsFixed(2)} €',
                    KronoColors.warning,
                  ),
                  _buildMetric(
                    'Pagado',
                    '${_controller.totalPagado.toStringAsFixed(2)} €',
                    KronoColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// Tabla de facturas
              Expanded(
                child: _controller.cargando
                    ? const LoadingView()
                    : _controller.facturas.isEmpty
                    ? EmptyView(
                        icon: Icons.description_outlined,
                        title: 'Sin facturas',
                        message: 'No hay facturas registradas todavía.',
                        actionLabel: 'Nueva factura',
                        onAction: () => _showFacturaDialog(context),
                      )
                    : _buildFacturasTable(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Widget privado auxiliar para mostrar una tarjeta de métrica financiera.
  Widget _buildMetric(String label, String value, Color color) {
    return KronoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: KronoColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye y devuelve la tabla de datos de facturas.
  Widget _buildFacturasTable() {
    return SingleChildScrollView(
      child: KronoCard(
        padding: EdgeInsets.zero,
        child: DataTable(
          columnSpacing: 20,
          columns: const [
            DataColumn(
              label: Text(
                'Nº Factura',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Cliente',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Estado',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Fecha',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
          rows: _controller.facturas.map((f) {
            final estadoColor = _controller.getEstadoColor(f.estado);
            return DataRow(
              cells: [
                DataCell(Text(f.numeroFactura)),
                DataCell(Text(f.clienteNombre ?? '-')),
                DataCell(Text('${f.total.toStringAsFixed(2)} €')),
                DataCell(
                  _StatusChip(
                    label: _controller.getEstadoLabel(f.estado),
                    color: estadoColor,
                  ),
                ),
                DataCell(
                  Text(
                    '${f.fechaEmision.day}/${f.fechaEmision.month}/${f.fechaEmision.year}',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Muestra un diálogo lateral (side sheet) para crear una factura.
  void _showFacturaDialog(BuildContext context) {
    final nifCtrl = TextEditingController();
    final baseCtrl = TextEditingController();
    double ivaPct = 21;
    String clienteSeleccionado = '';

    Future<List<Cliente>> cargarClientes() async {
      try {
        final response = await ApiClient.get('/clientes');
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((j) => Cliente.fromMap(j)).toList();
        }
        return [];
      } catch (e) {
        return [];
      }
    }

    showKronoSideSheet(
      context,
      title: 'Nueva Factura',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final base = double.tryParse(baseCtrl.text) ?? 0;
            if (clienteSeleccionado.isEmpty || base <= 0) return;
            final ivaImp = base * (ivaPct / 100);
            final total = base + ivaImp;
            try {
              await _controller.crearFactura({
                'clienteNombre': clienteSeleccionado,
                'clienteNif': nifCtrl.text,
                'baseImponible': base,
                'ivaPorcentaje': ivaPct,
                'ivaImporte': double.parse(ivaImp.toStringAsFixed(2)),
                'total': double.parse(total.toStringAsFixed(2)),
                'estado': 'emitida',
                'metodoPago': 'transferencia',
                'fechaVencimiento': DateTime.now()
                  .add(const Duration(days: 15))
                  .toIso8601String(),
              });
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
          child: const Text('Emitir factura'),
        ),
      ],
      children: [
        StatefulBuilder(
          builder: (context, setStateAction) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FutureBuilder<List<Cliente>>(
                future: cargarClientes(),
                builder: (ctx, snap) {
                  final clientes = snap.data ?? [];
                  return DropdownButtonFormField<String>(
                    initialValue: clienteSeleccionado.isEmpty ? null : clienteSeleccionado,
                    decoration: const InputDecoration(labelText: 'Cliente*'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Seleccionar cliente...')),
                      ...clientes.map((c) => DropdownMenuItem(value: c.fullName, child: Text(c.fullName))),
                    ],
                    onChanged: (v) => setStateAction(() {
                      clienteSeleccionado = v ?? '';
                      nifCtrl.text = ''; // O buscar NIF del cliente si existiera
                    }),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nifCtrl,
                decoration: const InputDecoration(labelText: 'NIF Cliente'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: baseCtrl,
                decoration: const InputDecoration(labelText: 'Base Imponible'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<double>(
                initialValue: 21,
                decoration: const InputDecoration(labelText: 'IVA %'),
                items: const [
                  DropdownMenuItem(value: 21.0, child: Text('21%')),
                  DropdownMenuItem(value: 10.0, child: Text('10%')),
                  DropdownMenuItem(value: 4.0, child: Text('4%')),
                ],
                onChanged: (v) => setStateAction(() => ivaPct = v ?? 21),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget que muestra un pequeño "chip" indicando el estado de la factura.
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(KronoRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
