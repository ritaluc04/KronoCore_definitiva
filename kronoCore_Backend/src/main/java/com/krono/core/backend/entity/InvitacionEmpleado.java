package com.krono.core.backend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

/**
 * ENTIDAD: InvitacionEmpleado
 * Gestiona las invitaciones para que un empleado acepte unirse a una empresa.
 * 
 * Cuando un jefe o administrador invita a un nuevo empleado:
 * 1. Se crea esta entidad con el email del invitado y un token UUID único
 * 2. Se envía un email con el enlace de aceptación
 * 3. El empleado hace clic en el enlace → se marca como aceptada
 * 
 * La invitación expira a los 7 días (configurable desde el servicio).
 */
@Entity
@Table(name = "invitaciones_empleado")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class InvitacionEmpleado {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String email;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "empresa_id")
    private Empresa empresa;

    @Column(nullable = false)
    private String token;

    @Column(nullable = false)
    private boolean aceptada;

    private LocalDateTime expiresAt;
}