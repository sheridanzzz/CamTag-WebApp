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