package com.krono.core.backend.controller;

import com.krono.core.backend.entity.*;
import com.krono.core.backend.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

/**
 * CONTROLADOR: ReporteController
 * Genera exportaciones CSV para clientes, citas, ventas y tareas.
 * Ruta: /api/reportes/...
 * Filtros opcionales: estado, prioridad, rango de fechas (desde/hasta)
 */
@RestController
@RequestMapping("/api/reportes")
@CrossOrigin(origins = "*")
public class ReporteController {

    @Autowired private ClienteService clienteService;
    @Autowired private CitaService citaService;
    @Autowired private VentaService ventaService;
    @Autowired private TareaService tareaService;

    @GetMapping(value = "/clientes", produces = "text/csv")
    public ResponseEntity<byte[]> exportarClientes() { return csv("clientes", csvClientes(clienteService.listarClientes())); }

    @GetMapping(value = "/citas", produces = "text/csv")
    public ResponseEntity<byte[]> exportarCitas(@RequestParam(required = false) String estado, @RequestParam(required = false) String desde, @RequestParam(required = false) String hasta) {
        return csv("citas", csvCitas(filtrarCitas(estado, desde, hasta)));
    }

    @GetMapping(value = "/ventas", produces = "text/csv")
    public ResponseEntity<byte[]> exportarVentas(@RequestParam(required = false) String desde, @RequestParam(required = false) String hasta) {
        return csv("ventas", csvVentas(filtrarVentas(desde, hasta)));
    }

    @GetMapping(value = "/tareas", produces = "text/csv")
    public ResponseEntity<byte[]> exportarTareas(@RequestParam(required = false) String estado, @RequestParam(required = false) String prioridad) {
        return csv("tareas", csvTareas(filtrarTareas(estado, prioridad)));
    }

    private List<Cita> filtrarCitas(String estado, String desde, String hasta) {
        return citaService.listarCitas().stream()
                .filter(c -> estado == null || estado.isBlank() || c.getEstado().name().equalsIgnoreCase(estado))
                .filter(c -> dentroDeRango(c.getInicio() == null ? null : c.getInicio().toLocalDate(), desde, hasta))
                .sorted(Comparator.comparing(Cita::getInicio, Comparator.nullsLast(Comparator.naturalOrder()))).collect(Collectors.toList());
    }

    private List<Venta> filtrarVentas(String desde, String hasta) {
        return ventaService.listarVentas().stream()
            .filter(v -> dentroDeRango(v.getFecha() == null ? null : v.getFecha().atZone(ZoneId.systemDefault()).toLocalDate(), desde, hasta))
            .sorted(Comparator.comparing(Venta::getFecha, Comparator.nullsLast(Comparator.naturalOrder()))).collect(Collectors.toList());
    }

    private List<Tarea> filtrarTareas(String estado, String prioridad) {
        return tareaService.listarTareas().stream()
                .filter(t -> estado == null || estado.isBlank() || t.getEstado().name().equalsIgnoreCase(estado))
                .filter(t -> prioridad == null || prioridad.isBlank() || t.getPrioridad().name().equalsIgnoreCase(prioridad))
                .sorted(Comparator.comparing(Tarea::getFechaLimite, Comparator.nullsLast(Comparator.naturalOrder()))).collect(Collectors.toList());
    }

    private boolean dentroDeRango(LocalDate fecha, String desde, String hasta) {
        if (fecha == null) return true;
        if (desde != null && !desde.isBlank() && fecha.isBefore(LocalDate.parse(desde))) return false;
        if (hasta != null && !hasta.isBlank() && fecha.isAfter(LocalDate.parse(hasta))) return false;
        return true;
    }

    private ResponseEntity<byte[]> csv(String nombre, String contenido) {
        byte[] bytes = contenido.getBytes(StandardCharsets.UTF_8);
        return ResponseEntity.ok().header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + nombre + ".csv\"").contentType(new MediaType("text", "csv", StandardCharsets.UTF_8)).body(bytes);
    }

    private String csvClientes(List<Cliente> clientes) {
        StringBuilder sb = new StringBuilder("id,nombre,apellidos,email,telefono\n");
        for (Cliente c : clientes) sb.append(csv(c.getId())).append(',').append(csv(c.getNombre())).append(',').append(csv(c.getApellidos())).append(',').append(csv(c.getEmail())).append(',').append(csv(c.getTelefono())).append('\n');
        return sb.toString();
    }
    private String csvCitas(List<Cita> citas) {
        StringBuilder sb = new StringBuilder("id,cliente,servicio,empleado,estado,inicio,duracion\n");
        for (Cita c : citas) sb.append(csv(c.getId())).append(',').append(csv(c.getClienteNombre())).append(',').append(csv(c.getServicio())).append(',').append(csv(c.getEmpleado())).append(',').append(csv(c.getEstado() == null ? "" : c.getEstado().name())).append(',').append(csv(c.getInicio() == null ? "" : c.getInicio().toString())).append(',').append(csv(c.getDuracionMinutos())).append('\n');
        return sb.toString();
    }
    private String csvVentas(List<Venta> ventas) {
        StringBuilder sb = new StringBuilder("id,cliente,subtotal,iva,total,fecha\n");
        for (Venta v : ventas) sb.append(csv(v.getId())).append(',').append(csv(v.getClienteNombre())).append(',').append(csv(v.getSubtotal())).append(',').append(csv(v.getIva())).append(',').append(csv(v.getTotal())).append(',').append(csv(v.getFecha() == null ? "" : v.getFecha().toString())).append('\n');
        return sb.toString();
    }
    private String csvTareas(List<Tarea> tareas) {
        StringBuilder sb = new StringBuilder("id,titulo,descripcion,asignado,estado,prioridad,fechaLimite,color,imagenUrl\n");
        for (Tarea t : tareas) sb.append(csv(t.getId())).append(',').append(csv(t.getTitulo())).append(',').append(csv(t.getDescripcion())).append(',').append(csv(t.getAsignado())).append(',').append(csv(t.getEstado() == null ? "" : t.getEstado().name())).append(',').append(csv(t.getPrioridad() == null ? "" : t.getPrioridad().name())).append(',').append(csv(t.getFechaLimite() == null ? "" : t.getFechaLimite().toString())).append(',').append(csv(t.getColor())).append(',').append(csv(t.getImagenUrl())).append('\n');
        return sb.toString();
    }

    private String csv(Object value) {
        if (value == null) return "";
        String s = String.valueOf(value).replace("\"", "\"\"");
        return "\"" + s + "\"";
    }
}