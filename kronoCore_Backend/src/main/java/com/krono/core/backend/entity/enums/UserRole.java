package com.krono.core.backend.entity.enums;

/**
 * ENUM: UserRole
 * Define los roles de usuario y sus permisos dentro del sistema.
 * 
 * - admin: Superadministrador, acceso total a todas las empresas
 * - jefe: Gerente de una empresa, acceso a inventario, facturas, gastos
 * - empleado: Trabajador, acceso a clientes, citas, ventas, tareas
 * - cliente: Usuario final, solo ve su área personal
 * 
 * Almacenado como VARCHAR en la base de datos (EnumType.STRING).
 */
public enum UserRole {
    admin, jefe, empleado, cliente
}