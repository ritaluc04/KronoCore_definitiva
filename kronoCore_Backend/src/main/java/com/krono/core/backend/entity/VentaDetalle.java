package com.krono.core.backend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * ENTIDAD: VentaDetalle
 * Representa una línea de producto dentro de una venta.
 * 
 * Cada detalle tiene: el producto vendido (ID y nombre desnormalizado),
 * la cantidad, el precio unitario en el momento de la venta,
 * y el subtotal de la línea (cantidad × precio).
 * 
 * El nombre del producto se almacena directamente aquí (desnormalizado)
 * para mantener el histórico aunque el producto cambie de nombre después.
 */
@Entity
@Table(name = "venta_detalles")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class VentaDetalle {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private Long productoId;
    private String productoNombre;
    private Integer cantidad;
    private Double precioUnitario;
    private Double subtotal;
}