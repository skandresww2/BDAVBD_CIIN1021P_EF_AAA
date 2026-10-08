/* ============================================================================
   BASE DE DATOS AVANZADAS Y BIG DATA - CIIN1021P
   TEMA 06 - ANALISIS Y VISUALIZACION DE DATOS EMPRESARIALES

   SCRIPT DE RECUPERACION DEL ENTORNO

   ---------------------------------------------------------------------------
   CUANDO USAR ESTE SCRIPT
   ---------------------------------------------------------------------------
   Solo si el Paso 0 de la guia fallo o los valores de control no coinciden:
     - trabajas en otro equipo distinto al del Tema 05,
     - la base MoviTrackTema05_Practica se perdio,
     - tu carga del Tema 05 quedo incompleta.

   Si el Paso 0 devolvio 6 viajes y 120.00, NO necesitas ejecutar esto.

   ---------------------------------------------------------------------------
   QUE HACE
   ---------------------------------------------------------------------------
   Reconstruye el minimo necesario para trabajar el Tema 06:
     - las tres dimensiones del modelo estrella,
     - la tabla de hechos FactViajeE04,
     - las tres tablas del proceso ETL, que se usan en el Ejercicio 04
       para medir la calidad de los datos.

   Es IDEMPOTENTE: puedes ejecutarlo varias veces sin duplicar informacion.
   Todos los bloques usan NOT EXISTS antes de insertar.

   Datos totalmente sinteticos. No corresponden a ninguna organizacion real.

   ---------------------------------------------------------------------------
   COMO EJECUTARLO
   ---------------------------------------------------------------------------
   Abrelo en SSMS y ejecuta el script completo, o bloque por bloque en orden.
   Al terminar, la seccion 9 muestra los valores de control.
   ============================================================================ */


/* ---------------------------------------------------------------------------
   1. CREAR LA BASE
   La base se crea solo si todavia no existe. DB_ID devuelve NULL cuando
   la base no esta registrada en el servidor.
   --------------------------------------------------------------------------- */

USE master;
GO

IF DB_ID('MoviTrackTema05_Practica') IS NULL
BEGIN
    CREATE DATABASE MoviTrackTema05_Practica;
END;
GO

USE MoviTrackTema05_Practica;
GO


/* ---------------------------------------------------------------------------
   2. CREAR LAS TRES DIMENSIONES

   Cada dimension tiene dos tipos de clave:
     - la clave subrogada, que identifica el miembro dentro del modelo,
     - la clave de negocio, que viene del sistema origen.

   La restriccion UNIQUE sobre la clave de negocio no es decorativa:
   garantiza que la busqueda de claves devuelva como maximo una fila.
   --------------------------------------------------------------------------- */

IF OBJECT_ID('dbo.DimServicioE02', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimServicioE02
    (
        -- La genera el motor: 1, 2, 3...
        ServicioKey INT IDENTITY(1, 1) NOT NULL
            CONSTRAINT PK_DimServicioE02 PRIMARY KEY,

        -- Viene del sistema origen y no puede repetirse.
        Servicio VARCHAR(30) NOT NULL
            CONSTRAINT UQ_DimServicioE02_Servicio UNIQUE
    );
END;
GO

IF OBJECT_ID('dbo.DimUbicacionE02', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimUbicacionE02
    (
        UbicacionKey INT IDENTITY(1, 1) NOT NULL
            CONSTRAINT PK_DimUbicacionE02 PRIMARY KEY,

        Distrito VARCHAR(40) NOT NULL
            CONSTRAINT UQ_DimUbicacionE02_Distrito UNIQUE
    );
END;
GO

/* En la dimension de fecha la clave NO la genera el motor: se calcula
   con el formato aaaammdd. Asi el 1 de setiembre de 2026 se convierte
   en 20260901. Es una clave subrogada igual que las otras dos, pero
   deducible de la fecha y ordenable cronologicamente. */

IF OBJECT_ID('dbo.DimFechaE02', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimFechaE02
    (
        FechaKey INT NOT NULL
            CONSTRAINT PK_DimFechaE02 PRIMARY KEY,

        Fecha DATE NOT NULL
            CONSTRAINT UQ_DimFechaE02_Fecha UNIQUE,

        Anio INT NOT NULL,

        Mes INT NOT NULL
            CONSTRAINT CK_DimFechaE02_Mes CHECK (Mes BETWEEN 1 AND 12)
    );
END;
GO


/* ---------------------------------------------------------------------------
   3. CREAR LA TABLA DE HECHOS

   Un viaje se identifica por su origen y su codigo: dos sistemas distintos
   podrian usar el mismo codigo, asi que la clave primaria es compuesta.

   Las tres claves foraneas obligan a que el miembro exista en su dimension
   antes de poder insertar el hecho. Por eso el orden de carga de la
   seccion 5 en adelante no se puede alterar.
   --------------------------------------------------------------------------- */

IF OBJECT_ID('dbo.FactViajeE04', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FactViajeE04
    (
        Origen VARCHAR(10) NOT NULL,
        CodigoViaje VARCHAR(10) NOT NULL,

        FechaKey INT NOT NULL
            CONSTRAINT FK_FactViajeE04_Fecha
            REFERENCES dbo.DimFechaE02 (FechaKey),

        ServicioKey INT NOT NULL
            CONSTRAINT FK_FactViajeE04_Servicio
            REFERENCES dbo.DimServicioE02 (ServicioKey),

        UbicacionKey INT NOT NULL
            CONSTRAINT FK_FactViajeE04_Ubicacion
            REFERENCES dbo.DimUbicacionE02 (UbicacionKey),

        -- Medida del viaje.
        Importe DECIMAL(10, 2) NOT NULL
            CONSTRAINT CK_FactViajeE04_Importe CHECK (Importe > 0),

        CONSTRAINT PK_FactViajeE04 PRIMARY KEY (Origen, CodigoViaje)
    );
END;
GO


/* ---------------------------------------------------------------------------
   4. CREAR LAS TABLAS DEL PROCESO ETL

   Estas tres tablas NO forman parte del modelo analitico: no se importan
   a Power BI. Se usan en el Ejercicio 04 para medir la calidad de los
   datos que alimentan el analisis.

   StgViajeE03 conserva los valores TAL COMO LLEGARON, incluidos los
   invalidos. Por eso casi todas sus columnas admiten NULL.
   --------------------------------------------------------------------------- */

IF OBJECT_ID('dbo.StgViajeE03', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.StgViajeE03
    (
        Origen VARCHAR(10) NOT NULL,
        CodigoViaje VARCHAR(10) NOT NULL,
        FechaViaje DATE NULL,
        Servicio VARCHAR(30) NULL,
        Distrito VARCHAR(40) NULL,
        Importe DECIMAL(10, 2) NULL,
        Estado VARCHAR(30) NULL,

        CONSTRAINT PK_StgViajeE03 PRIMARY KEY (Origen, CodigoViaje)
    );
END;
GO

/* Los viajes validos ya pasaron la limpieza: aqui todas las columnas
   son obligatorias y el estado esta normalizado. */

IF OBJECT_ID('dbo.ViajeValidoE03', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ViajeValidoE03
    (
        Origen VARCHAR(10) NOT NULL,
        CodigoViaje VARCHAR(10) NOT NULL,
        FechaViaje DATE NOT NULL,
        Servicio NVARCHAR(30) NOT NULL,
        Distrito NVARCHAR(40) NOT NULL,
        Importe DECIMAL(10, 2) NOT NULL,
        Estado NVARCHAR(30) NOT NULL,

        CONSTRAINT PK_ViajeValidoE03 PRIMARY KEY (Origen, CodigoViaje)
    );
END;
GO

/* Los rechazados conservan los valores ORIGINALES, sin limpiar, mas la
   explicacion del descarte. Un rechazo sin motivo registrado es un dato
   perdido: nadie podria corregir el origen. */

IF OBJECT_ID('dbo.ViajeRechazadoE03', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ViajeRechazadoE03
    (
        Origen VARCHAR(10) NOT NULL,
        CodigoViaje VARCHAR(10) NOT NULL,
        FechaViaje DATE NULL,
        Servicio VARCHAR(30) NULL,
        Distrito VARCHAR(40) NULL,
        Importe DECIMAL(10, 2) NULL,
        Estado VARCHAR(30) NULL,
        MotivoRechazo NVARCHAR(100) NOT NULL,

        CONSTRAINT PK_ViajeRechazadoE03 PRIMARY KEY (Origen, CodigoViaje)
    );
END;
GO


/* ---------------------------------------------------------------------------
   5. CARGAR LAS DIMENSIONES

   El orden de insercion define la clave subrogada:
   ESTANDAR sera 1, EJECUTIVO 2 y ENCOMIENDA 3.

   NOT EXISTS evita duplicar si el bloque se ejecuta otra vez.
   --------------------------------------------------------------------------- */

INSERT INTO dbo.DimServicioE02 (Servicio)
SELECT src.Servicio
FROM (VALUES ('ESTANDAR'), ('EJECUTIVO'), ('ENCOMIENDA')) AS src (Servicio)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.DimServicioE02 AS d
    WHERE d.Servicio = src.Servicio
);
GO

INSERT INTO dbo.DimUbicacionE02 (Distrito)
SELECT src.Distrito
FROM (VALUES ('Los Olivos'), ('Comas'), ('Independencia')) AS src (Distrito)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.DimUbicacionE02 AS d
    WHERE d.Distrito = src.Distrito
);
GO

/* La clave de fecha se calcula a partir de la propia fecha:
   YEAR * 10000 + MONTH * 100 + DAY. */

INSERT INTO dbo.DimFechaE02 (FechaKey, Fecha, Anio, Mes)
SELECT
    YEAR(src.Fecha) * 10000 + MONTH(src.Fecha) * 100 + DAY(src.Fecha),
    src.Fecha,
    YEAR(src.Fecha),
    MONTH(src.Fecha)
FROM
(
    VALUES
        (CAST('20260901' AS DATE)),
        (CAST('20260902' AS DATE)),
        (CAST('20260903' AS DATE)),
        (CAST('20260904' AS DATE)),
        (CAST('20261003' AS DATE)),
        (CAST('20261004' AS DATE))
) AS src (Fecha)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.DimFechaE02 AS d
    WHERE d.Fecha = src.Fecha
);
GO


/* ---------------------------------------------------------------------------
   6. CARGAR EL AREA INTERMEDIA CON LOS DATOS TAL COMO LLEGARON

   Son los diez registros de los dos sistemas origen del Tema 05, con sus
   defectos originales:
     - APP-003 trae un importe negativo,
     - APP-004 llega sin distrito,
     - CEN-003 trae un estado que no se reconoce,
     - CEN-004 llega sin fecha,
     - y el estado FINALIZADO aparece escrito de cuatro formas distintas.

   Estos defectos son deliberados: son los que el Ejercicio 04 mide.
   --------------------------------------------------------------------------- */

INSERT INTO dbo.StgViajeE03
(Origen, CodigoViaje, FechaViaje, Servicio, Distrito, Importe, Estado)
SELECT
    src.Origen,
    src.CodigoViaje,
    src.FechaViaje,
    src.Servicio,
    src.Distrito,
    src.Importe,
    src.Estado
FROM
(
    VALUES
        ('APP', 'APP-001', CAST('20260901' AS DATE), 'ESTANDAR',
         'Los Olivos', CAST(12.00 AS DECIMAL(10, 2)), 'FINALIZADO'),
        ('APP', 'APP-002', CAST('20260902' AS DATE), 'ESTANDAR',
         'Los Olivos', CAST(18.00 AS DECIMAL(10, 2)), 'FIN'),
        ('APP', 'APP-003', CAST('20260903' AS DATE), 'EJECUTIVO',
         'Comas', CAST(-5.00 AS DECIMAL(10, 2)), 'FINALIZADO'),
        ('APP', 'APP-004', CAST('20260904' AS DATE), 'ESTANDAR',
         NULL, CAST(10.00 AS DECIMAL(10, 2)), 'FINALIZADO'),
        ('APP', 'APP-005', CAST('20261003' AS DATE), 'ENCOMIENDA',
         'Independencia', CAST(25.00 AS DECIMAL(10, 2)), 'FIN'),
        ('CENTRAL', 'CEN-001', CAST('20260903' AS DATE), 'EJECUTIVO',
         'Comas', CAST(15.00 AS DECIMAL(10, 2)), 'FINALIZADA'),
        ('CENTRAL', 'CEN-002', CAST('20260904' AS DATE), 'EJECUTIVO',
         'Comas', CAST(20.00 AS DECIMAL(10, 2)), ' FINALIZADO '),
        ('CENTRAL', 'CEN-003', CAST('20261001' AS DATE), 'ESTANDAR',
         'Los Olivos', CAST(9.00 AS DECIMAL(10, 2)), 'DESCONOCIDO'),
        ('CENTRAL', 'CEN-004', NULL, 'ESTANDAR',
         'Comas', CAST(13.00 AS DECIMAL(10, 2)), 'FINALIZADO'),
        ('CENTRAL', 'CEN-005', CAST('20261004' AS DATE), 'ESTANDAR',
         'Comas', CAST(30.00 AS DECIMAL(10, 2)), 'FINALIZADA')
) AS src (Origen, CodigoViaje, FechaViaje, Servicio,
          Distrito, Importe, Estado)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.StgViajeE03 AS s
    WHERE s.Origen = src.Origen
      AND s.CodigoViaje = src.CodigoViaje
);
GO


/* ---------------------------------------------------------------------------
   7. CLASIFICAR EN VALIDOS Y RECHAZADOS

   Un viaje es valido si cumple las cuatro reglas a la vez:
     importe mayor que cero, fecha presente, distrito presente y
     estado reconocible.

   LTRIM y RTRIM quitan los espacios: sin ellos, ' FINALIZADO ' no
   coincidiria con 'FINALIZADO' y se perderia un viaje valido.
   --------------------------------------------------------------------------- */

INSERT INTO dbo.ViajeValidoE03
(Origen, CodigoViaje, FechaViaje, Servicio, Distrito, Importe, Estado)
SELECT
    s.Origen,
    s.CodigoViaje,
    s.FechaViaje,
    LTRIM(RTRIM(s.Servicio)),
    LTRIM(RTRIM(s.Distrito)),
    s.Importe,
    N'FINALIZADO'
FROM dbo.StgViajeE03 AS s
WHERE s.Importe > 0
  AND s.FechaViaje IS NOT NULL
  AND s.Distrito IS NOT NULL
  AND LTRIM(RTRIM(s.Estado)) IN ('FINALIZADO', 'FINALIZADA', 'FIN')
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.ViajeValidoE03 AS v
      WHERE v.Origen = s.Origen
        AND v.CodigoViaje = s.CodigoViaje
  );
GO

/* El orden del CASE define la prioridad del motivo: si una fila tuviera
   dos defectos, se reporta el primero que coincida. En esta muestra cada
   rechazo tiene un unico defecto, asi que deben salir cuatro motivos
   distintos, uno por registro. */

INSERT INTO dbo.ViajeRechazadoE03
(Origen, CodigoViaje, FechaViaje, Servicio, Distrito,
 Importe, Estado, MotivoRechazo)
SELECT
    s.Origen,
    s.CodigoViaje,
    s.FechaViaje,
    s.Servicio,
    s.Distrito,
    s.Importe,
    s.Estado,
    CASE
        WHEN s.FechaViaje IS NULL THEN N'Fecha ausente'
        WHEN s.Distrito IS NULL THEN N'Distrito ausente'
        WHEN s.Importe IS NULL OR s.Importe <= 0 THEN N'Importe invalido'
        ELSE N'Estado no reconocido'
    END
FROM dbo.StgViajeE03 AS s
WHERE NOT
  (
      s.Importe > 0
      AND s.FechaViaje IS NOT NULL
      AND s.Distrito IS NOT NULL
      AND LTRIM(RTRIM(s.Estado)) IN ('FINALIZADO', 'FINALIZADA', 'FIN')
  )
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.ViajeRechazadoE03 AS r
      WHERE r.Origen = s.Origen
        AND r.CodigoViaje = s.CodigoViaje
  );
GO


/* ---------------------------------------------------------------------------
   8. CARGAR LA TABLA DE HECHOS

   Los tres INNER JOIN hacen la busqueda de claves: convierten el texto
   del origen en la clave subrogada de cada dimension.

   Es seguro usar INNER JOIN porque la seccion 5 ya garantizo que los
   tres miembros existen. En un proceso real se verifica antes con
   LEFT JOIN, como practicaste en el Tema 05.
   --------------------------------------------------------------------------- */

INSERT INTO dbo.FactViajeE04
(Origen, CodigoViaje, FechaKey, ServicioKey, UbicacionKey, Importe)
SELECT
    v.Origen,
    v.CodigoViaje,
    f.FechaKey,
    s.ServicioKey,
    u.UbicacionKey,
    v.Importe
FROM dbo.ViajeValidoE03 AS v
INNER JOIN dbo.DimFechaE02 AS f
    ON f.Fecha = v.FechaViaje
INNER JOIN dbo.DimServicioE02 AS s
    ON s.Servicio = v.Servicio
INNER JOIN dbo.DimUbicacionE02 AS u
    ON u.Distrito = v.Distrito
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.FactViajeE04 AS h
    WHERE h.Origen = v.Origen
      AND h.CodigoViaje = v.CodigoViaje
);
GO


/* ---------------------------------------------------------------------------
   9. VERIFICAR

   Valores esperados:
     Viajes . . . . . 6          Recibidos . . . . 10
     ImporteTotal . . 120.00     Aceptados . . . .  6
     Servicios  . . . 3          Rechazados  . . .  4
     Ubicaciones  . . 3

   Si algo no coincide, vuelve a ejecutar el script completo: como todos
   los bloques usan NOT EXISTS, repetirlo no duplica informacion.
   Si el error persiste, avisa al docente antes de continuar.
   --------------------------------------------------------------------------- */

SELECT
    (SELECT COUNT(*) FROM dbo.FactViajeE04) AS Viajes,
    (SELECT SUM(Importe) FROM dbo.FactViajeE04) AS ImporteTotal,
    (SELECT COUNT(*) FROM dbo.DimServicioE02) AS Servicios,
    (SELECT COUNT(*) FROM dbo.DimUbicacionE02) AS Ubicaciones,
    (SELECT COUNT(*) FROM dbo.StgViajeE03) AS Recibidos,
    (SELECT COUNT(*) FROM dbo.ViajeValidoE03) AS Aceptados,
    (SELECT COUNT(*) FROM dbo.ViajeRechazadoE03) AS Rechazados;
GO
