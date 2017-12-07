/****************************************************/
/* Created by: SQL Server 2014 Profiler          */
/* Date: 26/10/2015  10:58:36         */
/****************************************************/


-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint = 100
declare @filecount int = 2
declare @options int = 2 /* TRACE_FILE_ROLLOVER - 2 / SHUTDOWN_ON_ERROR - 4 / TRACE_PRODUCE_BLACKBOX - 8 */
declare @stoptime datetime = null

-- Please replace the text InsertFileNameHere, with an appropriate
-- filename prefixed by a path, e.g., c:\MyFolder\MyTrace. The .trc extension
-- will be appended to the filename automatically. If you are writing from
-- remote server to local drive, please use UNC path and make sure server has
-- write access to your network share

exec @rc = sp_trace_create @TraceID output, @options, N'E:\SIGNA\Trace_Block_DeadLock', @maxfilesize, @stoptime , @filecount
if (@rc != 0) goto error

-- Client side File and Table cannot be scripted

-- Set the events
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 137, 1, @on
exec sp_trace_setevent @TraceID, 137, 13, @on
exec sp_trace_setevent @TraceID, 137, 14, @on
exec sp_trace_setevent @TraceID, 137, 22, @on
exec sp_trace_setevent @TraceID, 137, 15, @on
exec sp_trace_setevent @TraceID, 137, 24, @on
exec sp_trace_setevent @TraceID, 137, 32, @on
exec sp_trace_setevent @TraceID, 148, 1, @on
exec sp_trace_setevent @TraceID, 148, 12, @on
exec sp_trace_setevent @TraceID, 148, 11, @on
exec sp_trace_setevent @TraceID, 148, 14, @on


-- Set the Filters
declare @intfilter int = 5
declare @bigintfilter bigint

/*
logical_operator
	Specifies whether the AND (0) or OR (1) operator is applied. logical_operator is int, with no default.

comparison_operator 
	0 = (Equal)
	1 <> (Not Equal)
	2 > (Greater Than)
	3 < (Less Than)
	4 >= (Greater Than Or Equal)
	5 <= (Less Than Or Equal)
	6 LIKE
	7 NOT LIKE

ColumnId
https://msdn.microsoft.com/en-us/library/ms186265.aspx

*/


exec sp_trace_setfilter @traceid = @TraceID, @columnid = 3, @logical_operator = 0, @comparison_operator = 0, @value = 5

-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go
