package com.krono.core.backend.dto.gasto;

import java.time.LocalDateTime;

/** DTO para crear/editar gastos. Se usa en POST y PUT /api/gastos */
public class GastoRequestDTO {
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

    public String getCategoria() { return categoria; }
    public void setCategoria(String categoria) { this.categoria = categoria; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }
    public String getProveedor() { return proveedor; }
    public void setProveedor(String proveedor) { this.proveedor = proveedor; }
    public String getNumeroFactura() { return numeroFactura; }
    public void setNumeroFactura(String numeroFactura) { this.numeroFactura = numeroFactura; }
    public Double getImporte() { return importe; }
    public void setImporte(Double importe) { this.importe = importe; }
    public Double getIvaPorcentaje() { return ivaPorcentaje; }
    public void setIvaPorcentaje(Double ivaPorcentaje) { this.ivaPorcentaje = ivaPorcentaje; }
    public Double getIvaImporte() { return ivaImporte; }
    public void setIvaImporte(Double ivaImporte) { this.ivaImporte = ivaImporte; }
    public Double getTotal() { return total; }
    public void setTotal(Double total) { this.total = total; }
    public String getMetodoPago() { return metodoPago; }
    public void setMetodoPago(String metodoPago) { this.metodoPago = metodoPago; }
    public boolean isDeducible() { return deducible; }
    public void setDeducible(boolean deducible) { this.deducible = deducible; }
    public LocalDateTime getFecha() { return fecha; }
    public void setFecha(LocalDateTime fecha) { this.fecha = fecha; }
}