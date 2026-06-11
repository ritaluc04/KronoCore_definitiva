package com.krono.core.backend.controller;

import com.krono.core.backend.dto.cita.CitaRequestDTO;
import com.krono.core.backend.entity.Cita;
import com.krono.core.backend.service.CitaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * CONTROLADOR: CitaController
 * Endpoints REST para la gestión de la agenda de citas.
 * 
 * Ruta base: /api/citas
 * 
 * Endpoints:
 * - GET /api/citas → Listar todas las citas
 * - POST /api/citas → Crear una nueva cita
 * - PUT /api/citas/{id} → Actualizar una cita
 * - DELETE /api/citas/{id} → Eliminar una cita
 * 
 * Las citas se muestran en un cronograma diario con posición según la hora.
 * Estados disponibles: confirmada, pendiente, cancelada, noShow.
 */
@RestController
@RequestMapping("/api/citas")
@CrossOrigin(origins = "*")
public class CitaController {

    @Autowired
    private CitaService citaService;

    @GetMapping
    public List<Cita> listar() {
        return citaService.listarCitas();
    }

    @PostMapping
    public ResponseEntity<Cita> crear(@RequestBody CitaRequestDTO dto) {
        return new ResponseEntity<>(citaService.crearCita(dto), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Cita> actualizar(@PathVariable Long id, @RequestBody CitaRequestDTO dto) {
        return ResponseEntity.ok(citaService.actualizarCita(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        citaService.eliminarCita(id);
        return ResponseEntity.noContent().build();
    }
}