package com.krono.core.backend.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * ENTIDAD: Empresa
 * Representa un negocio o salón dentro del sistema multi-tenant.
 * 
 * Es la raíz del modelo de datos: todas las entidades de negocio
 * (clientes, productos, ventas, etc.) están vinculadas a una empresa
 * a través de su campo empresaId.
 * 
 * Cada empresa tiene un nombre único y un teléfono de contacto.
 * Los usuarios (jefes y empleados) pertenecen a una empresa específica.
 * El administrador (admin) no tiene empresa asignada y ve datos globales.
 */
@Entity
@Table(name = "empresas")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Empresa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String nombre;

    private String telefono;
}