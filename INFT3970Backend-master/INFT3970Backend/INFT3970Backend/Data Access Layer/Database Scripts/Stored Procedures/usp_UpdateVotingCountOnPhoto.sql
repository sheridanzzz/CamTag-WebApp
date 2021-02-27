-- =============================================
-- Author:		Jonathan Williams
-- Create date: 11/09/18
-- Description:	Updates the Yes/No vote count on the photo,
--				checks if the voting has been completed, if so,
--				the kills and deaths are updated etc.
-- Returns: 1 = Successful, or Anything else = An error occurred
-- =============================================
CREATE PROCEDURE [dbo].[usp_UpdateVotingCountOnPhoto] 
	-- Add the parameters for the stored procedure here 
	@photoID INT,
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
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			--Update the photo record with the number of Yes or No Votes
			DECLARE @countYes INT = 0;
			DECLARE @countNo INT = 0;
			SELECT @countYes = COUNT(*) FROM vw_Success_Votes WHERE PhotoID = @photoID
			SELECT @countNo = COUNT(*) FROM vw_Fail_Votes WHERE PhotoID = @photoID
			UPDATE tbl_Photo
			SET NumYesVotes = @countYes, NumNoVotes = @countNo
			WHERE PhotoID = @photoID

			--Update the photo's IsVotingComplete field if all the player votes have successfully been completed
			IF NOT EXISTS (SELECT * FROM vw_Incomplete_Votes WHERE PhotoID = @photoID)
			BEGIN
				UPDATE tbl_Photo
				SET IsVotingComplete = 1
				WHERE PhotoID = @photoID

				-- if successful vote
				IF (@countYes > @countNo)
				BEGIN
					-- updating kills and deaths per players in the photo
					UPDATE tbl_Player 
					SET NumKills = NumKills +1 
					WHERE PlayerID = 
						(SELECT TakenByPlayerID
						FROM tbl_Photo
						WHERE PhotoID = @photoID)

					UPDATE tbl_Player 
					SET NumDeaths = NumDeaths +1 
					WHERE PlayerID = 
						(SELECT PhotoOfPlayerID 
						FROM tbl_Photo
						WHERE PhotoID = @photoID)
				END
			END
		COMMIT
		SET @result = 1;
		SET @errorMSG = '';
	END TRY

	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to update the photo record.'
		END
	END CATCH
END
GO