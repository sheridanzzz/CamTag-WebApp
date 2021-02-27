-- =============================================
-- Author:		Jonathan Williams
-- Create date: 05/09/18
-- Description:	Removes the unverified player from the game.
--				Deletes the player record to allow the phone or email
--				to be used again.

-- Returns: The result (1 = successful, anything else = error), and the error message associated with it
-- =============================================
CREATE PROCEDURE [dbo].[usp_RemoveUnverifiedPlayer] 
	-- Add the parameters for the stored procedure here
	@playerID INT,
	@playerIDToRemove INT,
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Declare the error codes
	DECLARE @DATABASE_CONNECT_ERROR INT = 0;
    DECLARE @INSERT_ERROR INT = 2;
    DECLARE @BUILD_MODEL_ERROR INT = 3;
    DECLARE @ITEM_ALREADY_EXISTS INT = 4;
    DECLARE @DATA_INVALID INT = 5;
    DECLARE @ITEM_DOES_NOT_EXIST INT = 6;
    DECLARE @CANNOT_PERFORM_ACTION INT = 7;
    DECLARE @GAME_DOES_NOT_EXIST INT = 8;
    DECLARE @GAME_STATE_INVALID INT = 9;
    DECLARE @PLAYER_DOES_NOT_EXIST INT = 10;
    DECLARE @PLAYER_INVALID INT = 11;
    DECLARE @MODELINVALID_PLAYER INT = 12;
    DECLARE @MODELINVALID_GAME INT = 13;
    DECLARE @MODELINVALID_PHOTO INT = 14;
    DECLARE @MODELINVALID_VOTE INT = 15;

	BEGIN TRY
		
		--Validate the PlayerID
		EXEC [dbo].[usp_ConfirmPlayerIsActive] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Validate the PlayerIDToRemove
		EXEC [dbo].[usp_ConfirmPlayerIsActive] @id = @playerIDToRemove, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Check the players are in the same game
		DECLARE @playerGameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @playerGameID OUTPUT
		DECLARE @toRemoveGameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerIDToRemove, @gameID = @toRemoveGameID OUTPUT
		IF(@toRemoveGameID <> @playerGameID)
		BEGIN
			SET @result = @DATA_INVALID;
			SET @errorMSG = 'The players provided are not in the same game.'
			RAISERROR('', 16, 1);
		END

		--Confirm the Game is IN LOBBY state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @playerGameID, @correctGameState = 'IN LOBBY', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Confirm the playerID is the host player
		IF NOT EXISTS (SELECT * FROM vw_InGame_Players WHERE PlayerID = @playerID AND IsHost = 1)
		BEGIN
			SET @result = @CANNOT_PERFORM_ACTION;
			SET @errorMSG = 'Only the host player can perform this action. The player requesting is not the host.';
			RAISERROR('', 16, 1);
		END

		--Confirm the playerToRemove is not verified already
		IF NOT EXISTS (SELECT * FROM vw_Active_Players WHERE PlayerID = @playerIDToRemove AND IsVerified = 0)
		BEGIN
			SET @result = @ITEM_DOES_NOT_EXIST;
			SET @errorMSG = 'The player trying to remove is already verified. Only unverified players can be removed.';
			RAISERROR('', 16, 1);
		END

		--Leave the game
		DECLARE @isGameCompleted BIT;
		EXEC [dbo].[usp_LeaveGame]
		@playerID = @playerIDToRemove,
		@isGameCompleted = @isGameCompleted OUTPUT,
		@result = @result OUTPUT,
		@errorMSG = @errorMSG OUTPUT

		EXEC [dbo].[usp_DoRaiseError] @result = @result

		SELECT * FROM tbl_Player WHERE PlayerID = @playerIDToRemove
		
	END TRY

	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to remove the player from the game'
		END
	END CATCH
END
GO