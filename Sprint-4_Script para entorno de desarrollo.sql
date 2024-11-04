-- ===================================================================
-- Autores:        Hector Nuñez Cruz
-- Create date:    20 Octubre 2024
-- Modification date: 30 Octubre 2024
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

-- Deshabilitar temporalmente las restricciones de claves foráneas para eliminar tablas sin problemas
ALTER TABLE dbo.Comments DROP CONSTRAINT IF EXISTS FK_Comments_IdUser;
ALTER TABLE dbo.Comments DROP CONSTRAINT IF EXISTS FK_Comments_IdSeller;
ALTER TABLE dbo.Comments DROP CONSTRAINT IF EXISTS FK_Comments_IdTransaction;
ALTER TABLE dbo.Transactions DROP CONSTRAINT IF EXISTS FK_Transactions_IdPurchaseRequest;
ALTER TABLE dbo.PurchaseRequests DROP CONSTRAINT IF EXISTS FK_PurchaseRequests_IdProduct;
ALTER TABLE dbo.PurchaseRequests DROP CONSTRAINT IF EXISTS FK_PurchaseRequests_IdBuyer;
ALTER TABLE dbo.RefreshTokens DROP CONSTRAINT IF EXISTS FK_RefreshTokens_UserId;
ALTER TABLE dbo.Products DROP CONSTRAINT IF EXISTS FK_Products_IdSeller;
ALTER TABLE dbo.Sellers DROP CONSTRAINT IF EXISTS FK_Sellers_IdUser;
ALTER TABLE dbo.UserRoles DROP CONSTRAINT IF EXISTS FK_UserRoles_IdUser;
ALTER TABLE dbo.UserRoles DROP CONSTRAINT IF EXISTS FK_UserRoles_IdRole;

-- Verificar si existen tablas y eliminarlas para reiniciar el entorno de desarrollo
IF OBJECT_ID('dbo.Comments', 'U') IS NOT NULL DROP TABLE dbo.Comments;
IF OBJECT_ID('dbo.Transactions', 'U') IS NOT NULL DROP TABLE dbo.Transactions;
IF OBJECT_ID('dbo.PurchaseRequests', 'U') IS NOT NULL DROP TABLE dbo.PurchaseRequests;
IF OBJECT_ID('dbo.RefreshTokens', 'U') IS NOT NULL DROP TABLE dbo.RefreshTokens;
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL DROP TABLE dbo.Products;
IF OBJECT_ID('dbo.Sellers', 'U') IS NOT NULL DROP TABLE dbo.Sellers;
IF OBJECT_ID('dbo.UserRoles', 'U') IS NOT NULL DROP TABLE dbo.UserRoles;
IF OBJECT_ID('dbo.Roles', 'U') IS NOT NULL DROP TABLE dbo.Roles;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;

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
    Rating DECIMAL(3, 2) DEFAULT 0.0,  -- Campo de rating para almacenar la puntuación promedio
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

-- Crear la tabla Comments (comentarios de clientes a vendedores)
CREATE TABLE Comments (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    IdUser UNIQUEIDENTIFIER NOT NULL,  -- Cliente que hace el comentario
    IdSeller UNIQUEIDENTIFIER NOT NULL,  -- Vendedor que recibe el comentario
    IdTransaction UNIQUEIDENTIFIER NOT NULL,  -- Transacción a la que está relacionado el comentario
    Message NVARCHAR(512) NOT NULL,  -- Mensaje del comentario
    Rating DECIMAL(3, 2) NOT NULL CHECK (Rating BETWEEN 1 AND 5),  -- Puntuación de 0 a 10
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (IdUser) REFERENCES Users(Id) ON DELETE NO ACTION,
    FOREIGN KEY (IdSeller) REFERENCES Sellers(Id) ON DELETE CASCADE,
    FOREIGN KEY (IdTransaction) REFERENCES Transactions(Id) ON DELETE NO ACTION
);
GO
PRINT 'COMPILACIÓN CORRECTA --> Tabla Comments';
GO

-- Agregar los roles básicos (ADMIN, SELLER, BUYER) solo si no existen
IF NOT EXISTS (SELECT 1 FROM Roles WHERE Name = 'ADMIN')
    INSERT INTO Roles (Id, Name) VALUES (NEWID(), 'ADMIN');
IF NOT EXISTS (SELECT 1 FROM Roles WHERE Name = 'SELLER')
    INSERT INTO Roles (Id, Name) VALUES (NEWID(), 'SELLER');
IF NOT EXISTS (SELECT 1 FROM Roles WHERE Name = 'BUYER')
    INSERT INTO Roles (Id, Name) VALUES (NEWID(), 'BUYER');
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


-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   3 Noviembre 2024
-- Modification date: 3 Noviembre 2024
-- Description:   SP para insertar un comentario al vendedor
-- --------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_Comments_Add]
    @IdUser UNIQUEIDENTIFIER,
    @IdSeller UNIQUEIDENTIFIER,
    @IdTransaction UNIQUEIDENTIFIER,
    @Message NVARCHAR(512),
    @Rating DECIMAL(3,2),
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    BEGIN
        -- Verificar que la transacción existe y está completada
        IF NOT EXISTS (SELECT 1 FROM Transactions 
                      WHERE Id = @IdTransaction 
                      AND Status = 'COMPLETED')
        BEGIN
            SET @Result = 'La transacción no existe o no está completada'
            SET @NumError = 2
            RETURN
        END

        -- Verificar que el usuario existe
        IF NOT EXISTS (SELECT 1 FROM Users WHERE Id = @IdUser)
        BEGIN
            SET @Result = 'El usuario no existe'
            SET @NumError = 2
            RETURN
        END

        -- Verificar que el vendedor existe
        IF NOT EXISTS (SELECT 1 FROM Sellers WHERE Id = @IdSeller)
        BEGIN
            SET @Result = 'El vendedor no existe'
            SET @NumError = 2
            RETURN
        END

        -- Verificar que el rating está entre 1 y 5
        IF @Rating < 1 OR @Rating > 5
        BEGIN
            SET @Result = 'El rating debe estar entre 1 y 5'
            SET @NumError = 2
            RETURN
        END

        -- Insertar el comentario
        INSERT INTO Comments (Id, IdUser, IdSeller, IdTransaction, Message, Rating, CreatedAt)
        VALUES (NEWID(), @IdUser, @IdSeller, @IdTransaction, @Message, @Rating, GETDATE());

        -- Actualizar el rating promedio del vendedor
        UPDATE Sellers
        SET Rating = (
            SELECT AVG(Rating)
            FROM Comments
            WHERE IdSeller = @IdSeller
        )
        WHERE Id = @IdSeller;

        SET @Result = 'Operación Correcta'
        SET @NumError = 1
    END
    END TRY
    BEGIN CATCH
        IF (XACT_STATE()) = -1
            ROLLBACK TRANSACTION
        IF (XACT_STATE()) = 1
            COMMIT TRANSACTION
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE()        
        SET @Result = 'Se ha presentado un error en Base de Datos: ' + (SELECT CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE())    
        SET @NumError = 3        
        RAISERROR(@Result, @severity, @state)
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_Comments_Add';
GO

-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   3 Noviembre 2024
-- Modification date: 3 Noviembre 2024
-- Description:   SP para editar el comentario
-- --------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_Comments_Edit]
    @CommentId UNIQUEIDENTIFIER,
    @IdUser UNIQUEIDENTIFIER,
    @NewMessage NVARCHAR(512),
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    BEGIN
        -- Verificar que el comentario existe y pertenece al usuario
        IF NOT EXISTS (SELECT 1 FROM Comments 
                      WHERE Id = @CommentId 
                      AND IdUser = @IdUser)
        BEGIN
            SET @Result = 'El comentario no existe o no tienes permiso para editarlo'
            SET @NumError = 2
            RETURN
        END

        -- Actualizar el comentario
        UPDATE Comments
        SET Message = @NewMessage
        WHERE Id = @CommentId AND IdUser = @IdUser;

        SET @Result = 'Operación Correcta'
        SET @NumError = 1
    END
    END TRY
    BEGIN CATCH
        IF (XACT_STATE()) = -1
            ROLLBACK TRANSACTION
        IF (XACT_STATE()) = 1
            COMMIT TRANSACTION
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE()        
        SET @Result = 'Se ha presentado un error en Base de Datos: ' + (SELECT CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE())    
        SET @NumError = 3        
        RAISERROR(@Result, @severity, @state)
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_Comments_Edit';
GO

-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   3 Noviembre 2024
-- Modification date: 3 Noviembre 2024
-- Description:   SP para calificar al vendedor
-- --------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_Comments_UpdateRating]
    @CommentId UNIQUEIDENTIFIER,
    @IdUser UNIQUEIDENTIFIER,
    @NewRating DECIMAL(3,2),
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    BEGIN
        -- Verificar que el rating está entre 1 y 5
        IF @NewRating < 1 OR @NewRating > 5
        BEGIN
            SET @Result = 'El rating debe estar entre 1 y 5'
            SET @NumError = 2
            RETURN
        END

        -- Verificar que el comentario existe y pertenece al usuario
        DECLARE @IdSeller UNIQUEIDENTIFIER
        SELECT @IdSeller = IdSeller
        FROM Comments
        WHERE Id = @CommentId AND IdUser = @IdUser

        IF @IdSeller IS NULL
        BEGIN
            SET @Result = 'El comentario no existe o no tienes permiso para actualizarlo'
            SET @NumError = 2
            RETURN
        END

        -- Actualizar el rating del comentario
        UPDATE Comments
        SET Rating = @NewRating
        WHERE Id = @CommentId AND IdUser = @IdUser;

        -- Actualizar el rating promedio del vendedor
        UPDATE Sellers
        SET Rating = (
            SELECT AVG(Rating)
            FROM Comments
            WHERE IdSeller = @IdSeller
        )
        WHERE Id = @IdSeller;

        SET @Result = 'Operación Correcta'
        SET @NumError = 1
    END
    END TRY
    BEGIN CATCH
        IF (XACT_STATE()) = -1
            ROLLBACK TRANSACTION
        IF (XACT_STATE()) = 1
            COMMIT TRANSACTION
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE()        
        SET @Result = 'Se ha presentado un error en Base de Datos: ' + (SELECT CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE())    
        SET @NumError = 3        
        RAISERROR(@Result, @severity, @state)
    END CATCH
END
GO
PRINT 'COMPILACIÓN CORRECTA --> SP_Comments_UpdateRating';
GO
