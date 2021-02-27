-- =============================================
-- Author:		Jonathan Williams
-- Create date: 11/09/18
-- Description:	When the voting time expires on a photo the 
--				photo is automiatically marked as successful.
--				Updating the photo and all the votes because the time has now expired.
-- =============================================
CREATE PROCEDURE [dbo].[usp_BR_VotingTimeExpired] 
	-- Add the parameters for the stored procedure here
	@photoID INT,
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Declaring the possible error codes returned
	DECLARE @EC_INSERTERROR INT = 2;

	BEGIN TRY
		
		--Confirm the photo is actual expired
		DECLARE @voteFinish DATETIME2;
		SELECT @voteFinish = VotingFinishTime FROM tbl_Photo WHERE PhotoID = @photoID
		IF(GETDATE() < @voteFinish)
		BEGIN
			SET @result = @EC_INSERTERROR;
			SET @errorMSG = 'An error occurred while trying to update the photo record.'
			RAISERROR('',16,1);
		END

		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			--Update the photo to completed
			UPDATE tbl_Photo
			SET IsVotingComplete = 1
			WHERE PhotoID = @photoID

			--Since the voting time has expired the photo is an automatic success photo, set all the votes to successful
			UPDATE tbl_Vote
			SET IsPhotoSuccessful = 1
			WHERE PhotoID = @photoID

			--Update the counts of the votes
			DECLARE @countYesVotes INT;
			SELECT @countYesVotes = COUNT(*) FROM tbl_Vote WHERE IsPhotoSuccessful = 1 AND PhotoID = @photoID
			UPDATE tbl_Photo
			SET NumYesVotes = @countYesVotes, NumNoVotes = 0
			WHERE PhotoID = @photoID

			-- updating kills and deaths per players in the photo
			UPDATE tbl_Player 
			SET NumKills = NumKills +1 
			WHERE PlayerID = 
					(SELECT TakenByPlayerID 
					FROM tbl_Photo 
					WHERE PhotoID = @photoID)
			
			--Eliminate the player
			UPDATE tbl_Player 
			SET NumDeaths = NumDeaths +1 , IsEliminated = 1
			WHERE PlayerID = 
				(SELECT PhotoOfPlayerID 
				FROM tbl_Photo 
				WHERE PhotoID = @photoID)

			--Check to see if the game is now completed after eliminating the player
			DECLARE @countPlayersLeft INT = 0;
			DECLARE @gameID INT;
			SELECT @gameID = GameID FROM tbl_Photo WHERE PhotoID = @photoID
			SELECT @countPlayersLeft = COUNT(*) FROM vw_InGame_Players WHERE GameID = @gameID
			IF(@countPlayersLeft < 3)
			BEGIN
				--Complete the game because there is not enough players to play after the player was eliminated
				--Call the end game stored procedure to end the game
				EXEC [dbo].[usp_CompleteGame] @gameID = @gameID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
				EXEC [dbo].[usp_DoRaiseError] @result = @result
			END 
		COMMIT

		SELECT * FROM vw_Join_PhotoGamePlayers WHERE PhotoID = @photoID
		SET @result = 1;
		SET @errorMSG = '';

	END TRY

	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK;
			SET @result = @EC_INSERTERROR;
			SET @errorMSG = 'An error occurred while trying to update the photo record.'
		END
	END CATCH
END
GO