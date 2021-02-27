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