package com.krono.core.backend.validator;

import com.krono.core.backend.dto.tarea.TareaRequestDTO;
import com.krono.core.backend.util.ApiResponse;

/**
 * VALIDADOR: TareaValidator
 * Valida los datos de una tarea del tablero Kanban.
 * Reglas: título obligatorio, prioridad y estado requeridos.
 */
public class TareaValidator {
    public ApiResponse<?> validarTarea(TareaRequestDTO dto) {
        if (dto.getTitulo() == null || dto.getTitulo().isBlank()) return new ApiResponse<>(400, "El título es obligatorio");
        if (dto.getPrioridad() == null) return new ApiResponse<>(400, "La prioridad es obligatoria");
        if (dto.getEstado() == null) return new ApiResponse<>(400, "El estado es obligatorio");
        return null;
    }
}