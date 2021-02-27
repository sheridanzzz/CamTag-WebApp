-- =============================================
-- Author:		Jonathan Williams
-- Create date: 05/10/18
-- Description:	Creates a new battle royale game in the database.

-- Returns: The result (1 = successful, anything else = error), and the error message associated with it

-- Possible Errors Returned:
--		1. EC_INSERTERROR - An error occurred while trying to insert the game record
--		2. EC_ITEMALREADYEXISTS - An active game already exists with that game code.

-- =============================================
CREATE PROCEDURE [dbo].[usp_BR_CreateGame] 
	-- Add the parameters for the stored procedure here
	@gameCode VARCHAR(6),
	@timeLimit INT,
	@ammoLimit INT,
	@startDelay INT,
	@replenishAmmoDelay INT,
	@gameMode VARCHAR(255),
	@isJoinableAtAnytime BIT,
	@latitude FLOAT,
	@longitude FLOAT,
	@radius INT,
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
		--Confirm the game code does not already exist in a game
		IF EXISTS (SELECT * FROM vw_All_Games WHERE GameCode = @gameCode)
		BEGIN
			SET @result = @ITEM_ALREADY_EXISTS;
			SET @errorMSG = 'The game code already exists.';
			RAISERROR('',16,1);
		END;

		--Game code does not exist, create the new game
		DECLARE @createdGameID INT;
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			INSERT INTO tbl_Game (GameCode, TimeLimit, AmmoLimit, StartDelay, ReplenishAmmoDelay, GameMode, IsJoinableAtAnytime) 
			VALUES (@gameCode, @timeLimit, @ammoLimit, @startDelay, @replenishAmmoDelay, @gameMode, @isJoinableAtAnytime);
			SET @createdGameID = SCOPE_IDENTITY();

			--Create the BRGame table record
			INSERT INTO tbl_BRGame (GameID, Latitude, Longitude, Radius) VALUES (@createdGameID, @latitude, @longitude, @radius)
		COMMIT

		--Set the success return variables
		SET @result = 1;
		SET @errorMSG = '';

		--Read the new game record
		SELECT * FROM vw_BRGames WHERE GameID = @createdGameID
	END TRY

	--An error occurred in the data validation
	BEGIN CATCH
		--An error occurred while trying to perform the update on the PLayer table
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'The an error occurred while trying to create the game record';
		END
	END CATCH
END
GO