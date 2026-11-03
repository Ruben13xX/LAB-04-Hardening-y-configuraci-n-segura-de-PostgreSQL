-- LAB-04 | 03-configuracion.sql

-- Límites de conexiones y tiempos de espera 
SHOW max_connections;
SHOW superuser_reserved_connections;
SHOW statement_timeout;
SHOW idle_in_transaction_session_timeout;

-- Auditoría de extensiones instaladas en el motor 
SELECT 
    extname, 
    extversion 
FROM pg_extension 
ORDER BY extname;