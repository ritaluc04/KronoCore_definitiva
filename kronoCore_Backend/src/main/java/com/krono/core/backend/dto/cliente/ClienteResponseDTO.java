package com.krono.core.backend.dto.cliente;

import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

/**
 * DTO: ClienteResponseDTO
 * Estructura de salida para enviar datos de clientes al frontend.
 * Puede incluir campos calculados o formateados que no existen directamente en la entidad.
 */
@Data
public class ClienteResponseDTO {
    private Long id;
    private String nombre;
    private String apellidos;
    private String email;
    private String telefono;
    private List<String> etiquetas;
    private LocalDateTime ultimaCita;
}
