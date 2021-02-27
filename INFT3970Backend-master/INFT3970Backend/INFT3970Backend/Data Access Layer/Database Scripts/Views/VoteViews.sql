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