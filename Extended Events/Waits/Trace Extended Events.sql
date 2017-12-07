
--http://sqlblog.com/blogs/jonathan_kehayias/archive/2010/12/30/an-xevent-a-day-30-of-31-tracking-session-and-statement-level-waits.aspx


CREATE EVENT SESSION [TrackResourceWaits] ON SERVER 
ADD EVENT  sqlos.wait_info
(    -- Capture the database_id, session_id, plan_handle, and sql_text
    ACTION(sqlserver.database_id,sqlserver.session_id,sqlserver.sql_text,sqlserver.plan_handle)
    WHERE
        (opcode = 1 --End Events Only
            AND duration > 1000 -- had to accumulate 100ms of time
            AND ((wait_type > 0 AND wait_type < 22) -- LCK_ waits
                    OR (wait_type > 31 AND wait_type < 38) -- LATCH_ waits
                    OR (wait_type > 47 AND wait_type < 54) -- PAGELATCH_ waits
                    OR (wait_type > 63 AND wait_type < 70) -- PAGEIOLATCH_ waits
                    OR (wait_type > 96 AND wait_type < 100) -- IO (Disk/Network) waits
                    OR (wait_type = 107) -- RESOURCE_SEMAPHORE waits
                    OR (wait_type = 113) -- SOS_WORKER waits
                    OR (wait_type = 120) -- SOS_SCHEDULER_YIELD waits
                    OR (wait_type = 178) -- WRITELOG waits
                    OR (wait_type > 174 AND wait_type < 177) -- FCB_REPLICA_ waits
                    OR (wait_type = 186) -- CMEMTHREAD waits
                    OR (wait_type = 187) -- CXPACKET waits
                    OR (wait_type = 207) -- TRACEWRITE waits
                    OR (wait_type = 269) -- RESOURCE_SEMAPHORE_MUTEX waits
                    OR (wait_type = 283) -- RESOURCE_SEMAPHORE_QUERY_COMPILE waits
                    OR (wait_type = 284) -- RESOURCE_SEMAPHORE_SMALL_QUERY waits
                )
        )
)
ADD TARGET package0.ring_buffer(SET max_memory=4096)
WITH (EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
      MAX_DISPATCH_LATENCY=5 SECONDS)
GO

-- Start the Event Session
ALTER EVENT SESSION [TrackResourceWaits] 
ON SERVER 
STATE = START;

SET ANSI_NULLS, QUOTED_IDENTIFIER, CONCAT_NULL_YIELDS_NULL, ANSI_WARNINGS, ANSI_PADDING, ARITHABORT ON
-- Extract the Event information from the Event Session 
SELECT 
    event_data.value('(event/@name)[1]', 'varchar(50)') AS event_name,
    DATEADD(hh, 
        DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), 
        event_data.value('(event/@timestamp)[1]', 'datetime2')) AS [timestamp],
    COALESCE(event_data.value('(event/data[@name="database_id"]/value)[1]', 'int'), 
        event_data.value('(event/action[@name="database_id"]/value)[1]', 'int')) AS database_id,
    event_data.value('(event/action[@name="session_id"]/value)[1]', 'int') AS [session_id],
    event_data.value('(event/data[@name="wait_type"]/text)[1]', 'nvarchar(4000)') AS [wait_type],
    event_data.value('(event/data[@name="opcode"]/text)[1]', 'nvarchar(4000)') AS [opcode],
    event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint') AS [duration],
    event_data.value('(event/data[@name="max_duration"]/value)[1]', 'bigint') AS [max_duration],
    event_data.value('(event/data[@name="total_duration"]/value)[1]', 'bigint') AS [total_duration],
    event_data.value('(event/data[@name="signal_duration"]/value)[1]', 'bigint') AS [signal_duration],
    event_data.value('(event/data[@name="completed_count"]/value)[1]', 'bigint') AS [completed_count],
    event_data.value('(event/action[@name="plan_handle"]/value)[1]', 'nvarchar(4000)') AS [plan_handle],
    event_data.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(4000)') AS [sql_text]
FROM 
(    SELECT XEvent.query('.') AS event_data 
    FROM 
    (    -- Cast the target_data to XML 
        SELECT CAST(target_data AS XML) AS TargetData 
        FROM sys.dm_xe_session_targets st 
        JOIN sys.dm_xe_sessions s 
            ON s.address = st.event_session_address 
        WHERE name = 'TrackResourceWaits' 
          AND target_name = 'ring_buffer'
    ) AS Data 
    -- Split out the Event Nodes 
    CROSS APPLY TargetData.nodes ('RingBufferTarget/event') AS XEventData (XEvent)   
) AS tab (event_data)


