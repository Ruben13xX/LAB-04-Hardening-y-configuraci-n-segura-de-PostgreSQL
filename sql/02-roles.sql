-- LAB-04 | 02-roles.sql
-- Revision de roles y separacion de cuentas

-- Análisis detallado de los roles del sistema
SELECT 
    rolname, 
    rolsuper, 
    rolinherit, 
    rolcreaterole, 
    rolcreatedb, 
    rolcanlogin 
FROM pg_roles 
ORDER BY rolname;