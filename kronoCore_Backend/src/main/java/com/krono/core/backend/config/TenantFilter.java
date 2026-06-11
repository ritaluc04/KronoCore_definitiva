package com.krono.core.backend.config;

import com.krono.core.backend.util.TenantContext;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * FILTRO: TenantFilter
 * Filtro complementario que lee el contexto de empresa desde cabeceras HTTP.
 * 
 * FUNCIONAMIENTO:
 * - Cabecera X-Empresa-Id: permite que el frontend envíe el ID de empresa activa
 * - Cabecera X-User-Rol: rol del usuario
 * 
 * Este filtro es un soporte LEGACY. Actualmente la fuente principal de
 * multi-tenancy es el JWT (JwtAuthFilter extrae rol y empresaId del token).
 * Este filtro mantiene compatibilidad con frontends que aún no usan JWT
 * en todas las cabeceras.
 * 
 * Al finalizar, limpia TenantContext para no contaminar otros hilos.
 */
@Component
public class TenantFilter extends OncePerRequestFilter {

    public static final String HEADER_EMPRESA_ID = "X-Empresa-Id";
    public static final String HEADER_USER_ROL = "X-User-Rol";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        try {
            // Leer empresa de la cabecera (legacy)
            String empresaHeader = request.getHeader(HEADER_EMPRESA_ID);
            if (empresaHeader != null && !empresaHeader.isBlank()) {
                try {
                    TenantContext.setEmpresaId(Long.parseLong(empresaHeader.trim()));
                } catch (NumberFormatException ignored) {
                    // Cabecera inválida: se ignora sin error
                }
            }
            // Leer rol de la cabecera (legacy)
            String rol = request.getHeader(HEADER_USER_ROL);
            if (rol != null && !rol.isBlank()) {
                TenantContext.setUserRol(rol.trim());
            }
            filterChain.doFilter(request, response);
        } finally {
            TenantContext.clear();
        }
    }
}