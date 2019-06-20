USE [msdb]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

CREATE OR ALTER PROCEDURE sp_findLinkedServer
	@databaseName SYSNAME, 
	@remoteServerName SYSNAME OUTPUT
AS
BEGIN
--This procedure iterates thru list of linked server until it finds @databaseName.
--It returns as output parameter name of linked server that has @databaseName
SET NOCOUNT ON
	DECLARE @SQL nvarchar (max)
	DECLARE @message nvarchar (max)
	DECLARE @parmDef nvarchar(max) = '@databaseName SYSNAME, @ret BIT OUTPUT';
	DECLARE @serverName SYSNAME
	DECLARE @ret BIT

	DECLARE ServerCursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT [Name] FROM sys.servers ORDER BY server_id
	OPEN ServerCursor
	FETCH NEXT FROM ServerCursor INTO @serverName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- try to find database
		SET @Sql = 'SELECT @ret = ( SELECT 1 FROM '+quotename(@serverName)+'.master.sys.databases WHERE [name] = @DatabaseName and state = 0 )'
		BEGIN TRY
			EXEC sp_executesql @SQL, @parmDef, @databaseName= @databaseName, @ret = @ret OUTPUT;
			IF (@ret is not null and @ret =1)
			BEGIN
				SET @remoteServerName = @serverName
				BREAK
			END
		END TRY
		BEGIN CATCH
		END CATCH;
		FETCH NEXT FROM ServerCursor INTO @serverName
	END
	CLOSE ServerCursor;
	DEALLOCATE ServerCursor;
END