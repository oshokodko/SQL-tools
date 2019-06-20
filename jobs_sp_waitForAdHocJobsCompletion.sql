USE [msdb]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

-- Wait for a certain job to complete for a specified timeout.
CREATE OR ALTER PROCEDURE [dbo].[sp_waitForAdHocJobsCompletion]
	@jobNamePattern NVARCHAR(max),
	@jobMaxWaitTime INT	-- specified in seconds
AS
BEGIN
	-- Wait for the job to complete.
	DECLARE @startWait AS DATETIME = CURRENT_TIMESTAMP
	WHILE EXISTS ( SELECT job_id FROM sysjobs where CHARINDEX(@jobNamePattern, name)>0 	)
	BEGIN
		WAITFOR DELAY '00:00:01' -- Wait 5 seconds and check again
	END

	IF (DATEDIFF(MINUTE, @startWait, CURRENT_TIMESTAMP) >= @jobMaxWaitTime)
	BEGIN
		DECLARE @errorMessage AS NVARCHAR(max) = 'Waited a maximum of ' + CAST(@jobMaxWaitTime AS NVARCHAR(max)) + ' minutes for job with name like ' + @jobNamePattern + ' to complete before failing.';
		THROW 50000, @errorMessage, 1;
	END
END
