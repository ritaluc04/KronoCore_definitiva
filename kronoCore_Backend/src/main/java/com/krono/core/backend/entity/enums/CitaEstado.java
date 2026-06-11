package com.krono.core.backend.entity.enums;

/**
 * ENUM: CitaEstado
 * Define los estados del ciclo de vida de una cita en la agenda.
 * 
 * - confirmada: El cliente ha confirmado su asistencia (verde)
 * - pendiente: Pendiente de confirmación (amarillo)
 * - cancelada: Cancelada por cualquiera de las partes (gris)
 * - noShow: El cliente no asistió sin avisar (rojo)
 * 
 * Cada estado tiene un color asociado en el frontend para
 * facilitar la identificación visual en el cronograma diario.
 */
public enum CitaEstado {
    confirmada, pendiente, cancelada, noShow
}