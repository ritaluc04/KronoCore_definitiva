package com.krono.core.backend.config;

import com.krono.core.backend.util.JwtUtil;
import com.krono.core.backend.util.TenantContext;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * FILTRO: JwtAuthFilter
 * Intercepta todas las peticiones HTTP y valida el token JWT.
 * 
 * FLUJO:
 * 1. Extrae el token del header "Authorization: Bearer <token>"
 * 2. Valida el token usando JwtUtil.validateToken()
 * 3. Extrae claims: rol y empresaId del token
 * 4. Asigna los valores a TenantContext para el multi-tenant
 * 5. Si el token es inválido, simplemente no asigna contexto (continúa sin autenticación)
 * 6. Al finalizar la petición (finally), limpia TenantContext
 * 
 * Este filtro se ejecuta UNA VEZ por petición (OncePerRequestFilter)
 * y no bloquea peticiones sin token (las deja pasar para que
 * los endpoints públicos como /api/auth/login funcionen).
 */
@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

    public JwtAuthFilter(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String authHeader = request.getHeader("Authorization");

        // Extraer y validar JWT si existe en la cabecera
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7); // Quitar "Bearer "
            try {
                var claims = jwtUtil.validateToken(token);
                String rol = claims.get("rol", String.class);
                Number empIdNumber = claims.get("empresaId", Number.class);
                Long empresaId = empIdNumber != null && empIdNumber.longValue() > 0
                        ? empIdNumber.longValue() : null;

                // Asignar contexto para multi-tenant
                TenantContext.setUserRol(rol);
                if (empresaId != null) {
                    TenantContext.setEmpresaId(empresaId);
                }
            } catch (Exception e) {
                // Token inválido: se ignora y no se asigna contexto
                // Los endpoints protegidos devolverán 401 si no hay contexto
            }
        }

        try {
            filterChain.doFilter(request, response);
        } finally {
            // IMPORTANTE: Limpiar el contexto al finalizar para no contaminar otros hilos
            TenantContext.clear();
        }
    }
}