package com.krono.core.backend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

/**
 * ENTIDAD: Factura
 * Representa una factura emitida a un cliente con datos fiscales completos.
 * 
 * Es independiente de la venta (una venta puede generar cero, una o varias facturas).
 * Esto permite emitir facturas rectificativas o manuales sin venta asociada.
 * 
 * Datos fiscales incluidos:
 * - Emisor: nombre, NIF, dirección de la empresa
 * - Cliente: nombre, NIF
 * - Importes: base imponible, IVA (porcentaje e importe), total
 * 
 * Estados: emitida, pagada, vencida, cancelada.
 * Métodos de pago: efectivo, tarjeta, transferencia, bizum.
 * El número de factura es único (formato: F-YYYY-NNNN).
 */
@Entity
@Table(name = "facturas")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Factura {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String numeroFactura;

    private Long ventaId;
    private Long empresaId;
    private Long clienteId;
    private String clienteNombre;
    private String clienteNif;

    private String empresaNombre;
    private String empresaNif;
    private String empresaDireccion;

    private Double baseImponible;
    private Double ivaPorcentaje;
    private Double ivaImporte;
    private Double total;

    private String estado;
    private String metodoPago;

    private LocalDateTime fechaEmision;
    private LocalDateTime fechaVencimiento;
    private LocalDateTime fechaPago;
}