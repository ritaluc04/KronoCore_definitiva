package com.krono.core.backend.config;

import com.krono.core.backend.entity.*;
import com.krono.core.backend.entity.enums.*;
import com.krono.core.backend.repository.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.List;

/**
 * CONFIGURACIÓN: DataSeeder
 * Carga datos de ejemplo al arrancar la aplicación si la BD está vacía.
 * 
 * DATOS CARGADOS:
 * - 3 empresas (Salón Krono Madrid, Krono Beauty Center, Studio Uñas Krono)
 * - 4 clientes con etiquetas (VIP, Frecuente, Nuevo)
 * - 7 usuarios (admin, 2 jefes, 2 empleados, 2 clientes)
 * - 6 productos con stocks variados (algunos bajo mínimo para probar alertas)
 * - 5 citas en diferentes estados
 * - 5 tareas con diferentes prioridades
 * - 3 ventas con detalles
 * - 3 facturas (pagadas/emitidas)
 * - 5 gastos categorizados
 * 
 * SOLO SE EJECUTA SI NO HAY USUARIOS: usuarioRepository.count() == 0
 * Esto evita duplicar datos en PostgreSQL (que persiste entre reinicios).
 */
@Configuration
public class DataSeeder {

    @Bean
    CommandLineRunner seedData(
            UsuarioRepository usuarioRepository, EmpresaRepository empresaRepository,
            ClienteRepository clienteRepository, ProductoRepository productoRepository,
            CitaRepository citaRepository, TareaRepository tareaRepository,
            VentaRepository ventaRepository, FacturaRepository facturaRepository,
            GastoRepository gastoRepository) {
        return args -> {
            if (usuarioRepository.count() > 0) return; // No duplicar datos
            PasswordEncoder encoder = new BCryptPasswordEncoder();

            // Crear empresas
            Empresa salonUno = empresaRepository.save(new Empresa(null, "Salón Krono Madrid", "910 111 222"));
            Empresa salonDos = empresaRepository.save(new Empresa(null, "Krono Beauty Center", "910 333 444"));
            Empresa salonTres = empresaRepository.save(new Empresa(null, "Studio Uñas Krono", "910 555 666"));

            // Crear clientes con etiquetas
            Cliente clienteAna = guardarCliente(clienteRepository, salonUno.getId(), "Ana", "Pérez", "ana.perez@mail.com", "612345678", List.of("VIP", "Mensual"), LocalDateTime.now().minusDays(3));
            Cliente clienteLuis = guardarCliente(clienteRepository, salonUno.getId(), "Luis", "Martín", "luis.martin@mail.com", "622113998", List.of("Nuevo"), LocalDateTime.now().minusDays(12));
            Cliente clienteMaria = guardarCliente(clienteRepository, salonUno.getId(), "María", "Ruiz", "maria.ruiz@mail.com", "633552211", List.of("VIP"), LocalDateTime.now().minusDays(1));
            Cliente clienteCarlos = guardarCliente(clienteRepository, salonDos.getId(), "Carlos", "Vega", "carlos.vega@mail.com", "644887002", List.of(), LocalDateTime.now().minusDays(30));

            // Crear usuarios (contraseña: 123456)
            usuarioRepository.save(new Usuario(null, "Admin Krono", "admin@krono.dev", encoder.encode("123456"), "600000000", UserRole.admin, null, true, null, null, "A"));
            usuarioRepository.save(new Usuario(null, "Marta Vidal", "marta@krono.dev", encoder.encode("123456"), "611111111", UserRole.jefe, salonUno, true, null, null, "M"));
            usuarioRepository.save(new Usuario(null, "David López", "david@krono.dev", encoder.encode("123456"), "622222222", UserRole.empleado, salonUno, true, null, null, "D"));
            usuarioRepository.save(new Usuario(null, "Carla Ruiz", "carla@krono.dev", encoder.encode("123456"), "633333333", UserRole.empleado, salonDos, true, null, null, "C"));
            usuarioRepository.save(new Usuario(null, "Nuria Nails", "nuria@krono.dev", encoder.encode("123456"), "633444444", UserRole.jefe, salonTres, true, null, null, "N"));
            usuarioRepository.save(new Usuario(null, "Pedro Bel", "pedro@krono.dev", encoder.encode("123456"), "644444444", UserRole.cliente, null, true, null, null, "P"));
            usuarioRepository.save(new Usuario(null, "Lucía Gómez", "lucia@krono.dev", encoder.encode("123456"), "655555555", UserRole.cliente, salonUno, true, null, null, "L"));

            // Crear productos con stock variado
            Producto champu = guardarProducto(productoRepository, salonUno.getId(), "SH-001", "Champú profesional 500ml", "Cuidado", 12.50, 24, 5, true);
            Producto acond = guardarProducto(productoRepository, salonUno.getId(), "SH-002", "Acondicionador 500ml", "Cuidado", 11.00, 4, 5, true);
            Producto tinte = guardarProducto(productoRepository, salonUno.getId(), "TI-010", "Tinte castaño nº4", "Color", 8.50, 2, 6, true);
            Producto spray = guardarProducto(productoRepository, salonDos.getId(), "AC-001", "Spray fijador 300ml", "Acabado", 7.20, 22, 5, true);
            Producto secador = guardarProducto(productoRepository, salonDos.getId(), "HE-001", "Secador profesional", "Herramientas", 89.00, 3, 2, true);
            Producto esmalte = guardarProducto(productoRepository, salonTres.getId(), "UN-001", "Esmalte gel rojo", "Uñas", 6.50, 40, 10, true);

            // Crear citas
            guardarCita(citaRepository, clienteAna, salonUno, "Corte + peinado", "Marta", LocalDateTime.now().plusHours(2), 45, CitaEstado.confirmada);
            guardarCita(citaRepository, clienteMaria, salonUno, "Color completo", "Marta", LocalDateTime.now().plusDays(1).withHour(10).withMinute(30), 120, CitaEstado.pendiente);
            guardarCita(citaRepository, clienteLuis, salonUno, "Corte", "David", LocalDateTime.now().plusHours(4), 30, CitaEstado.confirmada);
            guardarCita(citaRepository, clienteCarlos, salonDos, "Tratamiento", "Carla", LocalDateTime.now().plusDays(2).withHour(16).withMinute(0), 60, CitaEstado.cancelada);
            guardarCita(citaRepository, clienteAna, salonTres, "Manicura gel", "Nuria", LocalDateTime.now().plusDays(3).withHour(11).withMinute(0), 60, CitaEstado.pendiente);

            // Crear tareas
            guardarTarea(tareaRepository, salonUno.getId(), "Hacer pedido de tintes", "Tinte castaño y rubio bajo mínimo", "Marta", TareaPrioridad.alta, TareaEstado.pendiente, LocalDateTime.now().plusDays(2));
            guardarTarea(tareaRepository, salonUno.getId(), "Llamar al proveedor de champú", "Renegociar precios anuales", "Admin", TareaPrioridad.media, TareaEstado.pendiente, null);
            guardarTarea(tareaRepository, salonUno.getId(), "Publicar promo Black Friday", "Diseñar cartel + redes", "David", TareaPrioridad.media, TareaEstado.enProceso, null);
            guardarTarea(tareaRepository, salonDos.getId(), "Limpieza profunda salón", "Sábado por la tarde", "Marta", TareaPrioridad.baja, TareaEstado.enProceso, null);
            guardarTarea(tareaRepository, salonTres.getId(), "Pedido esmaltes temporada", "Colores otoño", "Nuria", TareaPrioridad.alta, TareaEstado.finalizado, null);

            // Crear ventas con detalles
            Venta v1 = new Venta(null, clienteAna.getId(), clienteAna.getNombre() + " " + clienteAna.getApellidos(), salonUno.getId(), LocalDateTime.now().minusDays(1).withHour(19).withMinute(30), 23.1, 4.85, 27.95, List.of(new VentaDetalle(null, champu.getId(), champu.getNombre(), 1, champu.getPrecio(), champu.getPrecio())));
            Venta v2 = new Venta(null, clienteMaria.getId(), clienteMaria.getNombre() + " " + clienteMaria.getApellidos(), salonUno.getId(), LocalDateTime.now().minusDays(2).withHour(13).withMinute(10), 30.0, 6.3, 36.3, List.of(new VentaDetalle(null, tinte.getId(), tinte.getNombre(), 3, tinte.getPrecio(), tinte.getPrecio() * 3)));
            Venta v3 = new Venta(null, clienteLuis.getId(), clienteLuis.getNombre() + " " + clienteLuis.getApellidos(), salonDos.getId(), LocalDateTime.now().minusHours(8), 18.2, 3.82, 22.02, List.of(new VentaDetalle(null, spray.getId(), spray.getNombre(), 2, spray.getPrecio(), spray.getPrecio() * 2)));
            ventaRepository.save(v1); ventaRepository.save(v2); ventaRepository.save(v3);

            // Crear facturas
            LocalDateTime ahora = LocalDateTime.now();
            facturaRepository.save(new Factura(null, "F-2026-0001", v1.getId(), salonUno.getId(), clienteAna.getId(), clienteAna.getNombre() + " " + clienteAna.getApellidos(), "12345678A", salonUno.getNombre(), "B-87654321", "C/ Mayor 1, Madrid", 23.10, 21.0, 4.85, 27.95, "pagada", "tarjeta", ahora.minusDays(1), ahora.plusDays(15), ahora.minusDays(1)));
            facturaRepository.save(new Factura(null, "F-2026-0002", v2.getId(), salonUno.getId(), clienteMaria.getId(), clienteMaria.getNombre() + " " + clienteMaria.getApellidos(), "87654321B", salonUno.getNombre(), "B-87654321", "C/ Mayor 1, Madrid", 30.00, 21.0, 6.30, 36.30, "emitida", "transferencia", ahora.minusDays(2), ahora.plusDays(13), null));
            facturaRepository.save(new Factura(null, "F-2026-0003", v3.getId(), salonDos.getId(), clienteLuis.getId(), clienteLuis.getNombre() + " " + clienteLuis.getApellidos(), "11223344C", salonDos.getNombre(), "B-11223344", "Av. Central 45, Madrid", 18.20, 21.0, 3.82, 22.02, "pagada", "efectivo", ahora.minusHours(8), ahora.plusDays(29), ahora.minusHours(2)));

            // Crear gastos
            gastoRepository.save(new Gasto(null, salonUno.getId(), "alquiler", "Alquiler local mes actual", "Inmobiliaria Centro", "ALQ-2026-03", 800.00, 21.0, 168.00, 968.00, "transferencia", true, ahora.withDayOfMonth(1), ahora));
            gastoRepository.save(new Gasto(null, salonUno.getId(), "suministros", "Factura luz marzo", "Iberdrola", "LUZ-03-2026", 145.00, 21.0, 30.45, 175.45, "transferencia", true, ahora.withDayOfMonth(5), ahora));
            gastoRepository.save(new Gasto(null, salonUno.getId(), "proveedores", "Pedido tintes profesionales", "L'Oréal Profesional", "PED-4567", 320.00, 21.0, 67.20, 387.20, "transferencia", true, ahora.minusDays(3), ahora));
            gastoRepository.save(new Gasto(null, salonDos.getId(), "marketing", "Anuncio Instagram mes", "Meta Ads", "META-03", 150.00, 21.0, 31.50, 181.50, "tarjeta", true, ahora.withDayOfMonth(2), ahora));
            gastoRepository.save(new Gasto(null, salonDos.getId(), "suministros", "Agua y limpieza", "Gestión Aguas", "AG-03", 65.00, 10.0, 6.50, 71.50, "transferencia", true, ahora.withDayOfMonth(8), ahora));
        };
    }

    private static Cliente guardarCliente(ClienteRepository repo, Long empresaId, String nombre, String apellidos, String email, String telefono, List<String> etiquetas, LocalDateTime ultimaCita) {
        Cliente c = new Cliente(); c.setNombre(nombre); c.setApellidos(apellidos); c.setEmail(email); c.setTelefono(telefono); c.setEtiquetas(etiquetas); c.setUltimaCita(ultimaCita); c.setEmpresaId(empresaId); return repo.save(c);
    }

    private static Producto guardarProducto(ProductoRepository repo, Long empresaId, String sku, String nombre, String categoria, double precio, int stock, int stockMin, boolean activo) {
        Producto p = new Producto(); p.setSku(sku); p.setNombre(nombre); p.setCategoria(categoria); p.setPrecio(precio); p.setStock(stock); p.setStockMin(stockMin); p.setActivo(activo); p.setEmpresaId(empresaId); return repo.save(p);
    }

    private static void guardarCita(CitaRepository repo, Cliente cliente, Empresa empresa, String servicio, String empleado, LocalDateTime inicio, int duracion, CitaEstado estado) {
        Cita c = new Cita(); c.setClienteId(cliente.getId()); c.setClienteNombre(cliente.getNombre() + " " + cliente.getApellidos()); c.setServicio(servicio); c.setEmpleado(empleado); c.setEmpresaNombre(empresa.getNombre()); c.setEmpresaId(empresa.getId()); c.setInicio(inicio); c.setDuracionMinutos(duracion); c.setEstado(estado); repo.save(c);
    }

    private static void guardarTarea(TareaRepository repo, Long empresaId, String titulo, String descripcion, String asignado, TareaPrioridad prioridad, TareaEstado estado, LocalDateTime fechaLimite) {
        Tarea t = new Tarea(); t.setTitulo(titulo); t.setDescripcion(descripcion); t.setAsignado(asignado); t.setPrioridad(prioridad); t.setEstado(estado); t.setFechaLimite(fechaLimite); t.setEmpresaId(empresaId); repo.save(t);
    }
}