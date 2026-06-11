package com.krono.core.backend.validator;

import com.krono.core.backend.dto.cliente.ClienteRequestDTO;
import com.krono.core.backend.util.ApiResponse;

/**
 * VALIDADOR: ClienteValidator
 * Valida los datos de un cliente antes de crearlo o actualizarlo.
 * 
 * Reglas de validación:
 * - Nombre: debe estar informado
 * - Email: debe ser válido (contener @)
 * - Teléfono: debe estar informado
 * 
 * Devuelve null si la validación es correcta,
 * o un ApiResponse con el mensaje de error correspondiente.
 */
public class ClienteValidator {
    
    public ApiResponse<?> validarCliente(ClienteRequestDTO dto) {
        if (dto.getNombre() == null || dto.getNombre().isBlank()) {
            return new ApiResponse<>(400, "El nombre es obligatorio");
        }
        if (dto.getEmail() != null && !dto.getEmail().isBlank() && 
            !dto.getEmail().contains("@")) {
            return new ApiResponse<>(400, "El email no es válido");
        }
        if (dto.getTelefono() == null || dto.getTelefono().isBlank()) {
            return new ApiResponse<>(400, "El teléfono es obligatorio");
        }
        return null;
    }
}