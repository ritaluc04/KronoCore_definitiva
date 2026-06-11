-- Ejecutar UNA VEZ en tu servidor PostgreSQL (pgAdmin o psql conectado como postgres).
-- Spring Boot crea las TABLAS; la base de datos hay que crearla antes.

CREATE DATABASE kronocore
  WITH ENCODING 'UTF8'
       LC_COLLATE = 'Spanish_Spain.1252'
       LC_CTYPE = 'Spanish_Spain.1252'
       TEMPLATE template0;

-- Si el comando de collate falla en tu servidor, usa solo:
-- CREATE DATABASE kronocore;
