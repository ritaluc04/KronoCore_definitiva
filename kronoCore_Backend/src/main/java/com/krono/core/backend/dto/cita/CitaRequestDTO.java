package com.krono.core.backend.dto.cita;

import com.krono.core.backend.entity.enums.CitaEstado;
import java.time.LocalDateTime;

/**
 * DTO: CitaRequestDTO
 * Objeto de transferencia para crear o actualizar citas.
 * Incluye cliente, servicio, empleado, fecha, duración y estado.
 */
public class CitaRequestDTO {
    private Long clienteId;
    private String clienteNombre;
    private String servicio;
    private String empleado;
    private LocalDateTime inicio;
    private Integer duracionMinutos;
    private CitaEstado estado;

    public Long getClienteId() { return clienteId; }
    public void setClienteId(Long clienteId) { this.clienteId = clienteId; }
    public String getClienteNombre() { return clienteNombre; }
    public void setClienteNombre(String clienteNombre) { this.clienteNombre = clienteNombre; }
    public String getServicio() { return servicio; }
    public void setServicio(String servicio) { this.servicio = servicio; }
    public String getEmpleado() { return empleado; }
    public void setEmpleado(String empleado) { this.empleado = empleado; }
    public LocalDateTime getInicio() { return inicio; }
    public void setInicio(LocalDateTime inicio) { this.inicio = inicio; }
    public Integer getDuracionMinutos() { return duracionMinutos; }
    public void setDuracionMinutos(Integer duracionMinutos) { this.duracionMinutos = duracionMinutos; }
    public CitaEstado getEstado() { return estado; }
    public void setEstado(CitaEstado estado) { this.estado = estado; }
}