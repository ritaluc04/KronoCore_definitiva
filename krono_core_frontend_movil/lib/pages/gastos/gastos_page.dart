import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/api_client.dart';
import '../../global/utils/kons.dart';
import '../../global/widgets/krono_widgets.dart';
import '../../global/widgets/page_states_view.dart';
import '../../global/models/models.dart';
import 'gastos_controller.dart';

/// Pantalla principal de gastos del negocio.
/// Muestra un resumen del total de gastos y deducibles,
/// junto a una tabla detallada con los gastos y opción de crear nuevos.
class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});
  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  late final GastosController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GastosController();
    _controller.cargarGastos();
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
                    'Gastos',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _showGastoDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo gasto'),
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
                    'Total gastos',
                    '${_controller.totalGastos.toStringAsFixed(2)} €',
                    KronoColors.danger,
                  ),
                  _buildMetric(
                    'Deducible',
                    '${_controller.totalDeducible.toStringAsFixed(2)} €',
                    KronoColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// Tabla de gastos
              Expanded(
                child: _controller.cargando
                    ? const LoadingView()
                    : _controller.gastos.isEmpty
                    ? EmptyView(
                        icon: Icons.receipt_long_outlined,
                        title: 'Sin gastos',
                        message: 'No hay gastos registrados todavía.',
                        actionLabel: 'Nuevo gasto',
                        onAction: () => _showGastoDialog(context),
                      )
                    : _buildGastosTable(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Widget auxiliar para renderizar tarjetas de métricas.
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

  /// Construye y devuelve la tabla que lista todos los gastos.
  Widget _buildGastosTable() {
    return SingleChildScrollView(
      child: KronoCard(
        padding: EdgeInsets.zero,
        child: DataTable(
          columnSpacing: 20,
          columns: const [
            DataColumn(
              label: Text(
                'Categoría',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Descripción',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Proveedor',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Importe',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Fecha',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
          rows: _controller.gastos.map((g) {
            final deducibleBadge = g.deducible
                ? Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: KronoColors.success.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Deducible',
                      style: TextStyle(fontSize: 9, color: KronoColors.success),
                    ),
                  )
                : const SizedBox.shrink();

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 16,
                        color: KronoColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(_controller.getCategoriaLabel(g.categoria)),
                    ],
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text(g.descripcion), deducibleBadge],
                  ),
                ),
                DataCell(Text(g.proveedor ?? '-')),
                DataCell(Text('${g.total.toStringAsFixed(2)} €')),
                DataCell(
                  Text('${g.fecha.day}/${g.fecha.month}/${g.fecha.year}'),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Muestra un diálogo lateral (side sheet) para registrar un nuevo gasto.
  void _showGastoDialog(BuildContext context) {
    final descCtrl = TextEditingController();
    final provCtrl = TextEditingController();
    final importeCtrl = TextEditingController();
    String categoria = 'proveedores';
    double ivaPct = 21.0;
    bool deducible = true;

    /// Función auxiliar para cargar proveedores desde los gastos existentes.
    Future<List<String>> cargarProveedores() async {
      try {
        final response = await ApiClient.get('/gastos');
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          final gastos = data.map((j) => GastoModel.fromMap(j)).toList();
          final proveedores = gastos
              .map((g) => g.proveedor)
              .where((p) => p != null && p.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList();
          proveedores.sort();
          return proveedores;
        }
        return [];
      } catch (e) {
        return [];
      }
    }

    showKronoSideSheet(
      context,
      title: 'Nuevo Gasto',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final importe = double.tryParse(importeCtrl.text) ?? 0;
            if (descCtrl.text.isEmpty || importe <= 0) return;
            final ivaImp = importe * (ivaPct / 100);
            final total = importe + ivaImp;
            try {
              await _controller.crearGasto({
                'categoria': categoria,
                'descripcion': descCtrl.text,
                'proveedor': provCtrl.text,
                'importe': importe,
                'ivaPorcentaje': ivaPct,
                'ivaImporte': double.parse(ivaImp.toStringAsFixed(2)),
                'total': double.parse(total.toStringAsFixed(2)),
                'metodoPago': 'transferencia',
                'deducible': deducible,
                'fecha': DateTime.now().toIso8601String(),
              });
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
          child: const Text('Guardar'),
        ),
      ],
      children: [
        StatefulBuilder(
          builder: (context, setDialogState) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej. Compra de material',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: const [
                  DropdownMenuItem(value: 'alquiler', child: Text('Alquiler')),
                  DropdownMenuItem(
                    value: 'suministros',
                    child: Text('Suministros'),
                  ),
                  DropdownMenuItem(
                    value: 'proveedores',
                    child: Text('Proveedores'),
                  ),
                  DropdownMenuItem(value: 'marketing', child: Text('Marketing')),
                  DropdownMenuItem(value: 'otros', child: Text('Otros')),
                ],
                onChanged: (v) => setDialogState(() => categoria = v ?? 'otros'),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<String>>(
                future: cargarProveedores(),
                builder: (ctx, snap) {
                  final proveedores = snap.data ?? [];
                  return proveedores.isEmpty
                      ? TextField(
                          controller: provCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Proveedor'),
                        )
                      : DropdownButtonFormField<String>(
                          initialValue: provCtrl.text.isEmpty ? null : provCtrl.text,
                          decoration:
                              const InputDecoration(labelText: 'Proveedor'),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Escribir otro...'),
                            ),
                            ...proveedores.map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => provCtrl.text = v);
                            }
                          },
                        );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: importeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Importe Base',
                  suffixText: '€',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<double>(
                initialValue: ivaPct,
                decoration: const InputDecoration(labelText: 'IVA %'),
                items: const [
                  DropdownMenuItem(value: 21.0, child: Text('21%')),
                  DropdownMenuItem(value: 10.0, child: Text('10%')),
                  DropdownMenuItem(value: 4.0, child: Text('4%')),
                  DropdownMenuItem(value: 0.0, child: Text('Exento')),
                ],
                onChanged: (v) => setDialogState(() => ivaPct = v ?? 21.0),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Deducible fiscalmente'),
                subtitle: const Text('Indica si el gasto es desgravable'),
                value: deducible,
                onChanged: (v) => setDialogState(() => deducible = v ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
