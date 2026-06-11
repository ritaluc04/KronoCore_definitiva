package com.krono.core.backend.repository;

import com.krono.core.backend.entity.Cita;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

/** REPOSITORIO: CitaRepository - Acceso a datos de citas (agenda) */
@Repository
public interface CitaRepository extends JpaRepository<Cita, Long> {
    List<Cita> findByClienteId(Long clienteId);
    List<Cita> findByInicioBetween(LocalDateTime start, LocalDateTime end);
    List<Cita> findByEmpleado(String empleado);
    List<Cita> findByEmpresaId(Long empresaId);
}