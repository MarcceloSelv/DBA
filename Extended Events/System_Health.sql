
--http://troubleshootingsql.com/2011/09/28/system-health-session-part-4/

--drop table SystemHealthSessionData
--drop table #SystemHealthSessionData

If Object_Id('Tempdb..#SystemHealthSessionData2') Is Not Null
	Drop Table #SystemHealthSessionData

SELECT *
INTO #SystemHealthSessionData
FROM sys.dm_xe_session_targets xet
JOIN sys.dm_xe_sessions xe
ON (xe.address = xet.event_session_address)
WHERE xe.name = 'system_health'

ALTER TABLE #SystemHealthSessionData ALTER COLUMN TARGET_DATA XML

-- Extract the Event information from the Event Session 
SELECT 
    Event.Name AS event_name,
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
(    SELECT TARGET_DATA.query('.') AS event_data 
    FROM #SystemHealthSessionData
    -- Split out the Event Nodes 
    CROSS APPLY TARGET_DATA.nodes ('RingBufferTarget/event') AS XEventData (XEvent) 
) AS tab (event_data)
	Cross Apply (Select event_data.value('(event/@name)[1]', 'varchar(50)')) Event(Name)
Where Event.Name != 'error_reported'