import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../global/utils/kons.dart';
import '../../global/widgets/krono_widgets.dart';
import '../../global/models/models.dart';
import 'board_controller.dart';

/// Pantalla principal del tablero (Board) de tareas.
/// Permite visualizar las tareas en columnas por estado, moverlas (drag & drop),
/// filtrarlas y crear nuevas columnas o tareas.
class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late final BoardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BoardController();
    _controller.cargarTareas();
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
              Row(
                children: [
                  Text(
                    'Board',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _showAddColumnDialog(context),
                    icon: const Icon(Icons.view_column_outlined),
                    label: const Text('Nueva Columna'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _controller.filtrar,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filtros'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _controller.cargando
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width - 80,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (
                                int i = 0;
                                i < _controller.columnas.length;
                                i++
                              ) ...[
                                SizedBox(
                                  width: 320,
                                  child: _Column(
                                    label: _controller.columnas[i].label,
                                    color: _controller.columnas[i].color,
                                    tareas: _controller.getTareasPorEstado(
                                      _controller.columnas[i].estado,
                                    ),
                                    onAccept: (t) => _controller.moverTarea(
                                      t,
                                      _controller.columnas[i].estado,
                                    ),
                                    prioColor: _controller.getPrioridadColor,
                                    onAdd: () => _showTaskDialog(
                                      context,
                                      estado: _controller.columnas[i].estado,
                                    ),
                                    onEditTask: (t) =>
                                        _showTaskDialog(context, tarea: t),
                                    onDeleteColumn: () =>
                                        _controller.eliminarColumna(i),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Muestra un diálogo lateral (side sheet) para crear o editar una tarea.
  void _showTaskDialog(
    BuildContext context, {
    Tarea? tarea,
    TareaEstado? estado,
  }) {
    final tituloCtrl = TextEditingController(text: tarea?.titulo);
    final descCtrl = TextEditingController(text: tarea?.descripcion);
    final imgUrlCtrl = TextEditingController(text: tarea?.imagenUrl ?? '');
    final colorCtrl = TextEditingController(text: tarea?.color ?? '');
    final asignadoCtrl = TextEditingController(text: tarea?.asignado);
    final fechaCtrl = TextEditingController(
      text: tarea?.fechaLimite == null
          ? ''
          : DateFormat('dd/MM/yyyy').format(tarea!.fechaLimite!),
    );
    TareaPrioridad prio = tarea?.prioridad ?? TareaPrioridad.media;
    TareaEstado est = tarea?.estado ?? estado ?? TareaEstado.pendiente;
    DateTime? fecha = tarea?.fechaLimite;

    showKronoSideSheet(
      context,
      title: tarea == null ? 'Nueva Tarea' : 'Editar Tarea',
      actions: [
        if (tarea != null)
          TextButton(
            onPressed: () {
              _controller.eliminarTarea(tarea.id);
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: KronoColors.danger),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (tituloCtrl.text.isNotEmpty) {
              final nuevaTarea = Tarea(
                id:
                    tarea?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                titulo: tituloCtrl.text,
                descripcion: descCtrl.text,
                asignado: asignadoCtrl.text,
                imagenUrl: imgUrlCtrl.text.trim().isEmpty
                    ? null
                    : imgUrlCtrl.text.trim(),
                color: colorCtrl.text.trim().isEmpty
                    ? null
                    : colorCtrl.text.trim(),
                prioridad: prio,
                estado: est,
                fechaLimite: fecha,
              );
              if (tarea == null) {
                _controller.agregarTarea(nuevaTarea);
              } else {
                _controller.editarTarea(nuevaTarea);
              }
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
          child: const Text('Guardar'),
        ),
      ],
      children: [
        TextField(
          controller: tituloCtrl,
          decoration: const InputDecoration(labelText: 'Título'),
          autofocus: true,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descCtrl,
          decoration: const InputDecoration(labelText: 'Descripción'),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: imgUrlCtrl,
          decoration: const InputDecoration(labelText: 'Imagen URL'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: colorCtrl,
          decoration: const InputDecoration(labelText: 'Color (hex)'),
        ),
        const SizedBox(height: 12),
        StatefulBuilder(
          builder: (ctx, setLocalState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue:
                      (_controller.usuariosEmpresa.any(
                        (u) => u.nombre == asignadoCtrl.text,
                      ))
                      ? asignadoCtrl.text
                      : null,
                  decoration: const InputDecoration(labelText: 'Asignado a'),
                  items: _controller.usuariosEmpresa
                      .map((u) => u.nombre)
                      .toSet() // Evita duplicados que causan el error de Dropdown
                      .map(
                        (nombre) => DropdownMenuItem(
                          value: nombre,
                          child: Text(nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setLocalState(() => asignadoCtrl.text = v);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TareaPrioridad>(
                  initialValue: prio,
                  decoration: const InputDecoration(labelText: 'Prioridad'),
                  items: TareaPrioridad.values
                      .map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (v) => setLocalState(() => prio = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TareaEstado>(
                  initialValue: est,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: TareaEstado.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: (v) => setLocalState(() => est = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: fechaCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Fecha Límite',
                    hintText: 'Seleccionar fecha',
                    prefixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                    ),
                    suffixIcon: fecha != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setLocalState(() {
                              fecha = null;
                              fechaCtrl.clear();
                            }),
                          )
                        : null,
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate:
                          (fecha != null && fecha!.isAfter(DateTime(1900)))
                          ? fecha!
                          : DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setLocalState(() {
                        fecha = picked;
                        fechaCtrl.text = DateFormat(
                          'dd/MM/yyyy',
                        ).format(picked);
                      });
                    }
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Muestra un diálogo lateral (side sheet) para añadir una nueva columna.
  void _showAddColumnDialog(BuildContext context) {
    final controller = TextEditingController();
    showKronoSideSheet(
      context,
      title: 'Nueva Columna',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              _controller.agregarColumna(
                controller.text,
                TareaEstado.pendiente,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Crear'),
        ),
      ],
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre de la columna'),
          autofocus: true,
        ),
      ],
    );
  }
}

/// Widget que representa una columna en el tablero Kanban.
/// Recibe las tareas correspondientes a su estado y maneja el evento de drop.
class _Column extends StatelessWidget {
  final String label;
  final Color color;
  final List<Tarea> tareas;
  final void Function(Tarea) onAccept;
  final Color Function(TareaPrioridad) prioColor;
  final VoidCallback onAdd;
  final void Function(Tarea) onEditTask;
  final VoidCallback onDeleteColumn;

  const _Column({
    required this.label,
    required this.color,
    required this.tareas,
    required this.onAccept,
    required this.prioColor,
    required this.onAdd,
    required this.onEditTask,
    required this.onDeleteColumn,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Tarea>(
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (ctx, cand, rej) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cand.isNotEmpty
              ? color.withValues(alpha: .06)
              : Theme.of(context).brightness == Brightness.dark
              ? KronoColors.darkSurface2
              : KronoColors.surface2,
          borderRadius: BorderRadius.circular(KronoRadius.lg),
          border: Border.all(
            color: cand.isNotEmpty ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '· ${tareas.length}',
                  style: const TextStyle(
                    color: KronoColors.muted,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: onDeleteColumn,
                      child: const Text(
                        'Eliminar columna',
                        style: TextStyle(
                          color: KronoColors.danger,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: tareas
                    .map(
                      (t) => Draggable<Tarea>(
                        data: t,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Opacity(
                            opacity: .8,
                            child: SizedBox(
                              width: 296,
                              child: _Card(
                                t: t,
                                prioColor: prioColor,
                                onTap: () {},
                              ),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: .35,
                          child: _Card(
                            t: t,
                            prioColor: prioColor,
                            onTap: () {},
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _Card(
                            t: t,
                            prioColor: prioColor,
                            onTap: () => onEditTask(t),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget que representa una tarjeta individual de tarea dentro de una columna.
/// Muestra detalles como título, descripción, prioridad y responsable.
class _Card extends StatelessWidget {
  final Tarea t;
  final Color Function(TareaPrioridad) prioColor;
  final VoidCallback onTap;

  const _Card({required this.t, required this.prioColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = prioColor(t.prioridad);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KronoRadius.lg),
      child: KronoCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((t.imagenUrl ?? '').isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  t.imagenUrl!,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                if ((t.color ?? '').isNotEmpty)
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _parseHex(t.color!),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            if (t.descripcion.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                t.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: KronoColors.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                StatusChip(label: t.prioridad.name, color: c),
                const Spacer(),
                if (t.fechaLimite != null) ...[
                  const Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: KronoColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yy').format(t.fechaLimite!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: KronoColors.muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                AvatarCircle(name: t.asignado, size: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _parseHex(String value) {
    final cleaned = value.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return KronoColors.primary;
  }
}
