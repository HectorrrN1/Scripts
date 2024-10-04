-- ====================================================
-- Author:        Alexis Eduardo Santana Vega
-- Create date:   3 Octubre 2024
-- Description:   Script para entorno de desarrollo
-- ====================================================

-- Crear la base de datos si no existe (común en entornos de desarrollo)
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'Chepeat')
BEGIN
    CREATE DATABASE [Chepeat];
END
GO

-- Acceder a la base de datos
USE [Chepeat];
GO

-- Verificar si existen tablas y eliminarlas para reiniciar el entorno de desarrollo
IF OBJECT_ID('dbo.UserRoles', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.UserRoles;
END

IF OBJECT_ID('dbo.Sellers', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Sellers;
END

IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Users;
END

IF OBJECT_ID('dbo.Roles', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Roles;
END
GO

-- Crear la tabla Users
CREATE TABLE Users (
    Id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    Email VARCHAR(255) UNIQUE NOT NULL,
    Password VARCHAR(255) NOT NULL,
    Fullname VARCHAR(120) NOT NULL
);
GO

-- Crear la tabla Roles
CREATE TABLE Roles (
    Id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    Name VARCHAR(6) UNIQUE NOT NULL
);
GO

-- Crear la tabla intermedia (relación muchos a muchos) entre usuarios y roles
CREATE TABLE UserRoles (
    IdUser UNIQUEIDENTIFIER NOT NULL,
    IdRol UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY (IdUser, IdRol),
    FOREIGN KEY (IdUser) REFERENCES Users(Id) ON DELETE CASCADE,
    FOREIGN KEY (IdRol) REFERENCES Roles(Id) ON DELETE CASCADE
);
GO

-- Crear la tabla para los datos de usuarios vendedores
CREATE TABLE Sellers (
    Id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    StoreName VARCHAR(120),
    Street VARCHAR(100),
    ExtNumber VARCHAR(6),
    IntNumber VARCHAR(6),
    Neighborhood VARCHAR(100),
    City VARCHAR(100),
    State VARCHAR(100),
	Altitude VARCHAR(50),
	Longitude VARCHAR(50),
    CP VARCHAR(10),
    AddressNotes VARCHAR(255),
    IdUser UNIQUEIDENTIFIER NOT NULL,
    FOREIGN KEY (IdUser) REFERENCES Users(Id) ON DELETE CASCADE
);
GO

-- Agregar los roles básicos utilizando transacción en caso de error
BEGIN TRANSACTION;
BEGIN TRY
	-- Inserçión de los roles
    INSERT INTO Roles (Id, Name)
    VALUES 
    ('B04AFC35-4390-4D47-B128-41E0E034FC21', 'ADMIN'), 
    ('FA43C966-0237-4B14-BA3F-B2DF1756AFA6', 'SELLER'), 
    ('5D2FA8B2-3E2B-41B9-AF5E-D931DE370E71', 'BUYER');
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    THROW; -- Re-lanzar la excepción si ocurre algún error
END CATCH;
GO


-- =============================================
-- Author:        Alexis Eduardo Santana Vega
-- Create date:   3 Octubre 2024
-- Description:   Consulta hacia la tabla CE_Users
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[SP_Users_Selection]
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY        
    BEGIN            
        -- Operacion del SP
		SELECT 
			u.Id AS Id,
			u.Email AS Email,
			u.Password AS Password,
			u.Fullname AS Fullname
			FROM Users u

        SET @Result = 'Operación Correcta'
        SET @NumError = 1
    END
    END TRY
    BEGIN CATCH
        if (xact_state()) = -1
            rollback transaction
        if (xact_state()) = 1
            commit transaction
        declare @severity int = error_severity(), @state int = error_state()        
        set @Result = 'Se ha presentado un error en Base de Datos: ' + (select convert(nvarchar(2048), error_number()) + ' - ' + error_message())    
        SET @NumError = 3;        
        raiserror(@Result, @severity, @state)
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_Users_Selection'


-- =============================================
-- Author: <Hector Nuñez>
-- <Create date: 04/10/2024>
-- <Description: Eliminacion de registros de la tabla CE_User>
-- =============================================

CREATE PROCEDURE sp_user_delete
    @UserID UNIQUEIDENTIFIER,
    @TipoError int OUTPUT,
    @Mensaje varchar(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Eliminar el usuario basado en el ID proporcionado
        DELETE FROM Users
        WHERE Id = @UserID;

        SET @TipoError = 1;
        SET @Mensaje = 'Usuario eliminado correctamente';
    END TRY
    BEGIN CATCH
        
        IF (XACT_STATE() = -1)
            ROLLBACK TRANSACTION;
        IF (XACT_STATE() = 1)
            COMMIT TRANSACTION;

    
        SET @TipoError = 2;
        SET @Mensaje = 'Ha ocurrido un error al eliminar el usuario';
    END CATCH
END;

 -- Como ejecutar el store procedure

DECLARE @TipoError int;
DECLARE @Mensaje varchar(50);

EXEC sp_user_delete 
    @UserID = '1AFDDB17-A523-4586-BA1C-04957268D9CB', -- Reemplaza con el GUID del usuario
    @TipoError = @TipoError OUTPUT, 
    @Mensaje = @Mensaje OUTPUT;

-- Mostrar los resultados de las variables de salida
SELECT @TipoError AS TipoError, @Mensaje AS Mensaje;