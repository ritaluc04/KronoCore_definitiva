package com.krono.core.backend.repository;

import com.krono.core.backend.entity.Producto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

/** REPOSITORIO: ProductoRepository - Acceso a datos de productos (inventario) */
@Repository
public interface ProductoRepository extends JpaRepository<Producto, Long> {
    List<Producto> findByNombreContainingIgnoreCase(String nombre);
    List<Producto> findByStockLessThan(int cantidad);
    List<Producto> findByActivoTrue();
    List<Producto> findByEmpresaId(Long empresaId);
    List<Producto> findByEmpresaIdAndStockLessThanEqual(Long empresaId, int stockMin);

    /**
     * Consulta JPQL: productos de una empresa cuyo stock actual es menor o igual
     * al stock mínimo configurado. La comparación se hace en la BD (no en memoria).
     * Equivale a: SELECT * FROM producto WHERE empresa_id = ? AND stock <= stock_min
     */
    @Query("SELECT p FROM Producto p WHERE p.empresaId = :empresaId AND p.stock <= p.stockMin")
    List<Producto> findByEmpresaIdAndStockLessThanEqualStockMin(@Param("empresaId") Long empresaId);

    /**
     * Consulta JPQL: todos los productos (sin filtro de empresa) cuyo stock actual
     * es menor o igual al stock mínimo. Para administradores globales.
     * Equivale a: SELECT * FROM producto WHERE stock <= stock_min
     */
    @Query("SELECT p FROM Producto p WHERE p.stock <= p.stockMin")
    List<Producto> findAllWithStockBajo();
}
