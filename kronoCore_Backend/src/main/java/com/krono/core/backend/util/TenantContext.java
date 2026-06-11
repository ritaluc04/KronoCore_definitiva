package com.krono.core.backend.util;

/**
 * UTILIDAD: TenantContext
 * Almacena el contexto de empresa (multi-tenant) para el hilo actual de ejecución.
 * 
 * FUNCIONAMIENTO:
 * - Usa ThreadLocal para almacenar el empresaId y userRol de la petición actual
 * - El JwtAuthFilter extrae estos datos del JWT y los asigna aquí
 * - Los servicios usan shouldFilterByEmpresa() para saber si deben filtrar datos
 * - Se limpia al final de cada petición (finally block en los filtros)
 * 
 * Esto permite que un mismo servidor sirva a múltiples empresas sin que
 * se mezclen los datos, implementando el patrón multi-tenant.
 */
public class TenantContext {

    private static final ThreadLocal<Long> empresaIdHolder = new ThreadLocal<>();
    private static final ThreadLocal<String> userRolHolder = new ThreadLocal<>();

    public static void setEmpresaId(Long empresaId) {
        empresaIdHolder.set(empresaId);
    }

    public static Long getEmpresaId() {
        return empresaIdHolder.get();
    }

    public static void setUserRol(String rol) {
        userRolHolder.set(rol);
    }

    public static String getUserRol() {
        return userRolHolder.get();
    }

    /**
     * Determina si los datos deben filtrarse por empresa.
     * @return true si hay un empresaId en el contexto Y el usuario no es admin ni cliente
     */
    public static boolean shouldFilterByEmpresa() {
        Long empresaId = getEmpresaId();
        if (empresaId == null) return false;
        String rol = getUserRol();
        // Admin y cliente no filtran por empresa (admin ve todo, cliente ve sus datos)
        return !"admin".equals(rol) && !"cliente".equals(rol);
    }

    /**
     * Limpia el contexto del hilo actual. Debe llamarse al final de cada petición.
     */
    public static void clear() {
        empresaIdHolder.remove();
        userRolHolder.remove();
    }
}