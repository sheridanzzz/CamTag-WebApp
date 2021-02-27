USE udb_CamTag
GO;

--Function which is used to confirm if the phone number or email address is both NULL

CREATE FUNCTION udf_IsPlayerEmailAndPhoneValid (
  @phone VARCHAR(12),
  @email VARCHAR(255)
)
RETURNS tinyint
AS
BEGIN
  DECLARE @Result tinyint;
  IF (@phone IS NULL AND @email IS NULL)
    SET @Result= 0
  ELSE 
    SET @Result= 1
  RETURN @Result
END