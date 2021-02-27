-- =============================================
-- Author:		Jonathan Williams
-- Create date: 19/09/18
-- Description:	Gets the last photos uploaded in the game by each player if
--				applicable, using their last photo taken as their last known
--				location.

-- Returns: The result (1 = successful, anything else = error), and the error message associated with it
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetLastKnownLocations] 
	-- Add the parameters for the stored procedure here
	@playerID INT,
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
		
		--Validate the playerID
		EXEC [dbo].[usp_ConfirmPlayerInGame] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result
		
		--Get the GameID from the playerID
		DECLARE @gameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT

		--Confirm the Game is in a PLAYING state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Perform the select statement to get the last known locations
		SELECT * 
		FROM 
			vw_Join_PhotoGamePlayers p
		WHERE
			p.GameID = @gameID AND
			p.PhotoIsActive = 1 AND
			p.PhotoIsDeleted = 0 AND
			p.TakenByPlayerID <> @playerID AND
			p.TimeTaken IN (
				SELECT MAX(TimeTaken)
				FROM tbl_Photo ph
				WHERE
					ph.GameID = @gameID AND
					ph.PhotoIsActive = 1 AND
					ph.PhotoIsDeleted = 0
				GROUP BY
					ph.TakenByPlayerID
			)


		SET @result = 1
		SET @errorMSG = '';
	END TRY

	--An error occurred in the data validation
	BEGIN CATCH

	END CATCH
END
GO