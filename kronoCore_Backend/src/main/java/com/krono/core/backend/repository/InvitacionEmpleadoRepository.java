package com.krono.core.backend.repository;

import com.krono.core.backend.entity.InvitacionEmpleado;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * REPOSITORIO: InvitacionEmpleadoRepository
 * Gestiona el almacenamiento de invitaciones enviadas a empleados.
 * 
 * Cada invitación contiene un token único que permite al empleado
 * aceptar la invitación y unirse a la empresa.
 * 
 * Método principal:
 * - findByToken: Busca una invitación por su token único.
 *   Se usa cuando el empleado hace clic en el enlace de invitación.
 */
public interface InvitacionEmpleadoRepository extends JpaRepository<InvitacionEmpleado, Long> {
    
    /**
     * Busca una invitación por su token único.
     * @param token Token UUID generado al crear la invitación
     * @return Optional con la invitación si existe
     */
    Optional<InvitacionEmpleado> findByToken(String token);
}
