package com.krono.core.backend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * CONFIGURACIÓN: WebConfig
 * Configura CORS (Cross-Origin Resource Sharing) para la API REST.
 * 
 * Permite que el frontend web (en un puerto diferente) y la app Flutter
 * puedan comunicarse con el backend sin ser bloqueados por el navegador.
 * 
 * En desarrollo se permite cualquier origen (*). En producción se debe
 * restringir a los dominios reales por seguridad.
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("*")          // Permitir cualquier origen (desarrollo)
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*");
    }
}