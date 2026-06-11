package com.krono.core.backend.repository;

import com.krono.core.backend.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

/**
 * REPOSITORIO: UsuarioRepository
 * Proporciona métodos para interactuar con la tabla de usuarios.
 * 
 * Métodos principales:
 * - findByEmail: Busca un usuario por su email (login)
 * - findByVerificationToken: Busca por token de verificación (confirmación email)
 * - findByEmpresa_Id: Lista usuarios de una empresa (multi-tenant)
 */
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
    
    /**
     * Busca un usuario por su correo electrónico para el inicio de sesión.
     * @param email Email del usuario
     * @return Optional con el usuario si existe
     */
    Optional<Usuario> findByEmail(String email);

    /**
     * Busca un usuario por su token de verificación de email.
     * @param verificationToken Token UUID generado al registrarse
     * @return Optional con el usuario si el token es válido
     */
    Optional<Usuario> findByVerificationToken(String verificationToken);

    /**
     * Lista todos los usuarios que pertenecen a una empresa específica.
     * @param empresaId ID de la empresa
     * @return Lista de usuarios de esa empresa
     */
    List<Usuario> findByEmpresa_Id(Long empresaId);

    /**
     * Lista los usuarios que no pertenecen a ninguna empresa.
     * Esto se usa para la categoría "Clientes" en la administración.
     * @return Lista de usuarios sin empresa asociada
     */
    List<Usuario> findByEmpresaIsNull();
}
