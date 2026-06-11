package com.krono.core.backend.controller;

import com.krono.core.backend.dto.factura.FacturaRequestDTO;
import com.krono.core.backend.entity.Factura;
import com.krono.core.backend.service.FacturaService;
import com.krono.core.backend.util.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * CONTROLADOR: FacturaController
 * Endpoints REST para la gestión de facturación.
 * 
 * Ruta base: /api/facturas
 * 
 * Endpoints:
 * - GET /api/facturas → Listar todas las facturas
 * - POST /api/facturas → Crear nueva factura (genera número único)
 * - GET /api/facturas/{id} → Obtener factura por ID
 * - PATCH /api/facturas/{id}/estado → Cambiar estado (emitida→pagada, etc.)
 * - DELETE /api/facturas/{id} → Eliminar factura
 * - GET /api/facturas/totales-mes → Totales de facturación del mes
 * 
 * Solo accesible para administradores y jefes.
 */
@RestController
@RequestMapping("/api/facturas")
@CrossOrigin(origins = "*")
public class FacturaController {

    @Autowired
    private FacturaService facturaService;

    @GetMapping
    public List<Factura> listar() {
        return facturaService.listarFacturas();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Factura> obtener(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(facturaService.obtenerPorId(id));
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping
    public ResponseEntity<Factura> crear(@RequestBody FacturaRequestDTO dto) {
        return new ResponseEntity<>(facturaService.crearFactura(dto), HttpStatus.CREATED);
    }

    /**
     * PATCH /api/facturas/{id}/estado
     * Actualiza solo el estado de una factura.
     * Útil para marcar como pagada, vencida o cancelada.
     */
    @PatchMapping("/{id}/estado")
    public ResponseEntity<Factura> actualizarEstado(@PathVariable Long id, @RequestBody Map<String, String> body) {
        return ResponseEntity.ok(facturaService.actualizarEstado(id, body.get("estado")));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        facturaService.eliminarFactura(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * GET /api/facturas/totales-mes
     * Retorna un resumen con los totales de facturación del mes actual.
     * Filtrado por empresa si el usuario tiene contexto de empresa.
     */
    @GetMapping("/totales-mes")
    public ResponseEntity<Map<String, Object>> totalesMes() {
        Long empresaId = TenantContext.shouldFilterByEmpresa() ? TenantContext.getEmpresaId() : null;
        return ResponseEntity.ok(facturaService.totalesMes(empresaId));
    }
}