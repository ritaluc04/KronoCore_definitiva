package com.krono.core.backend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

/**
 * ENTIDAD: Venta
 * Representa una transacción comercial completada en el TPV.
 * 
 * Cada venta tiene: cliente asociado, empresa, fecha,
 * subtotal (base imponible), IVA (21%), total, y una lista
 * de detalles con los productos vendidos.
 * 
 * Al crear una venta, el stock de cada producto se descuenta
 * automáticamente desde VentaService.
 */
@Entity
@Table(name = "ventas")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Venta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long clienteId;
    private String clienteNombre;
    private Long empresaId;
    private LocalDateTime fecha;
    private Double subtotal;
    private Double iva;
    private Double total;

    @OneToMany(cascade = CascadeType.ALL)
    @JoinColumn(name = "venta_id")
    private List<VentaDetalle> detalles;
}