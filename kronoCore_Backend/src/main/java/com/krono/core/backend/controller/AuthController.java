package com.krono.core.backend.controller;

import com.krono.core.backend.dto.auth.RegisterRequestDTO;
import com.krono.core.backend.entity.Empresa;
import com.krono.core.backend.entity.Usuario;
import com.krono.core.backend.entity.enums.UserRole;
import com.krono.core.backend.repository.EmpresaRepository;
import com.krono.core.backend.repository.UsuarioRepository;
import com.krono.core.backend.service.EmailService;
import com.krono.core.backend.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * CONTROLADOR: AuthController
 * Gestiona el acceso de usuarios (Login y Registro) usando JWT.
 * 
 * Ruta base: /api/auth
 * Endpoints PÚBLICOS (sin autenticación):
 * - POST /login → Iniciar sesión, devuelve Access + Refresh Token
 * - POST /register → Registrar nuevo usuario (envía email verificación)
 * - POST /refresh → Renovar Access Token con Refresh Token
 * - GET /confirmar?token=xxx → Confirmar email
 * 
 * FLUJO DE LOGIN:
 * 1. Buscar usuario por email
 * 2. Verificar que la cuenta esté verificada
 * 3. Comparar contraseña con BCrypt
 * 4. Generar JWT (Access Token 1h + Refresh Token 7d)
 * 5. Devolver tokens + datos del usuario
 * 
 * FLUJO DE REGISTRO:
 * 1. Validar que el email no exista
 * 2. Si es jefe/empleado, verificar/crear empresa
 * 3. Crear usuario con verificado=false
 * 4. Enviar email de verificación con token UUID
 */
@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private EmpresaRepository empresaRepository;
    @Autowired private EmailService emailService;
    @Autowired private JwtUtil jwtUtil;

    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        String email = credentials.get("email");
        String password = credentials.get("password");

        // Auto-creación del admin si es la primera vez
        if (usuarioRepository.count() == 0 && "admin@krono.dev".equals(email)) {
            Usuario admin = new Usuario(null, "Admin Krono", email, passwordEncoder.encode(password), "000000000", UserRole.admin, null, true, null, null, null);
            usuarioRepository.save(admin);
        }

        Optional<Usuario> usuarioOpt = usuarioRepository.findByEmail(email);
        if (usuarioOpt.isEmpty()) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Email o contrasena incorrectos"));

        Usuario u = usuarioOpt.get();
        if (!u.isVerificado()) return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("message", "Debes confirmar tu correo antes de iniciar sesion"));
        if (!passwordEncoder.matches(password, u.getPassword())) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Email o contrasena incorrectos"));

        Long empresaId = u.getEmpresa() != null ? u.getEmpresa().getId() : null;
        String accessToken = jwtUtil.generateAccessToken(u.getId(), u.getEmail(), u.getRol().name(), empresaId);
        String refreshToken = jwtUtil.generateRefreshToken(u.getId());

        Map<String, Object> response = new HashMap<>();
        response.put("accessToken", accessToken); response.put("refreshToken", refreshToken); response.put("tokenType", "Bearer");
        response.put("id", u.getId().toString()); response.put("nombre", u.getNombre()); response.put("email", u.getEmail());
        response.put("rol", u.getRol().name()); response.put("empresaNombre", u.getEmpresa() != null ? u.getEmpresa().getNombre() : null); response.put("empresaId", empresaId);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(@RequestBody Map<String, String> body) {
        String refreshToken = body.get("refreshToken");
        if (refreshToken == null || refreshToken.isBlank()) return ResponseEntity.badRequest().body(Map.of("message", "Refresh token requerido"));
        try {
            Long userId = jwtUtil.getUserIdFromToken(refreshToken);
            Usuario u = usuarioRepository.findById(userId).orElseThrow(() -> new RuntimeException("Usuario no encontrado"));
            Long empresaId = u.getEmpresa() != null ? u.getEmpresa().getId() : null;
            String newAccessToken = jwtUtil.generateAccessToken(u.getId(), u.getEmail(), u.getRol().name(), empresaId);
            String newRefreshToken = jwtUtil.generateRefreshToken(u.getId());
            return ResponseEntity.ok(Map.of("accessToken", newAccessToken, "refreshToken", newRefreshToken, "tokenType", "Bearer"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Refresh token invalido o expirado"));
        }
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequestDTO data) {
        if (usuarioRepository.findByEmail(data.getEmail()).isPresent()) return ResponseEntity.badRequest().body(Map.of("message", "El email ya esta registrado"));

        UserRole rol = data.getRol() == null ? UserRole.cliente : data.getRol();
        Empresa empresa = null;
        if (rol == UserRole.jefe || rol == UserRole.empleado) {
            if (data.getEmpresaNombre() == null || data.getEmpresaNombre().isBlank()) return ResponseEntity.badRequest().body(Map.of("message", "Debes indicar la empresa para jefe o empleado"));
            empresa = empresaRepository.findByNombreIgnoreCase(data.getEmpresaNombre().trim()).orElseGet(() -> rol == UserRole.jefe ? empresaRepository.save(new Empresa(null, data.getEmpresaNombre().trim(), null)) : null);
            if (empresa == null) throw new RuntimeException("La empresa no existe. Primero debe registrarla un jefe.");
        }
        if (rol == UserRole.cliente && data.getEmpresaNombre() != null && !data.getEmpresaNombre().isBlank()) empresa = empresaRepository.findByNombreIgnoreCase(data.getEmpresaNombre().trim()).orElseGet(() -> empresaRepository.save(new Empresa(null, data.getEmpresaNombre().trim(), null)));

        String token = UUID.randomUUID().toString();
        Usuario nuevo = new Usuario();
        nuevo.setNombre(data.getNombre()); nuevo.setEmail(data.getEmail()); nuevo.setPassword(passwordEncoder.encode(data.getPassword()));
        nuevo.setTelefono(data.getTelefono()); nuevo.setRol(rol); nuevo.setEmpresa(empresa);
        nuevo.setVerificado(false); nuevo.setVerificationToken(token); nuevo.setVerificationTokenExpiresAt(LocalDateTime.now().plusHours(24));
        Usuario guardado = usuarioRepository.save(nuevo);
        emailService.sendVerificationEmail(guardado.getEmail(), guardado.getNombre(), token);

        Map<String, Object> response = new HashMap<>();
        response.put("id", guardado.getId().toString()); response.put("nombre", guardado.getNombre()); response.put("email", guardado.getEmail());
        response.put("rol", guardado.getRol().name()); response.put("empresaNombre", guardado.getEmpresa() != null ? guardado.getEmpresa().getNombre() : null);
        response.put("empresaId", guardado.getEmpresa() != null ? guardado.getEmpresa().getId() : null); response.put("message", "Registro creado. Revisa tu correo para confirmar la cuenta.");
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping("/confirmar")
    public ResponseEntity<?> confirmar(@RequestParam String token) {
        Optional<Usuario> usuarioOpt = usuarioRepository.findByVerificationToken(token);
        if (usuarioOpt.isEmpty()) return ResponseEntity.badRequest().body(Map.of("message", "Token invalido o inexistente"));
        Usuario usuario = usuarioOpt.get();
        if (usuario.getVerificationTokenExpiresAt() != null && usuario.getVerificationTokenExpiresAt().isBefore(LocalDateTime.now())) return ResponseEntity.badRequest().body(Map.of("message", "El token ha expirado"));
        usuario.setVerificado(true); usuario.setVerificationToken(null); usuario.setVerificationTokenExpiresAt(null);
        usuarioRepository.save(usuario);
        return ResponseEntity.ok(Map.of("message", "Cuenta verificada correctamente"));
    }
}