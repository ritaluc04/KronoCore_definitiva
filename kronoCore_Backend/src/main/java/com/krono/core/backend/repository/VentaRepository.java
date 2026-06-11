package com.krono.core.backend.repository;

import com.krono.core.backend.entity.Venta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

/** REPOSITORIO: VentaRepository - Acceso a datos de ventas (historial TPV) */
@Repository
public interface VentaRepository extends JpaRepository<Venta, Long> {
    List<Venta> findByClienteId(Long clienteId);
    List<Venta> findByEmpresaId(Long empresaId);
}