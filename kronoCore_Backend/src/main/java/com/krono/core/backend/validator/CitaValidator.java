package com.krono.core.backend.validator;

import com.krono.core.backend.dto.cita.CitaRequestDTO;
import com.krono.core.backend.util.ApiResponse;

/**
 * VALIDADOR: CitaValidator
 * Valida los datos de una cita antes de crearla o actualizarla.
 * 
 * Reglas de validación:
 * - Cliente: debe tener nombre informado
 * - Servicio: debe estar informado
 * - Empleado: debe estar informado
 * - Fecha de inicio: debe estar en el futuro
 * - Duración: debe ser mayor que 0
 */
public class CitaValidator {
    
    public ApiResponse<?> validarCita(CitaRequestDTO dto) {
        if (dto.getClienteNombre() == null || dto.getClienteNombre().isBlank()) {
            return new ApiResponse<>(400, "El cliente es obligatorio");
        }
        if (dto.getServicio() == null || dto.getServicio().isBlank()) {
            return new ApiResponse<>(400, "El servicio es obligatorio");
        }
        if (dto.getEmpleado() == null || dto.getEmpleado().isBlank()) {
            return new ApiResponse<>(400, "El empleado es obligatorio");
        }
        if (dto.getInicio() == null) {
            return new ApiResponse<>(400, "La fecha de inicio es obligatoria");
        }
        if (dto.getDuracionMinutos() == null || dto.getDuracionMinutos() <= 0) {
            return new ApiResponse<>(400, "La duración debe ser mayor que 0");
        }
        return null;
    }
}