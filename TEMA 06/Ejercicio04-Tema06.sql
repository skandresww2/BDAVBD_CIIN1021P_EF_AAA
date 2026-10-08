-- Paso 1. Contar los registros de cada etapa del ETL.
WITH Conteos AS
(
    SELECT
        (SELECT COUNT(*) FROM dbo.StgViajeE03)       AS Recibidos,
        (SELECT COUNT(*) FROM dbo.ViajeValidoE03)    AS Aceptados,
        (SELECT COUNT(*) FROM dbo.ViajeRechazadoE03) AS Rechazados
)
-- Paso 2. Calcular la tasa y comprobar que todos fueron clasificados.
SELECT
    Recibidos,
    Aceptados,
    Rechazados,
    CAST(
        100.0 * Aceptados / NULLIF(Recibidos, 0)
        AS DECIMAL(5, 2)
    ) AS TasaAceptacion,
    Recibidos - Aceptados - Rechazados AS SinClasificar
FROM Conteos;



-- TODO 2 resuelto: contar los rechazos por motivo.
SELECT
    MotivoRechazo,
    COUNT(*) AS Cantidad
FROM dbo.ViajeRechazadoE03
GROUP BY MotivoRechazo
ORDER BY MotivoRechazo;

--Parte D — Privacidad
--TODO 4 — solución docente
SELECT
    u.Distrito,
    s.Servicio,
    COUNT(*) AS CantidadViajes
FROM dbo.FactViajeE04 AS h
INNER JOIN dbo.DimUbicacionE02 AS u
    ON u.UbicacionKey = h.UbicacionKey
INNER JOIN dbo.DimServicioE02 AS s
    ON s.ServicioKey = h.ServicioKey
GROUP BY
    u.Distrito,
    s.Servicio
HAVING
    COUNT(*) < 2
ORDER BY
    u.Distrito,
    s.Servicio;
GO