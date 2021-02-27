CREATE PROCEDURE usp_DoRaiseError 
	@result INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF(@result <> 1)
	BEGIN
		RAISERROR('',16,1);
	END	
END
GO