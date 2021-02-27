-- =============================================
-- Author:		Jonathan Williams
-- Create date: 19/09/18
-- Description:	Updates the GameState of a game

-- Returns: 1 = Successful, or 0 = An error occurred

-- Possible Errors Returned:
--		1. @EC_INSERTERROR - An error occurred while trying to update the player record.

-- =============================================
CREATE PROCEDURE [dbo].[usp_SetGameState] 
	-- Add the parameters for the stored procedure here
	@gameID INT,
	@gameState VARCHAR(255),
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @EC_INSERTERROR INT = 2

	BEGIN TRY  
		--Confirm the GameID passed in exists
		EXEC [dbo].[usp_ConfirmGameExists] @id = @gameID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			UPDATE tbl_Game
			SET GameState = @gameState
			WHERE GameID = @gameID
		COMMIT
	END TRY

	--An error occurred in the data validation
	BEGIN CATCH
		--An error occurred while trying to perform the update on the PLayer table
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @EC_INSERTERROR;
			SET @errorMSG = 'An error occurred while trying to update the Game record.'
		END
	END CATCH
END
GO