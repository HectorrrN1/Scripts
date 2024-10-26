-- ===================================================================
-- Autores:        Hector Nuñez Cruz
-- Create date:    20 Octubre 2024
-- Modification date: 20 Octubre 2024
-- Description:    Creación de base de datos
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

IF OBJECT_ID('dbo.Roles', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Roles;
END

IF OBJECT_ID('dbo.UserRoles', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.UserRoles;
END

IF OBJECT_ID('dbo.PurchaseRequests', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.PurchaseRequests;
END

IF OBJECT_ID('dbo.Transactions', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Transactions;
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
    UpdatedAt DATETIME NOT NULL
);
GO
PRINT 'COMPILACIÓN CORRECTA --> Tabla Users';
GO

-- Crear la tabla Roles
CREATE TABLE Roles (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    Name VARCHAR(10) UNIQUE NOT NULL  -- Puede ser 'ADMIN', 'SELLER', 'BUYER'
);
GO
PRINT 'COMPILACIÓN CORRECTA --> Tabla Roles';
GO

-- Crear la tabla UserRoles (muchos a muchos entre Users y Roles)
CREATE TABLE UserRoles (
    IdUser UNIQUEIDENTIFIER NOT NULL,
    IdRole UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY (IdUser, IdRole),
    FOREIGN KEY (IdUser) REFERENCES Users(Id) ON DELETE CASCADE,
    FOREIGN KEY (IdRole) REFERENCES Roles(Id) ON DELETE CASCADE
);
GO
PRINT 'COMPILACIÓN CORRECTA --> Tabla UserRoles';
GO

-- Crear la tabla Sellers (vendedores)
CREATE TABLE Sellers (
    Id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    StoreName VARCHAR(120) NOT NULL,
    Street VARCHAR(100) NOT NULL,
    ExtNumber VARCHAR(6),
    IntNumber VARCHAR(6),
    Neighborhood VARCHAR(100),
    City VARCHAR(100),
    State VARCHAR(100),
    Country VARCHAR(100),
    CP VARCHAR(10) NOT NULL,
    AddressNotes VARCHAR(255),
    CreatedAt DATETIME NOT NULL,
    UpdatedAt DATETIME NOT NULL,
    IdUser UNIQUEIDENTIFIER NOT NULL,
    FOREIGN KEY (IdUser) REFERENCES Users(Id) ON DELETE CASCADE
);
GO
PRINT 'COMPILACIÓN CORRECTA --> Tabla Sellers';
GO

-- Crear la tabla Products (productos de los vendedores)
CREATE TABLE Products (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    Name NVARCHAR(120) NOT NULL,
    Description NVARCHAR(512) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    Image VARCHAR(255),  -- URL de la imagen del producto
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IdSeller UNIQUEIDENTIFIER NOT NULL,
    FOREIGN KEY (IdSeller) REFERENCES Sellers(Id) ON DELETE CASCADE
);
GO
PRINT 'COMPILACIÓN CORRECTA --> Tabla Products';
GO

-- Crear la tabla RefreshTokens (sesiones con tokens de refresco)
CREATE TABLE RefreshTokens (
    RefreshTokenId UNIQUEIDENTIFIER PRIMARY KEY,
    RefreshTokenValue VARCHAR(255) NOT NULL,
    Active BIT NOT NULL,
    Creation DATETIME NOT NULL,
    Expiration DATETIME NOT NULL,
    Used BIT NOT NULL,
    UserId UNIQUEIDENTIFIER NOT NULL,
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
);
GO
PRINT 'COMPILACIÓN CORRECTA --> Tabla RefreshTokens';
GO

-- Crear la tabla PurchaseRequests (solicitudes de compra)
CREATE TABLE PurchaseRequests (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    IdProduct UNIQUEIDENTIFIER NOT NULL,
    IdBuyer UNIQUEIDENTIFIER NOT NULL,
    RequestDate DATETIME NOT NULL DEFAULT GETDATE(),
    Status VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- Puede ser 'PENDING', 'ACCEPTED', 'REJECTED'
    FOREIGN KEY (IdProduct) REFERENCES Products(Id) ON DELETE CASCADE,
    FOREIGN KEY (IdBuyer) REFERENCES Users(Id) ON DELETE NO ACTION
);
GO
PRINT 'COMPILACIÓN CORRECTA --> Tabla PurchaseRequests';
GO

-- Crear la tabla Transactions (transacciones de ventas)
CREATE TABLE Transactions (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    IdPurchaseRequest UNIQUEIDENTIFIER NOT NULL,
    TransactionDate DATETIME NOT NULL DEFAULT GETDATE(),
    Status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',  -- 'COMPLETED' o 'CANCELLED'
    FOREIGN KEY (IdPurchaseRequest) REFERENCES PurchaseRequests(Id) ON DELETE CASCADE
);
GO
PRINT 'COMPILACIÓN CORRECTA --> Tabla Transactions';
GO

-- Agregar los roles básicos (ADMIN, SELLER, BUYER)
INSERT INTO Roles (Id, Name)
VALUES (NEWID(), 'ADMIN'), (NEWID(), 'SELLER'), (NEWID(), 'BUYER');
GO
PRINT 'COMPILACIÓN CORRECTA --> Inserción de roles básicos';
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
-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   22 Octubre 2024
-- Modification date: 22 Octubre 2024
-- Description:   SP para solicitud de producto
-- --------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_PurchaseRequest_Create]
    @IdProduct UNIQUEIDENTIFIER,
    @IdBuyer UNIQUEIDENTIFIER,
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si el producto existe
        IF NOT EXISTS (SELECT 1 FROM Products WHERE Id = @IdProduct)
        BEGIN
            SET @Result = 'El producto no existe';
            SET @NumError = 2;
            RETURN;
        END

        -- Insertar la solicitud de compra
        INSERT INTO PurchaseRequests (Id, IdProduct, IdBuyer, RequestDate, Status)
        VALUES (NEWID(), @IdProduct, @IdBuyer, GETDATE(), 'PENDING');

        SET @Result = 'Solicitud de compra creada con éxito';
        SET @NumError = 1;
    END TRY
    BEGIN CATCH
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE();
        --SET @Result = 'Error en Base de Datos: ' + CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE();
		 SET @Result = 'Success';
        SET @NumError = 3;        
        RAISERROR(@Result, @severity, @state);
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_PurchaseRequest_Create';
GO

-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   22 Octubre 2024
-- Modification date: 22 Octubre 2024
-- Description:   SP para visualizar solicitud (Vendedor)
-- --------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_PurchaseRequests_ViewBySeller]
    @IdSeller UNIQUEIDENTIFIER,
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si el vendedor existe
        IF NOT EXISTS (SELECT 1 FROM Sellers WHERE Id = @IdSeller)
        BEGIN
            SET @Result = 'El vendedor no existe';
            SET @NumError = 2;
            RETURN;
        END

        -- Mostrar solicitudes de productos del vendedor
        SELECT 
            pr.Id AS RequestId,
            p.Name AS ProductName,
            pr.RequestDate AS RequestDate,
            pr.Status AS Status,
            u.Fullname AS BuyerName
        FROM PurchaseRequests pr
        JOIN Products p ON pr.IdProduct = p.Id
        JOIN Users u ON pr.IdBuyer = u.Id
        WHERE p.IdSeller = @IdSeller;

        SET @Result = 'Operación Correcta';
        SET @NumError = 1;
    END TRY
    BEGIN CATCH
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE();
        SET @Result = 'Error en Base de Datos: ' + CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE();    
        SET @NumError = 3;        
        RAISERROR(@Result, @severity, @state);
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_PurchaseRequests_ViewBySeller';
GO

-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   22 Octubre 2024
-- Modification date: 22 Octubre 2024
-- Description:  SP para visualizar solicitud (Comprador)
-- --------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_PurchaseRequests_ViewByBuyer]
    @IdBuyer UNIQUEIDENTIFIER,
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si el comprador existe
        IF NOT EXISTS (SELECT 1 FROM Users WHERE Id = @IdBuyer AND IsBuyer = 1)
        BEGIN
            SET @Result = 'El comprador no existe';
            SET @NumError = 2;
            RETURN;
        END

        -- Mostrar solicitudes del comprador
        SELECT 
            pr.Id AS RequestId,
            p.Name AS ProductName,
            pr.RequestDate AS RequestDate,
            pr.Status AS Status
        FROM PurchaseRequests pr
        JOIN Products p ON pr.IdProduct = p.Id
        WHERE pr.IdBuyer = @IdBuyer;

        SET @Result = 'Operación Correcta';
        SET @NumError = 1;
    END TRY
    BEGIN CATCH
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE();
        SET @Result = 'Error en Base de Datos: ' + CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE();    
        SET @NumError = 3;        
        RAISERROR(@Result, @severity, @state);
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_PurchaseRequests_ViewByBuyer';
GO

-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   22 Octubre 2024
-- Modification date: 22 Octubre 2024
-- Description:   SP para rechazar solicitud (Vendedor)
-- --------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_PurchaseRequest_Reject]
    @IdRequest UNIQUEIDENTIFIER,
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si la solicitud existe y su estado es 'PENDING'
        IF NOT EXISTS (SELECT 1 FROM PurchaseRequests WHERE Id = @IdRequest AND Status = 'PENDING')
        BEGIN
            SET @Result = 'La solicitud no existe o ya fue procesada';
            SET @NumError = 2;
            RETURN;
        END

        -- Actualizar el estado de la solicitud a 'REJECTED'
        UPDATE PurchaseRequests
        SET Status = 'REJECTED'
        WHERE Id = @IdRequest;

        SET @Result = 'Solicitud rechazada con éxito';
        SET @NumError = 1;
    END TRY
    BEGIN CATCH
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE();
        SET @Result = 'Error en Base de Datos: ' + CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE();    
        SET @NumError = 3;        
        RAISERROR(@Result, @severity, @state);
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_PurchaseRequest_Reject';
GO

-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   22 Octubre 2024
-- Modification date: 22 Octubre 2024
-- Description:   SP para cancelar solicitud (Comprador)
-- --------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_PurchaseRequest_Cancel]
    @IdRequest UNIQUEIDENTIFIER,
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si la solicitud existe y su estado es 'PENDING'
        IF NOT EXISTS (SELECT 1 FROM PurchaseRequests WHERE Id = @IdRequest AND Status = 'PENDING')
        BEGIN
            SET @Result = 'La solicitud no existe o ya fue procesada';
            SET @NumError = 2;
            RETURN;
        END

        -- Actualizar el estado de la solicitud a 'CANCELLED'
        UPDATE PurchaseRequests
        SET Status = 'CANCELLED'
        WHERE Id = @IdRequest;

        SET @Result = 'Solicitud cancelada con éxito';
        SET @NumError = 1;
    END TRY
    BEGIN CATCH
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE();
        SET @Result = 'Error en Base de Datos: ' + CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE();    
        SET @NumError = 3;        
        RAISERROR(@Result, @severity, @state);
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_PurchaseRequest_Cancel';
GO

-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   24 Octubre 2024
-- Modification date: 24 Octubre 2024
-- Description:   SP para agregar producto mediante la solicitud
-- --------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_Transaction_Add]
    @IdPurchaseRequest UNIQUEIDENTIFIER,
    @Status VARCHAR(20) = 'COMPLETED',  -- 'COMPLETED' o 'CANCELLED'
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si la solicitud de compra existe
        IF NOT EXISTS (SELECT 1 FROM PurchaseRequests WHERE Id = @IdPurchaseRequest)
        BEGIN
            SET @Result = 'La solicitud de compra no existe';
            SET @NumError = 2;
            RETURN;
        END

        -- Insertar la nueva transacción
        INSERT INTO Transactions (Id, IdPurchaseRequest, TransactionDate, Status)
        VALUES (NEWID(), @IdPurchaseRequest, GETDATE(), @Status);

        SET @Result = 'Transacción agregada con éxito';
        SET @NumError = 1;
    END TRY
    BEGIN CATCH
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE();
        SET @Result = 'Error en Base de Datos: ' + CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE();
        SET @NumError = 3;
        RAISERROR(@Result, @severity, @state);
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_Transaction_Add';
GO

-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   24 Octubre 2024
-- Modification date: 24 Octubre 2024
-- Description:   SP para cnsultar estado de transacción
-- --------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_Transaction_GetStatus]
    @IdTransaction UNIQUEIDENTIFIER,
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si la transacción existe
        IF NOT EXISTS (SELECT 1 FROM Transactions WHERE Id = @IdTransaction)
        BEGIN
            SET @Result = 'La transacción no existe';
            SET @NumError = 2;
            RETURN;
        END

        -- Obtener el estado de la transacción
        DECLARE @TransactionStatus VARCHAR(20);
        SELECT @TransactionStatus = Status FROM Transactions WHERE Id = @IdTransaction;

        SET @Result = 'Estado de la transacción: ' + @TransactionStatus;
        SET @NumError = 1;
    END TRY
    BEGIN CATCH
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE();
        SET @Result = 'Error en Base de Datos: ' + CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE();
        SET @NumError = 3;
        RAISERROR(@Result, @severity, @state);
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_Transaction_GetStatus';
GO


