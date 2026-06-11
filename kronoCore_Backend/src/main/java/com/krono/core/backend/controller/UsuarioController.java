package com.krono.core.backend.controller;

import com.krono.core.backend.entity.Usuario;
import com.krono.core.backend.repository.UsuarioRepository;
import com.krono.core.backend.util.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** CONTROLADOR: UsuarioController - Gestión de usuarios (solo admin). Ruta: GET/PUT /api/usuarios */
@RestController
@RequestMapping("/api/usuarios")
@CrossOrigin(origins = "*")
public class UsuarioController {

    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private com.krono.core.backend.repository.EmpresaRepository empresaRepository;

    @GetMapping
    public List<Usuario> listar() {
        Long empresaId = TenantContext.getEmpresaId();
        String rol = TenantContext.getUserRol();
        if (empresaId != null && "admin".equals(rol)) {
            if (empresaId == 0L) {
                return usuarioRepository.findByEmpresaIsNull();
            }
            return usuarioRepository.findByEmpresa_Id(empresaId);
        }
        if (TenantContext.shouldFilterByEmpresa()) {
            return usuarioRepository.findByEmpresa_Id(TenantContext.getEmpresaId());
        }
        return usuarioRepository.findAll();
    }

    @DeleteMapping("/{id}")
    public org.springframework.http.ResponseEntity<?> eliminar(@PathVariable Long id) {
        return usuarioRepository.findById(id).map(user -> {
            usuarioRepository.delete(user);
            return org.springframework.http.ResponseEntity.noContent().build();
        }).orElse(org.springframework.http.ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    public org.springframework.http.ResponseEntity<?> actualizar(@PathVariable Long id, @RequestBody java.util.Map<String, Object> updates) {
        return usuarioRepository.findById(id).map(user -> {
            if (updates.containsKey("rol")) user.setRol(com.krono.core.backend.entity.enums.UserRole.valueOf(updates.get("rol").toString()));
            if (updates.containsKey("empresaId")) {
                Object empIdObj = updates.get("empresaId");
                user.setEmpresa(empIdObj != null ? empresaRepository.findById(Long.valueOf(empIdObj.toString())).orElse(null) : null);
            }
            if (updates.containsKey("verificado")) user.setVerificado((Boolean) updates.get("verificado"));
            usuarioRepository.save(user);
            return org.springframework.http.ResponseEntity.ok(user);
        }).orElse(org.springframework.http.ResponseEntity.notFound().build());
    }
}