-- =============================================
-- Author:		Jonathan Williams
-- Create date: 05/09/18
-- Description:	Joins a player to a game.

-- Returns: The result (1 = successful, anything else = error), and the error message associated with it
-- =============================================
CREATE PROCEDURE [dbo].[usp_JoinGame] 
	-- Add the parameters for the stored procedure here
	@gameCode VARCHAR(6),
	@nickname VARCHAR(255),
	@contact VARCHAR(255),
	@selfie VARCHAR(MAX),
	@smallSelfie VARCHAR(MAX),
	@extraSmallSelfie VARCHAR(MAX), 
	@isPhone BIT,
	@verificationCode INT,
	@isHost BIT,
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
		
		DECLARE @createdPlayerID INT;

		--Confirm the gameCode passed in exists and is active
		DECLARE @gameIDToJoin INT;
		SELECT @gameIDToJoin = GameID FROM tbl_Game WHERE GameCode = @gameCode AND GameIsActive = 1 AND GameIsDeleted = 0
		IF(@gameIDToJoin IS NULL)
		BEGIN
			SET @result = @GAME_DOES_NOT_EXIST;
			SET @errorMSG = 'The game code does not exist';
			RAISERROR('',16,1);
		END

		--Check to see if the player is okay to join the game, as the player may be attempting to join a game which has already begun
		DECLARE @canJoin BIT;
		SELECT @canJoin = IsJoinableAtAnytime FROM vw_Active_Games WHERE GameID = @gameIDToJoin
		DECLARE @gameState VARCHAR(255);
		SELECT @gameState = GameState FROM vw_Active_Games WHERE GameID = @gameIDToJoin

		--If the player cannot join at anytime and the current game state is currently PLAYING, return an error because the player
		--is trying to join a game which has already begun and does not allow players to join at anytime
		IF(@canJoin = 0 AND @gameState IN ('STARTING','PLAYING'))
		BEGIN
			SET @result = @CANNOT_PERFORM_ACTION;
			SET @errorMSG = 'The game you are trying to join is already playing and does not allow you to join after the game has started.';
			RAISERROR('',16,1);
		END


		--Check to see if the game is full and the player can join. There is a 16 player limit per game.
		IF EXISTS (SELECT * FROM vw_Active_Games WHERE GameID = @gameIDToJoin AND NumOfPlayers = 16)
		BEGIN
			SET @result = @CANNOT_PERFORM_ACTION;
			SET @errorMSG = 'The game you are trying to join is full.';
			RAISERROR('',16,1);
		END


		--Confirm the nickname entered is not already taken by a player in the game
		--Checking against verified and unverified players.
		IF EXISTS (SELECT * FROM vw_Active_Players WHERE GameID = @gameIDToJoin AND Nickname = @nickname)
		BEGIN
			SET @result = @ITEM_ALREADY_EXISTS;
			SET @errorMSG = 'The nickname you entered is already taken. Please chose another';
			RAISERROR('',16,1);
		END


		--Confirm if the phone number or email address is not already taken by a player in another active game
		IF(@isPhone = 1)
		BEGIN
			--Confirm the phone number is unique for all players currently in a game.
			--Check against players in the game and unverified players.
			IF EXISTS(SELECT Phone FROM vw_Active_Players WHERE Phone LIKE @contact AND HasLeftGame = 0)
			BEGIN
				SET @result = @ITEM_ALREADY_EXISTS;
				SET @errorMSG = 'The phone number you entered is already taken by another player in an active/not complete game. Please enter a unique contact.';
				RAISERROR('',16,1);
			END
		END
		ELSE
		BEGIN
			--Confirm the email is unique for all players currently in a game.
			--Check against players in the game and unverified players.
			IF EXISTS(SELECT Email FROM vw_Active_Players WHERE Email LIKE @contact AND HasLeftGame = 0)
			BEGIN
				SET @result = @ITEM_ALREADY_EXISTS;
				SET @errorMSG = 'The email address you entered is already taken by another player in an active/not complete game. Please enter a unique contact.';
				RAISERROR('',16,1);
			END
		END

		--If reaching this point all the inputs have been validated. Create the player record
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			
			--Get the AmmoLimit from the game
			DECLARE @ammoCount INT = 0;
			SELECT @ammoCount = AmmoLimit
			FROM tbl_Game
			WHERE GameID = @gameIDToJoin

			DECLARE @gameMode VARCHAR(255);
			SELECT @gameMode = GameMode FROM tbl_Game WHERE GameID = @gameIDToJoin

			--Insert a player record with a Phone or email address only
			IF(@isPhone = 1)
			BEGIN
				INSERT INTO tbl_Player(Nickname, Phone, Selfie, SmallSelfie, ExtraSmallSelfie, GameID, VerificationCode, IsHost, AmmoCount, PlayerType) VALUES (@nickname, @contact, @selfie, @smallSelfie, @extraSmallSelfie, @gameIDToJoin, @verificationCode, @isHost, @ammoCount, @gameMode);
			END
			ELSE
			BEGIN
				INSERT INTO tbl_Player(Nickname, Email, Selfie, SmallSelfie, ExtraSmallSelfie, GameID, VerificationCode, IsHost, AmmoCount, PlayerType) VALUES (@nickname, @contact, @selfie, @smallSelfie, @extraSmallSelfie, @gameIDToJoin, @verificationCode, @isHost, @ammoCount, @gameMode);
			END

			SET @createdPlayerID = SCOPE_IDENTITY();

			--Update the number of players in the game
			UPDATE tbl_Game
			SET NumOfPlayers = NumOfPlayers + 1
			WHERE GameID = @gameIDToJoin

		COMMIT

		--Set the return variables
		SET @result = 1;
		SET @errorMSG = ''

		--Read the player record
		SELECT * FROM vw_Join_PlayerGame WHERE PlayerID = @createdPlayerID

	END TRY

	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to add the player to the game'
		END
	END CATCH
END
GO