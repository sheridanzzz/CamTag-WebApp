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