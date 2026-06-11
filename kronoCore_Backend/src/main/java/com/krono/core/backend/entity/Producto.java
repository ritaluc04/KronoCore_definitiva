package com.krono.core.backend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * ENTIDAD: Producto
 * Representa un artículo en el inventario del negocio.
 * 
 * Cada producto tiene:
 * - sku: Código único del producto (ej: SH-001)
 * - nombre: Nombre descriptivo
 * - categoria: Tipo de producto (Cuidado, Color, Herramientas, etc.)
 * - precio: Precio de venta unitario
 * - stock: Cantidad actual en inventario
 * - stockMin: Cantidad mínima antes de generar alerta
 * - activo: Si el producto está disponible para la venta
 * - empresaId: Empresa propietaria (multi-tenant)
 * 
 * El stock se descuenta automáticamente al realizar ventas.
 */
@Entity
@Table(name = "productos")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Producto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String sku;
    private String nombre;
    private String categoria;
    private Double precio;
    private Integer stock;
    private Integer stockMin;
    private boolean activo = true;

    private Long empresaId;
}