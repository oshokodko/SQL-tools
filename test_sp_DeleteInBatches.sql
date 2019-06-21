use master
DROP TABLE IF EXISTS #TestDeleteInBatches 
DROP TABLE IF EXISTS #test_id 

DECLARE @TotalRecords INT
DECLARE @ToBeDeletedRecords INT
CREATE TABLE #TestDeleteInBatches (Id INT IDENTITY PRIMARY KEY, Name SYSNAME)

CREATE TABLE #test_id(Id INT PRIMARY KEY);

PRINT 'Inserting records into #TestDeleteInBatches'
INSERT INTO #TestDeleteInBatches(Name)
SELECT top 1111 name FROM syscolumns
SET @TotalRecords = @@ROWCOUNT

PRINT 'Inserting records into #TestDeleteInBatches'
INSERT INTO #test_id(Id)
SELECT Id FROM #TestDeleteInBatches WHERE id%3 = 0 OR Id%2 = 0
SET @ToBeDeletedRecords = @@ROWCOUNT

EXEC sp_DeleteInBatches @deleteTableName = '#TestDeleteInBatches',
						@keysTableName ='#test_id',
						@columnName = 'Id',
						@BatchSize = 100 
						--,@debug=1

IF (SELECT COUNT(1) FROM #TestDeleteInBatches) <> (@TotalRecords-@ToBeDeletedRecords)
	THROW 50000, 'Unexpected number of records left in #TestDeleteInBatches table', 1

IF EXISTS(SELECT 1 FROM #TestDeleteInBatches WHERE Id in (SELECT Id FROM #test_id)) 
	THROW 50001, 'Unexpected records left in #TestDeleteInBatches table', 1
PRINT 'Test passed.'

