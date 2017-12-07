/***********************************************************************
THIS OPTION USES A SERVER SIDE SQL TRACE TO PICK UP THE BPR.
YOU ONLY NEED THIS *OR* THE XEVENTS TRACE -- NOT BOTH
***********************************************************************/

/* Modified from a script generated from SQL Server Profiler */
/* Pre-requisites and notes: 
	Configure 'blocked process threshold (s)' to 5 or higher in sp_configure
	This works with SQL Server 2005 and higher
	Change the filename to a relevant location on the server itself 
	Tweak options to your preference (including the end date)

	THIS CREATES AND STARTS A SERVER SIDE SQL TRACE
*/

declare @rc int;
declare @TraceID int;
declare @maxfilesizeMB bigint;
declare @TraceEndDateTime datetime;
declare @TraceFilename nvarchar(500);
declare @rolloverfilecount int;

set @TraceEndDateTime = '2017-07-30 00:00:00.000';
set @maxfilesizeMB = 100024;
set @TraceFilename = N'D:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\Trace\Blocked-Process-Report';
set @rolloverfilecount = 4;

/* Create the basic server side trace */
exec @rc = sp_trace_create 
	@TraceID output, 
	@options = 2 /* trace will use rollover files */, 
	@tracefile = @TraceFilename, 
	@maxfilesize = @maxfilesizeMB, 
	@stoptime = @TraceEndDateTime,
	@filecount = @rolloverfilecount;

if (@rc != 0) goto error;

/* Add the blocked process report event and collect some columns */
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 137, 1, @on
exec sp_trace_setevent @TraceID, 137, 3, @on
exec sp_trace_setevent @TraceID, 137, 12, @on
exec sp_trace_setevent @TraceID, 137, 15, @on
exec sp_trace_setevent @TraceID, 137, 26, @on

exec sp_trace_setfilter @TraceID, 3, 0, 0, 7 --db_id

/* Start the trace */
exec sp_trace_setstatus @TraceID, 1

/* Return the trace id to the caller */
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go

--exec sp_trace_setstatus 3, 2