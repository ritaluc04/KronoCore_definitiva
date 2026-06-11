package com.krono.core.backend.repository;

import com.krono.core.backend.entity.Tarea;
import com.krono.core.backend.entity.enums.TareaEstado;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

/** REPOSITORIO: TareaRepository - Acceso a tareas del board Kanban */
@Repository
public interface TareaRepository extends JpaRepository<Tarea, Long> {
    List<Tarea> findByAsignado(String asignado);
    List<Tarea> findByEstado(TareaEstado estado);
    List<Tarea> findByEmpresaId(Long empresaId);
}