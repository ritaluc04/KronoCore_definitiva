package com.krono.core.backend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

/**
 * ENTIDAD: Gasto
 * Representa un gasto registrado del negocio para control financiero.
 * 
 * Categorías disponibles: alquiler, suministros, proveedores, marketing, otros.
 * Cada gasto puede marcarse como deducible fiscalmente.
 * 
 * Incluye datos del proveedor, números de factura (del proveedor),
 * importes con IVA, método de pago y fechas.
 */
@Entity
@Table(name = "gastos")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Gasto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long empresaId;
    private String categoria;
    private String descripcion;
    private String proveedor;
    private String numeroFactura;

    private Double importe;
    private Double ivaPorcentaje;
    private Double ivaImporte;
    private Double total;

    private String metodoPago;
    private boolean deducible;

    private LocalDateTime fecha;
    private LocalDateTime fechaCreacion;
}