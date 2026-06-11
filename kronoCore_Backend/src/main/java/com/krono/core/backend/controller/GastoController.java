package com.krono.core.backend.controller;

import com.krono.core.backend.dto.gasto.GastoRequestDTO;
import com.krono.core.backend.entity.Gasto;
import com.krono.core.backend.service.GastoService;
import com.krono.core.backend.util.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * CONTROLADOR: GastoController
 * Endpoints REST para la gestión de gastos del negocio.
 * 
 * Ruta base: /api/gastos
 * 
 * Endpoints:
 * - GET /api/gastos → Listar todos los gastos
 * - POST /api/gastos → Crear un nuevo gasto
 * - PUT /api/gastos/{id} → Actualizar un gasto existente
 * - DELETE /api/gastos/{id} → Eliminar un gasto
 * - GET /api/gastos/{id} → Obtener un gasto por ID
 * - GET /api/gastos/totales-mes → Totales de gastos del mes
 * 
 * Categorías disponibles: alquiler, suministros, proveedores, marketing, otros.
 * Los gastos pueden marcarse como deducibles fiscalmente.
 * Solo accesible para administradores y jefes.
 */
@RestController
@RequestMapping("/api/gastos")
@CrossOrigin(origins = "*")
public class GastoController {

    @Autowired
    private GastoService gastoService;

    @GetMapping
    public List<Gasto> listar() {
        return gastoService.listarGastos();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Gasto> obtener(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(gastoService.obtenerPorId(id));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping
    public ResponseEntity<Gasto> crear(@RequestBody GastoRequestDTO dto) {
        return new ResponseEntity<>(gastoService.crearGasto(dto), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Gasto> actualizar(@PathVariable Long id, @RequestBody GastoRequestDTO dto) {
        return ResponseEntity.ok(gastoService.actualizarGasto(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        gastoService.eliminarGasto(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * GET /api/gastos/totales-mes
     * Retorna el resumen de gastos del mes actual.
     * Incluye: totalGastos, totalDeducible, numGastos.
     */
    @GetMapping("/totales-mes")
    public ResponseEntity<Map<String, Object>> totalesMes() {
        Long empresaId = TenantContext.shouldFilterByEmpresa() ? TenantContext.getEmpresaId() : null;
        return ResponseEntity.ok(gastoService.totalesMes(empresaId));
    }
}