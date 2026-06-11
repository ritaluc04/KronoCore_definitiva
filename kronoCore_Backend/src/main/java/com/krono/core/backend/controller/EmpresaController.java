package com.krono.core.backend.controller;

import com.krono.core.backend.entity.Empresa;
import com.krono.core.backend.repository.EmpresaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * CONTROLADOR: EmpresaController
 * Permite buscar empresas para el registro y solicitud de citas.
 * Ruta: GET /api/empresas?q=texto
 */
@RestController
@RequestMapping("/api/empresas")
@CrossOrigin(origins = "*")
public class EmpresaController {

    @Autowired
    private EmpresaRepository empresaRepository;

    @GetMapping
    public List<Empresa> listar(@RequestParam(required = false) String q) {
        if (q == null || q.isBlank()) return empresaRepository.findAll();
        return empresaRepository.findByNombreContainingIgnoreCase(q);
    }
}