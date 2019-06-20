USE [master] 
GO

IF OBJECT_ID('sp_executeRemoteSQL') IS NOT NULL
	DROP PROCEDURE sp_executeRemoteSQL
GO 

USE [msdb]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

CREATE OR ALTER PROCEDURE sp_executeRemoteSQL
	@databaseName SYSNAME = NULL, 
	@remoteServerName SYSNAME = NULL,
	@dynamicSQL nvarchar (max)
AS
BEGIN
	DECLARE @SQL nvarchar (max)
	DECLARE @insideSQL nvarchar (max)
	DECLARE @ParmDef nvarchar(max) = '@insideSQL nvarchar (max)'

	SET @insideSQL = @dynamicSQL 
	SET @SQL = 'EXEC ' + IsNull(QUOTENAME(@remoteServerName) + '.','') + QUOTENAME(IsNull(@databaseName,DB_NAME()))  + '..sp_executeSQL @insideSql'

	EXEC sp_executeSQL @SQL, @parmdef, @insideSQL
END