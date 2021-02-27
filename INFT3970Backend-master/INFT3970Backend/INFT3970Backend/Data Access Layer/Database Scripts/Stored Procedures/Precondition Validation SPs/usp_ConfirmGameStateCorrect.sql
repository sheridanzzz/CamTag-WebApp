-- =============================================
-- Author:		Jonathan Williams
-- Create date: 15/09/18
-- Description:	Confirm the GameState of the GameID passed in is as expected.
-- =============================================
CREATE PROCEDURE usp_ConfirmGameStateCorrect
	@gameID INT,
	@correctGameState VARCHAR(255),
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

	--Confirm the game exists
	EXEC [dbo].[usp_ConfirmGameExists] @id = @gameID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
	
	IF(@result = 1)
	BEGIN
		--Get the actual current game state and confirm the game state is correct
		DECLARE @actualGameState VARCHAR(255);
		SELECT @actualGameState = GameState FROM tbl_Game WHERE GameID = @gameID

		--Confirm the game state matches the game state passed in
		IF(@correctGameState NOT LIKE @actualGameState)
		BEGIN
			SET @result = @GAME_STATE_INVALID;
			SET @errorMSG = 'The game state is invalid for this operation. Expecting game state to be ' + @correctGameState + ' but the actual game state is ' + @actualGameState;
		END
		ELSE
		BEGIN
			SET @result = 1;
			SET @errorMSG = '';
		END
	END
END
GO