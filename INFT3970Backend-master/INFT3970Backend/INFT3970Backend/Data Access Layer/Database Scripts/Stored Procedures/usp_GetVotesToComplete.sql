-- =============================================
-- Author:		Jonathan Williams
-- Create date: 10/09/18
-- Description:	Gets the PlayerVotePhoto records which the PlayerID must completed / has not voted on yet
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetVotesToComplete] 
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
	EXEC [dbo].[usp_ConfirmPlayerIsActive] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
	EXEC [dbo].[usp_DoRaiseError] @result = @result
		
	--Get the GameID from the playerID
	DECLARE @gameID INT;
	EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT

	--Confirm the Game is PLAYING state
	EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
	EXEC [dbo].[usp_DoRaiseError] @result = @result

	--Gets the votes to complete by the player.
	SELECT *
	FROM 
		vw_Join_VotePhotoPlayer
	WHERE
		PlayerID = @playerID AND 
		IsPhotoSuccessful IS NULL AND 
		VoteIsActive = 1 AND 
		VoteIsDeleted = 0
	ORDER BY 
		VoteID

	SET @result = 1;
	SET @errorMSG = '';

	END TRY

	BEGIN CATCH

	END CATCH
	
END
GO