-- ===================================================================
-- Authores:      Alexis Eduardo Santana Vega
-- Create date:   7 Octubre 2024
-- Description:   Sprint-3_Script para entorno de desarrollo
-- ===================================================================

-- -------------------------------------------------------------------
-- Authores:      Alexis Eduardo Santana Vega
-- Create date:   7 Octubre 2024
-- Description:   Generacion de base de datos
-- -------------------------------------------------------------------

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


-- -------------------------------------------------------------------
-- Authores:      Alexis Eduardo Santana Vega
-- Create date:   7 Octubre 2024
-- Description:   Generacion de tablas
-- -------------------------------------------------------------------

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
-- Authores:      Alexis Eduardo Santana Vega
-- Create date:   7 Octubre 2024
-- Description:   SP para consulta de tabla Users
-- -------------------------------------------------------------------

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
PRINT 'COMPILACIÓN CORRECTA --> sp_Users_Selection';
GO

-- -------------------------------------------------------------------
-- Authores:      Hector Nuñez Cruz
-- Create date:   7 Octubre 2024
-- Description:   SP para la eliminación de registros de Users
-- -------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_user_delete
    @Id UNIQUEIDENTIFIER,
	@Table VARCHAR(100),
    @NumError int OUTPUT,
    @Result varchar(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Eliminar el usuario basado en el ID proporcionado
        DELETE FROM Users
        WHERE Id = @Id;

        SET @NumError = 1;
        SET @Result = 'Usuario eliminado correctamente';

		SELECT @NumError AS NumError, @Result AS Result;
    END TRY
    BEGIN CATCH
        if (xact_state()) = -1
            rollback transaction
        if (xact_state()) = 1
            commit transaction
        declare @severity int = error_severity(), @state int = error_state()        
        set @Result = 'Se ha presentado un error en Base de Datos: ' + (select convert(nvarchar(2048), error_number()) + ' - ' + error_message())    
        SET @NumError = 3;        
    END CATCH
END;
GO
PRINT 'COMPILACIÓN CORRECTA --> sp_user_delete';
GO

-- -------------------------------------------------------------------
-- Authores:      Alexis Eduardo Santana Vega
-- Create date:   7 Octubre 2024
-- Description:   SP para agregar usuarios
-- -------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_user_add
	@Email VARCHAR(255),
	@Password VARCHAR(255),
	@Fullname VARCHAR(120),
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
	-- Verificar si el email ya existe
        IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
        BEGIN
            SET @NumError = 2;
            SET @Result = 'El email ya está registrado';
        END
        ELSE
        BEGIN
            -- Agregar usuario a tabla Users
            INSERT INTO Users (Id, Email, Password, Fullname) VALUES(NEWID(), @Email, @Password, @Fullname);
            SET @NumError = 1;
            SET @Result = 'Usuario agregado correctamente';
			SELECT @NumError as NumError, @Result as Result;
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
END;
GO
PRINT 'COMPILACIÓN CORRECTA --> sp_user_add';
GO

-- -------------------------------------------------------------------
-- Authores:      Alexis Eduardo Santana Vega
-- Create date:   8 Octubre 2024
-- Description:   SP para la actualizacion de datos de User
-- -------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_user_update
	@Id UNIQUEIDENTIFIER,
	@Email VARCHAR(255),
	@Fullname VARCHAR(120),
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
        BEGIN
            -- Agregar usuario a tabla Users
            UPDATE Users SET Email = @Email, Fullname = @Fullname WHERE Id = @Id;
            SET @NumError = 1;
            SET @Result = 'Usuario actualizado correctamente';
			SELECT @NumError as NumError, @Result as Result;
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
END;
GO
PRINT 'COMPILACIÓN CORRECTA --> sp_user_update';
GO

-- -------------------------------------------------------------------
-- Authores:      Alexis Eduardo Santana Vega
-- Create date:   10 Octubre 2024
-- Description:   SP para registro de usuarios (vista de registro)
-- -------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_registrar_usuario
	@Email VARCHAR(255),
	@Password VARCHAR(255),
	@Fullname VARCHAR(120),
	@CreatedAt DATETIME,
	@UpdatedAt DATETIME,
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
	-- Verificar si el email ya existe
        IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
        BEGIN
            SET @NumError = 1;
            SET @Result = 'Este email ya se encuentra registrado';
        END
        ELSE
        BEGIN
			DECLARE @Id UNIQUEIDENTIFIER = NEWID();
            -- Agregar usuario a tabla Users
            INSERT INTO Users(Id, Email, Password, Fullname, IsAdmin, IsBuyer, IsSeller, CreatedAt, UpdatedAt) VALUES(NEWID(), @Email, @Password, @Fullname, 0, 1, 0, @CreatedAt, @UpdatedAt);
            SET @NumError = 0;
            SET @Result = 'Cuenta creada con éxito';
        END
		SELECT @NumError as NumError, @Result as Result;
	END TRY
    BEGIN CATCH
        if (xact_state()) = -1
            rollback transaction
        if (xact_state()) = 1
            commit transaction
        declare @severity int = error_severity(), @state int = error_state()        
        set @Result = 'Se ha presentado un error en Base de Datos: ' + (select convert(nvarchar(2048), error_number()) + ' - ' + error_message())    
        SET @NumError = 2;        
        raiserror(@Result, @severity, @state)
    END CATCH
END;
GO
PRINT 'COMPILACIÓN CORRECTA --> sp_registrar_usuario';
GO

-- -------------------------------------------------------------------
-- Authores:      Alexis Eduardo Santana Vega
-- Create date:   15 Octubre 2024
-- Description:   SP para la generacion de RefreshToken de sesiones
-- -------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_create_refreshToken
	@RefreshTokenValue VARCHAR(255),
	@Active Bit,
	@Creation Datetime,
	@Expiration Datetime,
	@Used BIT,
	@UserId UNIQUEIDENTIFIER,
    @NumError INT OUTPUT,
    @Result VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
	-- Agregar usuario a tabla Users
	DECLARE @Id UNIQUEIDENTIFIER = NEWID();
            INSERT INTO RefreshTokens(RefreshTokenId, RefreshTokenValue, Active, Creation, Expiration, Used, UserId)
			VALUES (NEWID(), @RefreshTokenValue, @Active, @Creation, @Expiration, @Used, @UserId);
            SET @NumError = 1;
            SET @Result = 'Sesion generada correctamente';
			SELECT @NumError as NumError, @Result as Result;
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
END;
GO
PRINT 'COMPILACIÓN CORRECTA --> sp_create_refreshToken';
GO

-- -------------------------------------------------------------------
-- Authores:      Alexis Eduardo Santana Vega
-- Create date:   7 Octubre 2024
-- Description:   SP para el registro de vendedores (vista de alta de vendedores)
-- -------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_registrar_vendedor
    @StoreName NVARCHAR(120),
    @CreatedAt DATETIME,
    @UpdatedAt DATETIME,
    @IdUser UNIQUEIDENTIFIER,
    @NumError INT OUTPUT,
    @Result VARCHAR(512) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Iniciar transacción
        BEGIN TRANSACTION;

        -- Declarar nuevo ID
        DECLARE @Id UNIQUEIDENTIFIER = NEWID();

        -- Agregar vendedor a la tabla Sellers
        INSERT INTO Sellers(Id, StoreName, CreatedAt, UpdatedAt, IdUser) 
        VALUES(@Id, @StoreName, @CreatedAt, @UpdatedAt, @IdUser);

        -- Asignar parámetros de salida
        SET @NumError = 0;
        SET @Result = 'Cuenta creada con éxito';

        -- Confirmar transacción
        COMMIT TRANSACTION;
		SELECT @NumError as NumError, @Result as Result;
    END TRY
    BEGIN CATCH
        -- Revertir transacción si ocurre un error
        IF XACT_STATE() = -1
            ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1
            COMMIT TRANSACTION;

        -- Manejo de errores
        DECLARE @severity INT = ERROR_SEVERITY(), @state INT = ERROR_STATE();
        SET @Result = 'Se ha presentado un error en Base de Datos: ' + CONVERT(NVARCHAR(2048), ERROR_NUMBER()) + ' - ' + ERROR_MESSAGE();
        SET @NumError = 2;        

        -- Lanzar error con THROW en vez de RAISEERROR
        THROW;
    END CATCH;
END;
GO
PRINT 'COMPILACIÓN CORRECTA --> sp_registrar_vendedor';
GO
