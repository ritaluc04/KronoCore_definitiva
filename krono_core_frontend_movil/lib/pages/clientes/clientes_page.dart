import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../global/utils/kons.dart';
import '../../global/widgets/krono_widgets.dart';
import '../../global/widgets/page_states_view.dart';
import '../../global/models/models.dart';
import 'clientes_controller.dart';

/// Pantalla principal para la gestión de clientes del negocio.
/// Permite visualizar, buscar y abrir el formulario de creación de nuevos clientes.
class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});
  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

/// Estado de [ClientesScreen]: lista, búsqueda y diálogo de alta.
class _ClientesScreenState extends State<ClientesScreen> {
  late final ClientesController _controller;

  @override
  void initState() {
    super.initState();
    /// Inicialización del controlador y carga inicial de datos.
    _controller = ClientesController();
    _controller.cargarClientes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Construye cabecera, búsqueda y tabla o estados vacío/carga.
  @override
  Widget build(BuildContext context) {
    /// Reacciona a cambios en el controlador para redibujar la UI.
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final all = _controller.clientes;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(KronoSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Cabecera de la sección con botón de acción.
              Row(
                children: [
                  Text(
                    'Clientes',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _newClient(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo cliente'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              /// Barra de herramientas: Búsqueda y filtros.
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar por nombre o email',
                      ),
                      onChanged: _controller.search,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filtros'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              /// Manejo de estados de la lista: Carga, Vacío o Listado.
              if (_controller.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (all.isEmpty)
                const EmptyView(
                  icon: Icons.people_outline,
                  title: 'Sin resultados',
                  message: 'Prueba con otro término o crea un nuevo cliente.',
                )
              else
                KronoCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      const _ClientesHeaderRow(),
                      const Divider(height: 1),
                      for (var i = 0; i < all.length; i++) ...[
                        _ClienteRow(c: all[i]),
                        if (i < all.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Abre el panel lateral para crear un cliente nuevo.
  void _newClient(BuildContext c) {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();

    showKronoSideSheet(
      c,
      title: 'Nuevo cliente',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (nombreCtrl.text.isEmpty) return;
            final names = nombreCtrl.text.trim().split(' ');
            final nombre = names.isNotEmpty ? names[0] : '';
            final apellidos = names.length > 1 ? names.sublist(1).join(' ') : '';
            final nuevo = Cliente(
              id: '',
              nombre: nombre,
              apellidos: apellidos,
              email: emailCtrl.text,
              telefono: telCtrl.text,
              ultimaCita: DateTime.now(),
              etiquetas: [],
            );
            await _controller.crearCliente(nuevo);
            if (c.mounted) {
              Navigator.pop(c);
              ScaffoldMessenger.of(c).showSnackBar(
                const SnackBar(content: Text('Cliente creado')),
              );
            }
          },
          child: const Text('Crear'),
        ),
      ],
      children: [
        TextField(
          controller: nombreCtrl,
          decoration: const InputDecoration(labelText: 'Nombre y Apellidos*'),
          autofocus: true,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailCtrl,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: telCtrl,
          decoration: const InputDecoration(labelText: 'Teléfono*'),
        ),
      ],
    );
  }
}

/// Fila de encabezados de columnas en la tabla de clientes.
class _ClientesHeaderRow extends StatelessWidget {
  const _ClientesHeaderRow();
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 12,
      color: KronoColors.muted,
      fontWeight: FontWeight.w600,
    );
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 44),
          Expanded(flex: 3, child: Text('NOMBRE', style: style)),
          Expanded(flex: 3, child: Text('EMAIL', style: style)),
          Expanded(flex: 2, child: Text('TELÉFONO', style: style)),
          Expanded(flex: 2, child: Text('ÚLTIMA CITA', style: style)),
          SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// Fila clickable de un cliente; navega al detalle al pulsar.
class _ClienteRow extends StatelessWidget {
  final Cliente c;
  const _ClienteRow({required this.c});
  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd MMM');
    return InkWell(
      onTap: () => context.go('/clientes/${c.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AvatarCircle(name: c.fullName, size: 32),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (c.etiquetas.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Wrap(
                        spacing: 4,
                        children: c.etiquetas
                            .map(
                              (e) => StatusChip(
                            label: e,
                            color: KronoColors.accent,
                          ),
                        )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                c.email,
                style: const TextStyle(color: KronoColors.muted, fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(c.telefono, style: const TextStyle(fontSize: 13)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                f.format(c.ultimaCita),
                style: const TextStyle(fontSize: 13, color: KronoColors.muted),
              ),
            ),
            const Icon(Icons.chevron_right, color: KronoColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}


/// Pantalla de detalle de un cliente: ficha, pestañas y acciones editar/eliminar.
class ClienteDetalleScreen extends StatelessWidget {
  final String id;
  const ClienteDetalleScreen({super.key, required this.id});

  /// Carga el cliente por [id] y muestra cabecera con pestañas de información.
  @override
  Widget build(BuildContext context) {
    final controller = ClientesController();
    return FutureBuilder<List<Cliente>>(
      future: controller.cargarClientes().then((_) => controller.clientes),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final c = snapshot.data!.firstWhere(
              (x) => x.id == id,
          orElse: () => snapshot.data!.first,
        );

        return DefaultTabController(
          length: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KronoSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KronoCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          AvatarCircle(name: c.fullName, size: 64),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.fullName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${c.email}  ·  ${c.telefono}',
                                  style: const TextStyle(
                                    color: KronoColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  children: c.etiquetas
                                      .map(
                                        (e) => StatusChip(
                                      label: e,
                                      color: KronoColors.accent,
                                    ),
                                  )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              final nombreCtrl = TextEditingController(text: '${c.nombre} ${c.apellidos}'.trim());
                              final emailCtrl = TextEditingController(text: c.email);
                              final telCtrl = TextEditingController(text: c.telefono);

                              showKronoSideSheet(
                                context,
                                title: 'Editar cliente',
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (nombreCtrl.text.isEmpty) return;
                                      final names = nombreCtrl.text.trim().split(' ');
                                      final nombre = names.isNotEmpty ? names[0] : '';
                                      final apellidos = names.length > 1 ? names.sublist(1).join(' ') : '';
                                      
                                      final editado = Cliente(
                                        id: c.id,
                                        nombre: nombre,
                                        apellidos: apellidos,
                                        email: emailCtrl.text,
                                        telefono: telCtrl.text,
                                        ultimaCita: c.ultimaCita,
                                        etiquetas: c.etiquetas,
                                      );
                                      
                                      await controller.actualizarCliente(editado);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Cliente actualizado')),
                                        );
                                      }
                                    },
                                    child: const Text('Guardar cambios'),
                                  ),
                                ],
                                children: [
                                  TextField(
                                    controller: nombreCtrl,
                                    decoration: const InputDecoration(labelText: 'Nombre y Apellidos*'),
                                    autofocus: true,
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: emailCtrl,
                                    decoration: const InputDecoration(labelText: 'Email'),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: telCtrl,
                                    decoration: const InputDecoration(labelText: 'Teléfono*'),
                                  ),
                                ],
                              ).then(
                                    (_) => controller.cargarClientes().then((_) {
                                  if (context.mounted) {
                                    /// Forzar rebuild para ver cambios
                                    (context as Element).markNeedsBuild();
                                  }
                                }),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => KronoDialog(
                                  title: 'Eliminar cliente',
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Eliminar',
                                        style: TextStyle(color: KronoColors.danger),
                                      ),
                                    ),
                                  ],
                                  children: const [
                                    Text('¿Estás seguro de que deseas eliminar este cliente?'),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ClientesController().eliminarCliente(c.id);
                                if (context.mounted) context.go('/clientes');
                              }
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: KronoColors.danger,
                            ),
                            label: const Text(
                              'Eliminar',
                              style: TextStyle(color: KronoColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(KronoRadius.lg),
                    border: Border.all(color: KronoColors.border),
                  ),
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: KronoColors.primary,
                        unselectedLabelColor: KronoColors.muted,
                        indicatorColor: KronoColors.primary,
                        tabs: [
                          Tab(text: 'Datos'),
                          Tab(text: 'Historial'),
                          Tab(text: 'Compras'),
                          Tab(text: 'Notas'),
                        ],
                      ),
                      SizedBox(
                        height: 320,
                        child: TabBarView(
                          children: [
                            _kv('Email', c.email),
                            const Center(
                              child: Text(
                                'Sin historial reciente.',
                                style: TextStyle(color: KronoColors.muted),
                              ),
                            ),
                            const Center(
                              child: Text(
                                'Sin compras registradas.',
                                style: TextStyle(color: KronoColors.muted),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: TextField(
                                maxLines: 8,
                                decoration: InputDecoration(
                                  hintText:
                                  'Notas internas sobre el cliente...',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Widget auxiliar clave-valor para la pestaña de datos.
  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          k.toUpperCase(),
          style: const TextStyle(
            color: KronoColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(v, style: const TextStyle(fontSize: 15)),
      ],
    ),
  );
}
