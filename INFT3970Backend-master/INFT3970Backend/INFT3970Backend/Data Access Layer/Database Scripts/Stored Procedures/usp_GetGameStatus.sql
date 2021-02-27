-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	Gets the current status of the game / application.
--				Used by the front end to get the current state of the application
--				when a user returns to the web application.
--				Will check if the game state and confirm if there is anything the player
--				must complete or reload such as votes or notificiations etc.

-- Returns: 1 = Successful, or 0 = An error occurred
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetGameStatus] 
	-- Add the parameters for the stored procedure here
	@playerID INT,
	@hasVotesToComplete BIT OUTPUT,
	@hasNotifications BIT OUTPUT,
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
		--Confirm the playerID passed in exists
		EXEC [dbo].[usp_ConfirmPlayerExists] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result
		
		--Get the GameID from the playerID
		DECLARE @gameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT

		--Setting the default values for the notification and votes
		SET @hasNotifications = 0;
		SET @hasVotesToComplete = 0;

		--Check to see if the player has any votes they need to complete
		DECLARE @countVotes INT = 0;
		SELECT @countVotes = COUNT(*)
		FROM vw_Incomplete_Votes
		WHERE 
			PlayerID = @playerID
		IF(@countVotes > 0)
		BEGIN
			SET @hasVotesToComplete = 1;
		END
			
		--Check to see if the player has any new notifications
		DECLARE @countNotifs INT = 0;
		SELECT @countNotifs = COUNT(*)
		FROM vw_Unread_Notifications
		WHERE
			PlayerID = @playerID	
		IF(@countNotifs > 0)
		BEGIN
			SET @hasNotifications = 1;
		END
			
		--Get the player record
		SELECT * FROM vw_Join_PlayerGame WHERE PlayerID = @playerID
		
		SET @result = 1;
		SET @errorMSG = '';

	END TRY

	--An error occurred in the data validation
	BEGIN CATCH

	END CATCH
END
GO