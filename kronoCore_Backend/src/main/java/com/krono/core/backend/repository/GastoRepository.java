package com.krono.core.backend.repository;

import com.krono.core.backend.entity.Gasto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

/** REPOSITORIO: GastoRepository - Acceso a datos de gastos */
@Repository
public interface GastoRepository extends JpaRepository<Gasto, Long> {
    List<Gasto> findByEmpresaId(Long empresaId);
    List<Gasto> findByEmpresaIdAndFechaBetween(Long empresaId, LocalDateTime start, LocalDateTime end);
    List<Gasto> findByCategoria(String categoria);
}