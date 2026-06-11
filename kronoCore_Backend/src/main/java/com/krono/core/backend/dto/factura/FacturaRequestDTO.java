package com.krono.core.backend.dto.factura;

import java.time.LocalDateTime;

/** DTO para crear/editar facturas. Se usa en POST y PATCH /api/facturas */
public class FacturaRequestDTO {
    private Long ventaId;
    private Long clienteId;
    private String clienteNombre;
    private String clienteNif;
    private Double baseImponible;
    private Double ivaPorcentaje;
    private Double ivaImporte;
    private Double total;
    private String estado;
    private String metodoPago;
    private LocalDateTime fechaVencimiento;

    public Long getVentaId() { return ventaId; }
    public void setVentaId(Long ventaId) { this.ventaId = ventaId; }
    public Long getClienteId() { return clienteId; }
    public void setClienteId(Long clienteId) { this.clienteId = clienteId; }
    public String getClienteNombre() { return clienteNombre; }
    public void setClienteNombre(String clienteNombre) { this.clienteNombre = clienteNombre; }
    public String getClienteNif() { return clienteNif; }
    public void setClienteNif(String clienteNif) { this.clienteNif = clienteNif; }
    public Double getBaseImponible() { return baseImponible; }
    public void setBaseImponible(Double baseImponible) { this.baseImponible = baseImponible; }
    public Double getIvaPorcentaje() { return ivaPorcentaje; }
    public void setIvaPorcentaje(Double ivaPorcentaje) { this.ivaPorcentaje = ivaPorcentaje; }
    public Double getIvaImporte() { return ivaImporte; }
    public void setIvaImporte(Double ivaImporte) { this.ivaImporte = ivaImporte; }
    public Double getTotal() { return total; }
    public void setTotal(Double total) { this.total = total; }
    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }
    public String getMetodoPago() { return metodoPago; }
    public void setMetodoPago(String metodoPago) { this.metodoPago = metodoPago; }
    public LocalDateTime getFechaVencimiento() { return fechaVencimiento; }
    public void setFechaVencimiento(LocalDateTime fechaVencimiento) { this.fechaVencimiento = fechaVencimiento; }
}