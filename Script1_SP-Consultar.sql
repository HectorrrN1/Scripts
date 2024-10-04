USE [Chepeat]
GO
/****** Object:  StoredProcedure [dbo].[sp_users_selection] Script Date: 03/10/2024 10:47:13 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:         Alexis Eduardo Santana Vega
-- Create date:    3 Octubre 2024
-- Description:    Consulta todos los usuarios de la tabla CE_Usuarios
-- =============================================
CREATE OR ALTER PROCEDURE sp_users_selection
@ErrorType INT OUTPUT,
@Message VARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
	BEGIN
		SELECT 
			Id as Id,
			Email as Email,
			Password as Password,
			Fullname as Fullname
			FROM CE_Users
		SET @ErrorType = 1
		SET @Message = 'Operacion correcta'
	END
END TRY
BEGIN CATCH
	IF(XACT_STATE()=-1)
		rollback transaction
	IF(XACT_STATE()=1)
		commit transaction
	SET @ErrorType = 2
	Set @Message = 'Ha ocurrido un error'
END CATCH
END