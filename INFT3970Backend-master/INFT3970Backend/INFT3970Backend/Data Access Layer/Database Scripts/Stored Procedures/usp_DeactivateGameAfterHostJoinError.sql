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