# Linea base de seguridad — PostgreSQL 14

**Alumno:** Jesus Ruben Monzon Garcia | **Grupo:** 4-3
**Materia:** Gestion de Seguridad y Fundamentos de Base de Datos

## 1. Red
| Elemento | Valor de referencia |
|---|---|
| Interfaces | `localhost` + IP privada del servidor (10.10.10.20) solo si hay clientes remotos reales |
| Puerto | 5432, documentado y no expuesto a Internet |
| Firewall | Permitir 10.10.10.0/24 -> 5432/tcp; denegar el resto |
| Redes permitidas | Solo la red DBA / red de la aplicacion |
| Segmentacion | Servidor en red privada, sin IP publica |

## 2. Autenticacion
| Elemento | Valor |
|---|---|
| Metodo | scram-sha-256 para conexiones de red; peer para administracion local |
| Metodos prohibidos | trust, password (texto claro), md5 salvo compatibilidad justificada |
| Credenciales | Contrasenas largas y unicas por cuenta, fuera del repositorio y del codigo |
| Cuentas administrativas | Solo para DBA, nunca para aplicaciones |

## 3. Autorizacion
| Cuenta | Proposito | Privilegios |
|---|---|---|
| dba | Administracion | Administrativos, uso restringido y auditado |
| app_user | Aplicacion | SELECT/INSERT/UPDATE/DELETE sobre sus tablas |
| consulta_user | Reportes | Solo SELECT |

- Sin SUPERUSER, CREATEROLE ni CREATEDB para cuentas de aplicacion.
- REVOKE de privilegios a PUBLIC en base de datos y esquema public.

## 4. Configuracion
| Parametro | Valor |
|---|---|
| password_encryption | scram-sha-256 |
| log_connections / log_disconnections | on |
| idle_in_transaction_session_timeout | 5min |
| statement_timeout | 60s (ajustar segun la carga) |
| superuser_reserved_connections | 3 |
| max_connections | segun necesidad real (no sobredimensionar) |
| Extensiones | Solo las necesarias, revisadas y documentadas |

## 5. Sistema operativo
- Propietario: `postgres:postgres` en archivos de configuracion y datos.
- `postgresql.conf`, `pg_hba.conf`, `pg_ident.conf`: 640 (o 600).
- Directorio de datos: 700.
- Sin acceso de lectura para otros usuarios del sistema.

## 6. Cifrado
- `ssl = on`, `ssl_min_protocol_version = TLSv1.2`.
- Certificado y llave con permisos restrictivos (llave 600).
- Clientes con `sslmode=verify-full` cuando haya certificado de CA.
- Contrasenas almacenadas como hash SCRAM, no como cifrado reversible.
- Datos sensibles: cifrado a nivel de columna o disco segun lo visto en LAB-02.

## 7. Mantenimiento
- Aplicar actualizaciones menores de PostgreSQL 14 de forma periodica y documentar la politica.
- Revisar pg_hba.conf, roles y extensiones cada trimestre.
- Revisar logs de conexion y fallos de autenticacion.
- Todo cambio se registra en `cambios.md` con respaldo previo.
