-- =============================================
-- Author:		Jonathan Williams
-- Create date: 05/09/18
-- Description:	Completes a game and sets all references to the game to not active.
--				All players, photos, votes etc associated with the game will be set to inactive

-- Returns: The result (1 = successful, anything else = error), and the error message associated with it
-- =============================================
CREATE PROCEDURE [dbo].[usp_CompleteGame] 
	-- Add the parameters for the stored procedure here
	@gameID INT,
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
		
		--Confirm the gameID passed in exists not complete
		EXEC [dbo].[usp_ConfirmGameNotCompleted] @id = @gameID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Confirm the Game is STARTING state
		--Can be in a starting state because players could leave while the game is starting.
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'STARTING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		
		--If the game is not in SATRTING state, check if its in PLAYING
		IF(@result <> 1)
		BEGIN
			EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
			EXEC [dbo].[usp_DoRaiseError] @result = @result
		END

		--Update the Game to now be completed.
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			--Update the game to completed
			UPDATE tbl_Game
			SET GameIsActive = 0, GameState = 'COMPLETED'
			WHERE GameID = @gameID

			--Update all the players in the game to not active
			UPDATE tbl_Player
			SET PlayerIsActive = 0
			WHERE GameID = @gameID

			--Delete any votes on a photo which have not yet been completed in the game
			UPDATE tbl_Vote
			SET VoteIsDeleted = 1
			WHERE PhotoID IN (SELECT PhotoID FROM vw_Incompleted_Photos WHERE GameID = @gameID)

			--Update all votes to not active
			UPDATE tbl_Vote
			SET VoteIsActive = 0
			WHERE PlayerID IN (SELECT PlayerID FROM tbl_Player WHERE GameID = @gameID)

			--Delete any photos which voting has not yet been completed
			UPDATE tbl_Photo
			SET PhotoIsDeleted = 1
			WHERE IsVotingComplete = 0 AND GameID = @gameID

			--Update all photos in the game to not active
			UPDATE tbl_Photo
			SET PhotoIsActive = 0
			WHERE GameID = @gameID

			--Update all notifications to not active
			UPDATE tbl_Notification
			SET NotificationIsActive = 0
			WHERE GameID = @gameID
		COMMIT

		SET @result = 1;
		SET @errorMSG = '';

	END TRY

	--An error occurred in the data validation
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'The an error occurred while trying to complete the game.';
		END

	END CATCH
END
GO