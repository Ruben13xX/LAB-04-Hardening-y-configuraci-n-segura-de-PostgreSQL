# Informe — LAB-04 Hardening y configuración segura de PostgreSQL

**Alumno:** Jesus Ruben Monzon Garcia | **Grupo y grado:** 4-3
**Materia:** Gestion de Seguridad y Fundamentos de Base de Datos
**Fecha:** 02/11/2026

## 1. Analisis de la regla permisiva (Actividad 5)

Regla analizada: `host all all 0.0.0.0/0 scram-sha-256`

1. **Bases de datos:** todas (`all`), incluidas las de sistema.
2. **Usuarios:** todos los roles, incluidos los administrativos.
3. **Origenes:** cualquier direccion IPv4.
4. **Autenticacion:** scram-sha-256, que es un buen metodo, pero solo resuelve la identidad.
5. **Exposicion:** cualquier equipo que llegue al puerto puede intentar autenticarse con cualquier usuario y contra cualquier base. Ataques de fuerza bruta, relleno de credenciales o explotacion de vulnerabilidades del servicio quedan a un paso.
6. **Informacion necesaria para restringirla:** que base usa la aplicacion, con que usuario, desde que IP o segmento se conecta y si usa TLS.

| Campo | Contenido |
|---|---|
| Regla actual | `host all all 0.0.0.0/0 scram-sha-256` |
| Problema | Sin limite de base, usuario ni origen |
| Origen que necesita acceso | 10.10.10.0/24 |
| Base de datos | basedatos_lab |
| Usuario | app_user |
| Regla propuesta | `host basedatos_lab app_user 10.10.10.0/24 scram-sha-256` |

## 2. Autenticacion (Actividad 7)

1. **Autenticacion vs autorizacion:** la primera comprueba quien eres (usuario y contrasena); la segunda define que puedes hacer (SELECT, DELETE, etc.).
2. **Que protege scram-sha-256:** el intercambio de la contrasena, que no viaja en claro ni puede reutilizarse si alguien captura el intercambio, y el almacenamiento, que guarda un verificador con sal e iteraciones y no la clave.
3. **Hash vs cifrado reversible:** el verificador no puede revertirse a la contrasena original; un cifrado reversible permitiria recuperarla si se obtiene la llave.
4. **Cuenta con permisos excesivos y contrasena fuerte:** la contrasena no limita lo que la cuenta puede hacer. Si la cuenta es comprometida (por la aplicacion, por SQL injection o por una filtracion), el atacante tiene todos sus privilegios.

## 3. Roles y cuentas (Actividades 8 y 9)

Salida de `pg_roles` (captura 04, son 15 filas en total y en pantalla se alcanzan a ver las primeras 7):

| Rol | LOGIN | SUPERUSER | CREATEROLE | CREATEDB |
|---|---|---|---|---|
| analista | No | No | No | No |
| direccion | No | No | No | No |
| pg_database_owner, pg_execute_server_program, pg_monitor, pg_read_all_data, pg_read_all_settings (y demas `pg_*`) | No | No | No | No |

`analista` y `direccion` son roles de grupo sin login. Por orden alfabetico `app_user` y `consulta_user` tendrian que salir entre `analista` y `direccion`, y no estan, asi que se crean con `02-roles.sql`. En `pg_stat_activity` todas las sesiones usan `postgres`, que es el administrador.

| Rol | LOGIN | SUPERUSER | CREATEROLE | CREATEDB | Funcion |
|---|---|---|---|---|---|
| postgres | Si | Si | Si | Si | Administracion |
| app_user | Si | No | No | No | Aplicacion |
| consulta_user | Si | No | No | No | Reportes |

| Cuenta | Proposito | LOGIN | Privilegios |
|---|---|---|---|
| DBA | Administracion | Si | Administrativos |
| APP | Aplicacion | Si | Minimos (DML) |
| CONSULTA | Consulta | Si | Solo lectura |

- **¿Por que no SUPERUSER en una aplicacion?** Un superusuario omite los permisos de objetos y puede leer/escribir cualquier base, crear roles, cargar extensiones y, segun el caso, ejecutar programas en el servidor. Un fallo en la aplicacion se convierte en control del servidor de base de datos.
- **Riesgo de conectar la app con cuenta administrativa:** inyeccion SQL con alcance total, borrado o exfiltracion de todas las bases, modificacion de roles y pg_hba, y imposibilidad de rastrear quien hizo que.

## 4. Extensiones (Actividad 10)

Extensiones encontradas: en `lab01_seguridad` el arbol de pgAdmin marca 1 extension, que es la de por defecto (`plpgsql`). No vi mas instaladas.

Normalmente `plpgsql` viene por defecto y es necesaria. Las demas se clasifican como necesarias, de practica o innecesarias en otro entorno. Una extension no es insegura por estar instalada, pero cada una agrega codigo y funciones que hay que mantener y vigilar; el principio es dejar solo lo que el sistema necesita.

## 5. Parametros de conexion (Actividad 11)

| Parametro | Valor actual | Funcion |
|---|---|---|
| max_connections | 100 (valor por defecto) | Maximo de conexiones simultaneas |
| superuser_reserved_connections | 3 (valor por defecto) | Cupos reservados a superusuarios para poder entrar aunque el servidor este lleno |
| statement_timeout | 0, sin limite | Cancela consultas que superen el tiempo limite |
| idle_in_transaction_session_timeout | 0, sin limite | Cierra sesiones con transaccion abierta e inactiva |

Conexiones abiertas sin limite consumen memoria y ranuras de conexion, pueden mantener bloqueos que frenan otras operaciones y, si se agotan, impiden que usuarios legitimos se conecten (problema de disponibilidad). Tambien ensanchan la ventana para el abuso de una sesion olvidada.

## 6. Sistema operativo (Actividad 12)

Resultado: el servidor esta en Windows, entonces no existe `ls -l`/`ls -ld` y los permisos se ven por ACL (pestaña Seguridad de la carpeta o `icacls`). Se dejo la configuracion del instalador: carpeta `data` para la cuenta de servicio, SYSTEM y Administradores. No tome captura de esto.

Esperado (en Linux): propietario `postgres`, archivos 640 o 600, directorio de datos 700. En Windows la idea es la misma: que solo la cuenta de servicio y los administradores toquen la carpeta. No basta con GRANT y REVOKE porque esos controles actuan dentro de PostgreSQL; si un usuario del sistema puede leer `pg_hba.conf`, los archivos de datos o llaves TLS, obtiene informacion o datos sin pasar por el motor.

## 7. Exposicion de red (Actividad 13)

| Dato | Valor |
|---|---|
| Direccion de escucha | `*` (todas las interfaces) |
| Puerto | 5432 |
| ¿Expuesto fuera de la interfaz necesaria? | Si, escucha en todo. Por suerte pg_hba solo acepta localhost, pero si cambian esas reglas queda abierto |

**Arquitecturas comparadas (Actividad 3):** la segunda (Internet bloqueado, firewall, red privada, servidor) reduce mejor la exposicion porque el servidor no tiene ruta directa desde Internet. En la primera, un error en el firewall o en pg_hba deja el servicio accesible a cualquiera; en la segunda hay una capa adicional de aislamiento y solo hay que confiar en hosts de la red interna.

## 8. Firewall (Actividad 14)

| Origen | Destino | Puerto | Accion |
|---|---|---|---|
| 10.10.10.0/24 | PostgreSQL (10.10.10.20) | 5432 | Permitir |
| Cualquier otro origen | PostgreSQL (10.10.10.20) | 5432 | Denegar |

**¿Por que no son equivalentes pg_hba.conf y el firewall?** El firewall decide si un paquete llega al puerto, antes de que PostgreSQL intervenga. pg_hba.conf actua cuando la conexion ya llego al servicio y decide con que metodo, usuario y base se permite autenticar. Uno opera a nivel de red y otro a nivel de aplicacion; se complementan. Si el firewall falla, pg_hba sigue limitando; si pg_hba es laxo, el firewall reduce quien puede intentar.

## 9. TLS (Actividad 15)

| Dato | Valor |
|---|---|
| ssl | off |
| ssl_min_protocol_version | TLSv1.2 (el de por defecto en PostgreSQL 14) |
| ¿La conexion actual usa TLS? | No, ssl = f (captura 05) |
| Version / cipher | NULL / NULL, porque la sesion no esta cifrada |

Una conexion por socket local (peer) normalmente muestra `ssl = f`, lo cual es esperado. Para comprobar TLS hay que conectarse por TCP, por ejemplo `psql "host=127.0.0.1 dbname=basedatos_lab user=app_user sslmode=require"`. Para que TLS este bien integrado, el servidor necesita certificado y llave validos, version minima definida y los clientes deben exigirlo (`sslmode=require` o `verify-full`), idealmente con reglas `hostssl` en pg_hba.conf.

## 10. Linea base antes/despues (Actividad 16)

| Control | Antes | Despues | Justificacion |
|---|---|---|---|
| listen_addresses | `*` | localhost / IP privada | Reducir interfaces expuestas |
| pg_hba.conf | 6 reglas por defecto (local, 127.0.0.1 y ::1, mas replication), sin 0.0.0.0/0 | Reglas por base, usuario y red | Allowlist y minimo privilegio |
| Metodo de autenticacion | scram-sha-256 en todas | scram-sha-256 | Evitar md5/trust |
| Usuarios administrativos | `postgres` para todo | Solo DBA | Separar funciones |
| Cuentas de aplicacion | No existian, todo con `postgres` | app_user sin privilegios admin | Limitar impacto |
| Puerto | 5432 | 5432 documentado y filtrado | El cambio de puerto no es control suficiente |
| TLS | ssl off, sesion con ssl = f | ssl on, minimo TLS 1.2 | Proteger trafico |
| Permisos SO | ACL por defecto de Windows, sin revisar a detalle | 640 en .conf, 700 en data | Proteger archivos sensibles |
| Extensiones | Solo `plpgsql` | Solo las necesarias | Menos funcionalidad expuesta |
| Conexiones | Sin timeouts (statement_timeout e idle_in_transaction en 0) | Timeouts y logging | Disponibilidad y trazabilidad |

## 11. Caso integral (Actividad 18)

| # | Problema | Riesgo | Control propuesto |
|---|---|---|---|
| 1 | Acepta conexiones desde cualquier IPv4 | Escaneo, fuerza bruta, explotacion remota | Restringir origenes a la red autorizada |
| 2 | Escucha en todas las interfaces | Exposicion en interfaces que no se necesitan | `listen_addresses` a localhost o IP privada |
| 3 | La app usa cuenta administrativa | Compromiso total desde un fallo de la app | Cuenta `app_user` con privilegios minimos |
| 4 | Firewall permite 5432 desde cualquier origen | Servicio expuesto a Internet | Regla de firewall solo para 10.10.10.0/24 |
| 5 | pg_hba.conf con all/all desde 0.0.0.0/0 | Cualquier usuario contra cualquier base | Reglas por base, usuario y red |
| 6 | Se confia solo en contrasenas fuertes | Falsa sensacion de seguridad | Defensa por capas |
| 7 | Sin evidencia de TLS | Intercepcion de trafico y credenciales | Activar TLS y exigirlo con hostssl |
| 8 | Sin monitoreo de conexiones | Ataques no detectados | log_connections/disconnections y revision de logs |
| 9 | Sin timeouts de sesion | Agotamiento de conexiones, bloqueos | statement_timeout e idle_in_transaction_session_timeout |
| 10 | Archivos de configuracion y datos sin revisar | Lectura de configuracion o datos desde el SO | Propietario postgres, 640/700 |
| 11 | Sin segmentacion de red | Movimiento lateral si otro equipo cae | Servidor en red privada |
| 12 | Sin politica de actualizacion | Vulnerabilidades conocidas sin corregir | Actualizaciones menores periodicas |
| 13 | Sin separacion de cuentas | Sin trazabilidad ni minimo privilegio | Cuentas DBA, APP y CONSULTA |

**¿Es suficiente tener contraseñas fuertes? No.** Una contrasenia fuerte solo cubre la *autenticacion*. Con `0.0.0.0/0` el atacante puede intentar indefinidamente y explotar vulnerabilidades del servicio sin siquiera autenticarse. En *autorizacion*, la cuenta administrativa da acceso total si la app es comprometida, sin necesidad de adivinar ninguna clave. En *red*, el firewall abierto expone el servicio. En *configuracion*, faltan timeouts y TLS. En *sistema operativo*, los archivos pueden leerse sin pasar por PostgreSQL. Y sin *monitoreo* nadie se entera. La seguridad depende de que todas las capas funcionen juntas.

## 12. Preguntas del informe

1. **Principal superficie de ataque:** en mi servidor es `listen_addresses = '*'` con el puerto 5432, o sea escucha en todas las interfaces. Lo que lo frena es que pg_hba.conf solo acepta localhost; si alguien agrega una regla amplia, queda expuesto.
2. **Mayor riesgo de configuracion:** una regla `all all 0.0.0.0/0` junto con cuentas administrativas usadas por la aplicacion, porque permite intentar acceso desde cualquier lugar con privilegios maximos.
3. **Mayor reduccion de exposicion:** limitar `listen_addresses` y reemplazar las reglas amplias de pg_hba.conf, porque elimina quien puede siquiera intentar conectarse.
4. **Firewall vs pg_hba.conf:** el firewall filtra trafico de red antes de llegar al servicio; pg_hba.conf decide el metodo de autenticacion por origen, usuario y base una vez que la conexion llego.
5. **Autenticacion vs autorizacion:** verificar identidad vs definir permisos.
6. **Por que la app no debe ser SUPERUSER:** si se compromete, el atacante hereda control total del servidor de base de datos.
7. **Cambiar el puerto no basta:** solo evita parte del ruido automatizado; un escaneo lo encuentra y no agrega autenticacion, autorizacion ni filtrado.
8. **`listen_addresses='*'` puede ser innecesario:** abre el servicio en todas las interfaces aunque solo se use una o ninguna remota; lo seguro es escuchar solo donde hay clientes legitimos.
9. **Papel del sistema operativo:** protege archivos, llaves, directorio de datos y procesos; un fallo ahi evita todos los controles internos de PostgreSQL.
10. **Controles a revisar periodicamente:** reglas de pg_hba.conf, roles y privilegios, cuentas sin uso, extensiones, permisos de archivos, versiones y parches, certificados TLS, reglas de firewall y logs de conexion.

## 13. Reflexion

El proceso de hardening desarrollado en el laboratorio 04 demuestra que la seguridad de una base de datos de clase empresarial no depende exclusivamente de contar con contraseñas robustas, sino de implementar una estrategia integral de defensa en profundidad. Esto abarca desde la restricción perimetral en la red y el sistema operativo hasta la configuración estricta de la autenticación (scram-sha-256), el control de acceso basado en listas blancas y la aplicación rigurosa del principio de mínimo privilegio en los roles del motor. Documentar una línea base de seguridad y mantener un checklist de verificación son los pilares fundamentales para garantizar que la infraestructura tecnológica permanezca protegida a lo largo de su ciclo de vida productivo.