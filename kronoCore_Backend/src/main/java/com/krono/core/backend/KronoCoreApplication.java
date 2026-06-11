package com.krono.core.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * CLASE PRINCIPAL: KronoCoreApplication
 * Punto de entrada de la aplicación Spring Boot.
 * Configura el contexto de la aplicación y arranca el servidor embebido.
 */
@SpringBootApplication
public class KronoCoreApplication {
    public static void main(String[] args) {
        SpringApplication.run(KronoCoreApplication.class, args);
    }
}
