USE [master] 
GO

IF OBJECT_ID('sp_executeRemoteServerProcedure') IS NOT NULL
	DROP PROCEDURE sp_executeRemoteServerProcedure
GO 

USE [msdb] 
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

CREATE OR ALTER PROCEDURE sp_executeRemoteServerProcedure
	@databaseName SYSNAME = NULL,
	@remoteServerName SYSNAME = NULL,
	@procedureName nvarchar (128)
AS
BEGIN
	DECLARE @SQL nvarchar (max)
	DECLARE @insideSQL nvarchar (max)
	DECLARE @ParmDef nvarchar(max) = '@insideSQL nvarchar (max)'

	SET @insideSQL = 'EXEC ' + @procedureName 
	SET @SQL = 'EXEC ' + IsNull(QUOTENAME(@remoteServerName) + '.','') + QUOTENAME(IsNull(@databaseName,DB_NAME())) + '..sp_executeSQL @insideSql'

	EXEC sp_executeSQL @SQL, @parmdef, @insideSQL
END