package com.krono.core.backend.dto.tarea;

import com.krono.core.backend.entity.enums.TareaEstado;
import com.krono.core.backend.entity.enums.TareaPrioridad;
import java.time.LocalDateTime;

/** DTO para crear/editar tareas del tablero Kanban. Se usa en POST y PUT /api/tareas */
public class TareaRequestDTO {
    private String titulo;
    private String descripcion;
    private String asignado;
    private String imagenUrl;
    private String color;
    private TareaPrioridad prioridad;
    private TareaEstado estado;
    private LocalDateTime fechaLimite;

    public String getTitulo() { return titulo; }
    public void setTitulo(String titulo) { this.titulo = titulo; }
    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }
    public String getAsignado() { return asignado; }
    public void setAsignado(String asignado) { this.asignado = asignado; }
    public String getImagenUrl() { return imagenUrl; }
    public void setImagenUrl(String imagenUrl) { this.imagenUrl = imagenUrl; }
    public String getColor() { return color; }
    public void setColor(String color) { this.color = color; }
    public TareaPrioridad getPrioridad() { return prioridad; }
    public void setPrioridad(TareaPrioridad prioridad) { this.prioridad = prioridad; }
    public TareaEstado getEstado() { return estado; }
    public void setEstado(TareaEstado estado) { this.estado = estado; }
    public LocalDateTime getFechaLimite() { return fechaLimite; }
    public void setFechaLimite(LocalDateTime fechaLimite) { this.fechaLimite = fechaLimite; }
}