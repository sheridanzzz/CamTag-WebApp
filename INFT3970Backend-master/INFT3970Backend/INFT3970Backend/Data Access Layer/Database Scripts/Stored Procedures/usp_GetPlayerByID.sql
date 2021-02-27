-- =============================================
-- Author:		Jonathan Williams
-- Create date: 18/09/18
-- Description:	Gets the player record matching the specified ID
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetPlayerByID] 
	-- Add the parameters for the stored procedure here
	@playerID INT,
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRY

	--Validate the playerID
	EXEC [dbo].[usp_ConfirmPlayerExists] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
	EXEC [dbo].[usp_DoRaiseError] @result = @result

	SELECT *
	FROM vw_Join_PlayerGame
	WHERE PlayerID = @playerID

	SET @result = 1;
	SET @errorMSG = '';

	END TRY

	BEGIN CATCH

	END CATCH
END
GO