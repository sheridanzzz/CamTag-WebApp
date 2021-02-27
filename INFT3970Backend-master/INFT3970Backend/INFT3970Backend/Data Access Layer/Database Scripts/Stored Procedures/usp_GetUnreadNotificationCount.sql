-- =============================================
-- Author:		Jonathan Williams
-- Create date: 18/09/18
-- Description:	Gets the count of unread notifications for a player
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetUnreadNotificationCount] 
	-- Add the parameters for the stored procedure here
	@playerID INT,
	@count INT OUTPUT,
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET @count = -1;

	BEGIN TRY

	--Validate the playerID
	EXEC [dbo].[usp_ConfirmPlayerInGame] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
	EXEC [dbo].[usp_DoRaiseError] @result = @result

	--Get the GameID from the playerID
	DECLARE @gameID INT;
	EXEC [dbo].[usp_GetGameIDFromPlayer] @id = @playerID, @gameID = @gameID OUTPUT

	--Confirm the Game is PLAYING state
	EXEC [dbo].[usp_ConfirmGameStateCorrect] @gameID = @gameID, @correctGameState = 'PLAYING', @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
	EXEC [dbo].[usp_DoRaiseError] @result = @result

	SELECT @count = COUNT(*)
	FROM vw_Unread_Notifications
	WHERE PlayerID = @playerID

	SET @result = 1;
	SET @errorMSG = '';

	END TRY

	BEGIN CATCH
		SET @count = -1;
	END CATCH
END
GO