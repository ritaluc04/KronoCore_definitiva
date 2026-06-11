package com.krono.core.backend.controller;

import com.krono.core.backend.dto.producto.ProductoRequestDTO;
import com.krono.core.backend.entity.Producto;
import com.krono.core.backend.service.ProductoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * CONTROLADOR: ProductoController
 * Endpoints REST para la gestión del inventario de productos.
 * 
 * Ruta base: /api/productos
 * 
 * Endpoints:
 * - GET /api/productos → Listar todos los productos
 * - POST /api/productos → Crear un nuevo producto
 * - PUT /api/productos/{id} → Actualizar un producto
 * - DELETE /api/productos/{id} → Eliminar un producto
 * - GET /api/productos/stock-bajo → Productos con stock crítico
 * - GET /api/productos/exportar-csv → Descargar inventario en CSV
 * - GET /api/productos/{id} → Obtener un producto por ID
 * 
 * Solo accessible para administradores y jefes (el frontend oculta este menú a empleados).
 */
@RestController
@RequestMapping("/api/productos")
@CrossOrigin(origins = "*")
public class ProductoController {

    @Autowired
    private ProductoService productoService;

    @GetMapping
    public List<Producto> listar() {
        return productoService.listarProductos();
    }

    @PostMapping
    public ResponseEntity<Producto> crear(@RequestBody ProductoRequestDTO dto) {
        return new ResponseEntity<>(productoService.crearProducto(dto), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Producto> actualizar(@PathVariable Long id, @RequestBody ProductoRequestDTO dto) {
        return ResponseEntity.ok(productoService.actualizarProducto(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        productoService.eliminarProducto(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * GET /api/productos/stock-bajo
     * Retorna productos con stock igual o inferior al mínimo establecido.
     * Útil para el dashboard y notificaciones de inventario.
     */
    @GetMapping("/stock-bajo")
    public List<Producto> stockBajo() {
        return productoService.listarStockBajo();
    }

    /**
     * GET /api/productos/exportar-csv
     * Genera un archivo CSV descargable con todo el inventario.
     * Formato: SKU, Nombre, Categoría, Precio, Stock, Stock Mínimo
     */
    @GetMapping("/exportar-csv")
    public ResponseEntity<String> exportarCsv() {
        List<Producto> productos = productoService.listarProductos();
        StringBuilder csv = new StringBuilder();
        csv.append("SKU,Nombre,Categoría,Precio,Stock,Stock Mínimo\n");
        for (Producto p : productos) {
            csv.append(esc(p.getSku())).append(",");
            csv.append(esc(p.getNombre())).append(",");
            csv.append(esc(p.getCategoria())).append(",");
            csv.append(p.getPrecio()).append(",");
            csv.append(p.getStock()).append(",");
            csv.append(p.getStockMin()).append("\n");
        }
        return ResponseEntity.ok()
                .header("Content-Type", "text/csv; charset=UTF-8")
                .header("Content-Disposition", "attachment; filename=productos.csv")
                .body(csv.toString());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Producto> obtener(@PathVariable Long id) {
        try {
            Producto producto = productoService.obtenerPorId(id);
            return ResponseEntity.ok(producto);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Escapa un valor para CSV (añade comillas dobles si contiene comas o comillas).
     */
    private String esc(String s) {
        if (s == null) return "";
        if (s.contains(",") || s.contains("\"") || s.contains("\n")) {
            return "\"" + s.replace("\"", "\"\"") + "\"";
        }
        return s;
    }
}