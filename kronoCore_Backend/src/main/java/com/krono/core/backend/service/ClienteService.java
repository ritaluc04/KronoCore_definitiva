package com.krono.core.backend.service;

import com.krono.core.backend.dto.cliente.ClienteRequestDTO;
import com.krono.core.backend.entity.Cliente;
import com.krono.core.backend.repository.ClienteRepository;
import com.krono.core.backend.util.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * SERVICIO: ClienteService
 * Gestiona la base de datos de clientes (CRM) del negocio.
 * 
 * Responsabilidades:
 * - CRUD completo de clientes (crear, leer, actualizar, eliminar)
 * - Filtrado por empresa (multi-tenant)
 * - Las etiquetas permiten segmentar clientes (VIP, Frecuente, Nuevo, etc.)
 * 
 * Cada cliente pertenece a una empresa y puede tener múltiples etiquetas
 * para facilitar la segmentación y el marketing.
 */
@Service
public class ClienteService {

    @Autowired
    private ClienteRepository clienteRepository;

    /**
     * Lista todos los clientes, filtrados por empresa si corresponde.
     */
    public List<Cliente> listarClientes() {
        if (TenantContext.shouldFilterByEmpresa()) {
            return clienteRepository.findByEmpresaId(TenantContext.getEmpresaId());
        }
        return clienteRepository.findAll();
    }

    /**
     * Obtiene un cliente por su ID.
     */
    public Cliente obtenerPorId(Long id) {
        return clienteRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Cliente no encontrado"));
    }

    /**
     * Crea un nuevo cliente en el sistema.
     * 
     * @param dto Datos del cliente (nombre, apellidos, email, teléfono, etiquetas)
     * @return Cliente creado
     */
    public Cliente crearCliente(ClienteRequestDTO dto) {
        Cliente cliente = new Cliente();
        cliente.setNombre(dto.getNombre());
        cliente.setApellidos(dto.getApellidos());
        cliente.setEmail(dto.getEmail());
        cliente.setTelefono(dto.getTelefono());
        cliente.setEtiquetas(dto.getEtiquetas());
        
        if (TenantContext.shouldFilterByEmpresa()) {
            cliente.setEmpresaId(TenantContext.getEmpresaId());
        }
        
        return clienteRepository.save(cliente);
    }

    /**
     * Actualiza los datos de un cliente existente.
     */
    public Cliente actualizarCliente(Long id, ClienteRequestDTO dto) {
        Cliente cliente = obtenerPorId(id);
        cliente.setNombre(dto.getNombre());
        cliente.setApellidos(dto.getApellidos());
        cliente.setEmail(dto.getEmail());
        cliente.setTelefono(dto.getTelefono());
        cliente.setEtiquetas(dto.getEtiquetas());
        return clienteRepository.save(cliente);
    }

    /**
     * Elimina un cliente de la base de datos.
     */
    public void eliminarCliente(Long id) {
        clienteRepository.deleteById(id);
    }
}