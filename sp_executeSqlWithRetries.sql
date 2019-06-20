USE [master] 
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

CREATE OR ALTER PROCEDURE sp_executeSqlWithRetries
	@dynamicSQL nvarchar (max),
	@retries int = NULL,
	@delaySeconds int = NULL
AS
BEGIN
	--validate parameters and set reasonable default values
	SET @delaySeconds = IsNull(IIF(@delaySeconds < 1 , 1, @delaySeconds), 1)
	SET @retries = IsNull(IIF(@retries < 1, 1, @retries), 5)
	DECLARE @delay DATETIME
	DECLARE @rowcount INT = 0
	DECLARE @remainingRetries INT = @retries
	WHILE @remainingRetries > 0
	BEGIN
		BEGIN TRY
			BEGIN TRANSACTION;
			EXEC sp_executeSQL @dynamicSQL
			SET @rowcount= @@rowcount
			COMMIT TRANSACTION;
			RETURN @rowcount
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			SET @remainingRetries = @remainingRetries - 1;
			-- 1204 = SqlOutOfLocks, 1205 =  SqlDeadlockVictim, 1222  SqlLockRequestTimeout
			IF ERROR_NUMBER() NOT IN ( 1204, 1205, 1222 )
				OR @remainingRetries <= 0
			BEGIN -- other error, throw an exception and abort the loop
				THROW;
			END

			-- Wait to give the blocking transaction time to finish
			-- Escalate delay interval with additional retries
			SET @delay = dateadd(SECOND, @delaySeconds * ( @retries - @remainingRetries ) , convert(DATETIME, 0)) 
			WAITFOR DELAY @delay
		END CATCH
	END
	RETURN -1;	
END