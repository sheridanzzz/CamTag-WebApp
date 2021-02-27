-- =============================================
-- Author:		Jonathan Williams
-- Create date: 06/09/18
-- Description:	Gets the game record matching the specified ID
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetGameByID] 
	-- Add the parameters for the stored procedure here
	@gameID INT,
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRY

	--Confirm the GameID passed in exists
	EXEC [dbo].[usp_ConfirmGameExists] @id = @gameID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
	EXEC [dbo].[usp_DoRaiseError] @result = @result

	--Select the game record
	SELECT *
	FROM tbl_Game
	WHERE GameID = @gameID

	SET @result = 1;
	SET @errorMSG = '';

	END TRY

	BEGIN CATCH

	END CATCH
END
GO