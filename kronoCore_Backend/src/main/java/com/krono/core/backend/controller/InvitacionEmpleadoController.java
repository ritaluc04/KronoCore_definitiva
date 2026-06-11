package com.krono.core.backend.controller;

import com.krono.core.backend.dto.invitacion.InvitacionEmpleadoRequestDTO;
import com.krono.core.backend.entity.InvitacionEmpleado;
import com.krono.core.backend.repository.EmpresaRepository;
import com.krono.core.backend.repository.InvitacionEmpleadoRepository;
import com.krono.core.backend.repository.UsuarioRepository;
import com.krono.core.backend.service.EmailService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * CONTROLADOR: InvitacionEmpleadoController
 * Gestiona las invitaciones a empleados para unirse a una empresa.
 * 
 * Ruta base: /api/invitaciones
 * - POST /empleado → Enviar invitación por email
 * - GET /aceptar?token=xxx → Aceptar invitación
 * 
 * FLUJO:
 * 1. Jefe/admin envía email del empleado a invitar
 * 2. Se genera token UUID y se guarda la invitación
 * 3. Se envía email con enlace de aceptación
 * 4. Empleado hace clic → invitación se marca como aceptada
 */
@RestController
@RequestMapping("/api/invitaciones")
@CrossOrigin(origins = "*")
public class InvitacionEmpleadoController {

    @Autowired private InvitacionEmpleadoRepository invitacionRepository;
    @Autowired private EmpresaRepository empresaRepository;
    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private EmailService emailService;

    @PostMapping("/empleado")
    public ResponseEntity<?> invitar(@RequestBody InvitacionEmpleadoRequestDTO dto) {
        var empresa = (dto.getEmpresaId() == null || dto.getEmpresaId() == 0)
                ? null
                : empresaRepository.findById(dto.getEmpresaId())
                    .orElseThrow(() -> new RuntimeException("Empresa no encontrada"));
        if (usuarioRepository.findByEmail(dto.getEmail()).isPresent()) return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "El email ya pertenece a un usuario registrado"));

        String token = UUID.randomUUID().toString();
        InvitacionEmpleado inv = new InvitacionEmpleado(null, dto.getEmail(), empresa, token, false, LocalDateTime.now().plusDays(7));
        invitacionRepository.save(inv);
        String link = emailService.buildInvitationLink(token);
        emailService.sendInvitationEmail(dto.getEmail(), empresa.getNombre(), token);

        Map<String, Object> ok = new HashMap<>();
        ok.put("message", "Invitación enviada"); ok.put("link", link);
        return ResponseEntity.status(HttpStatus.CREATED).body(ok);
    }

    @GetMapping("/aceptar")
    public ResponseEntity<?> aceptar(@RequestParam String token) {
        var invOpt = invitacionRepository.findByToken(token);
        if (invOpt.isEmpty()) return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Token inválido"));
        InvitacionEmpleado inv = invOpt.get();
        if (inv.isAceptada() || (inv.getExpiresAt() != null && inv.getExpiresAt().isBefore(LocalDateTime.now()))) return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "La invitación ya no es válida"));
        inv.setAceptada(true);
        invitacionRepository.save(inv);
        return ResponseEntity.ok(Map.of("message", "Invitación aceptada"));
    }
}