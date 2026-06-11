package com.krono.core.backend.repository;

import com.krono.core.backend.entity.Cliente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

/** REPOSITORIO: ClienteRepository - Acceso a datos de clientes (CRM) */
@Repository
public interface ClienteRepository extends JpaRepository<Cliente, Long> {
    List<Cliente> findByNombreContainingIgnoreCaseOrApellidosContainingIgnoreCaseOrEmailContainingIgnoreCase(String n, String a, String e);
    List<Cliente> findByEmpresaId(Long empresaId);
}