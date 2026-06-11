package com.krono.core.backend.controller;

import com.krono.core.backend.entity.*;
import com.krono.core.backend.repository.*;
import com.krono.core.backend.util.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * CONTROLADOR: DashboardController
 * Proporciona las métricas del panel principal (Dashboard).
 * 
 * Ruta base: /api/dashboard
 * Endpoint: GET /api/dashboard/resumen
 * 
 * MÉTRICAS DEVUELTAS:
 * - totalClientes: número de clientes registrados
 * - ventasHoy: total de ventas del día actual
 * - ventasMes: total de ventas del mes actual
 * - productosStockBajo[]: productos con stock <= stockMin
 * - citasHoy: número de citas programadas para hoy
 * - ingresosHoy: mismo que ventasHoy (alias)
 * - totalFacturadoMes: facturación del mes actual
 * - totalGastosMes: gastos del mes actual
 * - rentabilidadMes: facturación - gastos
 * 
 * Multi-tenant: Filtra los datos por empresa si el usuario
 * tiene un contexto de empresa (jefe o empleado).
 */
@RestController
@RequestMapping("/api/dashboard")
@CrossOrigin(origins = "*")
public class DashboardController {

    @Autowired private ClienteRepository clienteRepository;
    @Autowired private VentaRepository ventaRepository;
    @Autowired private ProductoRepository productoRepository;
    @Autowired private CitaRepository citaRepository;
    @Autowired private FacturaRepository facturaRepository;
    @Autowired private GastoRepository gastoRepository;

    /**
     * GET /api/dashboard/resumen
     * Retorna un resumen con métricas clave para las tarjetas del dashboard.
     * Los datos se filtran por empresa si el usuario tiene contexto de empresa.
     */
    @GetMapping("/resumen")
    public Map<String, Object> resumen() {
        Long empresaId = TenantContext.shouldFilterByEmpresa() ? TenantContext.getEmpresaId() : null;

        LocalDate hoy = LocalDate.now();
        LocalDateTime inicioHoy = hoy.atStartOfDay();
        LocalDateTime finHoy = hoy.atTime(LocalTime.MAX);
        LocalDateTime inicioMes = hoy.withDayOfMonth(1).atStartOfDay();

        // Cargar datos base (filtrados por empresa si corresponde)
        List<Cliente> clientes = empresaId != null ? clienteRepository.findByEmpresaId(empresaId) : clienteRepository.findAll();
        List<Venta> ventas = empresaId != null ? ventaRepository.findByEmpresaId(empresaId) : ventaRepository.findAll();
        List<Producto> productos = empresaId != null ? productoRepository.findByEmpresaId(empresaId) : productoRepository.findAll();

        // Ventas de hoy
        double ventasHoy = ventas.stream()
                .filter(v -> !v.getFecha().isBefore(inicioHoy) && !v.getFecha().isAfter(finHoy))
                .mapToDouble(v -> v.getTotal() != null ? v.getTotal() : 0.0).sum();

        // Ventas del mes
        double ventasMes = ventas.stream()
                .filter(v -> !v.getFecha().isBefore(inicioMes))
                .mapToDouble(v -> v.getTotal() != null ? v.getTotal() : 0.0).sum();

        // Productos con stock bajo (stock <= stockMin)
        List<Producto> stockBajo = productos.stream()
                .filter(p -> p.getStock() != null && p.getStockMin() != null && p.getStock() <= p.getStockMin()).toList();

        // Citas de hoy
        List<Cita> citasHoy = citaRepository.findByInicioBetween(inicioHoy, finHoy);
        if (empresaId != null) citasHoy = citasHoy.stream().filter(c -> empresaId.equals(c.getEmpresaId())).toList();

        // Facturación y gastos del mes
        List<Factura> facturasMes = facturaRepository.findAll().stream()
                .filter(f -> !f.getFechaEmision().isBefore(inicioMes) && !f.getFechaEmision().isAfter(finHoy)).toList();
        List<Gasto> gastosMes = gastoRepository.findAll().stream()
                .filter(g -> !g.getFecha().isBefore(inicioMes) && !g.getFecha().isAfter(finHoy)).toList();
        if (empresaId != null) {
            facturasMes = facturasMes.stream().filter(f -> empresaId.equals(f.getEmpresaId())).toList();
            gastosMes = gastosMes.stream().filter(g -> empresaId.equals(g.getEmpresaId())).toList();
        }

        double totalFacturadoMes = facturasMes.stream()
                .filter(f -> "emitida".equals(f.getEstado()) || "pagada".equals(f.getEstado()))
                .mapToDouble(f -> f.getTotal() != null ? f.getTotal() : 0.0).sum();
        double totalGastosMes = gastosMes.stream()
                .mapToDouble(g -> g.getTotal() != null ? g.getTotal() : 0.0).sum();

        // Construir respuesta
        Map<String, Object> res = new HashMap<>();
        res.put("totalClientes", clientes.size());
        res.put("ventasHoy", Math.round(ventasHoy * 100.0) / 100.0);
        res.put("ventasMes", Math.round(ventasMes * 100.0) / 100.0);
        res.put("productosStockBajo", stockBajo.stream().map(p -> {
            Map<String, Object> item = new HashMap<>();
            item.put("id", p.getId()); item.put("nombre", p.getNombre());
            item.put("stock", p.getStock()); item.put("stockMin", p.getStockMin());
            return item;
        }).toList());
        res.put("citasHoy", citasHoy.size());
        res.put("ingresosHoy", Math.round(ventasHoy * 100.0) / 100.0);
        res.put("totalFacturadoMes", Math.round(totalFacturadoMes * 100.0) / 100.0);
        res.put("totalGastosMes", Math.round(totalGastosMes * 100.0) / 100.0);
        res.put("rentabilidadMes", Math.round((totalFacturadoMes - totalGastosMes) * 100.0) / 100.0);

        return res;
    }
}