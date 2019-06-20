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

		PRINT 'Deleting records from backupfile'
		SET @rowCount =1
		WHILE @rowCount > 0
		BEGIN
			SET @sql = 'DELETE TOP (1000) msdb.dbo.backupfile 
				WHERE backup_set_id IN (SELECT backup_set_id FROM #backup_set_id);'
			EXEC @rowCount = sp_executeSqlWithRetries @dynamicSQL = @sql
		END;


		PRINT 'Deleting records from backupfilegroup'		
		SET @rowCount =1
		WHILE @rowCount > 0
		BEGIN
			SET @sql = 'DELETE TOP (1000) msdb.dbo.backupfilegroup
				WHERE backup_set_id IN (SELECT backup_set_id FROM #backup_set_id);'
			EXEC @rowCount = sp_executeSqlWithRetries @dynamicSQL = @sql
		END;

		PRINT 'Deleting records from restorefile'
		SET @rowCount =1
		WHILE @rowCount > 0
		BEGIN
			SET @sql = 'DELETE TOP (1000) msdb.dbo.restorefile
				WHERE restore_history_id IN (SELECT restore_history_id FROM #restore_history_id);'
			EXEC @rowCount = sp_executeSqlWithRetries @dynamicSQL = @sql
		END;

		PRINT 'Deleting records from restorefilegroup'
		SET @rowCount =1
		WHILE @rowCount > 0
		BEGIN
			SET @sql = 'DELETE TOP (1000) msdb.dbo.restorefilegroup
				WHERE restore_history_id IN (SELECT restore_history_id FROM #restore_history_id);'
			EXEC @rowCount = sp_executeSqlWithRetries @dynamicSQL = @sql
		END;
		
		PRINT 'Deleting records from restorehistory'
		SET @rowCount =1
		WHILE @rowCount > 0
		BEGIN
			SET @sql = 'DELETE TOP (1000) FROM msdb.dbo.restorehistory
				WHERE restore_history_id IN (SELECT restore_history_id FROM #restore_history_id);'
			EXEC @rowCount = sp_executeSqlWithRetries @dynamicSQL = @sql
		END;
		
		PRINT 'Deleting records from backupset'
		SET @rowCount =1
		WHILE @rowCount > 0
		BEGIN
			SET @sql = 'DELETE TOP (1000) FROM msdb.dbo.backupset
				WHERE backup_set_id IN (SELECT backup_set_id FROM #backup_set_id);'
			EXEC @rowCount = sp_executeSqlWithRetries @dynamicSQL = @sql
		END;
		
		PRINT 'Deleting records from backupmediafamily'
		SET @rowCount =1
		WHILE @rowCount > 0
		BEGIN
			SET @sql = 'DELETE TOP (1000) FROM msdb.dbo.backupmediafamily
				WHERE media_set_id IN (SELECT media_set_id FROM #media_set_id);'
			EXEC @rowCount = sp_executeSqlWithRetries @dynamicSQL = @sql
		END;
		
		PRINT 'Deleting records from backupmediaset'
		SET @rowCount =1
		WHILE @rowCount > 0
		BEGIN
			SET @sql = 'DELETE TOP (1000) FROM msdb.dbo.backupmediaset
				WHERE media_set_id IN (SELECT media_set_id FROM #media_set_id);'
			EXEC @rowCount = sp_executeSqlWithRetries @dynamicSQL = @sql
		END;
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH	
END
