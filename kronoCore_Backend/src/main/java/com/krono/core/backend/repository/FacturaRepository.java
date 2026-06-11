package com.krono.core.backend.repository;

import com.krono.core.backend.entity.Factura;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

/** REPOSITORIO: FacturaRepository - Acceso a datos de facturación */
@Repository
public interface FacturaRepository extends JpaRepository<Factura, Long> {
    List<Factura> findByEmpresaId(Long empresaId);
    List<Factura> findByEmpresaIdAndFechaEmisionBetween(Long empresaId, LocalDateTime start, LocalDateTime end);
    List<Factura> findByClienteId(Long clienteId);
    long countByEmpresaId(Long empresaId);
}