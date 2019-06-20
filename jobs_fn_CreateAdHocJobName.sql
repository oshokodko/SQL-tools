USE [msdb]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER FUNCTION fn_CreateAdHocJobName(@JobPurpose SYSNAME)
RETURNS SYSNAME
AS
BEGIN
	declare @t varbinary(16)
	select top 1 @t = cast(login_time as varbinary(6)) + cast(GETUTCDATE() as varbinary(4)) + cast(@@SPID as varbinary(2)) from sys.sysprocesses where SPID = @@SPID
	RETURN IsNull(@JobPurpose,'AdHoc')+'-'+convert(varchar(max), @t, 2)
END