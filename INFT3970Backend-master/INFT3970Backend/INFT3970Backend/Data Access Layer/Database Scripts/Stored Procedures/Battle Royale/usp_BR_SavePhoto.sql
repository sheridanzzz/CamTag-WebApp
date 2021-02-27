CREATE PROCEDURE [dbo].[usp_BR_SavePhoto] 
	-- Add the parameters for the stored procedure here
	@dataURL VARCHAR(MAX), 
	@takenByID INT,
	@photoOfID INT,
	@lat FLOAT,
	@long FLOAT,
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
		--Validate the takenByID
		EXEC [dbo].[usp_ConfirmPlayerInGame] @id = @takenByID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Validate the photoOfID
		EXEC [dbo].[usp_ConfirmPlayerInGame] @id = @photoOfID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result


		--Get the GameID of the TakenByPLayerID and PhotoOfPlayerID and confirm they are in the same game
		DECLARE @takenByGameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @takenByID, @gameID = @takenByGameID OUTPUT
		DECLARE @photoOfGameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @photoOfID, @gameID = @photoOfGameID OUTPUT
		IF(@takenByGameID <> @photoOfGameID)
		BEGIN
			SET @result = @DATA_INVALID;
			SET @errorMSG = 'The players provided are not in the same game.'
			RAISERROR('', 16, 1);
		END

		--Confirm the Game is PLAYING state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @takenByGameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result


		--Confirm there is not an active photo record with the same taken by and photo of ID
		--This is to avoid the same player constantly taking photos of the same person.
		IF EXISTS (SELECT * FROM vw_Incompleted_Photos WHERE TakenByPlayerID = @takenByID AND PhotoOfPlayerID = @photoOfID)
		BEGIN
			SET @result = @CANNOT_PERFORM_ACTION;
			SET @errorMSG = 'There is already an existing photo of this player which has not completed voting. Please wait before voting completes before taking another photo of the same player.';
			RAISERROR('', 16, 1);
		END


		--Insert the new photo
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			INSERT INTO tbl_Photo(PhotoDataURL, TakenByPlayerID, PhotoOfPlayerID, GameID, Lat, Long) 
			VALUES (@dataURL, @takenByID, @photoOfID, @takenByGameID, @lat, @long);

			DECLARE @createdPhotoID INT;
			SET @createdPhotoID = SCOPE_IDENTITY();

			--Create the voting records for all the players in the game. 
			--Only active/verified players, players who have not left the game
			--and not the player who took the photo and who the photo is off.
			--Eliminated players can also have a voting record
			INSERT INTO tbl_Vote(PlayerID, PhotoID)
			SELECT PlayerID, @createdPhotoID
			FROM
				vw_Active_Players
			WHERE
				IsVerified = 1 AND
				HasLeftGame = 0 AND
				GameID = @takenByGameID AND 
				PlayerID <> @photoOfID AND 
				PlayerID <> @takenByID
				
		COMMIT

		SET @result = 1;
		SET @errorMSG = '';
		SELECT * FROM vw_Join_PhotoGamePlayers WHERE PhotoID = @createdPhotoID
	END TRY

	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to save the photo.'
		END
	END CATCH
END
GO