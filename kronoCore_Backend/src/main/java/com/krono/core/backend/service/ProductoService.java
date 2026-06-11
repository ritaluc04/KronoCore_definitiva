package com.krono.core.backend.service;

import com.krono.core.backend.dto.producto.ProductoRequestDTO;
import com.krono.core.backend.entity.Producto;
import com.krono.core.backend.repository.ProductoRepository;
import com.krono.core.backend.validator.ProductoValidator;
import com.krono.core.backend.util.ApiResponse;
import com.krono.core.backend.util.TenantContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * SERVICIO: ProductoService
 * Gestiona el inventario de productos del negocio.
 * 
 * Responsabilidades:
 * - CRUD completo de productos (crear, leer, actualizar, eliminar)
 * - Control de stock bajo (alertas cuando stock <= stockMin)
 * - Filtrado por empresa (multi-tenant)
 * - Validación de datos antes de guardar (precios, stocks)
 * 
 * El flujo típico es:
 * 1. El controlador recibe una petición HTTP
 * 2. El servicio procesa la lógica de negocio
 * 3. El repositorio accede a la base de datos
 * 4. Se devuelve el resultado al controlador
 */
@Service
public class ProductoService {

    @Autowired
    private ProductoRepository productoRepository;

    @Autowired
    private ProductoValidator productoValidator;

    /**
     * Lista todos los productos disponibles en el inventario.
     * Si el usuario tiene un contexto de empresa (jefe/empleado),
     * filtra solo los productos de esa empresa.
     * 
     * @return Lista de productos
     */
    public List<Producto> listarProductos() {
        if (TenantContext.shouldFilterByEmpresa()) {
            return productoRepository.findByEmpresaId(TenantContext.getEmpresaId());
        }
        return productoRepository.findAll();
    }

    /**
     * Obtiene un producto específico por su ID.
     * Lanza una excepción si no existe.
     * 
     * @param id ID del producto
     * @return Producto encontrado
     * @throws RuntimeException si el producto no existe
     */
    public Producto obtenerPorId(Long id) {
        return productoRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Producto no encontrado"));
    }

    /**
     * Registra un nuevo producto en el catálogo.
     * Primero valida los datos (precio > 0, stock >= 0, etc.),
     * luego asigna la empresa del contexto si existe.
     * 
     * @param dto Datos del producto a crear
     * @return Producto creado con su ID asignado
     */
    public Producto crearProducto(ProductoRequestDTO dto) {
        // Validar los datos antes de crear
        ApiResponse<?> error = productoValidator.validarProducto(dto);
        if (error != null) {
            throw new RuntimeException(error.getMessage());
        }

        Producto producto = new Producto();
        producto.setSku(dto.getSku());
        producto.setNombre(dto.getNombre());
        producto.setCategoria(dto.getCategoria());
        producto.setPrecio(dto.getPrecio());
        producto.setStock(dto.getStock());
        producto.setStockMin(dto.getStockMin());
        producto.setActivo(dto.isActivo());
        
        // Asignar la empresa del usuario si está autenticado en ese contexto
        if (TenantContext.shouldFilterByEmpresa()) {
            producto.setEmpresaId(TenantContext.getEmpresaId());
        }

        return productoRepository.save(producto);
    }

    /**
     * Actualiza los datos de un producto existente.
     * Busca el producto por ID, luego sobreescribe los campos
     * con los valores del DTO.
     * 
     * @param id ID del producto a actualizar
     * @param dto Nuevos datos del producto
     * @return Producto actualizado
     */
    public Producto actualizarProducto(Long id, ProductoRequestDTO dto) {
        Producto producto = obtenerPorId(id);
        
        // Validar los nuevos datos
        ApiResponse<?> error = productoValidator.validarProducto(dto);
        if (error != null) {
            throw new RuntimeException(error.getMessage());
        }

        producto.setSku(dto.getSku());
        producto.setNombre(dto.getNombre());
        producto.setCategoria(dto.getCategoria());
        producto.setPrecio(dto.getPrecio());
        producto.setStock(dto.getStock());
        producto.setStockMin(dto.getStockMin());
        producto.setActivo(dto.isActivo());

        return productoRepository.save(producto);
    }

    /**
     * Descuenta una cantidad del stock de un producto.
     * Se usa al registrar una venta para mantener el inventario sincronizado.
     * 
     * @param productoId ID del producto al que descontar stock
     * @param cantidad Cantidad a descontar (debe ser positiva)
     * @throws RuntimeException si el producto no existe o el stock es insuficiente
     */
    public void descontarStock(Long productoId, Integer cantidad) {
        Producto producto = obtenerPorId(productoId);
        
        if (cantidad <= 0) {
            throw new RuntimeException("La cantidad a descontar debe ser positiva");
        }
        
        if (producto.getStock() < cantidad) {
            throw new RuntimeException("Stock insuficiente para el producto: " + producto.getNombre());
        }
        
        producto.setStock(producto.getStock() - cantidad);
        productoRepository.save(producto);
    }

    /**
     * Obtiene los productos con stock igual o inferior al mínimo.
     * Se usa para generar alertas de stock bajo en el dashboard.
     * 
     * La consulta se realiza directamente en la base de datos usando
     * el método del repositorio findByEmpresaIdAndStockLessThanEqual,
     * que genera un WHERE stock <= stockMin en SQL, evitando cargar
     * todos los productos en memoria para filtrarlos.
     * 
     * Si no hay contexto de empresa (admin global), usa una consulta
     * JPQL personalizada para filtrar stock <= stockMin en toda la BD.
     * 
     * @return Lista de productos con stock crítico (stock <= stockMin)
     */
    public List<Producto> listarStockBajo() {
        if (TenantContext.shouldFilterByEmpresa()) {
            // Consulta SQL directa: WHERE empresa_id = ? AND stock <= stock_min
            return productoRepository.findByEmpresaIdAndStockLessThanEqualStockMin(TenantContext.getEmpresaId());
        }
        // Sin filtro de empresa: todos los productos con stock bajo
        return productoRepository.findAllWithStockBajo();
    }

    /**
     * Elimina un producto del inventario de forma permanente.
     * 
     * @param id ID del producto a eliminar
     */
    public void eliminarProducto(Long id) {
        productoRepository.deleteById(id);
    }
}