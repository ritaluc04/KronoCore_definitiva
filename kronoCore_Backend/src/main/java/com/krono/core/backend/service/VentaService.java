package com.krono.core.backend.service;

import com.krono.core.backend.entity.Venta;
import com.krono.core.backend.repository.VentaRepository;
import com.krono.core.backend.util.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * SERVICIO: VentaService
 * Gestiona las transacciones comerciales (ventas) del negocio.
 * 
 * Responsabilidades:
 * - listarVentas: Obtiene el historial de ventas (filtrado por empresa)
 * - crearVenta: Registra una nueva venta y descuenta el stock automáticamente
 * 
 * NOTA IMPORTANTE: Al crear una venta, se itera sobre los detalles
 * y se descuenta el stock de cada producto llamado a ProductoService.descontarStock().
 * Esto asegura que el inventario se mantenga sincronizado con las ventas.
 */
@Service
public class VentaService {

    @Autowired
    private VentaRepository ventaRepository;

    @Autowired
    private ProductoService productoService;

    /**
     * Obtiene todas las ventas del historial.
     * Si hay contexto de empresa, filtra por esa empresa.
     * 
     * @return Lista de ventas
     */
    public List<Venta> listarVentas() {
        if (TenantContext.shouldFilterByEmpresa()) {
            return ventaRepository.findByEmpresaId(TenantContext.getEmpresaId());
        }
        return ventaRepository.findAll();
    }

    /**
     * Registra una nueva venta en el sistema.
     * 
     * PROCESO:
     * 1. Asigna la empresa al contexto si existe
     * 2. Guarda la venta con sus detalles
     * 3. Por cada detalle, descuenta el stock del producto
     * 
     * @param venta Objeto venta con los detalles (productos, cantidades, totales)
     * @return Venta guardada con ID asignado
     */
    public Venta crearVenta(Venta venta) {
        // Asignar empresa del contexto
        if (TenantContext.shouldFilterByEmpresa()) {
            venta.setEmpresaId(TenantContext.getEmpresaId());
        }
        
        // Guardar la venta primero para obtener el ID
        Venta saved = ventaRepository.save(venta);
        
        // Descontar stock de cada producto vendido
        if (saved.getDetalles() != null) {
            saved.getDetalles().forEach(detalle -> {
                if (detalle.getProductoId() != null && detalle.getCantidad() != null) {
                    productoService.descontarStock(detalle.getProductoId(), detalle.getCantidad());
                }
            });
        }
        
        return saved;
    }
}