package com.krono.core.backend.dto.producto;

import lombok.Data;

/**
 * DTO: ProductoResponseDTO
 * Representación de un producto para las respuestas del API.
 */
@Data
public class ProductoResponseDTO {
    private Long id;
    private String sku;
    private String nombre;
    private String categoria;
    private Double precio;
    private Integer stock;
    private Integer stockMin;
    private boolean activo;
}
