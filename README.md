# LAB-04 — Hardening y configuración segura de PostgreSQL

**Alumno:** Jesus Ruben Monzon Garcia
**Grupo y grado:** 4-3
**Materia:** Gestion de Seguridad y Fundamentos de Base de Datos
**Fecha:** 02/11/2026

## Objetivo
Aplicar un proceso basico de hardening a una instancia PostgreSQL 14 de laboratorio: identificar configuraciones inseguras, reducir la superficie de exposicion y dejar documentados los controles de acceso, autenticacion y configuracion, comparando el estado antes y despues.

## Entorno
- Motor: PostgreSQL 14

## Superficie de ataque inicial
- Escucha abierta en todas las interfaces de red (`*`).
- Reglas excesivamente permisivas en `pg_hba.conf` (`0.0.0.0/0`).
- Uso de cuentas con privilegios de superusuario en aplicaciones.

## Hallazgos

Exposición innecesaria a redes públicas y ausencia de privilegios mínimos en roles de aplicación.

## Cambios realizados
Resumen (detalle en `configuracion/cambios.md`):
- `listen_addresses` restringido a localhost / interfaz privada.
- Reglas de `pg_hba.conf` reemplazadas por reglas especificas (base + usuario + red + scram-sha-256).
- Cuentas `app_user` y `consulta_user` con privilegios minimos.
- Parametros de logging y timeouts ajustados.
- Permisos de archivos y directorio de datos revisados.
- Regla de firewall documentada para 10.10.10.0/24 -> 5432.

## Justificación de los cambios
- **listen_addresses:** si PostgreSQL no escucha en una interfaz, nadie puede intentar conectarse por ahi.
- **pg_hba.conf:** pasa de aceptar cualquier origen a una lista explicita (allowlist).
- **scram-sha-256:** el servidor guarda un verificador y no se envia la contrasena en claro; md5 es un mecanismo heredado.
- **Roles minimos:** si la aplicacion es comprometida, el dano queda limitado a lo que esa cuenta puede hacer.
- **Timeouts y logs:** reducen consumo de recursos por sesiones abandonadas y dejan trazabilidad.
- **Permisos de SO:** GRANT/REVOKE no protegen archivos leidos directamente desde el sistema.

## Verificación

Comprobación mediante catálogos de sistema (pg_stat_activity, pg_stat_ssl) y comandos de red del SO (ss -lnt).


## Checklist de hardening
1. Puerto documentado y analizado.
2. Interfaces de escucha restringidas.
3. `pg_hba.conf` auditado y limpio de comodines.
4. Redes autorizadas limitadas.
5. Autenticación segura (`scram-sha-256`).
6. Superusuarios segregados.
7. Cuentas de aplicación separadas.
8. Principio de mínimo privilegio aplicado.
9. Extensiones revisadas.
10. TLS verificado y activo.
11. Archivos de configuración protegidos.
12. Directorio de datos protegido (`700`).
13. Firewall conceptual documentado.
14. Mantenimiento y parches registrados.
15. Línea base documentada.

## Conclusiones
El hardening integral asegura que la base de datos se defienda mediante múltiples capas tecnológicas, protegiendo tanto los datos como el entorno operativo que los sostiene.