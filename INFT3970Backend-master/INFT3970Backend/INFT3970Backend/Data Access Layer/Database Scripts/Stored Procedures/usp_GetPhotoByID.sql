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