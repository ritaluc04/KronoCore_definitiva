package com.krono.core.backend.dto.invitacion;

/** DTO para invitar a un empleado por email. Se usa en POST /api/invitaciones/empleado */
public class InvitacionEmpleadoRequestDTO {
    private String email;
    private Long empresaId;

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public Long getEmpresaId() { return empresaId; }
    public void setEmpresaId(Long empresaId) { this.empresaId = empresaId; }
}