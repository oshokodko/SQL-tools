USE [master]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.sp_DeleteInBatches
 @deleteTableName sysname,
 @keysTableName sysname,
 @columnName sysname,
 @BatchSize int = 1000,
 @debug bit = 0
AS
BEGIN
SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @rowCount INT = 0
		DECLARE @totalDeletedCount INT = 0
		DECLARE @Offset INT = 0
		DECLARE @keysCount INT = 0
		DECLARE @sql NVARCHAR(MAX)
		DECLARE @message NVARCHAR(MAX)

		SET @message = 'Deleting records from ' + @deleteTableName +'.'
		PRINT @message

		SET @sql = 'SELECT @KeysCount = COUNT(1) FROM '+ @keysTableName 
		EXEC sp_executeSQL @sql, N'@KeysCount INT output', @keysCount=@keysCount output

		SELECT @rowCount =1, @Offset = 0
		WHILE @rowCount > 0 AND  @Offset < @keysCount
		BEGIN
			SET @sql = 'DELETE TOP (' +cast( @BatchSize +1 as NVARCHAR(10) ) + ') FROM ' + @deleteTableName
			+ ' WHERE ' + @columnName + ' IN (SELECT ' + @columnName + ' FROM ' + @keysTableName 
			+ ' ORDER BY 1 OFFSET ' + cast( @Offset as NVARCHAR(10) )
			+ ' ROWS FETCH NEXT ' + cast( @BatchSize  as NVARCHAR(10) ) + ' ROWS ONLY);'
			IF @debug = 1
				PRINT @sql
			EXEC @rowCount = sp_executeSqlWithRetries @dynamicSQL = @sql
			SET @totalDeletedCount = @totalDeletedCount + @rowCount 
			IF @rowCount <=  @BatchSize
				SET @Offset = @Offset +  @BatchSize
		END
		SET @message = 'Deleted ' +cast( @totalDeletedCount as NVARCHAR(10) ) + ' records from ' + @deleteTableName +'.'
		PRINT @message
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH	
	RETURN @totalDeletedCount
END	
