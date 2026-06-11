package com.krono.core.backend.controller;

import com.krono.core.backend.dto.tarea.TareaRequestDTO;
import com.krono.core.backend.entity.Tarea;
import com.krono.core.backend.service.TareaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * CONTROLADOR: TareaController
 * Endpoints REST para la gestión de tareas (Board Kanban).
 * 
 * Ruta base: /api/tareas
 * 
 * Endpoints:
 * - GET /api/tareas → Listar todas las tareas
 * - POST /api/tareas → Crear una nueva tarea
 * - PUT /api/tareas/{id} → Actualizar una tarea (incluye cambio de estado)
 * - DELETE /api/tareas/{id} → Eliminar una tarea
 * 
 * Las tareas se organizan en un tablero Kanban con 3 columnas por defecto:
 * Pendiente, En Proceso, Finalizado. Cada tarea tiene una prioridad
 * (baja, media, alta) que se muestra con colores.
 */
@RestController
@RequestMapping("/api/tareas")
@CrossOrigin(origins = "*")
public class TareaController {

    @Autowired
    private TareaService tareaService;

    @GetMapping
    public List<Tarea> listar() {
        return tareaService.listarTareas();
    }

    @PostMapping
    public ResponseEntity<Tarea> crear(@RequestBody TareaRequestDTO dto) {
        return new ResponseEntity<>(tareaService.crearTarea(dto), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Tarea> actualizar(@PathVariable Long id, @RequestBody TareaRequestDTO dto) {
        return ResponseEntity.ok(tareaService.actualizarTarea(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        tareaService.eliminarTarea(id);
        return ResponseEntity.noContent().build();
    }
}