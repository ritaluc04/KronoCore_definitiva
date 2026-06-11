package com.krono.core.backend.entity;

import com.krono.core.backend.entity.enums.TareaEstado;
import com.krono.core.backend.entity.enums.TareaPrioridad;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

/**
 * ENTIDAD: Tarea
 * Representa una tarea del tablero Kanban para gestión interna del equipo.
 * 
 * Cada tarea tiene: título, descripción, persona asignada,
 * URL de imagen opcional, color hexadecimal opcional,
 * prioridad (baja, media, alta), estado (pendiente, enProceso, finalizado),
 * fecha límite y empresa propietaria.
 * 
 * Las tareas se organizan visualmente en 3 columnas por defecto:
 * Pendiente (📋), En Progreso (🔄), Finalizado (✅).
 * Se pueden mover entre columnas arrastrándolas (Drag & Drop).
 */
@Entity
@Table(name = "tareas")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Tarea {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String titulo;
    private String descripcion;
    private String asignado;
    private String imagenUrl;
    private String color;
    private Long empresaId;

    @Enumerated(EnumType.STRING)
    private TareaPrioridad prioridad;

    @Enumerated(EnumType.STRING)
    private TareaEstado estado;

    private LocalDateTime fechaLimite;
}