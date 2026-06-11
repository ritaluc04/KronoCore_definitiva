package com.krono.core.backend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

/**
 * ENTIDAD: Cliente
 * Representa un cliente del negocio en el módulo CRM.
 * 
 * Cada cliente tiene: nombre, apellidos, email, teléfono,
 * una lista de etiquetas (tags) para segmentación,
 * la fecha de su última cita (para seguimiento),
 * y la empresa a la que pertenece.
 * 
 * Las etiquetas permiten clasificar clientes como:
 * VIP, Frecuente, Nuevo, etc.
 */
@Entity
@Table(name = "clientes")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Cliente {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String nombre;
    private String apellidos;
    private String email;
    private String telefono;

    @ElementCollection
    private List<String> etiquetas;

    private LocalDateTime ultimaCita;

    private Long empresaId;
}