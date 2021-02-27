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