-- Paso 0.1. Identificar la conexión antes de cambiar de base.
SELECT
    CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)) AS Instancia,
    CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(30)) AS VersionSQLServer,
    DB_NAME() AS BaseInicial;
GO

-- Paso 0.2. Seleccionar la base usada en el Tema 05.
USE MoviTrackTema05_Practica;
GO

-- Paso 0.3. Confirmar la base activa y los datos de partida.
SELECT
    DB_NAME() AS BaseActiva,
    (SELECT COUNT(*) FROM dbo.FactViajeE04)    AS Viajes,
    (SELECT SUM(Importe) FROM dbo.FactViajeE04) AS ImporteTotal,
    (SELECT COUNT(*) FROM dbo.DimServicioE02)  AS Servicios,
    (SELECT COUNT(*) FROM dbo.DimUbicacionE02) AS Ubicaciones;
GO


/* ============================================================
   EJERCICIO 01 - PASO 1
   GUÍA DOCENTE: VIAJES E IMPORTE POR DISTRITO
   ============================================================

   Propósito:
   Pasar del detalle del Tema 05 a un primer resumen analítico.
   En FactViajeE04, cada fila representa un viaje. Esta consulta
   reúne esos viajes por distrito.

   Pregunta de negocio:
   ¿Cuántos viajes se realizaron y cuánto sumaron sus importes
   en cada distrito?
*/

USE MoviTrackTema05_Practica;
GO

SELECT
    u.Distrito,

    -- COUNT(*) cuenta las filas de viajes de cada distrito.
    COUNT(*) AS CantidadViajes,

    -- Importe es una medida aditiva: puede sumarse entre viajes.
    SUM(h.Importe) AS ImporteTotal

FROM dbo.FactViajeE04 AS h

-- El hecho guarda UbicacionKey; el nombre del distrito está
-- en la dimensión. La unión se realiza por la clave del modelo.
INNER JOIN dbo.DimUbicacionE02 AS u
    ON u.UbicacionKey = h.UbicacionKey

-- Cambiamos el grano del resultado:
-- de una fila por viaje a una fila por distrito.
GROUP BY u.Distrito

-- Solo ordena la presentación; no altera los cálculos.
ORDER BY u.Distrito;
GO

/* ============================================================
   RESULTADO ESPERADO

   Distrito         CantidadViajes    ImporteTotal
   --------------   --------------    ------------
   Comas                   3               65.00
   Independencia           1               25.00
   Los Olivos              2               30.00

   Comprobación:
   - Viajes: 3 + 1 + 2 = 6.
   - Importe: 65.00 + 25.00 + 30.00 = 120.00.
   - Ambos totales deben coincidir con el Paso 0.
   ============================================================ */

/* ============================================================
   EXPLICACIÓN PARA CLASE

   1. ¿Por qué aparece INNER JOIN?
      FactViajeE04 identifica la ubicación mediante UbicacionKey.
      DimUbicacionE02 proporciona el nombre legible del distrito.

   2. ¿Por qué aparecen tres filas si existen seis viajes?
      GROUP BY reúne los hechos en tres grupos: Comas,
      Independencia y Los Olivos.

   3. ¿Qué hace cada función?
      COUNT(*) cuenta los viajes de cada grupo.
      SUM(h.Importe) suma los importes de ese mismo grupo.

   4. ¿Qué hace ORDER BY?
      Muestra los distritos en orden alfabético. No participa
      en la formación de los grupos.

   Ejemplo aplicado:
   Un jefe de operaciones compara distritos para identificar
   dónde hubo más viajes. Comas concentra 3 de los 6 viajes
   y 65.00 de los 120.00 de importe total.

   Enlace con el Paso 2:
   Esta consulta entrega un solo nivel de resumen: distrito.
   A continuación se agregarán niveles de fecha y ROLLUP
   para mostrar detalle, subtotales y total general.
   ============================================================ */

/* ============================================================
   ERRORES FRECUENTES

   - Unir las tablas sin la condición ON: generaría
     combinaciones incorrectas de viajes y distritos.
   - Confundir las tres filas del resultado con tres viajes:
     son tres grupos que resumen seis viajes.
   - Confundir GROUP BY con ORDER BY: el primero agrupa;
     el segundo únicamente ordena la salida.
   ============================================================ */



/* ============================================================
   EJERCICIO 01 - PASO 2
   GUÍA DOCENTE: AGREGACIONES MULTINIVEL CON ROLLUP
   ============================================================

   Propósito:
   Obtener en una ejecución los viajes por año, mes y distrito,
   los subtotales de cada mes, el subtotal anual y el total
   general.

   Relación con el Paso 1:
   GROUP BY Distrito producía un solo nivel de resumen.
   ROLLUP produce varios niveles a partir de una lista ordenada.
*/

SELECT
    t.Anio,
    t.Mes,
    u.Distrito,
    COUNT(*) AS CantidadViajes,
    SUM(h.Importe) AS ImporteTotal
FROM dbo.FactViajeE04 AS h
INNER JOIN dbo.DimFechaE02 AS t
    ON t.FechaKey = h.FechaKey
INNER JOIN dbo.DimUbicacionE02 AS u
    ON u.UbicacionKey = h.UbicacionKey

/* ROLLUP (Anio, Mes, Distrito) genera estos niveles:

   1. (Anio, Mes, Distrito): detalle de cada combinación.
   2. (Anio, Mes):          subtotal mensual.
   3. (Anio):               subtotal anual.
   4. ():                   total general.

   Se retira primero Distrito, luego Mes y finalmente Anio.
   Por eso el orden de las columnas importa.
*/
GROUP BY ROLLUP (t.Anio, t.Mes, u.Distrito)

/* GROUPING devuelve 0 en las filas donde el nivel participa
   y 1 cuando ROLLUP lo retiró. Aquí se usa para ordenar:
   primero detalles, luego subtotales y al final el total
   general. En el Paso 3 se utilizará también para etiquetar.
*/
ORDER BY
    GROUPING(t.Anio), t.Anio,
    GROUPING(t.Mes), t.Mes,
    GROUPING(u.Distrito), u.Distrito;
GO

/* ============================================================
   RESULTADOS DE CONTROL

   Septiembre de 2026: 4 viajes; 65.00.
   Octubre de 2026:    2 viajes; 55.00.
   Subtotal de 2026:   6 viajes; 120.00.
   Total general:      6 viajes; 120.00.

   Hay un solo año en estos datos. Por eso el subtotal anual
   y el total general tienen el mismo valor, aunque representan
   niveles de agrupación diferentes.
   ============================================================ */

/* ============================================================
   CÓMO EXPLICAR LOS NULL

   Anio=2026, Mes=9, Distrito=NULL:
       Subtotal de septiembre, sin separar distritos.

   Anio=2026, Mes=NULL, Distrito=NULL:
       Subtotal del año 2026, sin separar meses ni distritos.

   Anio=NULL, Mes=NULL, Distrito=NULL:
       Total general, sin separar por ninguna dimensión.

   No afirmar que todo NULL en Distrito es un subtotal mensual:
   aparece también en los dos niveles más generales.
   El Paso 3 enseñará a distinguir un subtotal de un NULL
   que provenga realmente de los datos.
   ============================================================ */

/* ============================================================
   PREGUNTA BREVE PARA CLASE

   ¿Por qué el subtotal de 2026 y el total general muestran
   ambos 6 viajes y 120.00?

   Respuesta: porque el conjunto de práctica contiene un solo
   año. Si incorporamos viajes de otro año, cada año tendrá su
   subtotal, mientras que el total general sumará todos ellos.
   ============================================================ */





   /* ============================================================
   EJERCICIO 01 - PASO 3
   GUÍA DOCENTE: ETIQUETAR LOS NIVELES DE ROLLUP
   ============================================================

   Propósito:
   Mostrar que una celda NULL producida por ROLLUP representa
   "todos los valores de este nivel". GROUPING identifica qué
   columna fue retirada de la agrupación.

   En esta consulta se usan solo Anio y Mes para que los
   estudiantes observen claramente tres niveles:
   (Anio, Mes), (Anio) y ().
*/

SELECT
    CASE
        -- En el grupo vacío () se retiraron Anio y Mes.
        WHEN GROUPING(t.Anio) = 1 THEN 'TOTAL GENERAL'

        -- En el detalle mensual y el subtotal anual,
        -- Anio todavía participa en la agrupación.
        ELSE CAST(t.Anio AS VARCHAR(4))
    END AS Anio,

    CASE
        -- Esta condición debe evaluarse primero.
        -- En el total general GROUPING(Mes) también vale 1;
        -- si probamos Mes antes, lo llamaríamos incorrectamente
        -- "Subtotal anual".
        WHEN GROUPING(t.Anio) = 1 THEN 'Todos los meses'

        -- Se retiró Mes, pero se conservó Anio: subtotal
        -- de todos los meses del año mostrado.
        WHEN GROUPING(t.Mes) = 1 THEN 'Subtotal anual'

        -- Mes participa en la agrupación: fila mensual.
        ELSE CAST(t.Mes AS VARCHAR(2))
    END AS Mes,

    COUNT(*) AS CantidadViajes,
    SUM(h.Importe) AS ImporteTotal

FROM dbo.FactViajeE04 AS h
INNER JOIN dbo.DimFechaE02 AS t
    ON t.FechaKey = h.FechaKey

/* Niveles generados:
   (Anio, Mes) -> septiembre y octubre de 2026.
   (Anio)      -> subtotal de 2026.
   ()          -> total general.
*/
GROUP BY ROLLUP (t.Anio, t.Mes)

-- Detalle mensual primero; subtotal y total después.
ORDER BY
    GROUPING(t.Anio), t.Anio,
    GROUPING(t.Mes), t.Mes;
GO

/* ============================================================
   RESULTADO ESPERADO

   Anio             Mes                Viajes   Importe
   --------------   ----------------   ------   -------
   2026             9                     4      65.00
   2026             10                    2      55.00
   2026             Subtotal anual        6     120.00
   TOTAL GENERAL    Todos los meses       6     120.00

   El subtotal anual y el total general coinciden porque el
   conjunto de práctica contiene viajes de un solo año.
   Si hubiera dos años, cada uno tendría su subtotal, pero
   existiría un único total general para ambos.
   ============================================================ */

/* ============================================================
   PRECISIÓN CONCEPTUAL PARA CLASE

   GROUPING(t.Mes) = 1 indica que Mes fue retirado por la
   operación de agregación.

   GROUPING(t.Mes) = 0 indica que Mes participa en ese nivel.
   Si t.Mes fuese NULL en los datos originales, GROUPING=0
   permitiría reconocer que se trata de un dato ausente
   y no de un subtotal.

   En los datos actuales no hay un Mes ausente. El ejercicio
   enseña a interpretar correctamente el marcador que deja
   ROLLUP; no demuestra un registro faltante real.
   ============================================================ */











   /* ============================================================
   EJERCICIO 01 - PASO 4A
   CUBE: TODAS LAS AGRUPACIONES DE DISTRITO Y SERVICIO
   ============================================================

   Con dos atributos, CUBE genera cuatro niveles:
   (Distrito, Servicio), (Distrito), (Servicio) y ().

   Con estos datos se esperan:
   - 4 combinaciones distrito-servicio presentes.
   - 3 subtotales por distrito.
   - 3 subtotales por servicio.
   - 1 total general.
   Total: 11 filas.
*/
SELECT
    u.Distrito,
    s.Servicio,
    COUNT(*) AS CantidadViajes
FROM dbo.FactViajeE04 AS h
INNER JOIN dbo.DimUbicacionE02 AS u
    ON u.UbicacionKey = h.UbicacionKey
INNER JOIN dbo.DimServicioE02 AS s
    ON s.ServicioKey = h.ServicioKey
GROUP BY CUBE (u.Distrito, s.Servicio)
ORDER BY
    GROUPING(u.Distrito), u.Distrito,
    GROUPING(s.Servicio), s.Servicio;
GO

/* Lectura de ejemplos:
   Comas + EJECUTIVO -> 2 viajes: combinación específica.
   Comas + NULL      -> 3 viajes: todos los servicios de Comas.
   NULL + ESTANDAR   -> 3 viajes: ESTANDAR en todos los distritos.
   NULL + NULL       -> 6 viajes: total general.

   Los NULL anteriores son marcadores de agrupación. Se pueden
   identificar formalmente con GROUPING, como en el Paso 3.
*/

/* ============================================================
   EJERCICIO 01 - PASO 4B
   GROUPING SETS: SOLO LOS NIVELES SOLICITADOS
   ============================================================

   Se piden tres conjuntos de agrupación:
   (Mes)       -> dos filas: meses 9 y 10.
   (Servicio)  -> tres filas: un total por servicio.
   ()          -> una fila: total general.
   Resultado esperado: 6 filas.
*/
SELECT
    t.Mes,
    s.Servicio,
    SUM(h.Importe) AS ImporteTotal
FROM dbo.FactViajeE04 AS h
INNER JOIN dbo.DimFechaE02 AS t
    ON t.FechaKey = h.FechaKey
INNER JOIN dbo.DimServicioE02 AS s
    ON s.ServicioKey = h.ServicioKey
GROUP BY GROUPING SETS
(
    (t.Mes),
    (s.Servicio),
    ()
)
ORDER BY
    GROUPING(t.Mes), t.Mes,
    GROUPING(s.Servicio), s.Servicio;
GO

/* Resultados de control:
   Mes 9:          65.00
   Mes 10:         55.00
   ESTANDAR:       60.00
   EJECUTIVO:      35.00
   ENCOMIENDA:     25.00
   Total general: 120.00

   Advertencia docente:
   No se deben sumar las seis filas entre sí: contienen niveles
   distintos y el importe de los viajes se repite en varios
   resúmenes.

   El conjunto de práctica tiene un solo año. Si se agregan
   varios años, agrupar únicamente por Mes reuniría, por
   ejemplo, todos los meses 9 de distintos años. En ese caso,
   el nivel temporal debería ser (Anio, Mes).
*/








/* ============================================================
   EJERCICIO 01 - TODO 1 RESUELTO
   ROLLUP POR SERVICIO Y DISTRITO
   ============================================================

   ROLLUP(Servicio, Distrito) produce:
   1. (Servicio, Distrito): detalle.
   2. (Servicio): subtotal del servicio en todos los distritos.
   3. (): total general.

   Servicio se escribe primero porque queremos conservarlo
   cuando ROLLUP retire Distrito.
*/
SELECT
    s.Servicio,
    u.Distrito,
    SUM(h.Importe) AS ImporteTotal
FROM dbo.FactViajeE04 AS h
INNER JOIN dbo.DimServicioE02 AS s
    ON s.ServicioKey = h.ServicioKey
INNER JOIN dbo.DimUbicacionE02 AS u
    ON u.UbicacionKey = h.UbicacionKey
GROUP BY ROLLUP (s.Servicio, u.Distrito)
ORDER BY
    GROUPING(s.Servicio), s.Servicio,
    GROUPING(u.Distrito), u.Distrito;
GO

/* Control:
   ESTANDAR, Distrito=NULL:    60.00
   EJECUTIVO, Distrito=NULL:   35.00
   ENCOMIENDA, Distrito=NULL:  25.00
   Servicio=NULL, Distrito=NULL: 120.00

   Hay cuatro combinaciones de detalle, tres subtotales
   por servicio y un total general: 8 filas.
*/






/* ============================================================
   EJERCICIO 01 - TODO 1B RESUELTO
   SUBTOTALES CON ETIQUETAS
   ============================================================ */
SELECT
    CASE
        -- Si se retiró Servicio, se retiraron todos los niveles:
        -- esta fila es el total general.
        WHEN GROUPING(s.Servicio) = 1 THEN 'TOTAL GENERAL'
        ELSE s.Servicio
    END AS Servicio,

    CASE
        -- Evaluar primero el total general evita llamarlo
        -- equivocadamente "Subtotal del servicio".
        WHEN GROUPING(s.Servicio) = 1 THEN 'Todos los distritos'

        -- Servicio permanece y Distrito fue retirado.
        WHEN GROUPING(u.Distrito) = 1 THEN 'Subtotal del servicio'
        ELSE u.Distrito
    END AS Distrito,

    COUNT(*) AS CantidadViajes,
    SUM(h.Importe) AS ImporteTotal

FROM dbo.FactViajeE04 AS h
INNER JOIN dbo.DimServicioE02 AS s
    ON s.ServicioKey = h.ServicioKey
INNER JOIN dbo.DimUbicacionE02 AS u
    ON u.UbicacionKey = h.UbicacionKey
GROUP BY ROLLUP (s.Servicio, u.Distrito)
ORDER BY
    GROUPING(s.Servicio), s.Servicio,
    GROUPING(u.Distrito), u.Distrito;
GO

/* Subtotales esperados:
   ESTANDAR:      3 viajes y 60.00.
   EJECUTIVO:     2 viajes y 35.00.
   ENCOMIENDA:    1 viaje  y 25.00.
   TOTAL GENERAL: 6 viajes y 120.00.

   GROUPING resulta más preciso que sustituir indiscriminadamente
   los NULL con una etiqueta: identifica el nivel que generó
   ROLLUP, incluso si en otros datos hubiese un NULL auténtico.
*/






/* ============================================================
   EJERCICIO 01 - TODO 2 RESUELTO
   ============================================================

   (1) CUBE(Distrito, Servicio) devuelve 11 filas:
       4 detalles + 3 subtotales por distrito +
       3 subtotales por servicio + 1 total general.

   (2) ROLLUP(Distrito, Servicio) devuelve 8 filas:
       4 detalles + 3 subtotales por distrito +
       1 total general.

   (3) Las TRES filas que aparecen solo con CUBE son
       los subtotales por servicio, sin distinguir distrito:
       ESTANDAR 3 viajes, EJECUTIVO 2 y ENCOMIENDA 1.

   Pregunta de negocio:
   "¿Cuántos viajes de cada servicio hubo en toda la operación,
   independientemente del distrito?"

   El orden también importa aquí: si se escribiera
   ROLLUP(Servicio, Distrito), sus subtotales serían por
   servicio, como en el TODO 1.
*/








/* ============================================================
   EJERCICIO 01 - TODO 3 RESUELTO
   PARTICIPACIÓN RESPECTO DE LOS 6 VIAJES
   ============================================================ */
SELECT
    u.Distrito,
    s.Servicio,
    COUNT(*) AS CantidadViajes,

    -- El numerador cambia según el grupo de esta fila.
    -- El denominador permanece en 6 viajes.
    CAST(
        COUNT(*) * 100.0
        / (SELECT COUNT(*) FROM dbo.FactViajeE04)
        AS DECIMAL(5, 2)
    ) AS PorcentajeDelTotal

FROM dbo.FactViajeE04 AS h
INNER JOIN dbo.DimUbicacionE02 AS u
    ON u.UbicacionKey = h.UbicacionKey
INNER JOIN dbo.DimServicioE02 AS s
    ON s.ServicioKey = h.ServicioKey

GROUP BY CUBE (u.Distrito, s.Servicio)
ORDER BY
    GROUPING(u.Distrito), u.Distrito,
    GROUPING(s.Servicio), s.Servicio;
GO

/* ============================================================
   RESPUESTAS ESPERADAS

   Subtotales POR SERVICIO:
   Distrito=NULL, ENCOMIENDA: 1/6 = 16.67 %.
   Distrito=NULL, EJECUTIVO:  2/6 = 33.33 %.
   Distrito=NULL, ESTANDAR:   3/6 = 50.00 %.

   Los tres subtotales por servicio suman 100 %.

   No se suman los porcentajes de las 11 filas porque CUBE
   muestra el mismo conjunto de viajes en cuatro niveles:
   detalle por combinación, subtotal por distrito, subtotal
   por servicio y total general. Sumarlos contaría varias
   veces los mismos viajes.
   ============================================================ */
