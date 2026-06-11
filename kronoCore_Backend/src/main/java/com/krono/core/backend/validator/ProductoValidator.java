package com.krono.core.backend.validator;

import com.krono.core.backend.dto.producto.ProductoRequestDTO;
import com.krono.core.backend.util.ApiResponse;
import org.springframework.stereotype.Component;

/**
 * VALIDADOR: ProductoValidator
 * Valida los datos de un producto antes de crearlo o actualizarlo.
 * 
 * Reglas de validación:
 * - SKU: debe estar informado (no vacío)
 * - Nombre: debe estar informado
 * - Precio: debe ser mayor que 0
 * - Stock: debe ser >= 0
 * - Stock Mínimo: debe ser >= 0
 * 
 * Devuelve null si la validación es correcta, o un ApiResponse
 * con el mensaje de error si falla alguna regla.
 */
@Component
public class ProductoValidator {
    
    public ApiResponse<?> validarProducto(ProductoRequestDTO dto) {
        if (dto.getSku() == null || dto.getSku().isBlank()) {
            return new ApiResponse<>(400, "El SKU es obligatorio");
        }
        if (dto.getNombre() == null || dto.getNombre().isBlank()) {
            return new ApiResponse<>(400, "El nombre es obligatorio");
        }
        if (dto.getPrecio() == null || dto.getPrecio() <= 0) {
            return new ApiResponse<>(400, "El precio debe ser mayor que 0");
        }
        if (dto.getStock() == null || dto.getStock() < 0) {
            return new ApiResponse<>(400, "El stock no puede ser negativo");
        }
        if (dto.getStockMin() == null || dto.getStockMin() < 0) {
            return new ApiResponse<>(400, "El stock mínimo no puede ser negativo");
        }
        return null; // Validación correcta
    }
}