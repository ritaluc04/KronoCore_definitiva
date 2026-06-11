package com.krono.core.backend.controller;

import com.krono.core.backend.entity.Venta;
import com.krono.core.backend.repository.VentaRepository;
import com.krono.core.backend.service.VentaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * CONTROLADOR: VentaController
 * Endpoints REST para la gestión de ventas (TPV).
 * 
 * Ruta base: /api/ventas
 * 
 * Endpoints:
 * - GET /api/ventas → Listar historial de ventas
 * - POST /api/ventas → Registrar nueva venta (descuenta stock automáticamente)
 * - DELETE /api/ventas/{id} → Eliminar venta del historial
 * 
 * NOTA IMPORTANTE: Al crear una venta, el servicio se encarga de descontar
 * el stock de cada producto incluido en los detalles de la venta.
 * Al eliminar una venta NO se recupera el stock.
 */
@RestController
@RequestMapping("/api/ventas")
@CrossOrigin(origins = "*")
public class VentaController {

    @Autowired
    private VentaService ventaService;

    @Autowired
    private VentaRepository ventaRepository;

    /**
     * GET /api/ventas
     * Obtiene el historial completo de ventas realizadas.
     * Filtrado por empresa si el usuario tiene contexto de empresa.
     */
    @GetMapping
    public List<Venta> listar() {
        return ventaService.listarVentas();
    }

    /**
     * POST /api/ventas
     * Registra una nueva venta en el sistema.
     * El objeto venta debe incluir los detalles (productos, cantidades, precios).
     * El servicio se encarga de:
     * 1. Guardar la venta
     * 2. Descontar el stock de cada producto
     * 
     * @param venta Objeto venta con detalles y totales
     * @return Venta creada con código HTTP 201
     */
    @PostMapping
    public ResponseEntity<Venta> crear(@RequestBody Venta venta) {
        return new ResponseEntity<>(ventaService.crearVenta(venta), HttpStatus.CREATED);
    }

    /**
     * DELETE /api/ventas/{id}
     * Elimina una venta del historial.
     * ATENCIÓN: No recupera el stock de los productos.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        ventaRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}