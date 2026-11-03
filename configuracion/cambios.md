# Registro de cambios — LAB-04

**Alumno:** Jesus Ruben Monzon Garcia | **Grupo:** 4-3
**Materia:** Gestion de Seguridad y Fundamentos de Base de Datos
**Fecha:** 02/11/2026

## 1. listen_addresses

| | Valor |
|---|---|
| Antes | `*` (captura 02) |
| Despues | `localhost` (o `localhost,10.10.10.20` si hay acceso desde la red privada) |

Se aplica reiniciando el servicio desde `services.msc` o con `Restart-Service postgresql-x64-14` en PowerShell como administrador

## 2. pg_hba.conf

Antes (las 6 lineas de `pg_hba_file_rules`, captura 03):

```
# line  TYPE   DATABASE      USER   ADDRESS      NETMASK                                  METHOD
85      local  all           all                                                          scram-sha-256
87      host   all           all    127.0.0.1    255.255.255.255                          scram-sha-256
89      host   all           all    ::1          ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff  scram-sha-256
92      local  replication   all                                                          scram-sha-256
93      host   replication   all    127.0.0.1    255.255.255.255                          scram-sha-256
94      host   replication   all    ::1          ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff  scram-sha-256
```
Aqui no habia ninguna regla con `0.0.0.0/0`; el problema era que `all all` dejaba entrar a cualquier usuario a cualquier base, y que todo se hacia con `postgres`.

Despues (propuesta; ajustar nombre de BD y red al laboratorio):

```
# TYPE  DATABASE        USER            ADDRESS             METHOD
local   all             postgres                            peer
local   basedatos_lab   app_user                            scram-sha-256
host    basedatos_lab   app_user        10.10.10.0/24       scram-sha-256
host    basedatos_lab   consulta_user   10.10.10.0/24       scram-sha-256
# Si se activa TLS y se quiere obligarlo desde la red:
# hostssl basedatos_lab app_user        10.10.10.0/24       scram-sha-256
```

Las reglas `all all` se cambian por reglas por base y usuario, y se evita agregar `0.0.0.0/0` y `::/0`. Cualquier conexion que no coincida con una regla es rechazada.
Aplicar con `SELECT pg_reload_conf();` y comprobar la columna `error` en `pg_hba_file_rules`.

## 3. Autenticacion y parametros

Ver `sql/03-configuracion.sql`: scram-sha-256, log_connections/log_disconnections, timeouts, TLS minimo 1.2, reserva de conexiones.

Si habia contrasenas guardadas en md5, hay que reasignarlas despues de cambiar `password_encryption`:
```sql
ALTER ROLE app_user PASSWORD 'nueva_clave';
```

## 4. Roles

Ver `sql/02-roles.sql`. Se crearon `app_user` y `consulta_user` sin privilegios administrativos.
La aplicacion deja de usar cuentas de administracion.

## 5. Sistema operativo

En Windows no hay `chmod`, asi que se revisa la ACL de la carpeta `data` y de los .conf:

```powershell
icacls "C:\Program Files\PostgreSQL\14\data"
icacls "C:\Program Files\PostgreSQL\14\data\pg_hba.conf"
```

Permisos antes / despues: quedaron los del instalador (sin captura); no encontre necesario cambiar nada, solo confirmar que no haya `Everyone`.

## 6. Firewall

```powershell
New-NetFirewallRule -DisplayName "PostgreSQL 5432 solo red lab" -Direction Inbound -Protocol TCP -LocalPort 5432 -RemoteAddress 10.10.10.0/24 -Action Allow
Get-NetFirewallRule -DisplayName "PostgreSQL 5432*"
```
Windows bloquea por defecto lo que no tiene regla de permitir, por eso no hace falta una regla de denegar aparte. En mi caso lo deje como diseño (Actividad 14), no lo aplique en la red real.

## 7. Verificacion de exposicion

```powershell
netstat -ano | findstr 5432
```
(En Windows no existe `ss`, `netstat` hace lo mismo.)
Antes: con `listen_addresses = '*'` PostgreSQL queda escuchando en `0.0.0.0:5432` y `[::]:5432` | Despues: `127.0.0.1:5432` y `[::1]:5432`
