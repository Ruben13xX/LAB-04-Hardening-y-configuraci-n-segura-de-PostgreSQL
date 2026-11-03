-- LAB-04 | 01-inspeccion.sql
-- Estado INICIAL del servidor

SELECT version();
SHOW port;
SHOW listen_addresses;
SHOW ssl;
SHOW password_encryption;

SELECT pid, usename, datname, client_addr, client_port, application_name
FROM pg_stat_activity;

-- Archivos y directorios
SHOW config_file;
SHOW hba_file;
SHOW ident_file;
SHOW data_directory;
SHOW log_directory;
SHOW log_connections;
SHOW log_disconnections;

-- Reglas de pg_hba.conf
SELECT line_number, type, database, user_name, address, netmask, auth_method
FROM pg_hba_file_rules
ORDER BY line_number;

-- Extensiones
SELECT extname, extversion FROM pg_extension ORDER BY extname;

-- Parametros de conexion
SHOW max_connections;
SHOW superuser_reserved_connections;
SHOW statement_timeout;
SHOW idle_in_transaction_session_timeout;

-- TLS
SHOW ssl_min_protocol_version;
SELECT pid, usename, client_addr, ssl, version, cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();
