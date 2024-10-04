
-- ********************************* 
-- Author: <Hector Nuñez>
-- <Create date: 04/10/2024>
-- <Description: Eliminacion de registros de la tabla CE_User>
-- *********************************

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