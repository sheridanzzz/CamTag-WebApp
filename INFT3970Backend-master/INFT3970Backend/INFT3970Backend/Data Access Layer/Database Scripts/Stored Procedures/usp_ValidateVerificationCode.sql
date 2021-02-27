CREATE PROCEDURE [dbo].[usp_ValidateVerificationCode] 
	-- Add the parameters for the stored procedure here
	@verificationCode INT,
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
		EXEC [dbo].[usp_ConfirmPlayerExists] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result
		
		--Get the GameID from the playerID
		DECLARE @gameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT

		--Confirm the Game is not completed
		EXEC [dbo].[usp_ConfirmGameNotCompleted] @id = @gameID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Confirm the playerID is in a non verified state
		IF EXISTS (SELECT * FROM vw_InGame_Players WHERE PlayerID = @playerID)
		BEGIN
			SET @result = @CANNOT_PERFORM_ACTION;
			SET @errorMSG = 'The playerID is already verified.';
			RAISERROR('',16,1);
		END

		--Confirm the verification code passed in equals the verification code stored against the user account
		DECLARE @actualVerificationCode INT;
		SELECT @actualVerificationCode = VerificationCode FROM tbl_Player WHERE PlayerID = @playerID
		IF(@actualVerificationCode <> @verificationCode)
		BEGIN
			SET @result = @ITEM_DOES_NOT_EXIST;
			SET @errorMSG = 'The verification code is not correct.';
			RAISERROR('',16,1);
		END

		--The verification code is valid, update the player to verified
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			UPDATE tbl_Player
			SET IsVerified = 1
			WHERE PlayerID = @playerID
		COMMIT

		--Set the success return variables
		SELECT * FROM vw_Join_PlayerGame WHERE PlayerID = @playerID
		SET @result = 1;
		SET @errorMSG = ''
	END TRY

	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying update the player record';
		END
	END CATCH
END
GO