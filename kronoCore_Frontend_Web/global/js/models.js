/*
 * models.js — Constantes de dominio y tipos de datos de KronoCore.
 * 
 * Equivalente JavaScript de models.dart (Flutter).
 * Define:
 * - Roles de usuario (UserRole): admin, jefe, empleado, cliente
 * - Estados de cita (CitaEstado): confirmada, pendiente, cancelada, noShow
 * - Tareas: prioridades (TareaPrioridad) y estados (TareaEstado)
 * - Helpers: clienteFullName(), citaFin(), carritoSubtotal()
 * - Notificaciones del sistema
 */

/**
 * models.dart → JavaScript
 * Constantes y tipos del dominio del negocio.
 */

/** Roles de usuario disponibles en la aplicación */
const UserRole = {
  admin: 'admin',
  jefe: 'jefe',
  empleado: 'empleado',
  cliente: 'cliente',
};

/** Etiquetas legibles en español para cada rol */
const UserRoleLabel = {
  [UserRole.admin]: 'Administrador',
  [UserRole.jefe]: 'Jefe',
  [UserRole.empleado]: 'Empleado',
  [UserRole.cliente]: 'Cliente',
};

/** Estados posibles de una cita en la agenda */
const CitaEstado = {
  confirmada: 'confirmada',
  pendiente: 'pendiente',
  cancelada: 'cancelada',
  noShow: 'noShow',
};

/** Prioridad y estado de las tareas del tablero Kanban */
const TareaPrioridad = { baja: 'baja', media: 'media', alta: 'alta' };
const TareaEstado = { pendiente: 'pendiente', enProceso: 'enProceso', finalizado: 'finalizado' };

/** @typedef {{ id: string, nombre: string, email: string, rol: string, empresaNombre?: string, avatar?: string }} Usuario */
/** @typedef {{ id: string, nombre: string, telefono?: string }} Empresa */
/** @typedef {{ id: string, nombre: string, apellidos: string, email: string, telefono: string, etiquetas: string[], ultimaCita: Date }} Cliente */
/** @typedef {{ id: string, clienteId: string, clienteNombre: string, servicio: string, empleado: string, empresaNombre?: string, inicio: Date, duracionMin: number, estado: string }} Cita */
/** @typedef {{ id: string, sku: string, nombre: string, categoria: string, precio: number, stock: number, stockMin: number }} Producto */
/** @typedef {{ id: string, titulo: string, descripcion: string, asignado: string, prioridad: string, estado: string, fechaLimite?: Date }} Tarea */

/** Devuelve el nombre completo de un cliente (nombre + apellidos) */
function clienteFullName(c) {
  return `${c.nombre} ${c.apellidos}`;
}

/** Calcula la fecha/hora de fin de una cita a partir del inicio y la duración en minutos */
function citaFin(c) {
  return new Date(c.inicio.getTime() + c.duracionMin * 60000);
}

/** Subtotal de una línea del carrito de ventas (precio × cantidad) */
function carritoSubtotal(l) {
  return l.producto.precio * l.cantidad;
}

/** Representa una notificación del sistema (stock bajo, nueva cita, meta alcanzada) */
class Notificacion {
  static get dummyData() {
    const now = new Date();
    return [
      { id: '1', titulo: 'Stock bajo', mensaje: 'El producto "Tinte Rojo" está por debajo del stock mínimo.', fecha: new Date(now.getTime() - 5 * 60000), leida: false },
      { id: '2', titulo: 'Nueva cita', mensaje: 'Juan ha reservado un Corte de Cabello para mañana.', fecha: new Date(now.getTime() - 2 * 3600000), leida: false },
      { id: '3', titulo: 'Meta alcanzada', mensaje: '¡Has superado el objetivo de ventas de la semana!', fecha: new Date(now.getTime() - 24 * 3600000), leida: true },
    ];
  }
}