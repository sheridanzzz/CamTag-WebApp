-- =============================================
-- Author:		Jonathan Williams
-- Create date: 05/09/18
-- Description:	Begins the Game, sets the GameState to Starting and sets the StartTime and EndTime
--				Business Logic Code is scheduled to Run at start time to start the game and update the Game State to PLAYING.

-- Returns: The result (1 = successful, anything else = error), and the error message associated with it
-- =============================================
CREATE PROCEDURE usp_BeginGame 
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
		

		--Confirm the playerID passed in Is the host of the Game because only the host can begin the game
		DECLARE @isHost BIT;
		SELECT @isHost = IsHost FROM vw_InGame_Players WHERE PlayerID = @playerID
		IF(@isHost = 0)
		BEGIN
			SET @result = @DATA_INVALID;
			SET @errorMSG = 'The playerID passed in is not the host player. Only the host can begin the game.';
			RAISERROR('',16,1);
		END

		--Get the GameID from the playerID
		DECLARE @gameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT


		--Confirm the Game is IN LOBBY state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'IN LOBBY', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result


		--Confirm there is enough players in the Game to Start
		DECLARE @activePlayerCount INT = 0;
		SELECT @activePlayerCount = COUNT(*) FROM vw_Active_Players WHERE GameID = @gameID AND HasLeftGame = 0
		IF(@activePlayerCount < 3)
		BEGIN
			SET @result = @CANNOT_PERFORM_ACTION;
			SET @errorMSG = 'Not enough players to start the game, need a minimum of 3.';
			RAISERROR('',16,1);
		END


		--Confirm that all players are verified, all players in the game need to be verified before the game can start
		IF EXISTS (SELECT * FROM vw_All_Players WHERE GameID = @gameID AND IsVerified = 0 AND HasLeftGame = 0)
		BEGIN
			SET @result = @CANNOT_PERFORM_ACTION;
			SET @errorMSG = 'All players must be verified before the game can begin.';
			RAISERROR('',16,1);
		END


		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			--Get the StartDelay and the TimeLimit
			DECLARE @delay INT = 0;
			DECLARE @timeLimit INT = 0;
			SELECT @delay = StartDelay, @timeLimit = TimeLimit
			FROM tbl_Game
			WHERE GameID = @gameID

			--Update the GameState to STARTING
			UPDATE tbl_Game
			SET 
				GameState = 'STARTING', 
				StartTime = DATEADD(MILLISECOND, @delay, GETDATE())
			WHERE GameID = @gameID

			--Set the end time, use the start time + the time limit to calculate the end time
			DECLARE @startTime DATETIME2;
			SELECT @startTime = StartTime
			FROM tbl_Game
			WHERE GameID = @gameID
			UPDATE tbl_Game
			SET EndTime = DATEADD(MILLISECOND, @timeLimit, @startTime)
		COMMIT

		--Return the updated game record
		SET @result = 1
		SET @errorMSG = '';
		SELECT * FROM tbl_Game WHERE GameID = @gameID
	END TRY

	--An error occurred in the data validation
	BEGIN CATCH
		--An error occurred while trying to perform the update on the PLayer table
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'The an error occurred while trying to begin the game.';
		END
	END CATCH
END
GO