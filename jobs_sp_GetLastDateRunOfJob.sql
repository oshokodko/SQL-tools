USE [msdb]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE or ALTER PROCEDURE sp_GetLastDateRunOfJob
	@jobName sysname = NULL
	,@lastRunDateTime datetime OUTPUT
AS
	SELECT @lastRunDateTime = max(msdb.dbo.agent_datetime(sjh.run_date,sjh.run_time))
	FROM msdb.dbo.sysjobhistory sjh
	INNER JOIN
		msdb.dbo.sysjobs_view sj
	ON sjh.job_id = sj.job_id
	WHERE (sj.name = @jobName )