package com.krono.core.backend.dto.auth;

import com.krono.core.backend.entity.enums.UserRole;

/**
 * DTO: RegisterRequestDTO
 * Datos necesarios para el registro de un nuevo usuario.
 * Se usa en POST /api/auth/register
 */
public class RegisterRequestDTO {
    private String nombre;
    private String email;
    private String password;
    private String telefono;
    private UserRole rol;
    private String empresaNombre;

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getTelefono() { return telefono; }
    public void setTelefono(String telefono) { this.telefono = telefono; }
    public UserRole getRol() { return rol; }
    public void setRol(UserRole rol) { this.rol = rol; }
    public String getEmpresaNombre() { return empresaNombre; }
    public void setEmpresaNombre(String empresaNombre) { this.empresaNombre = empresaNombre; }
}