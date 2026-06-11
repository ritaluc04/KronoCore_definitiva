package com.krono.core.backend.service;

import com.krono.core.backend.dto.tarea.TareaRequestDTO;
import com.krono.core.backend.entity.Tarea;
import com.krono.core.backend.repository.TareaRepository;
import com.krono.core.backend.util.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * SERVICIO: TareaService
 * Gestiona las tareas internas del equipo mediante un tablero Kanban.
 * 
 * Responsabilidades:
 * - CRUD completo de tareas (crear, leer, actualizar, eliminar)
 * - Las tareas se organizan en columnas por estado (Pendiente, En Proceso, Finalizado)
 * - Prioridades disponibles: baja, media, alta (con colores asociados)
 * - Filtrado por empresa (multi-tenant)
 * 
 * Cada tarea tiene: título, descripción, persona asignada, prioridad,
 * estado, fecha límite, URL de imagen opcional y color opcional.
 */
@Service
public class TareaService {

    @Autowired
    private TareaRepository tareaRepository;

    /**
     * Lista todas las tareas, filtradas por empresa si corresponde.
     */
    public List<Tarea> listarTareas() {
        if (TenantContext.shouldFilterByEmpresa()) {
            return tareaRepository.findByEmpresaId(TenantContext.getEmpresaId());
        }
        return tareaRepository.findAll();
    }

    /**
     * Crea una nueva tarea en el tablero.
     * 
     * @param dto Datos de la tarea (título, descripción, asignado, prioridad, estado, etc.)
     * @return Tarea creada
     */
    public Tarea crearTarea(TareaRequestDTO dto) {
        Tarea tarea = new Tarea();
        tarea.setTitulo(dto.getTitulo());
        tarea.setDescripcion(dto.getDescripcion());
        tarea.setAsignado(dto.getAsignado());
        tarea.setImagenUrl(dto.getImagenUrl());
        tarea.setColor(dto.getColor());
        tarea.setPrioridad(dto.getPrioridad());
        tarea.setEstado(dto.getEstado());
        tarea.setFechaLimite(dto.getFechaLimite());
        
        if (TenantContext.shouldFilterByEmpresa()) {
            tarea.setEmpresaId(TenantContext.getEmpresaId());
        }
        
        return tareaRepository.save(tarea);
    }

    /**
     * Actualiza los datos de una tarea existente.
     * Se usa tanto para editar como para mover tareas entre columnas (cambio de estado).
     */
    public Tarea actualizarTarea(Long id, TareaRequestDTO dto) {
        Tarea tarea = tareaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Tarea no encontrada"));
        tarea.setTitulo(dto.getTitulo());
        tarea.setDescripcion(dto.getDescripcion());
        tarea.setAsignado(dto.getAsignado());
        tarea.setImagenUrl(dto.getImagenUrl());
        tarea.setColor(dto.getColor());
        tarea.setPrioridad(dto.getPrioridad());
        tarea.setEstado(dto.getEstado());
        tarea.setFechaLimite(dto.getFechaLimite());
        return tareaRepository.save(tarea);
    }

    /**
     * Elimina una tarea del tablero.
     */
    public void eliminarTarea(Long id) {
        tareaRepository.deleteById(id);
    }
}