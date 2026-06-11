package com.krono.core.backend.dto.cliente;

import java.util.List;

/**
 * DTO: ClienteRequestDTO
 * Objeto de transferencia de datos para las peticiones de cliente.
 * 
 * Se usa en:
 * - POST /api/clientes (crear)
 * - PUT /api/clientes/{id} (actualizar)
 * 
 * Incluye una lista de etiquetas (tags) para segmentación CRM.
 */
public class ClienteRequestDTO {
    private String nombre;
    private String apellidos;
    private String email;
    private String telefono;
    private List<String> etiquetas;

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getApellidos() { return apellidos; }
    public void setApellidos(String apellidos) { this.apellidos = apellidos; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getTelefono() { return telefono; }
    public void setTelefono(String telefono) { this.telefono = telefono; }

    public List<String> getEtiquetas() { return etiquetas; }
    public void setEtiquetas(List<String> etiquetas) { this.etiquetas = etiquetas; }
}