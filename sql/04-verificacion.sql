-- LAB-04 | 04-verificacion.sql

SHOW ssl;
SHOW ssl_min_protocol_version;

-- Inspección uniendo la sesion actual
SELECT 
    a.pid,
    a.usename,
    a.client_addr,
    s.ssl,
    s.version,
    s.cipher
FROM pg_stat_ssl s
JOIN pg_stat_activity a ON s.pid = a.pid
WHERE s.pid = pg_backend_pid();