
CREATE PROCEDURE sp_user_selection
@TipoError int output,
@Mensaje varchar(50) output
AS
BEGIN
SET NOCOUNT ON
BEGIN TRY
	SELECT 
		id as id,
		email as email,
		password as password,
		fullname as fullname
	FROM CE_Users
	SET @TipoError = 1
	SET @Mensaje = 'Operacion correcta'
END TRY
BEGIN CATCH
	IF(XACT_STATE()=-1)
	rollback transaction
	IF(XACT_STATE()=1)
	commit transaction
	SET @TipoError = 2
	Set @Mensaje = 'Ha ocurrido un error'
END CATCH
END