-- Paso 1. Comprobar el entorno y preparar la base de práctica.

-- Identificar la versión del motor.
SELECT @@VERSION AS VersionSQLServer;

-- Identificar la base activa al iniciar.
SELECT DB_NAME() AS BaseActual;
GO

-- Identificar instancia.
SELECT @@SERVERNAME AS NombreInstancia;
