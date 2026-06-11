package com.krono.core.backend.repository;

import com.krono.core.backend.entity.Empresa;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

/**
 * REPOSITORIO: EmpresaRepository
 * Proporciona acceso a la tabla 'empresas' para operaciones de búsqueda.
 * 
 * Métodos principales:
 * - findByNombreIgnoreCase: Busca una empresa por su nombre exacto (sin distinguir mayúsculas).
 *   Se usa en el registro para verificar si ya existe una empresa con ese nombre.
 * - findByNombreContainingIgnoreCase: Busca empresas cuyo nombre contenga el texto indicado.
 *   Se usa en el controlador /api/empresas?q=texto para el autocompletado.
 * 
 * La empresa es la raíz del multi-tenant: todos los datos de negocio dependen de ella.
 */
public interface EmpresaRepository extends JpaRepository<Empresa, Long> {
    
    /**
     * Busca una empresa por su nombre exacto (ignore case).
     * @param nombre Nombre de la empresa a buscar
     * @return Optional con la empresa si existe, vacío si no
     */
    Optional<Empresa> findByNombreIgnoreCase(String nombre);

    /**
     * Busca empresas cuyo nombre contenga el texto (búsqueda parcial, ignore case).
     * @param nombre Texto a buscar en el nombre
     * @return Lista de empresas que coinciden
     */
    List<Empresa> findByNombreContainingIgnoreCase(String nombre);
}
