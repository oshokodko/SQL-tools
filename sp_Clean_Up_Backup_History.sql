USE [master]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.sp_Clean_Up_Backup_History @number_of_Days INT = 90
AS
BEGIN
SET NOCOUNT ON;
SET DEADLOCK_PRIORITY LOW;
	BEGIN TRY
		IF OBJECT_ID('tempdb.dbo.#backup_set_id', 'U') IS NOT NULL
			DROP TABLE #backup_set_id;

		IF OBJECT_ID('tempdb.dbo.#media_set_id', 'U') IS NOT NULL
			DROP TABLE #media_set_id;

		IF OBJECT_ID('tempdb.dbo.#restore_history_id', 'U') IS NOT NULL
			DROP TABLE #restore_history_id;

		CREATE TABLE #backup_set_id(backup_set_id INT PRIMARY KEY);

		CREATE TABLE #media_set_id(media_set_id INT PRIMARY KEY);

		CREATE TABLE #restore_history_id(restore_history_id INT PRIMARY KEY);

		DECLARE @Purge_Date DATETIME = GETDATE() - @number_of_Days;
		DECLARE @rowCount INT = 0
		DECLARE @sql NVARCHAR(MAX)

		INSERT INTO #backup_set_id(backup_set_id)
			SELECT DISTINCT backup_set_id
			FROM msdb.dbo.backupset
			WHERE backup_finish_date < @Purge_Date
			ORDER BY backup_set_id;

		INSERT INTO #media_set_id(media_set_id)
			SELECT DISTINCT media_set_id
			FROM msdb.dbo.backupset
			GROUP BY media_set_id
			HAVING MAX(backup_finish_date) < @Purge_Date
			ORDER BY media_set_id;

		INSERT INTO #restore_history_id(restore_history_id)
			SELECT DISTINCT restore_history_id
			FROM msdb.dbo.restorehistory
			WHERE backup_set_id IN (SELECT backup_set_id FROM #backup_set_id)
			ORDER BY restore_history_id;

		EXEC sp_DeleteInBatches @deleteTableName = 'msdb.dbo.backupfile',
								@keysTableName ='#backup_set_id',
								@columnName = 'backup_set_id'

		EXEC sp_DeleteInBatches @deleteTableName = 'msdb.dbo.backupfilegroup',
								@keysTableName ='#backup_set_id',
								@columnName = 'backup_set_id'

		EXEC sp_DeleteInBatches @deleteTableName = 'msdb.dbo.restorefile',
								@keysTableName ='#restore_history_id',
								@columnName = 'restore_history_id'

		EXEC sp_DeleteInBatches @deleteTableName = 'msdb.dbo.restorefilegroup',
								@keysTableName ='#restore_history_id',
								@columnName = 'restore_history_id'
	
		EXEC sp_DeleteInBatches @deleteTableName = 'msdb.dbo.restorehistory',
								@keysTableName ='#restore_history_id',
								@columnName = 'restore_history_id'
		
		EXEC sp_DeleteInBatches @deleteTableName = 'msdb.dbo.backupset',
								@keysTableName ='#backup_set_id',
								@columnName = 'backup_set_id'
		
		EXEC sp_DeleteInBatches @deleteTableName = 'msdb.dbo.backupmediafamily',
								@keysTableName ='#media_set_id',
								@columnName = 'media_set_id'
		
		EXEC sp_DeleteInBatches @deleteTableName = 'msdb.dbo.backupmediaset',
								@keysTableName ='#media_set_id',
								@columnName = 'media_set_id'

	END TRY
	BEGIN CATCH
		THROW;
	END CATCH	
END
