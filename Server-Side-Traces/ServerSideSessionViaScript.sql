https://www.mssqltips.com/sqlservertip/1710/capture-all-statements-for-a-sql-server-session/

CREATE PROCEDURE [dbo].[spTraceMySessionStart] @spid INT 
AS 

-- Create a Queue 
DECLARE @rc INT 
DECLARE @TraceID INT 
DECLARE @maxfilesize bigint 
SET @maxfilesize = 5  
DECLARE @filename NVARCHAR(245) 
SET @filename = 'C:\TraceMySession_'  
    + CONVERT(NVARCHAR(10),@spid)  
    + '_d'  
    + REPLACE(CONVERT(VARCHAR, GETDATE(),111),'/','') 
    + REPLACE(CONVERT(VARCHAR, GETDATE(),108),':','') 

EXEC @rc = sp_trace_create @TraceID output, 2, @filename, @maxfilesize, NULL  
IF (@rc != 0) GOTO error 

-- Set the events 
DECLARE @on bit 
SET @on = 1 
EXEC sp_trace_setevent @TraceID, 12, 1, @on 
EXEC sp_trace_setevent @TraceID, 12, 12, @on 
EXEC sp_trace_setevent @TraceID, 12, 14, @on 

-- Set the Filters 
DECLARE @intfilter INT 
DECLARE @bigintfilter bigint 
EXEC sp_trace_setfilter @TraceID, 12, 1, 0, @spid 

-- Set the trace status to start 
EXEC sp_trace_setstatus @TraceID, 1 

-- display trace id for future references 
SELECT TraceID=@TraceID 
GOTO finish 

error:  
SELECT ErrorCode=@rc 

finish: 

go

CREATE PROCEDURE [dbo].[spTraceMySessionStop] @traceId INT 
AS 
EXEC sp_trace_setstatus @traceId,0 
EXEC sp_trace_setstatus @traceId,2

EXEC master.dbo.spTraceMySessionStart 52 

USE AdventureWorks 
GO 

SELECT name 
FROM sys.sysobjects WHERE xtype = 'U' 
GO 
SELECT TOP 10 Title 
FROM HumanResources.Employee 
GO 

EXEC master.dbo.spTraceMySessionStop 2