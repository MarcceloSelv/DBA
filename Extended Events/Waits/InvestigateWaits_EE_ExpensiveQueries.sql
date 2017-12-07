--http://www.sqlskills.com/blogs/paul/tracking-expensive-queries-with-extended-events-in-sql-2008/

-- Drop the session if it exists.
IF EXISTS (
    SELECT * FROM sys.server_event_sessions
        WHERE [name] = N'InvestigateWaits')
    DROP EVENT SESSION [InvestigateWaits] ON SERVER
GO
 
-- Create the event session
-- Note that before SQL 2012, the wait_type to use may be
-- a different value.
-- On SQL 2012 the target name is 'histogram' but the old
-- name still works.
CREATE EVENT SESSION [InvestigateWaits] ON SERVER
ADD EVENT [sqlos].[wait_info]
(
    ACTION ([package0].[callstack])
    WHERE [wait_type] > 0 -- WRITE_COMPLETION only
    AND [opcode] = 1 -- Just the end wait events
    AND [duration] > 5000--milliseconds
)
ADD TARGET [package0].[asynchronous_bucketizer]
(
    SET filtering_event_name = N'sqlos.wait_info',
    source_type = 1, -- source_type = 1 is an action
    source = N'package0.callstack' -- bucketize on the callstack
)
WITH
(
    MAX_MEMORY = 50 MB,
    MAX_DISPATCH_LATENCY = 5 SECONDS)
GO
 

-- TF to allow call stack resolution
DBCC TRACEON (3656, -1);
GO



CREATE EVENT SESSION [InvestigateWaits] ON SERVER
ADD EVENT [sqlos].[wait_info]
(
    ACTION ([package0].[callstack], [package0].collect_system_time, sqlserver.plan_handle, sqlserver.sql_text, sqlserver.database_id, sqlserver.client_hostname, sqlos.task_time)
    WHERE [wait_type] > 0 -- WRITE_COMPLETION only
    AND [opcode] = 1 -- Just the end wait events
    AND [duration] > 5000--milliseconds
    AND [wait_type] != 127--LOGMGR_QUEUE
    AND [wait_type] != 594--FT_SCHEDULER_IDLE_WAIT
    AND [wait_type] != 291--FT_SCHEDULER_IDLE_WAIT
    AND [wait_type] != 128--FT_SCHEDULER_IDLE_WAIT
    AND [wait_type] != 129--FT_SCHEDULER_IDLE_WAIT
    AND [wait_type] != 117--BROKER_RECEIVE_WAITFOR
    AND [wait_type] != 174--BROKER_EVENTHANDLER
    AND [wait_type] != 218--CLR_AUTO_EVENT
    AND [wait_type] != 189--WAITFOR
)
ADD TARGET [package0].[ring_buffer]
WITH
(
    MAX_MEMORY = 50 MB,
    MAX_DISPATCH_LATENCY = 5 SECONDS)
GO

-- Start the session
ALTER EVENT SESSION [InvestigateWaits] ON SERVER
STATE = START;
GO
 


SELECT
    [event_session_address],
    [target_name],
    [execution_count],
    CAST ([target_data] AS XML)
FROM sys.dm_xe_session_targets [xst]
INNER JOIN sys.dm_xe_sessions [xs]
    ON [xst].[event_session_address] = [xs].[address]
WHERE [xs].[name] = N'InvestigateWaits';
GO


Select	* 
From	sys.dm_os_waiting_tasks ts
		Left Join sys.dm_exec_requests r on ts.session_id = r.session_id
		Left Join sys.dm_exec_sessions s on s.session_id = r.session_id
		Outer Apply dbo.FN_Get_Statement_Sql_Handle(r.statement_start_offset, r.statement_end_offset, r.sql_handle) t
		--Cross Apply sys.dm_exec_sql_text(r.sql_handle) t
where	ts.session_id > 50

select * from sys.dm_exec_sessions
select * from sys.dm_exec_requests

Select * From sys.dm_exec_query_memory_grants

select * from sys.objects where name like 'Fn_Get_Statement%'


 -- Drop the session if it exists.
IF EXISTS (
    SELECT * FROM sys.server_event_sessions
        WHERE [name] = N'EE_ExpensiveQueries')
    DROP EVENT SESSION [EE_ExpensiveQueries] ON SERVER
GO
 
CREATE EVENT SESSION EE_ExpensiveQueries ON SERVER
ADD EVENT sqlserver.sql_statement_completed
   (ACTION (sqlserver.sql_text, sqlserver.plan_handle, [package0].collect_system_time, sqlserver.database_id, sqlserver.client_hostname, sqlos.task_time)
      WHERE sqlserver.database_id = 7 /*DBID*/  
      AND (cpu > 2000 /*total ms of CPU time*/
       Or duration > 1000000
       Or reads > 30000
       Or writes > 5000
       )
      ),
ADD EVENT sqlos.wait_info(
    ACTION(package0.callstack,package0.collect_cpu_cycle_time,package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.is_system,sqlserver.plan_handle,sqlserver.sql_text,sqlserver.tsql_stack)
    WHERE opcode = 1
	and	
        (
            (duration > 2000 AND
			wait_type > 31    -- Waits for latches and important wait resources (not locks) 
                            -- that have exceeded 15 seconds. 
                AND
                (
                    (wait_type > 47 AND wait_type < 54)
                    OR wait_type < 38
                    OR (wait_type > 63 AND wait_type < 70)
                    OR (wait_type > 96 AND wait_type < 100)
                    OR (wait_type = 107)
                    OR (wait_type = 113)
                    OR (wait_type > 174 AND wait_type < 179)
                    OR (wait_type = 186)
                    OR (wait_type = 207)
                    OR (wait_type = 269)
                    OR (wait_type = 283)
                    OR (wait_type = 284)
                )
            )
            OR 
            (duration > 2000        -- Waits for locks that have exceeded 30 secs.
                AND wait_type < 22
            ) 
        )
    ),
ADD EVENT sqlos.wait_info_external(
    ACTION(package0.callstack,package0.collect_cpu_cycle_time,package0.collect_system_time,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.is_system,sqlserver.plan_handle,sqlserver.sql_text,sqlserver.tsql_stack)
    WHERE opcode = 1
	and	
        (
            (duration > 2000
			AND
				wait_type > 31    -- Waits for latches and important wait resources (not locks) 
                AND
                (
                    (wait_type > 47 AND wait_type < 54)
                    OR wait_type < 38
                    OR (wait_type > 63 AND wait_type < 70)
                    OR (wait_type > 96 AND wait_type < 100)
                    OR (wait_type = 107)
                    OR (wait_type = 113)
                    OR (wait_type > 174 AND wait_type < 179)
                    OR (wait_type = 186)
                    OR (wait_type = 207)
                    OR (wait_type = 269)
                    OR (wait_type = 283)
                    OR (wait_type = 284)
                )
            )
            OR 
            (duration > 2000        -- Waits for locks that have exceeded 30 secs.
                AND wait_type < 22
            ) 
        )
    )
ADD TARGET package0.asynchronous_file_target
   (SET     max_file_size = 100,
    max_rollover_files = 5, FILENAME = N'E:\Database\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ExtendedEvents\EE_ExpensiveQueries.xel', METADATAFILE = N'E:\Database\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ExtendedEvents\EE_ExpensiveQueries.xem')
WITH
(
    MAX_MEMORY=15096KB,
    EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY=1 SECONDS,
    TRACK_CAUSALITY=OFF,
    STARTUP_STATE=OFF
)


-- Start the session
ALTER EVENT SESSION EE_ExpensiveQueries ON SERVER
STATE = START;
GO
 

 drop table #temp

 SELECT --top 50
   data.value ('(/event/action[@name=''collect_system_time'']/text)[1]', 'datetime') - 0.0833333 AS [collect_system_time],-- GETUTCDATE();
   data.value ('(/event/@name)[1]', 'varchar(100)') AS [event.name],
   data.value ('(/event/data[@name=''wait_type'']/text)[1]', 'varchar(100)') AS [wait_type],
   --data.value ('(/event[@name=''sql_statement_completed'']/@timestamp)[1]', 'DATETIME') AS [Time],
   data.value ('(/event/data[@name=''cpu'']/value)[1]', 'BIGINT') AS [CPU (ms)],
   data.value ('(/event/data[@name=''reads'']/value)[1]', 'BIGINT') AS [reads],
   data.value ('(/event/data[@name=''duration'']/value)[1]', 'BIGINT') AS [duration],
   --data.value ('(/event/data[@name=''signal_duration'']/value)[1]', 'BIGINT') AS [signal_duration],
   data.value ('(/event/data[@name=''writes'']/value)[1]', 'BIGINT') AS [writes],
   --data.value ('(/event/data[@name=''object_id'']/value)[1]', 'INT') AS [object_id],
      CONVERT (FLOAT, data.value ('(/event/data[@name=''duration'']/value)[1]', 'BIGINT')) / 1000000 AS [Duration (s)],
   data.value ('(/event/action[@name=''sql_text'']/value)[1]', 'VARCHAR(MAX)') AS [SQL Statement],
      --SUBSTRING (data.value ('(/event/action[@name=''plan_handle'']/value)[1]', 'VARCHAR(100)'), 15, 50)
      --AS [Plan Handle]
   data.query('.') text_xml
INTO #TEMP
FROM 
   (SELECT CONVERT (XML, event_data) AS data 
FROM sys.fn_xe_file_target_read_file
      ('E:\Database\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ExtendedEvents\EE_ExpensiveQueries*.xel', 
	  'E:\Database\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ExtendedEvents\EE_ExpensiveQueries*.xem', null, null)
) entries
--ORDER BY [collect_system_time] DESC;
GO

Delete from #temp where [sql statement] = '(@P1 int)exec sp_trace_getdata @P1, 0'

create nonclustered index idx_dt on #temp ([collect_system_time])

Select	Top 50  *
From	#TEMP
Where	[collect_system_time] > '2015-11-23 09:50'
And		[collect_system_time] < '2015-11-23 10:05'
ORDER BY [collect_system_time] DESC;


EXEC sp_logmsg @texto = timeout

SELECT getdate()
SELECT GETUTCDATE() 

select * from master.dbo.FN_Get_Statement_Sql_Handle(1454, 1652, 0x03000700DF7AAB5C74F87C0152A500000100000000000000)
select * from master.dbo.FN_Get_Statement_Sql_Handle(0, -1, 0x01000700867C7E02B09E05A9010000000000000000000000)
select * from sys.dm_exec_sql_text(0x020000008AF7121D372119C67BB9C109E20DC7D2FEBEB242)


