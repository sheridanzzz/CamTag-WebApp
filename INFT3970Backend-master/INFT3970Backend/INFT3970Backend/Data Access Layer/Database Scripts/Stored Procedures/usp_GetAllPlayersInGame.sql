-- =============================================
-- Author:		Jonathan Williams
-- Create date: 18/09/18
-- Description:	Gets all the players in a game with multiple filter parameters

--FILTER
--ALL = get all the players in the game which arnt deleted
--ACTIVE = get all players in the game which arnt deleted and is active
--INGAME = get all players in the game which arnt deleted, is active, have not left the game and have been verified
--INGAMEALL = get all players in the game which arnt deleted, is active, and have been verified (includes players who have left the game)
--TAGGABLE = Get all player in the game who are taggable, so players who arnt deleted, is active, verified, have not left game and is not the playerID passed in
--HOST = Get all players in the game for the Host lobby view, includes unverified players
--UPDATEABLE = Get all players in the game which are not deleted, is active, is verified. Also includes BR players who have been eliminated.

--ORDER by
--AZ = Order by name in alphabetical order
--ZA = Order by name in reverse alphabetical order
--KILLS= Order from highest to lowest in number of kills

-- Returns: 1 = Successful, or 0 = An error occurred
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetAllPlayersInGame] 
	-- Add the parameters for the stored procedure here
	@id INT,
	@isPlayerID BIT,
	@filter VARCHAR(255),
	@orderBy VARCHAR(255),
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
		
		--Use the variable for taggable filter
		DECLARE @playerID INT;
		SET @playerID = @id;

		--If the id is a playerID get the GameID from the Player record
		IF(@isPlayerID = 1)
		BEGIN
			--Confirm the playerID exists
			EXEC [dbo].[usp_ConfirmPlayerExists] @id = @id, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
			EXEC [dbo].[usp_DoRaiseError] @result = @result

			--Get the GameID from the playerID
			DECLARE @gameID INT;
			EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @id, @gameID = @gameID OUTPUT

			--Set the @id to the GameID so it can now be used in the query
			SET @id = @gameID
		END

		--Otherwise, confirm the GameID exists
		ELSE
		BEGIN
			EXEC [dbo].[usp_ConfirmGameExists] @id = @id, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
			EXEC [dbo].[usp_DoRaiseError] @result = @result
		END


		--If filter = ALL get all the players in the game which arnt deleted
		IF(@filter LIKE 'ALL')
		BEGIN
			SELECT * 
			FROM 
				vw_All_Players
			WHERE 
				GameID = @id
			ORDER BY
				CASE WHEN @orderBy LIKE 'AZ' THEN Nickname END ASC,
				CASE WHEN @orderBy LIKE 'ZA' THEN Nickname END DESC,
				CASE WHEN @orderBy LIKE 'KILLS' THEN NumKills END DESC
		END

		--If filer = ACTIVE get all players in the game which arnt deleted and active
		IF(@filter LIKE 'ACTIVE')
		BEGIN
			SELECT * 
			FROM 
				vw_Active_Players
			WHERE 
				GameID = @id
			ORDER BY
				CASE WHEN @orderBy LIKE 'AZ' THEN Nickname END ASC,
				CASE WHEN @orderBy LIKE 'ZA' THEN Nickname END DESC,
				CASE WHEN @orderBy LIKE 'KILLS' THEN NumKills END DESC
		END

		--If filer = INGAME get all players in the game which arnt deleted, isactive, have not left the game and have been verified
		IF(@filter LIKE 'INGAME')
		BEGIN
			SELECT * 
			FROM 
				vw_InGame_Players
			WHERE 
				GameID = @id
			ORDER BY
				CASE WHEN @orderBy LIKE 'AZ' THEN Nickname END ASC,
				CASE WHEN @orderBy LIKE 'ZA' THEN Nickname END DESC,
				CASE WHEN @orderBy LIKE 'KILLS' THEN NumKills END DESC
		END

		--If filer = INGAMEALL get all players in the game which arnt deleted, isactive, and have been verified (includes players who have left the game)
		IF(@filter LIKE 'INGAMEALL')
		BEGIN
			SELECT * 
			FROM 
				vw_InGameAll_Players
			WHERE 
				GameID = @id
			ORDER BY
				CASE WHEN @orderBy LIKE 'AZ' THEN Nickname END ASC,
				CASE WHEN @orderBy LIKE 'ZA' THEN Nickname END DESC,
				CASE WHEN @orderBy LIKE 'KILLS' THEN NumKills END DESC
		END


		--If filer = TAGGABLE get all players in the game which are able to be tagged, so players which are verified, in game, have not left game, have not been eliminated
		IF(@filter LIKE 'TAGGABLE')
		BEGIN
			SELECT * 
			FROM 
				vw_InGame_Players
			WHERE 
				GameID = @id AND
				(IsEliminated = 0 OR IsEliminated IS NULL) AND
				PlayerID <> @playerID
			ORDER BY
				CASE WHEN @orderBy LIKE 'AZ' THEN Nickname END ASC,
				CASE WHEN @orderBy LIKE 'ZA' THEN Nickname END DESC,
				CASE WHEN @orderBy LIKE 'KILLS' THEN NumKills END DESC
		END

		--If filter = HOST get all the players in the game which arnt deleted, and have not left the game, include unverified players
		IF(@filter LIKE 'HOST')
		BEGIN
			SELECT * 
			FROM 
				vw_All_Players
			WHERE 
				GameID = @id AND
				HasLeftGame = 0 AND
				PlayerIsActive = 1
			ORDER BY
				CASE WHEN @orderBy LIKE 'AZ' THEN Nickname END ASC,
				CASE WHEN @orderBy LIKE 'ZA' THEN Nickname END DESC,
				CASE WHEN @orderBy LIKE 'KILLS' THEN NumKills END DESC
		END


		--If filter is UPDATEABLE get all players in the game which are updateable.
		--Players who have not left the game, is active, not deleted. Updateable also includes Eliminated BR players. 
		IF(@filter LIKE 'UPDATEABLE')
		BEGIN
			SELECT * 
			FROM 
				vw_All_Players
			WHERE 
				GameID = @id AND
				HasLeftGame = 0 AND
				PlayerIsActive = 1 AND
				IsVerified = 1
			ORDER BY
				CASE WHEN @orderBy LIKE 'AZ' THEN Nickname END ASC,
				CASE WHEN @orderBy LIKE 'ZA' THEN Nickname END DESC,
				CASE WHEN @orderBy LIKE 'KILLS' THEN NumKills END DESC
		END

		--Set the return variables
		SET @result = 1;
		SET @errorMSG = ''
	END TRY

	BEGIN CATCH
	END CATCH
END
GO