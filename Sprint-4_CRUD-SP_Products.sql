-- ===================================================================
-- Authores:      Hector Nuñez Cruz
-- Create date:   20 Octubre 2024
-- Modification date: 21 Octubre 2024
-- Description:   Sprint-4_Script para entorno de desarrollo
-- ===================================================================

-- Crear la base de datos si no existe
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ChepeatDev')
BEGIN
    CREATE DATABASE [ChepeatDev];
END
GO
PRINT 'COMPILACIÓN CORRECTA --> BD ChepeatDev';
GO

-- Acceder a la base de datos
USE [ChepeatDev];
GO
PRINT 'COMPILACIÓN CORRECTA --> Acceso a BD';
GO

-- Verificar si existen tablas y eliminarlas para reiniciar el entorno de desarrollo
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Products;
END
GO

IF OBJECT_ID('dbo.Sellers', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Sellers;
END

IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Users;
END

IF OBJECT_ID('dbo.RefreshTokens', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.RefreshTokens;
END
GO
PRINT 'COMPILACIÓN CORRECTA --> Eliminación exitosa de las tablas existentes';
GO

-- Crear la tabla Users
CREATE TABLE Users (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    Email VARCHAR(255) UNIQUE NOT NULL,
    Password VARCHAR(255) NOT NULL,
    Fullname VARCHAR(120) NOT NULL,
	IsAdmin BIT NOT NULL,
	IsBuyer BIT NOT NULL,
	IsSeller BIT NOT NULL,
	CreatedAt DATETIME NOT NULL,
	UpdatedAt DATETIME NOT NULL,
);
GO
PRINT 'COMPILACIÓN CORRECTA --> Tabla Users';
GO

-- Crear la tabla para los datos de usuarios vendedores
CREATE TABLE Sellers (
    Id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    StoreName VARCHAR(120),
	-- Description VARCHAR(255),
    -- Street VARCHAR(100),
    -- ExtNumber VARCHAR(6),
    -- IntNumber VARCHAR(6),
    -- Neighborhood VARCHAR(100),
    -- City VARCHAR(100),
    -- State VARCHAR(100),
    -- CP VARCHAR(10),
	-- Altitude VARCHAR(50),
	-- Longitude VARCHAR(50),
    -- AddressNotes VARCHAR(255),
	CreatedAt DATETIME NOT NULL,
	UpdatedAt DATETIME NOT NULL,
	IdUser UNIQUEIDENTIFIER NOT NULL,
    FOREIGN KEY (IdUser) REFERENCES Users(Id) ON DELETE CASCADE
);
GO
PRINT 'COMPILACIÓN CORRECTA --> Tabla Sellers';
GO

-- Crear la tabla de las sesiones con RefreshToken
Create table RefreshTokens(
	RefreshTokenId UNIQUEIDENTIFIER Not Null Primary Key,
	RefreshTokenValue VARCHAR(255) NOT null,
	Active BIT NOT NULL,
	Creation DateTime NOT null,
	Expiration DateTime Not null,
	Used BIT NOT NULL,
	UserId UNIQUEIDENTIFIER Not Null,
);
GO
PRINT 'COMPILACIÓN CORRECTA --> Tabla RefreshTokens';
GO

-- Crear la tabla de Products de los vendedores
CREATE TABLE Products(
	Id UNIQUEIDENTIFIER PRIMARY KEY,
	Name NVARCHAR(120) NOT NULL,
	Description NVARCHAR(512) NOT NULL,
	Price DECIMAL(10, 2) NOT NULL,
	CreatedAT DATETIME NOT NULL,
	UpdatedAt DATETIME NOT NULL,
	IdSeller UNIQUEIDENTIFIER NOT NULL,
	FOREIGN KEY (IdSeller) REFERENCES Sellers(Id) ON DELETE CASCADE
);
GO
PRINT 'COMPILACIÓN CORRECTA --> Tabla Products';
GO

-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   20 Octubre 2024
-- Modification date: 21 Octubre 2024
-- Description:   SP para consulta de tabla Products
-- -------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_Products_Selection]
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY        
        BEGIN            
            SELECT 
                p.Id AS Id,
                p.Name AS Name,
                p.Description AS Description,
                p.Price AS Price,
                p.CreatedAT AS CreatedAT,
                p.UpdatedAt AS UpdatedAt,
                p.IdSeller AS IdSeller
            FROM Products p;

            SET @Result = 'Operación Correcta';
            SET @NumError = 1;
        END
    END TRY
    BEGIN CATCH
        IF (xact_state()) = -1
            ROLLBACK TRANSACTION;
        IF (xact_state()) = 1
            COMMIT TRANSACTION;
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE();        
        SET @Result = 'Error en Base de Datos: ' + CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE();    
        SET @NumError = 3;        
        RAISERROR(@Result, @severity, @state);
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_Products_Selection';
GO

-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   20 Octubre 2024
-- Modification date: 21 Octubre 2024
-- Description:   SP para insertar en tabla Products
-- -------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_Products_Insert]
    @Name NVARCHAR(120),
    @Description NVARCHAR(512),
    @Price DECIMAL(10, 2),
    @IdSeller UNIQUEIDENTIFIER,
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY        
        BEGIN            
            INSERT INTO Products (Id, Name, Description, Price, CreatedAT, UpdatedAt, IdSeller)
            VALUES (NEWID(), @Name, @Description, @Price, GETDATE(), GETDATE(), @IdSeller);

            SET @Result = 'Producto Agregado Correctamente';
            SET @NumError = 1;
        END
    END TRY
    BEGIN CATCH
        IF (xact_state()) = -1
            ROLLBACK TRANSACTION;
        IF (xact_state()) = 1
            COMMIT TRANSACTION;
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE();        
        SET @Result = 'Error en Base de Datos: ' + CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE();    
        SET @NumError = 3;        
        RAISERROR(@Result, @severity, @state);
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_Products_Insert';
GO

-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   20 Octubre 2024
-- Modification date: 21 Octubre 2024
-- Description:   SP para eliminar en tabla Products
-- -------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_Products_Delete]
    @Id UNIQUEIDENTIFIER,
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY        
        BEGIN            
            DELETE FROM Products
            WHERE Id = @Id;

            SET @Result = 'Producto Eliminado Correctamente';
            SET @NumError = 1;
        END
    END TRY
    BEGIN CATCH
        IF (xact_state()) = -1
            ROLLBACK TRANSACTION;
        IF (xact_state()) = 1
            COMMIT TRANSACTION;
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE();        
        SET @Result = 'Error en Base de Datos: ' + CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE();    
        SET @NumError = 3;        
        RAISERROR(@Result, @severity, @state);
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_Products_Delete';
GO

-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   20 Octubre 2024
-- Modification date: 21 Octubre 2024
-- Description:   SP para editar en tabla Products
-- --------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_Products_Update]
    @Id UNIQUEIDENTIFIER,
    @Name NVARCHAR(120),
    @Description NVARCHAR(512),
    @Price DECIMAL(10, 2),
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY        
        BEGIN            
            UPDATE Products
            SET 
                Name = @Name,
                Description = @Description,
                Price = @Price,
                UpdatedAt = GETDATE()
            WHERE Id = @Id;

            SET @Result = 'Producto Actualizado Correctamente';
            SET @NumError = 1;
        END
    END TRY
    BEGIN CATCH
        IF (xact_state()) = -1
            ROLLBACK TRANSACTION;
        IF (xact_state()) = 1
            COMMIT TRANSACTION;
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE();        
        SET @Result = 'Error en Base de Datos: ' + CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE();    
        SET @NumError = 3;        
        RAISERROR(@Result, @severity, @state);
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_Products_Update';
GO
