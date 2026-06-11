package com.krono.core.backend.controller;

import com.krono.core.backend.dto.cliente.ClienteRequestDTO;
import com.krono.core.backend.entity.Cliente;
import com.krono.core.backend.service.ClienteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * CONTROLADOR: ClienteController
 * Endpoints REST para la gestión de clientes (CRM).
 * 
 * Ruta base: /api/clientes
 * 
 * Endpoints:
 * - GET /api/clientes → Listar todos los clientes
 * - POST /api/clientes → Crear un nuevo cliente
 * - PUT /api/clientes/{id} → Actualizar un cliente existente
 * - DELETE /api/clientes/{id} → Eliminar un cliente
 * - GET /api/clientes/{id} → Obtener detalle de un cliente
 * 
 * Cada cliente puede tener etiquetas (VIP, Frecuente, etc.) para segmentación.
 * Los datos se filtran automáticamente por empresa (multi-tenant) a través del servicio.
 */
@RestController
@RequestMapping("/api/clientes")
@CrossOrigin(origins = "*")
public class ClienteController {

    @Autowired
    private ClienteService clienteService;

    /**
     * GET /api/clientes
     * Retorna el listado de todos los clientes del negocio.
     * Filtrado por empresa si el usuario tiene contexto de empresa.
     * 
     * @return Lista de clientes
     */
    @GetMapping
    public List<Cliente> listar() {
        return clienteService.listarClientes();
    }

    /**
     * POST /api/clientes
     * Crea un nuevo cliente en el sistema.
     * 
     * @param dto Datos del cliente: nombre, apellidos, email, teléfono, etiquetas
     * @return Cliente creado con código HTTP 201
     */
    @PostMapping
    public ResponseEntity<Cliente> crear(@RequestBody ClienteRequestDTO dto) {
        return new ResponseEntity<>(clienteService.crearCliente(dto), HttpStatus.CREATED);
    }

    /**
     * PUT /api/clientes/{id}
     * Actualiza los datos de un cliente existente.
     * 
     * @param id ID del cliente a actualizar
     * @param dto Nuevos datos del cliente
     * @return Cliente actualizado
     */
    @PutMapping("/{id}")
    public ResponseEntity<Cliente> actualizar(@PathVariable Long id, @RequestBody ClienteRequestDTO dto) {
        return ResponseEntity.ok(clienteService.actualizarCliente(id, dto));
    }

    /**
     * DELETE /api/clientes/{id}
     * Elimina un cliente del sistema.
     * 
     * @param id ID del cliente a eliminar
     * @return HTTP 204 Sin contenido
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        clienteService.eliminarCliente(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * GET /api/clientes/{id}
     * Obtiene un cliente específico por su ID.
     * 
     * @param id ID del cliente
     * @return Cliente encontrado, o 404 si no existe
     */
    @GetMapping("/{id}")
    public ResponseEntity<Cliente> obtener(@PathVariable Long id) {
        try {
            Cliente cliente = clienteService.obtenerPorId(id);
            return ResponseEntity.ok(cliente);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
}