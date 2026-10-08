-- EJERCICIO 02 - PASO 1. PROYECTO Y ORIGEN DE DATOS

-- Aclarar al comenzar:
-- Hay dos servicios distintos. La conexión del origen de datos
-- apunta a SQL Server, donde están FactViajeE04 y las dimensiones.
-- La implementación del cubo, en el Paso 3, apunta a Analysis
-- Services. No intercambiar los nombres de esas instancias.

-- En el laboratorio ya se verificó la base relacional con el
-- Paso 0: 6 viajes y 120.00. Aquí no se vuelven a cargar datos.

-- La vista del origen debe contener cuatro tablas y tres enlaces:
-- FactViajeE04.FechaKey     -> DimFechaE02.FechaKey
-- FactViajeE04.ServicioKey  -> DimServicioE02.ServicioKey
-- FactViajeE04.UbicacionKey -> DimUbicacionE02.UbicacionKey

-- StgViajeE03, ViajeValidoE03 y ViajeRechazadoE03 pertenecen
-- al control del proceso ETL del Ejercicio 04. No se necesitan
-- para definir este cubo de viajes.

-- Una prueba de conexión correcta en Visual Studio comprueba
-- que el usuario conectado llega al origen. Durante el
-- procesamiento, Analysis Services accede con la identidad
-- indicada en la configuración de suplantación. Si luego
-- aparece "no se pudo establecer una conexión al origen de
-- datos", revisar esa identidad y sus permisos de lectura.


--Paso 4. Consulta resuelta
-- Origen del conjunto de datos dsViajesDistrito.
-- La conexión dsMoviTrack ya apunta a MoviTrackTema05_Practica.
-- No se agrega GROUP BY: cada fila corresponde a un viaje.

SELECT
    h.CodigoViaje,
    t.Fecha     AS Fecha,
    s.Servicio  AS Servicio,
    u.Distrito  AS Distrito,
    h.Importe
FROM dbo.FactViajeE04 AS h
INNER JOIN dbo.DimFechaE02 AS t
    ON t.FechaKey = h.FechaKey
INNER JOIN dbo.DimServicioE02 AS s
    ON s.ServicioKey = h.ServicioKey
INNER JOIN dbo.DimUbicacionE02 AS u
    ON u.UbicacionKey = h.UbicacionKey
WHERE u.Distrito = @Distrito
ORDER BY h.CodigoViaje;

/*Lectura docente: las claves subrogadas permiten recuperar las descripciones 
de las dimensiones. @Distrito limita los viajes recuperados por el conjunto 
de datos; el total de la tabla se calcula después sobre ese detalle filtrado. 
En Report Builder, verifica la asociación del 
parámetro de consulta @Distrito con =Parameters!Distrito.
Value si no quedó configurada automáticamente. Microsoft Learn
Para Comas, la comprobación es tres filas de detalle 
y un pie con TOTAL VIAJES: 3 e Importe: 65.00. 
La fila de total pertenece al diseño del reporte, 
mientras que la consulta sigue devolviendo el detalle de cada viaje.
*/


