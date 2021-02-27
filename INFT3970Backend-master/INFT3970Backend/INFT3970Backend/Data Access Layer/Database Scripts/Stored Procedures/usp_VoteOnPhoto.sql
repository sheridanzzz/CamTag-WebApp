-- =============================================
-- Author:		Jonathan Williams
-- Create date: 11/09/18
-- Description:	Updates a PlayerVotePhoto record with a players vote decision

-- Returns: 1 = Successful, or 0 = An error occurred
-- =============================================
CREATE PROCEDURE [dbo].[usp_VoteOnPhoto] 
	-- Add the parameters for the stored procedure here 
	@voteID INT,
	@playerID INT,
	@isPhotoSuccessful BIT,
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

		--Confirm the Game is PLAYING state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Confirm the vote record exists and has not already been voted on.
		IF NOT EXISTS (SELECT * FROM vw_Incomplete_Votes WHERE VoteID = @voteID)
		BEGIN
			SET @result = @ITEM_DOES_NOT_EXIST;
			SET @errorMSG = 'The PlayerVotePhoto record does not exist or already voted.';
			RAISERROR('',16,1);
		END

		--Get the photoID from the Vote record
		DECLARE @photoID INT;
		SELECT @photoID = PhotoID FROM vw_Incomplete_Votes WHERE VoteID = @voteID

		--Confirm the voting is not already complete on the photo record
		IF EXISTS (SELECT * FROM vw_Completed_Photos WHERE PhotoID = @photoID)
		BEGIN
			SET @result = @CANNOT_PERFORM_ACTION;
			SET @errorMSG = 'The Voting on the photo has already been completed.';
			RAISERROR('',16,1);
		END

		--If reaching this point all pre-condition checks have passed successfully


		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			
			--Update the Vote record with the decision
			UPDATE tbl_Vote
			SET IsPhotoSuccessful = @isPhotoSuccessful
			WHERE VoteID = @voteID

			--Call a procedure to update the number of yes/no votes and check to see
			--if the photo voting has now been completed. If completed update the kills/deaths
			EXEC [dbo].[usp_UpdateVotingCountOnPhoto] @photoID = @photoID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
			EXEC [dbo].[usp_DoRaiseError] @result = @result
		COMMIT

		SET @result = 1;
		SET @errorMSG = '';
		SELECT * FROM vw_Join_VotePhotoPlayer WHERE VoteID = @voteID
	END TRY

	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to cast your vote.'
		END
	END CATCH
END
GO