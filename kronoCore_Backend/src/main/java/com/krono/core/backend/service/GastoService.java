package com.krono.core.backend.service;

import com.krono.core.backend.dto.gasto.GastoRequestDTO;
import com.krono.core.backend.entity.Gasto;
import com.krono.core.backend.repository.GastoRepository;
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
 * SERVICIO: GastoService
 * Gestiona los gastos del negocio para control financiero.
 * 
 * Responsabilidades:
 * - CRUD completo de gastos (crear, leer, actualizar, eliminar)
 * - Cálculo de totales del mes (para dashboard y reportes)
 * - Filtrado por empresa (multi-tenant)
 * - Marcado de gastos como deducibles fiscalmente
 * 
 * Las categorías de gasto disponibles son:
 * - alquiler: Alquiler del local
 * - suministros: Luz, agua, internet, etc.
 * - proveedores: Material, productos, etc.
 * - marketing: Publicidad y promoción
 * - otros: Cualquier otro tipo de gasto
 */
@Service
public class GastoService {

    @Autowired
    private GastoRepository gastoRepository;

    /**
     * Lista todos los gastos, filtrados por empresa si corresponde.
     */
    public List<Gasto> listarGastos() {
        if (TenantContext.shouldFilterByEmpresa()) {
            return gastoRepository.findByEmpresaId(TenantContext.getEmpresaId());
        }
        return gastoRepository.findAll();
    }

    /**
     * Obtiene un gasto por su ID.
     */
    public Gasto obtenerPorId(Long id) {
        return gastoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Gasto no encontrado"));
    }

    /**
     * Crea un nuevo gasto en el sistema.
     * 
     * @param dto Datos del gasto (categoría, descripción, importe, IVA, etc.)
     * @return Gasto creado
     */
    public Gasto crearGasto(GastoRequestDTO dto) {
        Gasto gasto = new Gasto();
        gasto.setCategoria(dto.getCategoria());
        gasto.setDescripcion(dto.getDescripcion());
        gasto.setProveedor(dto.getProveedor());
        gasto.setNumeroFactura(dto.getNumeroFactura());
        gasto.setImporte(dto.getImporte());
        gasto.setIvaPorcentaje(dto.getIvaPorcentaje());
        gasto.setIvaImporte(dto.getIvaImporte());
        gasto.setTotal(dto.getTotal());
        gasto.setMetodoPago(dto.getMetodoPago());
        gasto.setDeducible(dto.isDeducible());
        gasto.setFecha(dto.getFecha());
        gasto.setFechaCreacion(LocalDateTime.now());
        
        if (TenantContext.shouldFilterByEmpresa()) {
            gasto.setEmpresaId(TenantContext.getEmpresaId());
        }
        
        return gastoRepository.save(gasto);
    }

    /**
     * Actualiza un gasto existente.
     */
    public Gasto actualizarGasto(Long id, GastoRequestDTO dto) {
        Gasto gasto = obtenerPorId(id);
        gasto.setCategoria(dto.getCategoria());
        gasto.setDescripcion(dto.getDescripcion());
        gasto.setProveedor(dto.getProveedor());
        gasto.setNumeroFactura(dto.getNumeroFactura());
        gasto.setImporte(dto.getImporte());
        gasto.setIvaPorcentaje(dto.getIvaPorcentaje());
        gasto.setIvaImporte(dto.getIvaImporte());
        gasto.setTotal(dto.getTotal());
        gasto.setMetodoPago(dto.getMetodoPago());
        gasto.setDeducible(dto.isDeducible());
        gasto.setFecha(dto.getFecha());
        return gastoRepository.save(gasto);
    }

    /**
     * Elimina un gasto.
     */
    public void eliminarGasto(Long id) {
        gastoRepository.deleteById(id);
    }

    /**
     * Calcula los totales de gastos del mes actual.
     * 
     * @param empresaId ID de empresa (puede ser null para admin global)
     * @return Mapa con: totalGastos, totalDeducible, numGastos
     */
    public Map<String, Object> totalesMes(Long empresaId) {
        LocalDateTime inicioMes = LocalDate.now().withDayOfMonth(1).atStartOfDay();
        LocalDateTime finMes = LocalDate.now().atTime(LocalTime.MAX);
        
        List<Gasto> gastos;
        if (empresaId != null) {
            gastos = gastoRepository.findByEmpresaIdAndFechaBetween(empresaId, inicioMes, finMes);
        } else {
            gastos = gastoRepository.findAll().stream()
                    .filter(g -> !g.getFecha().isBefore(inicioMes) && !g.getFecha().isAfter(finMes))
                    .toList();
        }
        
        double totalGastos = gastos.stream()
                .mapToDouble(g -> g.getTotal() != null ? g.getTotal() : 0.0).sum();
        double totalDeducible = gastos.stream()
                .filter(g -> g.isDeducible())
                .mapToDouble(g -> g.getTotal() != null ? g.getTotal() : 0.0).sum();
        
        Map<String, Object> res = new HashMap<>();
        res.put("totalGastos", Math.round(totalGastos * 100.0) / 100.0);
        res.put("totalDeducible", Math.round(totalDeducible * 100.0) / 100.0);
        res.put("numGastos", gastos.size());
        return res;
    }
}