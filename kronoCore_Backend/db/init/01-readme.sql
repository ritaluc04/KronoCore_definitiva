-- =============================================================================
-- Inicialización Docker (solo primer arranque del contenedor)
-- =============================================================================
-- La base de datos "kronocore" se crea automáticamente con POSTGRES_DB.
-- Las tablas las genera Hibernate al arrancar el backend con:
--   spring.jpa.hibernate.ddl-auto=update
-- y el perfil:  --spring.profiles.active=postgres
--
-- No hace falta crear tablas manualmente para empezar.
-- Para esquemas versionados en producción, valora Flyway o Liquibase más adelante.
-- =============================================================================

SELECT 1;
