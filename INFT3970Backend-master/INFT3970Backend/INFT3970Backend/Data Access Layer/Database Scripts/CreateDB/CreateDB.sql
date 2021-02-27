/*
-----------------------------------------------------------------
Script Name: CreateDB

Description:    Creates the database tables, views and stored procedures
				required to run the CamTag web application

Course: INFT3970 - IT Major Project - CamTag

Author:         Jonathan Williams & the CamTag Team
-----------------------------------------------------------------
*/

--Creating a login to use with the connection string
CREATE LOGIN DataAccessLayerLogin WITH PASSWORD = 'test'
GO
EXEC master..sp_addsrvrolemember @loginame = N'DataAccessLayerLogin', @rolename = N'sysadmin'
GO

--Drop the database if it exists
DROP DATABASE udb_CamTag
GO

--Create the Database
CREATE DATABASE udb_CamTag
GO

USE udb_CamTag
GO

--Creating a user for the login
CREATE USER DataAccessLayerUser FOR LOGIN DataAccessLayerLogin;
GO

--Create the Game table
CREATE TABLE tbl_Game
(
	GameID INT NOT NULL IDENTITY(100000, 1),
	GameCode VARCHAR(6) NOT NULL DEFAULT 'ABC123' UNIQUE,
	NumOfPlayers INT NOT NULL DEFAULT 0,
	GameMode VARCHAR(255) NOT NULL DEFAULT 'CORE',
	StartTime DATETIME2,
	EndTime DATETIME2,
	TimeLimit INT NOT NULL DEFAULT 86400000,
	AmmoLimit INT NOT NULL DEFAULT 3,
	StartDelay INT NOT NULL DEFAULT 600000,
	ReplenishAmmoDelay INT NOT NULL DEFAULT 600000,
	GameState VARCHAR(255) NOT NULL DEFAULT 'IN LOBBY',
	IsJoinableAtAnytime BIT NOT NULL DEFAULT 0,
	GameIsActive BIT NOT NULL DEFAULT 1,
	GameIsDeleted BIT NOT NULL DEFAULT 0,

	--Used for battle royale
	Latitude FLOAT NOT NULL DEFAULT 0.00,
	Longitude FLOAT NOT NULL DEFAULT 0.00,
	Radius INT NOT NULL DEFAULT 0,

	PRIMARY KEY (GameID),

	CHECK(LEN(GameCode) = 6),
	CHECK(NumOfPlayers >= 0 AND NumOfPlayers <= 16),
	CHECK(GameMode IN ('CORE', 'BR')),
	CHECK(StartTime < EndTime),
	CHECK(GameState IN ('IN LOBBY', 'STARTING', 'PLAYING', 'COMPLETED')),

	--Timelimit is between 10 minutes and 24 hours (in milliseconds)
	CHECK(TimeLimit >= 600000 AND TimeLimit <= 86400000),

	CHECK(AmmoLimit >= 1 AND AmmoLimit <= 9),

	--ReplenishAmmoDelay is between 1 minute and 1 hour (in milliseconds)
	CHECK(ReplenishAmmoDelay >= 60000 AND ReplenishAmmoDelay <= 3600000),

	--Start Delay is between 1 minute and 10 minutes (in milliseconds)
	CHECK(StartDelay >= 60000 AND StartDelay <= 600000)
);
GO

--Create a function which will be used as a check constraint to verify
-- a players contact, either phone or email must be provided, both cannot be null
CREATE FUNCTION udf_IsPlayerEmailAndPhoneValid (
  @phone VARCHAR(12),
  @email VARCHAR(255)
)
RETURNS tinyint
AS
BEGIN
  DECLARE @Result tinyint;
  IF (@phone IS NULL AND @email IS NULL)
    SET @Result= 0
  ELSE 
    SET @Result= 1
  RETURN @Result
END
GO

--Create the Player table
CREATE TABLE tbl_Player
(
	PlayerID INT NOT NULL IDENTITY(100000, 1),
	Nickname VARCHAR(255) NOT NULL DEFAULT 'Player',
	Phone VARCHAR(12),
	Email VARCHAR(255),
	Selfie VARCHAR(MAX) NOT NULL,
	SmallSelfie VARCHAR(MAX) NOT NULL,
	ExtraSmallSelfie VARCHAR(MAX) NOT NULL,
	AmmoCount INT NOT NULL DEFAULT 3,
	NumKills INT NOT NULL DEFAULT 0,
	NumDeaths INT NOT NULL DEFAULT 0,
	IsHost BIT NOT NULL DEFAULT 0,
	IsVerified BIT NOT NULL DEFAULT 0,
	VerificationCode INT,
	ConnectionID VARCHAR(255) DEFAULT NULL,
	HasLeftGame BIT NOT NULL DEFAULT 0,
	PlayerIsDeleted BIT NOT NULL DEFAULT 0,
	PlayerIsActive BIT NOT NULL DEFAULT 1,
	GameID INT NOT NULL,

	--Used for battle royale
	PlayerType VARCHAR(255) NOT NULL DEFAULT 'CORE',
	IsEliminated BIT NOT NULL DEFAULT 0,
	IsDisabled BIT NOT NULL DEFAULT 0,

	PRIMARY KEY (PlayerID),
	FOREIGN KEY (GameID) REFERENCES tbl_Game(GameID),

	CHECK(NumKills >= 0),
	CHECK(NumDeaths >= 0),
	CHECK(AmmoCount >= 0),
	CONSTRAINT IsContactProvided CHECK 
	(
		dbo.udf_IsPlayerEmailAndPhoneValid(Phone, Email) = 1
	)
);
GO

--Create the Photo table
CREATE TABLE tbl_Photo 
(
	PhotoID INT NOT NULL IDENTITY(100000, 1),
	Lat FLOAT NOT NULL DEFAULT 0,
	Long FLOAT NOT NULL DEFAULT 0,
	PhotoDataURL VARCHAR(MAX) NOT NULL,
	TimeTaken DATETIME2 NOT NULL DEFAULT GETDATE(),
	VotingFinishTime DATETIME2 NOT NULL DEFAULT DATEADD(MINUTE, 15, GETDATE()),
	NumYesVotes INT NOT NULL DEFAULT 0,
	NumNoVotes INT NOT NULL DEFAULT 0,
	IsVotingComplete BIT NOT NULL DEFAULT 0,
	PhotoIsActive BIT NOT NULL DEFAULT 1,
	PhotoIsDeleted BIT NOT NULL DEFAULT 0,
	GameID INT NOT NULL,
	TakenByPlayerID INT NOT NULL,
	PhotoOfPlayerID INT NOT NULL,

	PRIMARY KEY (PhotoID),
	FOREIGN KEY (GameID) REFERENCES tbl_Game(GameID),
	FOREIGN KEY (TakenByPlayerID) REFERENCES tbl_Player(PlayerID),
	FOREIGN KEY (PhotoOfPlayerID) REFERENCES tbl_Player(PlayerID),

	CHECK(VotingFinishTime > TimeTaken),
	CHECK(NumYesVotes >= 0),
	CHECK(NumNoVotes >= 0)
);
GO

--Create the Player and Photo many to many relationship
CREATE TABLE tbl_Vote
(
	VoteID INT NOT NULL IDENTITY(100000, 1),
	IsPhotoSuccessful BIT DEFAULT NULL,
	VoteIsActive BIT NOT NULL DEFAULT 1,
	VoteIsDeleted BIT NOT NULL DEFAULT 0,
	PhotoID INT NOT NULL,
	PlayerID INT NOT NULL,

	PRIMARY KEY (VoteID),
	FOREIGN KEY (PhotoID) REFERENCES tbl_Photo(PhotoID),
	FOREIGN KEY (PlayerID) REFERENCES tbl_Player(PlayerID)
);
GO

--Create the Notification table
CREATE TABLE tbl_Notification
(
	NotificationID INT NOT NULL IDENTITY(100000, 1),
	MessageText VARCHAR(255) NOT NULL DEFAULT 'Notification',
	NotificationType VARCHAR(255) NOT NULL DEFAULT 'SUCCESS',
	IsRead BIT NOT NULL DEFAULT 0,
	NotificationIsActive BIT NOT NULL DEFAULT 1,
	NotificationIsDeleted BIT NOT NULL DEFAULT 0,
	GameID INT NOT NULL,
	PlayerID INT NOT NULL,

	PRIMARY KEY (NotificationID),
	FOREIGN KEY (GameID) REFERENCES tbl_Game(GameID),
	FOREIGN KEY (PlayerID) REFERENCES tbl_Player(PlayerID),

	CHECK(NotificationType IN ('SUCCESS', 'FAIL', 'JOIN', 'LEAVE', 'AMMO', 'DISABLED', 'RE-ENABLED'))
);
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all Games matching the following requirements:
--				1. Not Deleted
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_All_Games
AS
SELECT *
FROM
	tbl_Game
WHERE
	GameIsDeleted = 0
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all Games matching the following requirements:
--				1. Not Deleted
--				2. Is Active
--				3. Game is not completed
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Active_Games
AS
SELECT *
FROM
	vw_All_Games
WHERE
	GameIsActive = 1 AND
	GameState NOT LIKE 'COMPLETED'
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/10/18
-- Description:	Creates the Battle Royal Game View
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_BRGames
AS
SELECT *
FROM
	vw_All_Games
WHERE
	GameMode LIKE 'BR'
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all players matching the following requirements:
--				1. Not Deleted
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_All_Players
AS
SELECT *
FROM
	tbl_Player
WHERE
	PlayerIsDeleted = 0
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all players matching the following requirements:
--				1. Not Deleted
--				2. Is Active
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Active_Players
AS
SELECT *
FROM
	vw_All_Players
WHERE
	PlayerIsActive = 1
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all players matching the following requirements:
--				1. Not Deleted
--				2. Is Active
--				3. Is verified
--				4. Has not left the game / been eliminated from the game
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_InGame_Players
AS
SELECT *
FROM
	vw_Active_Players
WHERE
	IsVerified = 1 AND
	HasLeftGame = 0 AND
	(IsEliminated = 0 OR IsEliminated IS NULL)
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all players matching the following requirements:
--				1. Not Deleted
--				2. Is Active
--				3. Is verified
--				4. Include players who have left the game as well as still in the game.
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_InGameAll_Players
AS
SELECT *
FROM
	vw_Active_Players
WHERE
	IsVerified = 1
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all Votes matching the following requirements:
--				1. Not Deleted
--				2. Is Active
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Active_Votes
AS
SELECT *
FROM
	tbl_Vote
WHERE
	VoteIsDeleted = 0 AND
	VoteIsActive = 1
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all Votes matching the following requirements:
--				1. Not Deleted
--				2. Is Active
--				3. Vote has NOT been completed / submited
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Incomplete_Votes
AS
SELECT *
FROM
	vw_Active_Votes
WHERE
	IsPhotoSuccessful IS NULL
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all Votes matching the following requirements:
--				1. Not Deleted
--				2. Is Active
--				3. Vote is a SUCCESS
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Success_Votes
AS
SELECT *
FROM
	vw_Active_Votes
WHERE
	IsPhotoSuccessful = 1
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all Votes matching the following requirements:
--				1. Not Deleted
--				2. Is Active
--				3. Vote is a FAIL
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Fail_Votes
AS
SELECT *
FROM
	vw_Active_Votes
WHERE
	IsPhotoSuccessful = 0
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all Photos matching the following requirements:
--				1. Not Deleted
--				2. Is Active
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Active_Photos
AS
SELECT *
FROM
	tbl_Photo
WHERE
	PhotoIsDeleted = 0 AND
	PhotoIsActive = 1
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all Photos matching the following requirements:
--				1. Not Deleted
--				2. Is Active
--				3. Voting has been completed
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Completed_Photos
AS
SELECT *
FROM
	vw_Active_Photos
WHERE
	IsVotingComplete = 1
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all Photos matching the following requirements:
--				1. Not Deleted
--				2. Is Active
--				3. Voting has NOT been completed
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Incompleted_Photos
AS
SELECT *
FROM
	vw_Active_Photos
WHERE
	IsVotingComplete = 0
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all Notifications matching the following requirements:
--				1. Not Deleted
--				2. Is Active
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Active_Notifications
AS
SELECT *
FROM
	tbl_Notification
WHERE
	NotificationIsDeleted = 0 AND
	NotificationIsActive = 1
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all Notifications matching the following requirements:
--				1. Not Deleted
--				2. Is Active
--				3. Notification has been read by the user
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Read_Notifications
AS
SELECT *
FROM
	vw_Active_Notifications
WHERE
	IsRead = 1
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which contains all Notifications matching the following requirements:
--				1. Not Deleted
--				2. Is Active
--				3. Notification has NOT been read by the user
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Unread_Notifications
AS
SELECT *
FROM
	vw_Active_Notifications
WHERE
	IsRead = 0
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which JOINS the Player and Game tables
--				Contains all records which are not deleted.
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Join_PlayerGame
AS
SELECT 
	PlayerID,
	Nickname,
	Phone,
	Email,
	Selfie,
	SmallSelfie,
	ExtraSmallSelfie,
	AmmoCount,
	NumKills,
	NumDeaths,
	IsHost,
	IsVerified,
	VerificationCode,
	HasLeftGame,
	PlayerIsActive,
	PlayerIsDeleted,
	PlayerType,
	IsEliminated,
	IsDisabled,
	ConnectionID,
	g.GameID,
	GameCode,
	NumOfPlayers,
	GameMode,
	StartTime,
	EndTime,
	AmmoLimit,
	ReplenishAmmoDelay,
	StartDelay,
	GameState,
	IsJoinableAtAnytime,
	GameIsActive,
	GameIsDeleted,
	Latitude,
	Longitude,
	Radius
FROM
	vw_All_Players p INNER JOIN
	vw_All_Games g ON (p.GameID = g.GameID)
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which JOINS the Photo Game and Players table
--				Contains all records which are not deleted and IS ACTIVE.
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Join_PhotoGamePlayers
AS
SELECT
	PhotoID,
	Lat,
	Long,
	PhotoDataURL,
	TimeTaken,
	VotingFinishTime,
	NumYesVotes,
	NumNoVotes,
	IsVotingComplete,
	PhotoIsActive,
	PhotoIsDeleted,
	p.GameID,
	GameCode,
	NumOfPlayers,
	GameMode,
	StartTime,
	EndTime,
	AmmoLimit,
	ReplenishAmmoDelay,
	StartDelay,
	GameState,
	IsJoinableAtAnytime,
	GameIsActive,
	GameIsDeleted,
	Latitude,
	Longitude,
	Radius,
	TakenByPlayerID,
	takenBy.Nickname AS TakenByPlayerNickname,
	takenBy.Phone AS TakenByPlayerPhone,
	takenBy.Email AS TakenByPlayerEmail,
	takenBy.Selfie AS TakenByPlayerSelfie,
	takenBy.SmallSelfie AS TakenByPlayerSmallSelfie,
	takenBy.ExtraSmallSelfie AS TakenByPlayerExtraSmallSelfie,
	takenBy.AmmoCount AS TakenByPlayerAmmoCount,
	takenBy.NumKills AS TakenByPlayerNumKills,
	takenBy.NumDeaths AS TakenByPlayerNumDeaths,
	takenBy.IsHost AS TakenByPlayerIsHost,
	takenBy.IsVerified AS TakenByPlayerIsVerified,
	takenBy.ConnectionID AS TakenByPlayerConnectionID,
	takenBy.PlayerIsActive AS TakenByPlayerIsActive,
	takenBy.PlayerIsDeleted AS TakenByPlayerIsDeleted,
	takenBy.HasLeftGame AS TakenByPlayerHasLeftGame,
	takenBy.PlayerType AS TakenByPlayerPlayerType,
	takenBy.IsEliminated AS TakenByPlayerIsEliminated,
	takenBy.IsDisabled AS TakenByPlayerIsDisabled,
	PhotoOfPlayerID,
	photoOf.Nickname AS PhotoOfPlayerNickname,
	photoOf.Phone AS PhotoOfPlayerPhone,
	photoOf.Email AS PhotoOfPlayerEmail,
	photoOf.Selfie AS PhotoOfPlayerSelfie,
	photoOf.SmallSelfie AS PhotoOfPlayerSmallSelfie,
	photoOf.ExtraSmallSelfie AS PhotoOfPlayerExtraSmallSelfie,
	photoOf.AmmoCount AS PhotoOfPlayerAmmoCount,
	photoOf.NumKills AS PhotoOfPlayerNumKills,
	photoOf.NumDeaths AS PhotoOfPlayerNumDeaths,
	photoOf.IsHost AS PhotoOfPlayerIsHost,
	photoOf.IsVerified AS PhotoOfPlayerIsVerified,
	photoOf.ConnectionID AS PhotoOfPlayerConnectionID,
	photoOf.PlayerIsActive AS PhotoOfPlayerIsActive,
	photoOf.PlayerIsDeleted AS PhotoOfPlayerIsDeleted,
	photoOf.HasLeftGame AS PhotoOfPlayerHasLeftGame,
	photoOf.PlayerType AS PhotoOfPlayerPlayerType,
	photoOf.IsEliminated AS PhotoOfPlayerIsEliminated,
	photoOf.IsDisabled AS PhotoOfPlayerIsDisabled
FROM
	vw_Active_Photos p 
	INNER JOIN vw_Active_Games g ON (p.GameID = g.GameID)
	INNER JOIN vw_Active_Players takenBy ON (p.TakenByPlayerID = takenBy.PlayerID)
	INNER JOIN vw_Active_Players photoOf ON (p.PhotoOfPlayerID = photoOf.PlayerID)
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which JOINS the Vote, Photo and Player tables.
--				Contains all records which are not deleted and IS ACTIVE.
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Join_VotePhotoPlayer
AS
SELECT
	v.VoteID,
	v.IsPhotoSuccessful,
	v.VoteIsActive,
	v.VoteIsDeleted,
	pgp.*,
	pl.PlayerID,
	pl.Nickname,
	pl.Phone,
	pl.Email,
	pl.Selfie,
	pl.SmallSelfie,
	pl.ExtraSmallSelfie,
	pl.AmmoCount,
	pl.NumKills,
	pl.NumDeaths,
	pl.IsHost,
	pl.IsVerified,
	pl.ConnectionID,
	pl.HasLeftGame,
	pl.PlayerIsActive,
	pl.PlayerIsDeleted,
	pl.PlayerType,
	pl.IsEliminated,
	pl.IsDisabled
FROM
	vw_Active_Votes v
	INNER JOIN vw_Active_Players pl ON (pl.PlayerID = v.PlayerID)
	INNER JOIN vw_Join_PhotoGamePlayers pgp ON (v.PhotoID = pgp.PhotoID)
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	View which JOINS the Notifications, Game and Player tables
--				Contains all records which are not deleted and IS ACTIVE.
-- =============================================
USE udb_CamTag
GO
CREATE VIEW vw_Join_NotificationGamePlayer
AS
SELECT
	NotificationID,
	MessageText,
	NotificationType,
	IsRead,
	NotificationIsActive,
	NotificationIsDeleted,
	p.*
FROM 
	vw_Active_Notifications n
	INNER JOIN vw_Join_PlayerGame p ON (n.PlayerID = p.PlayerID)
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 15/09/18
-- Description:	Confirms the GameID exists
-- =============================================
CREATE PROCEDURE usp_ConfirmGameExists
	@id INT,
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

    IF NOT EXISTS (SELECT * FROM tbl_Game WHERE GameID = @id AND GameIsDeleted = 0)
	BEGIN
		SELECT @result = @GAME_DOES_NOT_EXIST;
		SET @errorMSG = 'The Game does not exist.';
	END
	ELSE
	BEGIN
		SELECT @result = 1;
		SET @errorMSG = '';
	END
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 15/09/18
-- Description:	Confirms the Game is not already completed.
-- =============================================
CREATE PROCEDURE usp_ConfirmGameNotCompleted
	@id INT,
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

	--Confirm the game exists
	EXEC [dbo].[usp_ConfirmGameExists] @id = @id, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT

	--If the game exists check to see if the game is completed.
	IF(@result = 1)
	BEGIN
		IF NOT EXISTS (SELECT * FROM vw_Active_Games WHERE GameID = @id)
		BEGIN
			SELECT @result = @GAME_STATE_INVALID;
			SET @errorMSG = 'The game is already completed.';
		END
		ELSE
		BEGIN
			SELECT @result = 1;
			SET @errorMSG = '';
		END
	END
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 15/09/18
-- Description:	Confirm the GameState of the GameID passed in is as expected.
-- =============================================
CREATE PROCEDURE usp_ConfirmGameStateCorrect
	@gameID INT,
	@correctGameState VARCHAR(255),
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

	--Confirm the game exists
	EXEC [dbo].[usp_ConfirmGameExists] @id = @gameID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
	
	IF(@result = 1)
	BEGIN
		--Get the actual current game state and confirm the game state is correct
		DECLARE @actualGameState VARCHAR(255);
		SELECT @actualGameState = GameState FROM tbl_Game WHERE GameID = @gameID

		--Confirm the game state matches the game state passed in
		IF(@correctGameState NOT LIKE @actualGameState)
		BEGIN
			SET @result = @GAME_STATE_INVALID;
			SET @errorMSG = 'The game state is invalid for this operation. Expecting game state to be ' + @correctGameState + ' but the actual game state is ' + @actualGameState;
		END
		ELSE
		BEGIN
			SET @result = 1;
			SET @errorMSG = '';
		END
	END
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 15/09/18
-- Description:	Confirms the PlayerID exists.
-- =============================================
CREATE PROCEDURE usp_ConfirmPlayerExists
	@id INT,
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

    IF NOT EXISTS (SELECT * FROM vw_All_Players WHERE PlayerID = @id)
	BEGIN
		SELECT @result = @PLAYER_DOES_NOT_EXIST;
		SET @errorMSG = 'The PlayerID does not exist';
	END
	ELSE
	BEGIN
		SELECT @result = 1;
		SET @errorMSG = '';
	END
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 23/09/18
-- Description:	Confirms the PlayerID passed in has not left the game.
-- =============================================
CREATE PROCEDURE usp_ConfirmPlayerInGame
	@id INT,
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

	EXEC [dbo].[usp_ConfirmPlayerExists] @id = @id, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT

	--If the player exists and isactive, check to see if the player is in the game.
	IF(@result = 1)
	BEGIN
		IF NOT EXISTS (SELECT * FROM vw_InGame_Players WHERE PlayerID = @id)
		BEGIN
			SELECT @result = @PLAYER_INVALID;
			SET @errorMSG = 'The PlayerID is not in the game.';
		END
		ELSE
		BEGIN
			SELECT @result = 1;
			SET @errorMSG = '';
		END
	END
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 15/09/18
-- Description:	Confirms the PlayerID exists and is active.
-- =============================================
CREATE PROCEDURE usp_ConfirmPlayerIsActive
	@id INT,
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

	--Confirm the playerID passed in exists
	EXEC [dbo].[usp_ConfirmPlayerExists] @id = @id, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT

	--If the player exists, check if the player is active
	IF(@result = 1)
	BEGIN
		IF NOT EXISTS (SELECT * FROM vw_Active_Players WHERE PlayerID = @id)
		BEGIN
			SELECT @result = @PLAYER_INVALID;
			SET @errorMSG = 'The PlayerID is not active.';
		END
		ELSE
		BEGIN
			SELECT @result = 1;
			SET @errorMSG = '';
		END
	END
END
GO

CREATE PROCEDURE usp_DoRaiseError 
	@result INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF(@result <> 1)
	BEGIN
		RAISERROR('',16,1);
	END	
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 05/09/18
-- Description:	Begins the Game, sets the GameState to Starting and sets the StartTime and EndTime
--				Business Logic Code is scheduled to Run at start time to start the game and update the Game State to PLAYING.

-- Returns: The result (1 = successful, anything else = error), and the error message associated with it
-- =============================================
CREATE PROCEDURE usp_BeginGame 
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
		EXEC [dbo].[usp_ConfirmPlayerInGame] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result
		

		--Confirm the playerID passed in Is the host of the Game because only the host can begin the game
		DECLARE @isHost BIT;
		SELECT @isHost = IsHost FROM vw_InGame_Players WHERE PlayerID = @playerID
		IF(@isHost = 0)
		BEGIN
			SET @result = @DATA_INVALID;
			SET @errorMSG = 'The playerID passed in is not the host player. Only the host can begin the game.';
			RAISERROR('',16,1);
		END

		--Get the GameID from the playerID
		DECLARE @gameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT


		--Confirm the Game is IN LOBBY state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'IN LOBBY', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result


		--Confirm there is enough players in the Game to Start
		DECLARE @activePlayerCount INT = 0;
		SELECT @activePlayerCount = COUNT(*) FROM vw_Active_Players WHERE GameID = @gameID AND HasLeftGame = 0
		IF(@activePlayerCount < 3)
		BEGIN
			SET @result = @CANNOT_PERFORM_ACTION;
			SET @errorMSG = 'Not enough players to start the game, need a minimum of 3.';
			RAISERROR('',16,1);
		END


		--Confirm that all players are verified, all players in the game need to be verified before the game can start
		IF EXISTS (SELECT * FROM vw_All_Players WHERE GameID = @gameID AND IsVerified = 0 AND HasLeftGame = 0)
		BEGIN
			SET @result = @CANNOT_PERFORM_ACTION;
			SET @errorMSG = 'All players must be verified before the game can begin.';
			RAISERROR('',16,1);
		END


		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			--Get the StartDelay and the TimeLimit
			DECLARE @delay INT = 0;
			DECLARE @timeLimit INT = 0;
			SELECT @delay = StartDelay, @timeLimit = TimeLimit
			FROM tbl_Game
			WHERE GameID = @gameID

			--Update the GameState to STARTING
			UPDATE tbl_Game
			SET 
				GameState = 'STARTING', 
				StartTime = DATEADD(MILLISECOND, @delay, GETDATE())
			WHERE GameID = @gameID

			--Set the end time, use the start time + the time limit to calculate the end time
			DECLARE @startTime DATETIME2;
			SELECT @startTime = StartTime
			FROM tbl_Game
			WHERE GameID = @gameID
			UPDATE tbl_Game
			SET EndTime = DATEADD(MILLISECOND, @timeLimit, @startTime)
		COMMIT

		--Return the updated game record
		SET @result = 1
		SET @errorMSG = '';
		SELECT * FROM tbl_Game WHERE GameID = @gameID
	END TRY

	--An error occurred in the data validation
	BEGIN CATCH
		--An error occurred while trying to perform the update on the PLayer table
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'The an error occurred while trying to begin the game.';
		END
	END CATCH
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 05/09/18
-- Description:	Completes a game and sets all references to the game to not active.
--				All players, photos, votes etc associated with the game will be set to inactive

-- Returns: The result (1 = successful, anything else = error), and the error message associated with it
-- =============================================
CREATE PROCEDURE [dbo].[usp_CompleteGame] 
	-- Add the parameters for the stored procedure here
	@gameID INT,
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
		
		--Confirm the gameID passed in exists not complete
		EXEC [dbo].[usp_ConfirmGameNotCompleted] @id = @gameID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Confirm the Game is STARTING state
		--Can be in a starting state because players could leave while the game is starting.
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'STARTING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		
		--If the game is not in SATRTING state, check if its in PLAYING
		IF(@result <> 1)
		BEGIN
			EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
			EXEC [dbo].[usp_DoRaiseError] @result = @result
		END

		--Update the Game to now be completed.
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			--Update the game to completed
			UPDATE tbl_Game
			SET GameIsActive = 0, GameState = 'COMPLETED'
			WHERE GameID = @gameID

			--Update all the players in the game to not active
			UPDATE tbl_Player
			SET PlayerIsActive = 0
			WHERE GameID = @gameID

			--Delete any votes on a photo which have not yet been completed in the game
			UPDATE tbl_Vote
			SET VoteIsDeleted = 1
			WHERE PhotoID IN (SELECT PhotoID FROM vw_Incompleted_Photos WHERE GameID = @gameID)

			--Update all votes to not active
			UPDATE tbl_Vote
			SET VoteIsActive = 0
			WHERE PlayerID IN (SELECT PlayerID FROM tbl_Player WHERE GameID = @gameID)

			--Delete any photos which voting has not yet been completed
			UPDATE tbl_Photo
			SET PhotoIsDeleted = 1
			WHERE IsVotingComplete = 0 AND GameID = @gameID

			--Update all photos in the game to not active
			UPDATE tbl_Photo
			SET PhotoIsActive = 0
			WHERE GameID = @gameID

			--Update all notifications to not active
			UPDATE tbl_Notification
			SET NotificationIsActive = 0
			WHERE GameID = @gameID
		COMMIT

		SET @result = 1;
		SET @errorMSG = '';

	END TRY

	--An error occurred in the data validation
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'The an error occurred while trying to complete the game.';
		END

	END CATCH
END
GO

-- =============================================
-- Author:		Dylan Levin
-- Create date: 11/09/18
-- Description:	Adds a notification informing the user that their ammo has refilled

-- Returns: 1 = Successful, or 0 = An error occurred
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreateAmmoNotification] 
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
		EXEC [dbo].[usp_ConfirmPlayerInGame] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result
		
		--Get the GameID from the playerID
		DECLARE @gameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT

		--Confirm the Game is PLAYING state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Add the notification after successfully performing the precondition checks
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION		
			INSERT INTO tbl_Notification(MessageText, NotificationType, IsRead, NotificationIsActive, GameID, PlayerID) 
			VALUES ('You have more ammo!', 'AMMO', 0, 1, @gameID, @playerID)			
		COMMIT
	END TRY

	--An error occurred in the data validation
	BEGIN CATCH
		--An error occurred while trying to perform the update on the Notification table
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SELECT @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to create the ammo notification.'
		END
	END CATCH
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 05/09/18
-- Description:	Creates a new game in the database.

-- Returns: The result (1 = successful, anything else = error), and the error message associated with it
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreateGame] 
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
			INSERT INTO tbl_Game (GameCode, TimeLimit, AmmoLimit, StartDelay, ReplenishAmmoDelay, GameMode, IsJoinableAtAnytime, Latitude, Longitude, Radius) 
			VALUES (@gameCode, @timeLimit, @ammoLimit, @startDelay, @replenishAmmoDelay, @gameMode, @isJoinableAtAnytime, @latitude, @longitude, @radius);
			SET @createdGameID = SCOPE_IDENTITY();
		COMMIT

		--Set the success return variables
		SET @result = 1;
		SET @errorMSG = '';

		--Read the new game record
		SELECT * FROM vw_Active_Games WHERE GameID = @createdGameID
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

-- =============================================
-- Author:		Dylan Levin
-- Create date: 06/09/18
-- Description:	Adds a Join notification to each player in the game.

-- Returns: 1 = Successful, or 0 = An error occurred
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreateJoinNotification] 
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
		EXEC [dbo].[usp_ConfirmPlayerInGame] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result
		
		--Get the GameID from the playerID
		DECLARE @gameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT

		--Confirm the Game is PLAYING state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Add the join notification to each other player in the game.
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION

			--Get the message which will be added as the notification text
			DECLARE @msgTxt VARCHAR(255)
			SELECT @msgTxt = p.Nickname + ' has joined the game.' FROM tbl_Player p WHERE p.PlayerID = @PlayerID


			--Create the notifications for all other players in the game
			INSERT INTO tbl_Notification(MessageText, NotificationType, IsRead, NotificationIsActive, GameID, PlayerID) 
			SELECT @msgTxt, 'JOIN', 0, 1, @gameID, PlayerID
			FROM vw_InGame_Players
			WHERE PlayerID <> @playerID AND GameID = @gameID

		COMMIT

		SET @result = 1;
		SET @errorMSG = '';

	END TRY

	--An error occurred in the data validation
	BEGIN CATCH
		--An error occurred while trying to perform the update on the Notification table
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to create the join notification.'
		END
	END CATCH
END
GO

-- =============================================
-- Author:		Dylan Levin
-- Create date: 06/09/18
-- Description:	Adds a player left notification for all players in the game.

-- Returns: 1 = Successful, or 0 = An error occurred
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreateLeaveNotification] 
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
		--Get the GameID from the playerID
		DECLARE @gameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT

		--Confirm the Game is PLAYING state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--PlayerID exists and connectionID exists, add the notif
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			
			--Get the message which will be added as the notification text
			DECLARE @msgTxt VARCHAR(255)
			SELECT @msgTxt = p.Nickname + ' has left the game.' FROM tbl_Player p WHERE p.PlayerID = @PlayerID

			--Create the notifications for all other players in the game
			INSERT INTO tbl_Notification(MessageText, NotificationType, IsRead, NotificationIsActive, GameID, PlayerID) 
			SELECT @msgTxt, 'LEAVE', 0, 1, @gameID, PlayerID
			FROM vw_InGame_Players
			WHERE PlayerID <> @playerID AND GameID = @gameID
		COMMIT
	END TRY

	--An error occurred in the data validation
	BEGIN CATCH
		--An error occurred while trying to perform the update on the Notification table
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to create the leave notification.'
		END
	END CATCH
END
GO

-- =============================================
-- Author:		Dylan Levin
-- Create date: 06/09/18
-- Description:	Creates a tag notification for each player depending on the result of a tag.

-- Returns: 1 = Successful, or 0 = An error occurred
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreateTagResultNotification] 
	-- Add the parameters for the stored procedure here
	@takenByID INT,
	@photoOfID INT,
	@decision BIT,
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @msgTxt VARCHAR(255)
	
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

		--Validate the photoOfByID
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
		END

		--Confirm the Game is PLAYING state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @takenByGameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		IF (@decision = 1) --success
		BEGIN
			SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
			BEGIN TRANSACTION

				-- send to the tagged player
				SELECT @msgTxt = 'You have been tagged by ' + p.Nickname + '.' FROM tbl_Player p WHERE p.PlayerID = @takenByID
				INSERT INTO tbl_Notification(MessageText, NotificationType, IsRead, NotificationIsActive, GameID, PlayerID) VALUES (@msgTxt, 'SUCCESS', 0, 1, @takenByGameID, @photoOfID) -- insert into table with specific playerID			
						
				-- send to the tagging player
				SELECT @msgTxt = 'You successfully tagged ' + p.Nickname + '.' FROM tbl_Player p WHERE p.PlayerID = @photoOfID
				INSERT INTO tbl_Notification(MessageText, NotificationType, IsRead, NotificationIsActive, GameID, PlayerID) VALUES (@msgTxt, 'SUCCESS', 0, 1, @takenByGameID, @takenByID) -- insert into table with specific playerID	
						
				-- send to everyone else						
				SELECT @msgTxt = p.Nickname + ' was tagged by ' FROM tbl_Player p WHERE p.PlayerID = @photoOfID
				SELECT @msgTxt += p.Nickname + '.' FROM tbl_Player p WHERE p.PlayerID = @takenByID

				--Create the notifications for all other players in the game
				INSERT INTO tbl_Notification(MessageText, NotificationType, IsRead, NotificationIsActive, GameID, PlayerID) 
				SELECT @msgTxt, 'SUCCESS', 0, 1, @takenByGameID, PlayerID
				FROM vw_InGame_Players
				WHERE PlayerID <> @takenByID AND PlayerID <> @photoOfID AND GameID = @takenByGameID						
			COMMIT
		END
		ELSE --fail
		BEGIN
		BEGIN
			SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
			BEGIN TRANSACTION

				-- send to the tagged player				
				SELECT @msgTxt = 'You were missed by ' + p.Nickname + '.' FROM tbl_Player p WHERE p.PlayerID = @takenByID
				INSERT INTO tbl_Notification(MessageText, NotificationType, IsRead, NotificationIsActive, GameID, PlayerID) VALUES (@msgTxt, 'FAIL', 0, 1, @takenByGameID, @photoOfID) -- insert into table with specific playerID			
						
				-- send to the tagging player
				SELECT @msgTxt = 'You failed to tag ' + p.Nickname + '.' FROM tbl_Player p WHERE p.PlayerID = @photoOfID
				INSERT INTO tbl_Notification(MessageText, NotificationType, IsRead, NotificationIsActive, GameID, PlayerID) VALUES (@msgTxt, 'FAIL', 0, 1, @takenByGameID, @takenByID) -- insert into table with specific playerID	
						
				-- send to everyone else		
				SELECT @msgTxt = p.Nickname + ' failed to tag ' FROM tbl_Player p WHERE p.PlayerID = @takenByID
				SELECT @msgTxt += p.Nickname + '.' FROM tbl_Player p WHERE p.PlayerID = @photoOfID
				
				--Create the notifications for all other players in the game
				INSERT INTO tbl_Notification(MessageText, NotificationType, IsRead, NotificationIsActive, GameID, PlayerID) 
				SELECT @msgTxt, 'FAIL', 0, 1, @takenByGameID, PlayerID
				FROM vw_InGame_Players
				WHERE PlayerID <> @takenByID AND PlayerID <> @photoOfID AND GameID = @takenByGameID						
			COMMIT
		END
		END	
	END TRY

	--An error occurred in the data validation
	BEGIN CATCH
		--An error occurred while trying to perform the update on the Notification table
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to create the tag notification.'
		END
	END CATCH
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 05/09/18
-- Description:	Deactivates the game after the host player tried to create a game but failed to join
--				due to an unexpected error such as the email address is already taken by a player in a game etc.
-- =============================================
CREATE PROCEDURE [dbo].[usp_DeactivateGameAfterHostJoinError] 
	-- Add the parameters for the stored procedure here
	@gameID INT,
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Validate the gameID
	EXEC [dbo].[usp_ConfirmGameNotCompleted] @id = @gameID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
	EXEC [dbo].[usp_DoRaiseError] @result = @result

	UPDATE tbl_Game
	SET GameIsActive = 0, GameIsDeleted = 1
	WHERE GameID = @gameID

END
GO
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
-- =============================================
-- Author:		Jonathan Williams
-- Create date: 18/09/18
-- Description:	Gets the player's ammo count
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetAmmoCount] 
	-- Add the parameters for the stored procedure here
	@playerID INT,
	@ammoCount INT OUTPUT,
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET @ammoCount = -1;

	BEGIN TRY

	--Validate the playerID
	EXEC [dbo].[usp_ConfirmPlayerInGame] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
	EXEC [dbo].[usp_DoRaiseError] @result = @result

	--Get the players ammo count
	SELECT @ammoCount = AmmoCount
	FROM vw_InGame_Players
	WHERE PlayerID = @playerID

	SET @result = 1;
	SET @errorMSG = '';

	END TRY

	BEGIN CATCH
		SET @ammoCount = -1;
	END CATCH
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 06/09/18
-- Description:	Gets the game record matching the specified ID
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetGameByID] 
	-- Add the parameters for the stored procedure here
	@gameID INT,
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRY

	--Confirm the GameID passed in exists
	EXEC [dbo].[usp_ConfirmGameExists] @id = @gameID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
	EXEC [dbo].[usp_DoRaiseError] @result = @result

	--Select the game record
	SELECT *
	FROM tbl_Game
	WHERE GameID = @gameID

	SET @result = 1;
	SET @errorMSG = '';

	END TRY

	BEGIN CATCH

	END CATCH
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 15/09/18
-- Description:	Get the GameID from the passed in PlayerID
-- =============================================
CREATE PROCEDURE usp_GetGameIDFromPlayer
	@id INT,
	@gameID INT OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @gameID = GameID
	FROM tbl_Player
	WHERE PlayerID = @id
END
GO

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

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 19/09/18
-- Description:	Gets the last photos uploaded in the game by each player if
--				applicable, using their last photo taken as their last known
--				location.

-- Returns: The result (1 = successful, anything else = error), and the error message associated with it
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetLastKnownLocations] 
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
		EXEC [dbo].[usp_ConfirmPlayerInGame] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result
		
		--Get the GameID from the playerID
		DECLARE @gameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT

		--Confirm the Game is in a PLAYING state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Perform the select statement to get the last known locations
		SELECT * 
		FROM 
			vw_Join_PhotoGamePlayers p
		WHERE
			p.GameID = @gameID AND
			p.PhotoIsActive = 1 AND
			p.PhotoIsDeleted = 0 AND
			p.TakenByPlayerID <> @playerID AND
			p.TimeTaken IN (
				SELECT MAX(TimeTaken)
				FROM tbl_Photo ph
				WHERE
					ph.GameID = @gameID AND
					ph.PhotoIsActive = 1 AND
					ph.PhotoIsDeleted = 0
				GROUP BY
					ph.TakenByPlayerID
			)


		SET @result = 1
		SET @errorMSG = '';
	END TRY

	--An error occurred in the data validation
	BEGIN CATCH

	END CATCH
END
GO

-- =============================================
-- Author:		Dylan Levin
-- Create date: 06/09/18
-- Description:	Returns all the notifications for a player

-- Returns: 1 = Successful, or anything else = An error occurred
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetNotifications] 
	-- Add the parameters for the stored procedure here
	@playerID INT,
	@all BIT,
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

		--The playerID exists, get the notifications associated with that player, If ALL =1 get all notifications including ones already read, otherwise, just get unread
		IF (@all = 1)
			SELECT * FROM vw_Active_Notifications WHERE PlayerID = @playerID ORDER BY NotificationID DESC
		ELSE
			SELECT * FROM vw_Unread_Notifications WHERE PlayerID = @playerID ORDER BY NotificationID DESC

		--Set the return variables
		SET @result = 1;
		SET @errorMSG = ''

	END TRY

	BEGIN CATCH
		
	END CATCH
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 10/09/18
-- Description:	Gets the Photo Record matching the specified ID
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetPhotoByID] 
	-- Add the parameters for the stored procedure here
	@photoID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT *
	FROM vw_Join_PhotoGamePlayers
	WHERE PhotoID = @photoID
	
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 18/09/18
-- Description:	Gets the player record matching the specified ID
-- =============================================
CREATE PROCEDURE usp_GetPlayerByID
	-- Add the parameters for the stored procedure here
	@playerID INT,
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRY

	--Validate the playerID
	EXEC [dbo].[usp_ConfirmPlayerExists] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
	EXEC [dbo].[usp_DoRaiseError] @result = @result

	SELECT *
	FROM vw_Join_PlayerGame
	WHERE PlayerID = @playerID

	SET @result = 1;
	SET @errorMSG = '';

	END TRY

	BEGIN CATCH

	END CATCH
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 10/09/18
-- Description:	Gets the PlayerVotePhoto records which the PlayerID must completed / has not voted on yet
-- =============================================
CREATE PROCEDURE usp_GetVotesToComplete
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

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 13/09/18
-- Description:	Removes a player to a game.

-- Returns: The result (1 = successful, anything else = error), and the error message associated with it
-- =============================================
CREATE PROCEDURE [dbo].[usp_LeaveGame] 
	-- Add the parameters for the stored procedure here
	@playerID INT,
	@isGameCompleted BIT OUTPUT,
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
		
		SET @isGameCompleted = 0;

		--Validate the playerID
		EXEC [dbo].[usp_ConfirmPlayerIsActive] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Get the GameID from the playerID
		DECLARE @gameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT

		--Confirm the Game is not completed
		EXEC [dbo].[usp_ConfirmGameNotCompleted] @id = @gameID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION

			--Update the player record
			UPDATE tbl_Player
			SET HasLeftGame = 1
			WHERE PlayerID = @playerID

			--Update the number of players in the game
			UPDATE tbl_Game
			SET NumOfPlayers = NumOfPlayers - 1
			WHERE GameID = @gameID

			--Get the game state
			DECLARE @gameState VARCHAR(255);
			SELECt @gameState = GameState FROM tbl_Game WHERE GameID = @gameID

			--If the player is leaving a game which is currently in Lobby or Starting, delete the player record to allow other players to use nickname or contact info
			IF (@gameState NOT LIKE 'PLAYING')
			BEGIN
				UPDATE tbl_Player
				SET PlayerIsDeleted = 1
				WHERE PlayerID = @playerID

				--There is nothing else to complete so return and commit the changes
				SET @result = 1;
				SET @errorMSG = '';
			END

			--If the current game state is in lobby leave the stored procedure because there is nothing else to perform.
			IF(@gameState LIKE 'IN LOBBY')
			BEGIN
				SET @result = 1;
				SET @errorMSG = '';
				COMMIT;
				RETURN;
			END

			--Check to see if the game is completed because it has reached the minimum number of players
			DECLARE @countPlayers INT;
			SELECT @countPlayers = COUNT(*) FROM vw_InGame_Players WHERE GameID = @gameID
			IF(@countPlayers < 3)
			BEGIN
				--Call the end game stored procedure to end the game
				EXEC [dbo].[usp_CompleteGame] @gameID = @gameID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
				EXEC [dbo].[usp_DoRaiseError] @result = @result

				SET @isGameCompleted = 1;
				SET @result = 1;
				SET @errorMSG = '';
				COMMIT;
				--Leave the stored procedure because the game has now ended and there is nothing else to complete
				RETURN;
			END


			--If the current game state is STARTING leave the stored procedure because there is nothing else to perform.
			IF(@gameState LIKE 'STARTING')
			BEGIN
				SET @result = 1;
				SET @errorMSG = '';
				COMMIT;
				RETURN;
			END


			--Delete all notifications received by the player
			UPDATE tbl_Notification
			SET NotificationIsDeleted = 1
			WHERE PlayerID = @playerID

			--Delete all votes on non completed photos submitted by the player.
			UPDATE tbl_Vote
			SET VoteIsDeleted = 1
			WHERE PhotoID IN (SELECT PhotoID FROM vw_Incompleted_Photos WHERE TakenByPlayerID = @playerID)

			--Delete all non completed photos submitted by the player
			UPDATE tbl_Photo
			SET PhotoIsDeleted = 1
			WHERE PhotoID IN (SELECT PhotoID FROM vw_Incompleted_Photos WHERE TakenByPlayerID = @playerID)

			--Create a table variable to store the PhotoID's being updated
			DECLARE @photosBeingUpdated TABLE ( id INT NOT NULL);

			--Insert into the the table variable, the ID's of the photos that are being updated / affected by the player leaving
			INSERT INTO @photosBeingUpdated (id)
			SELECT PhotoID
			FROM vw_Incomplete_Votes
			WHERE PlayerID = @playerID

			--Delete all incomplete votes made the player
			UPDATE tbl_Vote
			SET VoteIsDeleted = 1
			WHERE VoteID IN (SELECT VoteID FROM vw_Incomplete_Votes WHERE PlayerID = @playerID)

			--Loop through each of the photos and check to see if any of them have now been completed
			DECLARE @tempCursorID INT;
			DECLARE photoCursor CURSOR FOR     
			SELECT id
			FROM @photosBeingUpdated
			OPEN photoCursor
			FETCH NEXT FROM photoCursor
			INTO @tempCursorID

			--Loop through each photoID and check to see if the photo is now completed
			WHILE @@FETCH_STATUS = 0    
			BEGIN    
				--Call a procedure to update the number of yes/no votes and check to see
				--if the photo voting has now been completed. If completed update the kills/deaths
				EXEC [dbo].[usp_UpdateVotingCountOnPhoto] @photoID = @tempCursorID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
				EXEC [dbo].[usp_DoRaiseError] @result = @result

				FETCH NEXT FROM photoCursor
				INTO @tempCursorID
			END     
			CLOSE photoCursor;    
			DEALLOCATE photoCursor; 
		COMMIT

		SET @result = 1;
		SET @errorMSG = '';

		--Select any photos which have now been completed after the player left the game
		SELECT *
		FROM vw_Join_PhotoGamePlayers
		WHERE 
			PhotoID IN (SELECT id FROM @photosBeingUpdated) AND
			IsVotingComplete = 1 AND
			PhotoIsActive = 1 AND
			PhotoIsDeleted = 0
	END TRY

	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to remove the player from the game'
		END
	END CATCH
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 06/09/18
-- Description:	Removes a players connectionID to the ApplicationHub, outlining
--				that the player is no longer connected to the application hub and
--				receive live updates in the game
-- =============================================
CREATE PROCEDURE [dbo].[usp_RemoveConnectionID] 
	-- Add the parameters for the stored procedure here
	@connectionID VARCHAR(255)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE tbl_Player
	SET ConnectionID = NULL
	WHERE ConnectionID LIKE @connectionID
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 30/08/18
-- Description:	Replenishes a players ammo by one.

-- Returns: 1 = Successful, or 0 = An error occurred
-- =============================================
CREATE PROCEDURE [dbo].[usp_ReplenishAmmo] 
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
		EXEC [dbo].[usp_ConfirmPlayerInGame] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result
		
		--Get the GameID from the playerID
		DECLARE @gameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT

		--Confirm the Game is PLAYING state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Make the update on the Players ammo count
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			UPDATE tbl_Player
			SET AmmoCount = AmmoCount + 1
			WHERE PlayerID = @playerID
		COMMIT

		SET @result = 1;
		SET @errorMSG = '';
		SELECT * FROM vw_Join_PlayerGame WHERE PlayerID = @playerID
	END TRY


	--An error occurred in the data validation
	BEGIN CATCH
		--An error occurred while trying to perform the update on the PLayer table
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to update the player record.'
		END
	END CATCH
END
GO

CREATE PROCEDURE [dbo].[usp_SavePhoto] 
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
			INSERT INTO tbl_Vote(PlayerID, PhotoID)
			SELECT
				PlayerID, 
				@createdPhotoID
			FROM 
				vw_InGame_Players
			WHERE 
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

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 19/09/18
-- Description:	Updates the GameState of a game

-- Returns: 1 = Successful, or 0 = An error occurred

-- Possible Errors Returned:
--		1. @EC_INSERTERROR - An error occurred while trying to update the player record.

-- =============================================
CREATE PROCEDURE [dbo].[usp_SetGameState] 
	-- Add the parameters for the stored procedure here
	@gameID INT,
	@gameState VARCHAR(255),
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @EC_INSERTERROR INT = 2

	BEGIN TRY  
		--Confirm the GameID passed in exists
		EXEC [dbo].[usp_ConfirmGameExists] @id = @gameID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			UPDATE tbl_Game
			SET GameState = @gameState
			WHERE GameID = @gameID
		COMMIT
	END TRY

	--An error occurred in the data validation
	BEGIN CATCH
		--An error occurred while trying to perform the update on the PLayer table
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @EC_INSERTERROR;
			SET @errorMSG = 'An error occurred while trying to update the Game record.'
		END
	END CATCH
END
GO

-- =============================================
-- Author:		Dylan Levin
-- Create date: 14/09/18
-- Description:	Marks player notifications as read.

-- Returns: The result (1 = successful, anything else = error), and the error message associated with it

-- Possible Errors Returned:
--		1. EC_INSERTERROR - An error occurred while trying to insert the game record

-- =============================================

-- create type to store incoming data into a table
DROP TYPE IF EXISTS udtNotifs
GO
CREATE TYPE udt_Notifs AS TABLE
    ( 
        notificationID INT
    )
GO

CREATE PROCEDURE [dbo].[usp_SetNotificationsRead] 
	-- Add the parameters for the stored procedure here
	@udtNotifs AS dbo.udt_Notifs READONLY,
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
		EXEC [dbo].[usp_ConfirmPlayerInGame] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result
		
		--Get the GameID from the playerID
		DECLARE @gameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT

		--Confirm the Game is PLAYING state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Update the notifications to IsRead = 1
		UPDATE tbl_Notification
		SET IsRead = 1
		WHERE 
			PlayerID = @playerID AND 
			NotificationID IN (
				SELECT notificationID
				FROM @udtNotifs
			)

		--Set the success return variables
		SET @result = 1;
		SET @errorMSG = '';

	END TRY

	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to set notifications to read.'
		END
	END CATCH
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 30/08/18
-- Description:	Updates a Player's ConnectionID and sets them as CONNECTED to the SignalR Hub

-- Returns: 1 = Successful, or 0 = An error occurred

-- Possible Errors Returned:
--		1. The playerID trying to update does not exist
--		2. The new connectionID already exists inside the database
--		3. When performing the update in the DB an error occurred

-- =============================================
CREATE PROCEDURE [dbo].[usp_UpdateConnectionID] 
	-- Add the parameters for the stored procedure here
	@playerID INT,
	@connectionID VARCHAR(255),
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
		--Confirm the playerID passed in exists and is active
		EXEC [dbo].[usp_ConfirmPlayerExists] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Confirm the new connectionID does not already exists
		IF EXISTS (SELECT * FROM tbl_Player WHERE ConnectionID = @connectionID)
		BEGIN
			SET @result = @ITEM_ALREADY_EXISTS;
			SET @errorMSG = 'The connectionID already exists.';
			RAISERROR('',16,1);
		END;

		--PlayerID exists and connectionID does not exists, make the update
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			UPDATE tbl_Player
			SET ConnectionID = @connectionID
			WHERE PlayerID = @playerID
		COMMIT
	END TRY

	--An error occurred in the data validation
	BEGIN CATCH
		--An error occurred while trying to perform the update on the PLayer table
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'Insert error.';
		END
	END CATCH
END
GO

CREATE PROCEDURE [dbo].[usp_UpdateVerificationCode] 
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
		IF NOT EXISTS (SELECT * FROM tbl_Player WHERE PlayerID = @playerID AND IsVerified = 0)
		BEGIN
			SET @result = @CANNOT_PERFORM_ACTION;
			SET @errorMSG = 'The playerID is already verified.';
			RAISERROR('',16,1);
		END

		--Update the players verfication code
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			UPDATE tbl_Player
			SET VerificationCode = @verificationCode
			WHERE PlayerID = @playerID
		COMMIT

		--Set the success return variables
		SET @result = 1;
		SET @errorMSG = ''
		SELECT * FROM vw_Active_Players WHERE PlayerID = @playerID
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

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 30/08/18
-- Description:	Decrements a players ammo count. When the player has taken a photo
--				their ammo is decremented and their number of photos taken is increased.

-- Returns: 1 = Successful, or 0 = An error occurred
-- =============================================
CREATE PROCEDURE [dbo].[usp_UseAmmo] 
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
		EXEC [dbo].[usp_ConfirmPlayerInGame] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result
		
		--Get the GameID from the playerID
		DECLARE @gameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT

		--Confirm the Game is PLAYING state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Confirm the Ammo Count is not already at 0
		DECLARE @ammoCount INT;
		SELECT @ammoCount = AmmoCount FROM tbl_Player WHERE PlayerID = @playerID
		IF(@ammoCount = 0)
		BEGIN
			SET @result = @CANNOT_PERFORM_ACTION;
			SET @errorMSG = 'The players ammo count is already at 0, cannot use ammo.';
			RAISERROR('', 16, 1);
		END

		--Make the update on the Players ammo count and number of photos taken
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			UPDATE tbl_Player
			SET AmmoCount = AmmoCount - 1
			WHERE PlayerID = @playerID
		COMMIT

		SET @result = 1;
		SET @errorMSG = '';
		SELECT * FROM vw_Join_PlayerGame WHERE PlayerID = @playerID
	END TRY


	--An error occurred in the data validation
	BEGIN CATCH
		--An error occurred while trying to perform the update on the PLayer table
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to update the player record.'
		END
	END CATCH
END
GO

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

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 25/10/18
-- Description:	Ends the lobby after the host player leaves the lobby before starting the game.

-- Returns: The result (1 = successful, anything else = error), and the error message associated with it
-- =============================================
CREATE PROCEDURE [dbo].[usp_EndLobby] 
	-- Add the parameters for the stored procedure here
	@gameID INT,
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

			--Update the player records
			UPDATE tbl_Player
			SET HasLeftGame = 1, PlayerIsActive = 0
			WHERE GameID = @gameID

			--Set the game to complete and not active anymore
			UPDATE tbl_Game
			SET GameState = 'COMPLETED', GameIsActive = 0
			WHERE GameID = @gameID
		COMMIT

		SET @result = 1;
		SET @errorMSG = '';
	END TRY

	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to end the lobby';
		END
	END CATCH
END
GO

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

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 11/09/18
-- Description:	When the voting time expires on a photo the 
--				photo is automiatically marked as successful.
--				Updating the photo and all the votes because the time has now expired.
-- =============================================
CREATE PROCEDURE [dbo].[usp_VotingTimeExpired] 
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
			
			UPDATE tbl_Player 
			SET NumDeaths = NumDeaths +1 
			WHERE PlayerID = 
				(SELECT PhotoOfPlayerID 
				FROM tbl_Photo 
				WHERE PhotoID = @photoID)
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

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 18/09/18
-- Description:	Gets the count of unread notifications for a player
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetUnreadNotificationCount] 
	-- Add the parameters for the stored procedure here
	@playerID INT,
	@count INT OUTPUT,
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET @count = -1;

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

	SELECT @count = COUNT(*)
	FROM vw_Unread_Notifications
	WHERE PlayerID = @playerID

	SET @result = 1;
	SET @errorMSG = '';

	END TRY

	BEGIN CATCH
		SET @count = -1;
	END CATCH
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 05/09/18
-- Description:	Removes the unverified player from the game.
--				Deletes the player record to allow the phone or email
--				to be used again.

-- Returns: The result (1 = successful, anything else = error), and the error message associated with it
-- =============================================
CREATE PROCEDURE [dbo].[usp_RemoveUnverifiedPlayer] 
	-- Add the parameters for the stored procedure here
	@playerID INT,
	@playerIDToRemove INT,
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
		
		--Validate the PlayerID
		EXEC [dbo].[usp_ConfirmPlayerIsActive] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Validate the PlayerIDToRemove
		EXEC [dbo].[usp_ConfirmPlayerIsActive] @id = @playerIDToRemove, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Check the players are in the same game
		DECLARE @playerGameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @playerGameID OUTPUT
		DECLARE @toRemoveGameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerIDToRemove, @gameID = @toRemoveGameID OUTPUT
		IF(@toRemoveGameID <> @playerGameID)
		BEGIN
			SET @result = @DATA_INVALID;
			SET @errorMSG = 'The players provided are not in the same game.'
			RAISERROR('', 16, 1);
		END

		--Confirm the Game is IN LOBBY state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @playerGameID, @correctGameState = 'IN LOBBY', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		--Confirm the playerID is the host player
		IF NOT EXISTS (SELECT * FROM vw_InGame_Players WHERE PlayerID = @playerID AND IsHost = 1)
		BEGIN
			SET @result = @CANNOT_PERFORM_ACTION;
			SET @errorMSG = 'Only the host player can perform this action. The player requesting is not the host.';
			RAISERROR('', 16, 1);
		END

		--Confirm the playerToRemove is not verified already
		IF NOT EXISTS (SELECT * FROM vw_Active_Players WHERE PlayerID = @playerIDToRemove AND IsVerified = 0)
		BEGIN
			SET @result = @ITEM_DOES_NOT_EXIST;
			SET @errorMSG = 'The player trying to remove is already verified. Only unverified players can be removed.';
			RAISERROR('', 16, 1);
		END

		--Leave the game
		DECLARE @isGameCompleted BIT;
		EXEC [dbo].[usp_LeaveGame]
		@playerID = @playerIDToRemove,
		@isGameCompleted = @isGameCompleted OUTPUT,
		@result = @result OUTPUT,
		@errorMSG = @errorMSG OUTPUT

		EXEC [dbo].[usp_DoRaiseError] @result = @result

		SELECT * FROM tbl_Player WHERE PlayerID = @playerIDToRemove
		
	END TRY

	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to remove the player from the game'
		END
	END CATCH
END
GO

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

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 30/10/18
-- Description:	Disables the player for a certain amount of time
--				after attempting to take a photo when outside of the
--				playing zone in a battle royale game.

-- Returns: 1 = Successful, or 0 = An error occurred
-- =============================================
CREATE PROCEDURE [dbo].[usp_BR_DisablePlayer] 
	-- Add the parameters for the stored procedure here
	@playerID INT,
	@isAlreadyDisabled BIT,
	@disabledForMinutes INT,
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

		--Make the update on the Players ammo count and number of photos taken
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
		BEGIN TRANSACTION
			
			--Renable the player if already disabled
			IF(@isAlreadyDisabled = 1)
			BEGIN
				UPDATE tbl_Player
				SET IsDisabled = 0
				WHERE PlayerID = @playerID

				--Create a notification that the player is now re-enabled
				INSERT INTO tbl_Notification (MessageText, NotificationType, PlayerID, GameID)
				VALUES ('You have been re-enabled, you can take photos again.', 'RE-ENABLED', @playerID, @gameID)
			END
			
			--Disable the player if not already disabled
			ELSE
			BEGIN
				UPDATE tbl_Player
				SET IsDisabled = 1
				WHERE PlayerID = @playerID

				--Create a notification that the player is now disabled
				DECLARE @msg VARCHAR(255);
				SET @msg = 'You have been disabled for ' + CAST(@disabledForMinutes AS VARCHAR) + ' minutes for taking a photo outside of the zone.';
				INSERT INTO tbl_Notification (MessageText, NotificationType, PlayerID, GameID)
				VALUES (@msg, 'DISABLED', @playerID, @gameID)
			END
		COMMIT

		SET @result = 1;
		SET @errorMSG = '';
		SELECT * FROM vw_Join_PlayerGame WHERE PlayerID = @playerID
	END TRY


	--An error occurred in the data validation
	BEGIN CATCH
		--An error occurred while trying to perform the update on the PLayer table
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to update the player record.'
		END
	END CATCH
END
GO

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 11/09/18
-- Description:	Updates the Yes/No vote count on the photo,
--				checks if the voting has been completed, if so,
--				the kills and deaths are updated etc.

-- Returns: 1 = Successful, or Anything else = An error occurred
-- =============================================
CREATE PROCEDURE [dbo].[usp_BR_UpdateVotingCountOnPhoto] 
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

					--Eliminate the player
					UPDATE tbl_Player 
					SET NumDeaths = NumDeaths +1, IsEliminated = 1
					WHERE PlayerID = 
						(SELECT PhotoOfPlayerID 
						FROM tbl_Photo
						WHERE PhotoID = @photoID)

					--Check to see if the game is now completed after eliminating the player
					DECLARE @countPlayersLeft INT = 0;
					DECLARE @gameID INT;
					SELECT @gameID = GameID FROM tbl_Photo WHERE PhotoID = @photoID
					SELECT @countPlayersLeft = COUNT(*) FROM vw_InGame_Players WHERE GameID = @gameID
					IF(@countPlayersLeft < 2)
					BEGIN
						--Complete the game because there is not enough players to play after the player was eliminated
						--Call the end game stored procedure to end the game
						EXEC [dbo].[usp_CompleteGame] @gameID = @gameID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
						EXEC [dbo].[usp_DoRaiseError] @result = @result
					END 
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

-- =============================================
-- Author:		Jonathan Williams
-- Create date: 11/09/18
-- Description:	Updates a PlayerVotePhoto record with a players vote decision

-- Returns: 1 = Successful, or 0 = An error occurred
-- =============================================
CREATE PROCEDURE [dbo].[usp_BR_VoteOnPhoto] 
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
		
		--Confirm the player is allowed to vote
		IF NOT EXISTS (SELECT PlayerID FROM vw_Active_Players WHERE PlayerID = @playerID AND IsVerified = 1 AND HasLeftGame = 0)
		BEGIN
			SET @result = @PLAYER_INVALID;
			SET @errorMSG = 'The PlayerID cannot vote.';
			RAISERROR('',16,1);
		END
		
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
			EXEC [dbo].[usp_BR_UpdateVotingCountOnPhoto] @photoID = @photoID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
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

-- =============================================
-- Author:		Dylan Levin
-- Create date: 06/09/18
-- Description:	Creates a tag notification for each player depending on the result of a tag.

-- Returns: 1 = Successful, or 0 = An error occurred

-- Possible Errors Returned:
--		1. The playerID of the recipient does not exist
--		2. The gameID does not exist
--		3. When performing the update in the DB an error occurred

-- =============================================
CREATE PROCEDURE [dbo].[usp_BR_CreateTagResultNotification] 
	-- Add the parameters for the stored procedure here
	@takenByID INT,
	@photoOfID INT,
	@decision BIT,
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @msgTxt VARCHAR(255)
	
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

		--Validate the photoOfByID
		IF NOT EXISTS (SELECT PlayerID FROM vw_Active_Players WHERE PlayerID = @photoOfID AND IsVerified = 1 AND HasLeftGame = 0)
		BEGIN
			SET @result = @PLAYER_INVALID;
			SET @errorMSG = 'The PhotoOfID Is not in the game.';
			RAISERROR('',16,1);
		END

		--Get the GameID of the TakenByPLayerID and PhotoOfPlayerID and confirm they are in the same game
		DECLARE @takenByGameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @takenByID, @gameID = @takenByGameID OUTPUT
		DECLARE @photoOfGameID INT;
		EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @photoOfID, @gameID = @photoOfGameID OUTPUT
		IF(@takenByGameID <> @photoOfGameID)
		BEGIN
			SET @result = @DATA_INVALID;
			SET @errorMSG = 'The players provided are not in the same game.'
		END

		--Confirm the Game is PLAYING state
		EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @takenByGameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
		EXEC [dbo].[usp_DoRaiseError] @result = @result

		IF (@decision = 1) --success
		BEGIN
			SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
			BEGIN TRANSACTION
				
				-- send to the tagging player
				SELECT @msgTxt = 'You eliminated ' + p.Nickname + '.' FROM tbl_Player p WHERE p.PlayerID = @photoOfID
				INSERT INTO tbl_Notification(MessageText, NotificationType, IsRead, NotificationIsActive, GameID, PlayerID) VALUES (@msgTxt, 'SUCCESS', 0, 1, @takenByGameID, @takenByID) -- insert into table with specific playerID	
						
				-- send to everyone else						
				SELECT @msgTxt = p.Nickname + ' was eliminated by ' FROM tbl_Player p WHERE p.PlayerID = @photoOfID
				SELECT @msgTxt += p.Nickname + '.' FROM tbl_Player p WHERE p.PlayerID = @takenByID

				--Create the notifications for all other players in the game
				INSERT INTO tbl_Notification(MessageText, NotificationType, IsRead, NotificationIsActive, GameID, PlayerID) 
				SELECT @msgTxt, 'SUCCESS', 0, 1, @takenByGameID, PlayerID
				FROM vw_InGame_Players
				WHERE PlayerID <> @takenByID AND PlayerID <> @photoOfID AND GameID = @takenByGameID						
			COMMIT
		END
		ELSE --fail
		BEGIN
		BEGIN
			SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
			BEGIN TRANSACTION

				-- send to the tagged player				
				SELECT @msgTxt = 'You were missed by ' + p.Nickname + '.' FROM tbl_Player p WHERE p.PlayerID = @takenByID
				INSERT INTO tbl_Notification(MessageText, NotificationType, IsRead, NotificationIsActive, GameID, PlayerID) VALUES (@msgTxt, 'FAIL', 0, 1, @takenByGameID, @photoOfID) -- insert into table with specific playerID			
						
				-- send to the tagging player
				SELECT @msgTxt = 'You failed to eliminate ' + p.Nickname + '.' FROM tbl_Player p WHERE p.PlayerID = @photoOfID
				INSERT INTO tbl_Notification(MessageText, NotificationType, IsRead, NotificationIsActive, GameID, PlayerID) VALUES (@msgTxt, 'FAIL', 0, 1, @takenByGameID, @takenByID) -- insert into table with specific playerID	
						
				-- send to everyone else		
				SELECT @msgTxt = p.Nickname + ' failed to eliminate ' FROM tbl_Player p WHERE p.PlayerID = @takenByID
				SELECT @msgTxt += p.Nickname + '.' FROM tbl_Player p WHERE p.PlayerID = @photoOfID
				
				--Create the notifications for all other players in the game
				INSERT INTO tbl_Notification(MessageText, NotificationType, IsRead, NotificationIsActive, GameID, PlayerID) 
				SELECT @msgTxt, 'FAIL', 0, 1, @takenByGameID, PlayerID
				FROM vw_InGame_Players
				WHERE PlayerID <> @takenByID AND PlayerID <> @photoOfID AND GameID = @takenByGameID						
			COMMIT
		END
		END	
	END TRY

	--An error occurred in the data validation
	BEGIN CATCH
		--An error occurred while trying to perform the update on the Notification table
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK;
			SET @result = @INSERT_ERROR;
			SET @errorMSG = 'An error occurred while trying to create the join notification.'
		END
	END CATCH
END
GO