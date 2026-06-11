/// =============================================================================
/// models.dart — Modelos de dominio y DTOs compartidos en toda la app Flutter.
///
/// Define todos los enums y clases que representan los datos del negocio.
/// Cada modelo tiene métodos fromMap() (JSON → Dart) y toMap() (Dart → JSON)
/// para serializar/deserializar las respuestas de la API REST.
/// =============================================================================

/// ENUM: Roles de usuario para control de acceso (RBAC)
enum UserRole { admin, jefe, empleado, cliente }

extension UserRoleX on UserRole {
  String get label => switch (this) {
    UserRole.admin => 'Administrador',
    UserRole.jefe => 'Jefe',
    UserRole.empleado => 'Empleado',
    UserRole.cliente => 'Cliente',
  };
}

/// Modelo fundamental que representa a un usuario autenticado dentro del sistema.
/// Encapsula la información personal (ID, nombre, correo), su nivel de permisos (`UserRole`),
/// y opcionalmente los datos de la empresa a la que pertenece, junto con la ruta a su avatar.
class Usuario {
  final String id, nombre, email;
  final UserRole rol;
  final String? empresaNombre, avatar;
  final int? empresaId;
  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.empresaNombre,
    this.empresaId,
    this.avatar,
  });
  factory Usuario.fromMap(Map<String, dynamic> map) => Usuario(
    id: map['id']?.toString() ?? '',
    nombre: map['nombre'] ?? '',
    email: map['email'] ?? '',
    rol: UserRole.values.firstWhere(
      (e) => e.name == map['rol'],
      orElse: () => UserRole.cliente,
    ),
    empresaNombre: map['empresaNombre'],
    empresaId: map['empresaId'] != null
        ? int.tryParse(map['empresaId'].toString())
        : null,
    avatar: map['avatar'],
  );
  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'email': email,
    'rol': rol.name,
    'empresaNombre': empresaNombre,
    'empresaId': empresaId,
    'avatar': avatar,
  };
}

/// Representa una entidad empresarial dentro de la arquitectura multi-tenant de la aplicación.
/// Mantiene la información básica de la compañía, como su identificador único, nombre comercial
/// y un teléfono de contacto opcional.
class Empresa {
  final String id, nombre;
  final String? telefono;
  Empresa({required this.id, required this.nombre, this.telefono});
  factory Empresa.fromMap(Map<String, dynamic> map) => Empresa(
    id: map['id']?.toString() ?? '',
    nombre: map['nombre'] ?? '',
    telefono: map['telefono'],
  );
}

/// Estructura de datos que define a un Cliente dentro del módulo CRM.
/// Permite almacenar información de contacto detallada, clasificar al cliente mediante 
/// una lista de etiquetas personalizadas y registrar la fecha de su última cita para métricas.
class Cliente {
  final String id, nombre, apellidos, email, telefono;
  final List<String> etiquetas;
  final DateTime ultimaCita;
  Cliente({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.telefono,
    required this.etiquetas,
    required this.ultimaCita,
  });
  String get fullName => '$nombre $apellidos';
  factory Cliente.fromMap(Map<String, dynamic> map) => Cliente(
    id: map['id']?.toString() ?? '',
    nombre: map['nombre'] ?? '',
    apellidos: map['apellidos'] ?? '',
    email: map['email'] ?? '',
    telefono: map['telefono'] ?? '',
    etiquetas: List<String>.from(map['etiquetas'] ?? []),
    ultimaCita: map['ultimaCita'] != null
        ? DateTime.parse(map['ultimaCita'])
        : DateTime.now(),
  );
  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'apellidos': apellidos,
    'email': email,
    'telefono': telefono,
    'etiquetas': etiquetas,
    'ultimaCita': ultimaCita.toIso8601String(),
  };
}

enum CitaEstado { confirmada, pendiente, cancelada, noShow }

/// Entidad que representa una reserva o cita registrada en la agenda del sistema.
/// Almacena las referencias cruzadas entre el cliente, el empleado asignado y el servicio,
/// gestionando además la fecha de inicio, la duración estimada y el estado actual de la cita.
class Cita {
  final String id, clienteId, clienteNombre, servicio, empleado;
  final String? empresaNombre;
  final DateTime inicio;
  final Duration duracion;
  final CitaEstado estado;
  Cita({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.servicio,
    required this.empleado,
    this.empresaNombre,
    required this.inicio,
    required this.duracion,
    required this.estado,
  });
  DateTime get fin => inicio.add(duracion);
  factory Cita.fromMap(Map<String, dynamic> map) => Cita(
    id: map['id']?.toString() ?? '',
    clienteId: map['clienteId']?.toString() ?? '',
    clienteNombre: map['clienteNombre'] ?? '',
    servicio: map['servicio'] ?? '',
    empleado: map['empleado'] ?? '',
    empresaNombre: map['empresaNombre'],
    inicio: DateTime.parse(map['inicio']),
    duracion: Duration(minutes: map['duracionMinutos'] ?? 30),
    estado: CitaEstado.values.firstWhere(
      (e) => e.name == map['estado'],
      orElse: () => CitaEstado.pendiente,
    ),
  );
  Map<String, dynamic> toMap() => {
    'id': id,
    'clienteId': clienteId,
    'servicio': servicio,
    'empleado': empleado,
    'empresaNombre': empresaNombre,
    'inicio': inicio.toIso8601String(),
    'duracionMinutos': duracion.inMinutes,
    'estado': estado.name,
  };
}

/// Representa un artículo gestionable dentro del módulo de inventario.
/// Centraliza la información del producto incluyendo su identificador SKU, categoría,
/// precio de venta y variables críticas para alertas como el stock actual y el nivel de stock mínimo.
class Producto {
  final String id, sku, nombre, categoria;
  final double precio;
  final int stock, stockMin;
  Producto({
    required this.id,
    required this.sku,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    required this.stockMin,
  });
  factory Producto.fromMap(Map<String, dynamic> map) => Producto(
    id: map['id']?.toString() ?? '',
    sku: map['sku'] ?? '',
    nombre: map['nombre'] ?? '',
    categoria: map['categoria'] ?? '',
    precio: (map['precio'] as num?)?.toDouble() ?? 0.0,
    stock: map['stock'] ?? 0,
    stockMin: map['stockMin'] ?? 0,
  );
  Map<String, dynamic> toMap() => {
    'id': id,
    'sku': sku,
    'nombre': nombre,
    'categoria': categoria,
    'precio': precio,
    'stock': stock,
    'stockMin': stockMin,
  };
}

enum TareaPrioridad { baja, media, alta }

enum TareaEstado { pendiente, enProceso, finalizado }

/// Elemento de trabajo dentro del flujo del tablero Kanban.
/// Define las propiedades visuales y organizativas de una tarea, tales como su asignación, 
/// colores de tarjeta, prioridad operativa, estado en el flujo y posible fecha límite.
class Tarea {
  String id, titulo, descripcion, asignado;
  String? imagenUrl, color;
  TareaPrioridad prioridad;
  TareaEstado estado;
  DateTime? fechaLimite;
  Tarea({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.asignado,
    this.imagenUrl,
    this.color,
    required this.prioridad,
    required this.estado,
    this.fechaLimite,
  });
  factory Tarea.fromMap(Map<String, dynamic> map) => Tarea(
    id: map['id']?.toString() ?? '',
    titulo: map['titulo'] ?? '',
    descripcion: map['descripcion'] ?? '',
    asignado: map['asignado'] ?? '',
    imagenUrl: map['imagenUrl'],
    color: map['color'],
    prioridad: TareaPrioridad.values.firstWhere(
      (e) => e.name == map['prioridad'],
      orElse: () => TareaPrioridad.media,
    ),
    estado: TareaEstado.values.firstWhere(
      (e) => e.name == map['estado'],
      orElse: () => TareaEstado.pendiente,
    ),
    fechaLimite: map['fechaLimite'] != null
        ? DateTime.parse(map['fechaLimite'])
        : null,
  );
  Map<String, dynamic> toMap() => {
    'id': id,
    'titulo': titulo,
    'descripcion': descripcion,
    'asignado': asignado,
    'imagenUrl': imagenUrl,
    'color': color,
    'prioridad': prioridad.name,
    'estado': estado.name,
    'fechaLimite': fechaLimite?.toIso8601String(),
  };
}

/// Representa un renglón o ítem individual dentro de un carrito de compras.
/// Agrupa una instancia de `Producto` con su cantidad seleccionada, facilitando
/// el cálculo dinámico del subtotal para el Punto de Venta (TPV).
class CarritoLinea {
  final Producto producto;
  int cantidad;
  CarritoLinea({required this.producto, this.cantidad = 1});
  double get subtotal => producto.precio * cantidad;
}

/// Registro histórico de una transacción de venta completada en el sistema.
/// Almacena el identificador de la operación, el cliente asociado y el monto total cobrado.
class Venta {
  final String id, clienteNombre;
  final DateTime fecha;
  final double total;
  Venta({
    required this.id,
    required this.clienteNombre,
    required this.fecha,
    required this.total,
  });
  factory Venta.fromMap(Map<String, dynamic> map) => Venta(
    id: map['id']?.toString() ?? '',
    clienteNombre: map['clienteNombre']?.toString() ?? 'Mostrador',
    fecha: map['fecha'] != null
        ? DateTime.parse(map['fecha'].toString())
        : DateTime.now(),
    total: double.tryParse(map['total']?.toString() ?? '') ?? 0.0,
  );
}

class ActividadItem {
  final String texto, icono;
  final DateTime cuando;
  ActividadItem({
    required this.texto,
    required this.cuando,
    required this.icono,
  });
}

/// Documento fiscal emitido a nombre de un cliente.
/// Estructura todos los valores económicos correspondientes a una facturación, incluyendo 
/// base imponible, porcentaje de IVA, total calculado, así como el estado de pago de la misma.
class FacturaModel {
  final String id, numeroFactura, estado;
  final String? clienteNombre, clienteNif, metodoPago;
  final double baseImponible, ivaPorcentaje, total;
  final DateTime fechaEmision;
  FacturaModel({
    required this.id,
    required this.numeroFactura,
    this.clienteNombre,
    this.clienteNif,
    required this.baseImponible,
    required this.ivaPorcentaje,
    required this.total,
    required this.estado,
    this.metodoPago,
    required this.fechaEmision,
  });
  factory FacturaModel.fromMap(Map<String, dynamic> map) => FacturaModel(
    id: map['id']?.toString() ?? '',
    numeroFactura: map['numeroFactura'] ?? '',
    clienteNombre: map['clienteNombre'],
    clienteNif: map['clienteNif'],
    baseImponible: (map['baseImponible'] as num?)?.toDouble() ?? 0.0,
    ivaPorcentaje: (map['ivaPorcentaje'] as num?)?.toDouble() ?? 21.0,
    total: (map['total'] as num?)?.toDouble() ?? 0.0,
    estado: map['estado'] ?? 'emitida',
    metodoPago: map['metodoPago'],
    fechaEmision: map['fechaEmision'] != null
        ? DateTime.parse(map['fechaEmision'])
        : DateTime.now(),
  );
}

/// Modelo para registrar salidas de dinero o gastos operativos del negocio.
/// Permite clasificar el gasto, detallar el proveedor involucrado, especificar
/// el monto total y definir si el gasto aplica para deducciones fiscales.
class GastoModel {
  final String id, categoria, descripcion;
  final String? proveedor;
  final double importe, total;
  final bool deducible;
  final DateTime fecha;
  GastoModel({
    required this.id,
    required this.categoria,
    required this.descripcion,
    this.proveedor,
    required this.importe,
    required this.total,
    required this.deducible,
    required this.fecha,
  });
  factory GastoModel.fromMap(Map<String, dynamic> map) => GastoModel(
    id: map['id']?.toString() ?? '',
    categoria: map['categoria'] ?? 'otros',
    descripcion: map['descripcion'] ?? '',
    proveedor: map['proveedor'],
    importe: (map['importe'] as num?)?.toDouble() ?? 0.0,
    total: (map['total'] as num?)?.toDouble() ?? 0.0,
    deducible: map['deducible'] ?? true,
    fecha: map['fecha'] != null ? DateTime.parse(map['fecha']) : DateTime.now(),
  );
}

/// Entidad empleada para el sistema de alertas y notificaciones globales.
/// Gestiona mensajes temporales dirigidos al usuario (ej. stock bajo, nuevas citas),
/// llevando un control sobre si el mensaje ya fue marcado como leído.
class Notificacion {
  final String id, titulo, mensaje;
  final DateTime fecha;
  final bool leida;
  Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    this.leida = false,
  });
  static List<Notificacion> get dummyData => [
    Notificacion(
      id: '1',
      titulo: 'Stock bajo',
      mensaje: 'El producto "Tinte Rojo" está por debajo del stock mínimo.',
      fecha: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Notificacion(
      id: '2',
      titulo: 'Nueva cita',
      mensaje: 'Juan ha reservado un Corte de Cabello para mañana.',
      fecha: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Notificacion(
      id: '3',
      titulo: 'Meta alcanzada',
      mensaje: '¡Has superado el objetivo de ventas de la semana!',
      fecha: DateTime.now().subtract(const Duration(days: 1)),
      leida: true,
    ),
  ];
}
