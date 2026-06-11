package com.krono.core.backend.util;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * UTILIDAD: JwtUtil
 * Genera y valida tokens JWT para la autenticación de usuarios.
 * 
 * FUNCIONAMIENTO:
 * - Access Token: Duración corta (1 hora), contiene userId, email, rol y empresaId
 * - Refresh Token: Duración larga (7 días), solo contiene userId
 * 
 * El algoritmo usado es HMAC-SHA256 con una clave secreta configurable.
 * 
 * FLUJO TÍPICO:
 * 1. El usuario hace login → se generan Access + Refresh Token
 * 2. El frontend envía el Access Token en cada petición (Authorization: Bearer)
 * 3. Cuando el Access Token expira, el frontend usa el Refresh Token para obtener uno nuevo
 */
@Component
public class JwtUtil {

    private final SecretKey key;
    private final long accessTokenExpiration;
    private final long refreshTokenExpiration;

    /**
     * Constructor que inicializa la clave secreta y las duraciones de los tokens.
     * 
     * @param secret Clave secreta para firmar los JWT (configurable via jwt.secret)
     * @param accessExp Duración del Access Token en milisegundos (default: 1h)
     * @param refreshExp Duración del Refresh Token en milisegundos (default: 7d)
     */
    public JwtUtil(
            @Value("${jwt.secret:kronoCoreSecretKey2026SuperSecretDevToken}") String secret,
            @Value("${jwt.access-expiration:3600000}") long accessExp,
            @Value("${jwt.refresh-expiration:604800000}") long refreshExp
    ) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessTokenExpiration = accessExp;
        this.refreshTokenExpiration = refreshExp;
    }

    /**
     * Genera un Access Token con los datos del usuario.
     * 
     * @param userId ID del usuario
     * @param email Email del usuario
     * @param rol Rol del usuario (admin, jefe, empleado, cliente)
     * @param empresaId ID de la empresa (puede ser null para admin global)
     * @return Token JWT firmado
     */
    public String generateAccessToken(Long userId, String email, String rol, Long empresaId) {
        return Jwts.builder()
                .subject(userId.toString())
                .claim("email", email)
                .claim("rol", rol)
                .claim("empresaId", empresaId != null ? empresaId : 0)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + accessTokenExpiration))
                .signWith(key)
                .compact();
    }

    /**
     * Genera un Refresh Token con mayor duración que el Access Token.
     * Solo contiene el userId, no los claims completos.
     * 
     * @param userId ID del usuario
     * @return Token JWT firmado con 7 días de validez
     */
    public String generateRefreshToken(Long userId) {
        return Jwts.builder()
                .subject(userId.toString())
                .claim("type", "refresh")
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + refreshTokenExpiration))
                .signWith(key)
                .compact();
    }

    /**
     * Valida un token y devuelve sus claims.
     * Lanza una excepción si el token es inválido o ha expirado.
     * 
     * @param token Token JWT a validar
     * @return Claims del token
     * @throws JwtException si el token es inválido
     */
    public Claims validateToken(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /**
     * Extrae el userId almacenado en el subject del token.
     * 
     * @param token Token JWT
     * @return ID del usuario
     */
    public Long getUserIdFromToken(String token) {
        return Long.parseLong(validateToken(token).getSubject());
    }

    /**
     * Extrae el rol del usuario desde los claims del token.
     * 
     * @param token Token JWT
     * @return Rol del usuario (admin, jefe, empleado, cliente)
     */
    public String getRolFromToken(String token) {
        return validateToken(token).get("rol", String.class);
    }

    /**
     * Extrae el empresaId desde los claims del token.
     * 
     * @param token Token JWT
     * @return ID de la empresa, o null si es admin global
     */
    public Long getEmpresaIdFromToken(String token) {
        Number empId = validateToken(token).get("empresaId", Number.class);
        return empId != null && empId.longValue() > 0 ? empId.longValue() : null;
    }
}