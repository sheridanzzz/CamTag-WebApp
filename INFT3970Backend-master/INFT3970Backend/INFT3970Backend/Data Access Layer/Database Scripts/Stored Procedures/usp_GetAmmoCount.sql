-- =============================================
-- Author:		Jonathan Williams
-- Create date: 18/09/18
-- Description:	Gets the player's ammo count
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetAmmoCount] 
	-- Add the parameters for the stored procedure here
	@playerID INT,
	@ammoCount INT OUTPUT,
	@result INT OUTPUT,
	@errorMSG VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET @ammoCount = -1;

	BEGIN TRY

	--Validate the playerID
	EXEC [dbo].[usp_ConfirmPlayerInGame] @id = @playerID, @result = @result OUTPUT, @errorMSG = @errorMSG OUTPUT
	EXEC [dbo].[usp_DoRaiseError] @result = @result

	--Get the players ammo count
	SELECT @ammoCount = AmmoCount
	FROM vw_InGame_Players
	WHERE PlayerID = @playerID

	SET @result = 1;
	SET @errorMSG = '';

	END TRY

	BEGIN CATCH
		SET @ammoCount = -1;
	END CATCH
END
GO