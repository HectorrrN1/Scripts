USE [Chepeat]
GO
/****** Object:  StoredProcedure [dbo].[SP_Users_Selection]    Script Date: 03/10/2024 10:00:00 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
			u.Fullname AS Fullname,
			(
				SELECT STRING_AGG(r.Name, ', ') AS Roles
				FROM UserRoles ur
				JOIN Roles r ON ur.IdRol = r.Id
				WHERE ur.IdUser = u.Id
				FOR JSON PATH
			) AS Roles
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