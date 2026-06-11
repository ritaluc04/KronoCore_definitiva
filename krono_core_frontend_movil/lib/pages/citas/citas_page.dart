import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../global/models/models.dart';
import '../../global/utils/kons.dart';
import '../../global/widgets/krono_widgets.dart';
import 'citas_controller.dart';

/// Pantalla de gestión de citas con vista de agenda diaria.
class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  late final CitasController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CitasController();
    _controller.cargarCitas();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE d MMMM', 'es');

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final dayCitas = _controller.dayCitas;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(KronoSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Citas',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _dialogCita(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva cita'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _controller.previousDay,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Flexible(
                    child: Text(
                      fmt.format(_controller.day),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _controller.nextDay,
                    icon: const Icon(Icons.chevron_right),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _controller.goToToday,
                    icon: const Icon(Icons.today),
                    label: const Text('Hoy'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  StatusChip(label: 'Confirmada', color: KronoColors.success),
                  StatusChip(label: 'Pendiente', color: KronoColors.warning),
                  StatusChip(label: 'Cancelada', color: KronoColors.muted),
                ],
              ),
              const SizedBox(height: 16),
              KronoCard(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  height: 600,
                  child: Row(
                    children: [
                      Column(
                        children: List.generate(15, (index) {
                          final hour = 8 + index;
                          return SizedBox(
                            height: 40,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8, top: 2),
                              child: Text(
                                '${hour.toString().padLeft(2, '0')}:00',
                                style: const TextStyle(
                                  color: KronoColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Column(
                              children: List.generate(
                                15,
                                (index) => Container(
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: KronoColors.border,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ...dayCitas.map((cita) {
                              final startH =
                                  cita.inicio.hour + cita.inicio.minute / 60.0;
                              final top = (startH - 8) * 40;
                              final rawHeight =
                                  (cita.duracion.inMinutes / 60.0) * 40;
                              final displayHeight = math.max(rawHeight, 42.0);
                              final color = _controller.getColorFor(
                                cita.estado,
                              );

                              return Positioned(
                                top: top,
                                left: 8,
                                right: 8,
                                height: displayHeight,
                                child: GestureDetector(
                                  onTap: () => _dialogCita(context, cita: cita),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: .12),
                                      border: Border(
                                        left: BorderSide(
                                          color: color,
                                          width: 4,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: ClipRect(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            cita.clienteNombre,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (displayHeight > 30)
                                            Text(
                                              '${cita.servicio} · ${cita.empleado}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: KronoColors.muted,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _dialogCita(BuildContext context, {Cita? cita}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CitaSideSheet',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => _CitaDialog(controller: _controller, cita: cita),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }
}

/// Widget para el diálogo lateral (side sheet) de creación y edición de citas.
class _CitaDialog extends StatefulWidget {
  final CitasController controller;
  final Cita? cita;

  const _CitaDialog({required this.controller, this.cita});

  @override
  State<_CitaDialog> createState() => _CitaDialogState();
}

class _CitaDialogState extends State<_CitaDialog> {
  late final TextEditingController _clienteCtrl;
  late final TextEditingController _servicioCtrl;
  late final TextEditingController _empleadoCtrl;
  late final TextEditingController _duracionCtrl;
  late CitaEstado _estado;

  @override
  void initState() {
    super.initState();
    _clienteCtrl = TextEditingController(
      text: widget.cita?.clienteNombre ?? '',
    );
    _servicioCtrl = TextEditingController(text: widget.cita?.servicio ?? '');
    _empleadoCtrl = TextEditingController(text: widget.cita?.empleado ?? '');
    _duracionCtrl = TextEditingController(
      text: widget.cita?.duracion.inMinutes.toString() ?? '30',
    );
    _estado = widget.cita?.estado ?? CitaEstado.pendiente;
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _servicioCtrl.dispose();
    _empleadoCtrl.dispose();
    _duracionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.cita != null;
    return KronoSideSheet(
      title: isEdit ? 'Editar Cita' : 'Nueva Cita',
      actions: [
        if (isEdit)
          TextButton(
            onPressed: () async {
              await widget.controller.eliminarCita(widget.cita!.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: KronoColors.danger)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final citaToSave = Cita(
              id: widget.cita?.id ?? '',
              clienteId: widget.cita?.clienteId ?? '',
              clienteNombre: _clienteCtrl.text,
              servicio: _servicioCtrl.text,
              empleado: _empleadoCtrl.text,
              inicio: widget.cita?.inicio ?? widget.controller.day.add(const Duration(hours: 9)),
              duracion: Duration(minutes: int.tryParse(_duracionCtrl.text) ?? 30),
              estado: _estado,
            );
            if (isEdit) {
              await widget.controller.actualizarCita(citaToSave);
            } else {
              await widget.controller.crearCita(citaToSave);
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(isEdit ? 'Guardar' : 'Crear'),
        ),
      ],
      children: [
        TextField(
          controller: _clienteCtrl,
          decoration: const InputDecoration(labelText: 'Cliente'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _servicioCtrl,
          decoration: const InputDecoration(labelText: 'Servicio'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _empleadoCtrl,
          decoration: const InputDecoration(labelText: 'Empleado'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _duracionCtrl,
          decoration: const InputDecoration(labelText: 'Duración (min)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<CitaEstado>(
          initialValue: _estado,
          decoration: const InputDecoration(labelText: 'Estado'),
          items: CitaEstado.values
              .map((estado) => DropdownMenuItem(value: estado, child: Text(estado.name)))
              .toList(),
          onChanged: (value) => setState(() => _estado = value!),
        ),
      ],
    );
  }
}
