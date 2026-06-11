package com.krono.core.backend.service;

import com.krono.core.backend.dto.cita.CitaRequestDTO;
import com.krono.core.backend.entity.Cita;
import com.krono.core.backend.repository.CitaRepository;
import com.krono.core.backend.util.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * SERVICIO: CitaService
 * Gestiona las reservas de servicios (citas) en la agenda del negocio.
 * 
 * Responsabilidades:
 * - CRUD completo de citas
 * - Filtrado por empresa (multi-tenant)
 * - Las citas se muestran en un cronograma diario con posición horaria
 * 
 * Estados de cita disponibles:
 * - confirmada: El cliente confirmó su asistencia
 * - pendiente: Pendiente de confirmación
 * - cancelada: La cita fue cancelada
 * - noShow: El cliente no asistió
 */
@Service
public class CitaService {

    @Autowired
    private CitaRepository citaRepository;

    /**
     * Lista todas las citas, filtradas por empresa si corresponde.
     */
    public List<Cita> listarCitas() {
        if (TenantContext.shouldFilterByEmpresa()) {
            return citaRepository.findByEmpresaId(TenantContext.getEmpresaId());
        }
        return citaRepository.findAll();
    }

    /**
     * Crea una nueva cita en la agenda.
     * 
     * @param dto Datos de la cita (cliente, servicio, empleado, fecha, duración, estado)
     * @return Cita creada
     */
    public Cita crearCita(CitaRequestDTO dto) {
        Cita cita = new Cita();
        cita.setClienteId(dto.getClienteId());
        cita.setClienteNombre(dto.getClienteNombre());
        cita.setServicio(dto.getServicio());
        cita.setEmpleado(dto.getEmpleado());
        cita.setInicio(dto.getInicio());
        cita.setDuracionMinutos(dto.getDuracionMinutos());
        cita.setEstado(dto.getEstado());
        
        if (TenantContext.shouldFilterByEmpresa()) {
            cita.setEmpresaId(TenantContext.getEmpresaId());
        }
        
        return citaRepository.save(cita);
    }

    /**
     * Actualiza los datos de una cita existente.
     */
    public Cita actualizarCita(Long id, CitaRequestDTO dto) {
        Cita cita = citaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Cita no encontrada"));
        cita.setClienteNombre(dto.getClienteNombre());
        cita.setServicio(dto.getServicio());
        cita.setEmpleado(dto.getEmpleado());
        cita.setInicio(dto.getInicio());
        cita.setDuracionMinutos(dto.getDuracionMinutos());
        cita.setEstado(dto.getEstado());
        return citaRepository.save(cita);
    }

    /**
     * Elimina una cita de la agenda.
     */
    public void eliminarCita(Long id) {
        citaRepository.deleteById(id);
    }
}