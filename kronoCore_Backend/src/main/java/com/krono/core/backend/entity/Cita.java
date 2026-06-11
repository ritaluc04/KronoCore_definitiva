package com.krono.core.backend.entity;

import java.time.LocalDateTime;

import com.krono.core.backend.entity.enums.CitaEstado;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * ENTIDAD: Cita
 * Representa una reserva de servicio en la agenda del negocio.
 * 
 * Cada cita tiene: cliente (ID y nombre desnormalizado),
 * servicio solicitado, empleado asignado, empresa,
 * fecha/hora de inicio, duración en minutos y estado.
 * 
 * Estados disponibles:
 * - confirmada: El cliente confirmó su asistencia
 * - pendiente: Pendiente de confirmación
 * - cancelada: Cancelada por el cliente o el negocio
 * - noShow: El cliente no asistió sin avisar
 */
@Entity
@Table(name = "citas")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Cita {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long clienteId;
    private String clienteNombre;
    private String servicio;
    private String empleado;
    private String empresaNombre;
    private Long empresaId;

    private LocalDateTime inicio;
    private Integer duracionMinutos;

    @Enumerated(EnumType.STRING)
    private CitaEstado estado;
}