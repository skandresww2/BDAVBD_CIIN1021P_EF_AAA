USE [master];
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE name = N'NT SERVICE\MSSQLServerOLAPService'
)
    CREATE LOGIN [NT SERVICE\MSSQLServerOLAPService] FROM WINDOWS;
GO

USE [MoviTrackTema05_Practica];
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'NT SERVICE\MSSQLServerOLAPService'
)
    CREATE USER [NT SERVICE\MSSQLServerOLAPService]
    FOR LOGIN [NT SERVICE\MSSQLServerOLAPService];
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members AS rm
    JOIN sys.database_principals AS r
        ON r.principal_id = rm.role_principal_id
    JOIN sys.database_principals AS u
        ON u.principal_id = rm.member_principal_id
    WHERE r.name = N'db_datareader'
      AND u.name = N'NT SERVICE\MSSQLServerOLAPService'
)
    ALTER ROLE [db_datareader]
    ADD MEMBER [NT SERVICE\MSSQLServerOLAPService];
GO

-- Comprobación: debe mostrar la cuenta y el rol db_datareader.
SELECT u.name AS Cuenta, r.name AS Rol
FROM sys.database_role_members AS rm
JOIN sys.database_principals AS r
    ON r.principal_id = rm.role_principal_id
JOIN sys.database_principals AS u
    ON u.principal_id = rm.member_principal_id
WHERE u.name = N'NT SERVICE\MSSQLServerOLAPService';
GO