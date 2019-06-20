USE [msdb]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE sp_RunAdHocJob(
	@jobName SYSNAME, 
	@jobCommand as NVARCHAR(MAX), 
	@jobId UNIQUEIDENTIFIER OUTPUT)
AS
BEGIN
	SET @jobId = NULL
	DECLARE @workerJobName NVARCHAR(100) = @jobName + '-' + cast(BINARY_CHECKSUM(NEWID()) as NVARCHAR(16))
	DECLARE @workerCategoryName NVARCHAR(100) = 'AdHocWorker'
	
	IF NOT EXISTS (SELECT * FROM dbo.syscategories where name = @workerCategoryName)
	BEGIN
		EXEC sp_add_category @class = 'JOB', @type = 'LOCAL', @name = @workerCategoryName;
	END

	DECLARE @ret INT
	EXEC @ret = msdb.dbo.sp_add_job @job_name = @workerJobName,
		@category_name = @workerCategoryName,
		@owner_login_name = N'sa',
		@enabled = 0, -- Create disabled by default.  sp_s2s_reconfigure will enable/disable them.
		@delete_level = 3, 
		@job_id = @jobId OUTPUT
	IF @ret != 0
	BEGIN
		THROW 50000, 'Could not create job.', 1;
	END

	DECLARE @wrappedJobCommand NVARCHAR(MAX) ='EXEC master.dbo.CommandExecute  @Command ='+QUOTENAME(@jobCommand,'''')+
		', @CommandType = ''Execute Job'', @ObjectName ='+QUOTENAME(@jobName,'''')+ 
		', @Mode = 2, @LogToTable = ''Y'', @Execute = ''Y'''

		PRINT @wrappedJobCommand

	EXEC @ret = msdb.dbo.sp_add_jobstep
		@job_id = @jobId,
		@step_name = 'step 1',
		@command = @wrappedJobCommand

	IF @ret != 0
	BEGIN
		THROW 50000, 'Could not create job step.', 1;
	END

	EXEC @ret = msdb.dbo.sp_add_jobserver @job_id = @jobId,
		@server_name = N'(local)'
	IF @ret != 0
	BEGIN
		THROW 50000, 'Could not add job server.', 1;
	END;

	EXEC @ret = dbo.sp_start_job @job_id = @jobId, @output_flag =1, @error_flag = 1
	IF @ret != 0
	BEGIN
		THROW 50000, 'Could not start job.', 1;
	END;
END