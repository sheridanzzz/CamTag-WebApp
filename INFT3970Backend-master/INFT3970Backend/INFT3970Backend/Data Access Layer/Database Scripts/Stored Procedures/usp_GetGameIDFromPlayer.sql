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