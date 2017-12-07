/***********************************************************************

NEXT, TRACE THE BLOCKED PROCESS REPORT

THIS OPTION USES XEVENTS.

YOU CAN USE A SERVER SIDE SQL TRACE INSTEAD THOUGH (SCROLL DOWN)

***********************************************************************/


SELECT *
FROM sys.dm_xe_sessions;
GO

EXEC XP_CMDSHELL 'DIR "D:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\Trace"'
EXEC XP_CMDSHELL 'MD "D:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\Trace\XE"'
EXEC XP_DIRTREE 'D:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log', 1, 1

SELECT *
FROM sys.traces;

/* Pre-requisites and notes: 
	Configure 'blocked process threshold (s)' to 5 or higher in sp_configure
	This works with SQL Server 2014 and higher
	Change the filename to a relevant location on the server itself 
	Tweak options in the WITH clause to your preference
	Note that there is no automatic stop for this! If you want that, use a 
		Server Side SQL Trace instead.
	THIS CREATES AND STARTS AN EXTENDED EVENTS TRACE
*/

/* Create the Extended Events trace */

CREATE EVENT SESSION [Blocked Process Report] ON SERVER 
ADD EVENT sqlserver.blocked_process_report
ADD TARGET package0.event_file
	(SET filename=
		N'D:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\Trace\XE\Blocked-Process-Report.xel', max_file_size=(10024),max_rollover_files=(4))

		/* File size is in MB */

WITH (
	MAX_MEMORY=4096 KB,
	EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
	MAX_DISPATCH_LATENCY=120 SECONDS /* 0 = unlimited */,
	MAX_EVENT_SIZE=0 KB,
	MEMORY_PARTITION_MODE=NONE,
	TRACK_CAUSALITY=OFF,
	STARTUP_STATE=ON)
GO

/* Start the Extended Events trace */
ALTER EVENT SESSION [Blocked Process Report]  
	ON SERVER  
	STATE = START;  
GO

/* Drop the trace when you're done with a command like this:
DROP EVENT SESSION [Blocked Process Report] ON SERVER 
GO
*/