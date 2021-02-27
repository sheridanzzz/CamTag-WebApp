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