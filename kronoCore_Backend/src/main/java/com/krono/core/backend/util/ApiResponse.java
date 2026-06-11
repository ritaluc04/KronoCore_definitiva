package com.krono.core.backend.util;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * UTILIDAD: ApiResponse<T>
 * Estructura genérica para estandarizar todas las respuestas de la API.
 * 
 * Formato:
 * {
 *   "status": 200,          // Código HTTP
 *   "message": "Operación exitosa",  // Mensaje descriptivo
 *   "data": { ... }         // Datos de la respuesta (genérico)
 * }
 * 
 * Asegura que el frontend reciba siempre un formato consistente
 * independientemente del tipo de dato que se devuelva.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApiResponse<T> {
    private int status;
    private String message;
    private T data;

    public ApiResponse(int status, String message) {
        this.status = status;
        this.message = message;
    }
}