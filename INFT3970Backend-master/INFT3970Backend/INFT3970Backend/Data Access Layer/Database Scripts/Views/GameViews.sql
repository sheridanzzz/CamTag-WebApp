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