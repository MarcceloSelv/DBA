
SET ANSI_NULLS, QUOTED_IDENTIFIER, CONCAT_NULL_YIELDS_NULL, ANSI_WARNINGS, ANSI_PADDING, ARITHABORT ON
-- Extract the Event information from the Event Session 
SELECT top 50
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
    event_data.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(4000)') AS [sql_text],
    event_data
FROM 
(    SELECT XEvent.query('.') AS event_data 
    FROM 
    (    -- Cast the target_data to XML 
        SELECT CAST(target_data AS XML) AS TargetData 
        FROM sys.dm_xe_session_targets st 
        JOIN sys.dm_xe_sessions s 
            ON s.address = st.event_session_address 
        WHERE name = 'Waits' 
          AND target_name = 'ring_buffer'
    ) AS Data 
    -- Split out the Event Nodes 
    CROSS APPLY TargetData.nodes ('RingBufferTarget/event') AS XEventData (XEvent)   
) AS tab (event_data)


SELECT TOP 50 *
FROM sys.dm_os_wait_stats
