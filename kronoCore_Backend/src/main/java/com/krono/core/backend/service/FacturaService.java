package com.krono.core.backend.service;

import com.krono.core.backend.dto.factura.FacturaRequestDTO;
import com.krono.core.backend.entity.Factura;
import com.krono.core.backend.repository.FacturaRepository;
import com.krono.core.backend.util.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * SERVICIO: FacturaService
 * Gestiona la facturación del negocio.
 * 
 * Responsabilidades:
 * - CRUD completo de facturas
 * - Generación automática de número de factura único
 * - Cambio de estado (emitida → pagada / vencida / cancelada)
 * - Cálculo de totales del mes para el dashboard
 * - Filtrado por empresa (multi-tenant)
 * 
 * Las facturas son independientes de las ventas (una venta puede generar 
 * cero, una o varias facturas). El número de factura sigue el formato
 * F-YYYY-NNNN (ej: F-2026-0001).
 */
@Service
public class FacturaService {

    @Autowired
    private FacturaRepository facturaRepository;

    /**
     * Lista todas las facturas, filtradas por empresa si corresponde.
     */
    public List<Factura> listarFacturas() {
        if (TenantContext.shouldFilterByEmpresa()) {
            return facturaRepository.findByEmpresaId(TenantContext.getEmpresaId());
        }
        return facturaRepository.findAll();
    }

    /**
     * Obtiene una factura por su ID.
     */
    public Factura obtenerPorId(Long id) {
        return facturaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Factura no encontrada"));
    }

    /**
     * Crea una nueva factura con datos fiscales.
     * 
     * PROCESO:
     * 1. Asigna la empresa del contexto
     * 2. Genera un número de factura único (F-YYYY-NNNN)
     * 3. Establece la fecha de emisión actual
     * 4. Guarda la factura en base de datos
     * 
     * @param dto Datos de la factura (cliente, importes, método pago, etc.)
     * @return Factura creada con número y fecha asignados
     */
    public Factura crearFactura(FacturaRequestDTO dto) {
        Factura factura = new Factura();
        
        // Asignar empresa del contexto
        if (TenantContext.shouldFilterByEmpresa()) {
            factura.setEmpresaId(TenantContext.getEmpresaId());
        }
        
        // Generar número de factura único: contar facturas existentes + 1
        long count = facturaRepository.count();
        String numero = String.format("F-%d-%04d", LocalDate.now().getYear(), count + 1);
        factura.setNumeroFactura(numero);
        
        // Datos del cliente
        factura.setVentaId(dto.getVentaId());
        factura.setClienteId(dto.getClienteId());
        factura.setClienteNombre(dto.getClienteNombre());
        factura.setClienteNif(dto.getClienteNif());
        
        // Importes
        factura.setBaseImponible(dto.getBaseImponible());
        factura.setIvaPorcentaje(dto.getIvaPorcentaje());
        factura.setIvaImporte(dto.getIvaImporte());
        factura.setTotal(dto.getTotal());
        
        // Estado y fechas
        factura.setEstado(dto.getEstado() != null ? dto.getEstado() : "emitida");
        factura.setMetodoPago(dto.getMetodoPago());
        factura.setFechaEmision(LocalDateTime.now());
        factura.setFechaVencimiento(dto.getFechaVencimiento());
        
        return facturaRepository.save(factura);
    }

    /**
     * Cambia el estado de una factura (emitida → pagada, etc.).
     * 
     * @param id ID de la factura
     * @param nuevoEstado Nuevo estado (pagada, vencida, cancelada)
     * @return Factura actualizada
     */
    public Factura actualizarEstado(Long id, String nuevoEstado) {
        Factura factura = obtenerPorId(id);
        factura.setEstado(nuevoEstado);
        
        // Si se marca como pagada, registrar la fecha de pago
        if ("pagada".equals(nuevoEstado)) {
            factura.setFechaPago(LocalDateTime.now());
        }
        
        return facturaRepository.save(factura);
    }

    /**
     * Elimina una factura.
     */
    public void eliminarFactura(Long id) {
        facturaRepository.deleteById(id);
    }

    /**
     * Calcula los totales de facturación del mes actual.
     * 
     * @param empresaId ID de empresa (puede ser null para admin global)
     * @return Mapa con: totalFacturado, totalPendiente, totalPagado, numFacturas
     */
    public Map<String, Object> totalesMes(Long empresaId) {
        LocalDateTime inicioMes = LocalDate.now().withDayOfMonth(1).atStartOfDay();
        LocalDateTime finMes = LocalDate.now().atTime(LocalTime.MAX);
        
        List<Factura> facturas;
        if (empresaId != null) {
            facturas = facturaRepository.findByEmpresaIdAndFechaEmisionBetween(empresaId, inicioMes, finMes);
        } else {
            facturas = facturaRepository.findAll().stream()
                    .filter(f -> !f.getFechaEmision().isBefore(inicioMes) && !f.getFechaEmision().isAfter(finMes))
                    .toList();
        }
        
        double totalFacturado = facturas.stream()
                .mapToDouble(f -> f.getTotal() != null ? f.getTotal() : 0.0).sum();
        double totalPendiente = facturas.stream()
                .filter(f -> "emitida".equals(f.getEstado()))
                .mapToDouble(f -> f.getTotal() != null ? f.getTotal() : 0.0).sum();
        double totalPagado = facturas.stream()
                .filter(f -> "pagada".equals(f.getEstado()))
                .mapToDouble(f -> f.getTotal() != null ? f.getTotal() : 0.0).sum();
        
        Map<String, Object> res = new HashMap<>();
        res.put("totalFacturado", Math.round(totalFacturado * 100.0) / 100.0);
        res.put("totalPendiente", Math.round(totalPendiente * 100.0) / 100.0);
        res.put("totalPagado", Math.round(totalPagado * 100.0) / 100.0);
        res.put("numFacturas", facturas.size());
        return res;
    }
}