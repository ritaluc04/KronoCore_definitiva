package com.krono.core.backend.entity;

import com.krono.core.backend.entity.enums.UserRole;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * ENTIDAD: Usuario
 * Representa a cualquier persona que utiliza el sistema.
 * Puede ser administrador, jefe, empleado o cliente.
 * 
 * Cada usuario tiene: nombre, email (único para login), password (hash BCrypt),
 * rol (define permisos), y opcionalmente una empresa asociada.
 * 
 * El email debe verificarse antes del primer inicio de sesión mediante
 * un token de verificación con fecha de caducidad.
 */
@Entity
@Table(name = "usuarios")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nombre;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    private String telefono;

    @Enumerated(EnumType.STRING)
    private UserRole rol;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "empresa_id")
    @com.fasterxml.jackson.annotation.JsonIgnore
    private Empresa empresa;

    @Transient
    public String getEmpresaNombre() {
        return empresa != null ? empresa.getNombre() : null;
    }

    @Column(nullable = false)
    private boolean verificado;

    private String verificationToken;

    private java.time.LocalDateTime verificationTokenExpiresAt;

    private String avatar;
}