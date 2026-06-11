package com.krono.core.backend.dto.producto;

/**
 * DTO: ProductoRequestDTO
 * Objeto de transferencia de datos para las peticiones de producto.
 * 
 * Se usa en:
 * - POST /api/productos (crear)
 * - PUT /api/productos/{id} (actualizar)
 * 
 * Todos los campos son opcionales para permitir actualización parcial.
 * El backend solo sobreescribe los campos que vienen informados.
 */
public class ProductoRequestDTO {
    private String sku;
    private String nombre;
    private String categoria;
    private Double precio;
    private Integer stock;
    private Integer stockMin;
    private boolean activo;
    private Long empresaId;

    // Getters y setters
    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getCategoria() { return categoria; }
    public void setCategoria(String categoria) { this.categoria = categoria; }

    public Double getPrecio() { return precio; }
    public void setPrecio(Double precio) { this.precio = precio; }

    public Integer getStock() { return stock; }
    public void setStock(Integer stock) { this.stock = stock; }

    public Integer getStockMin() { return stockMin; }
    public void setStockMin(Integer stockMin) { this.stockMin = stockMin; }

    public boolean isActivo() { return activo; }
    public void setActivo(boolean activo) { this.activo = activo; }

    public Long getEmpresaId() { return empresaId; }
    public void setEmpresaId(Long empresaId) { this.empresaId = empresaId; }
}