If Exists(Select 1 From sys.objects Where name = 'SystemHealthSessionData')
	drop table SystemHealthSessionData

SELECT CAST(xet.target_data AS XML) AS XmlData
INTO SystemHealthSessionData
FROM sys.dm_xe_session_targets xet
JOIN sys.dm_xe_sessions xe
ON (xe.address = xet.event_session_address)
WHERE xe.name = 'system_health'

--Select * from SystemHealthSessionData

-- Extract the Event information from the Event Session 
SELECT TOP 300
    event_name = Event.Name,
    [collect_system_time] = convert(datetime, event_data.value('(event/action[@name="collect_system_time"]/text)[1]', 'varchar(24)'), 127),
    --[collect_system_time] = event_data.value('(event/action[@name="collect_system_time"]/text)[1]', 'varchar(24)'),
    [timestamp]	= DATEADD(hh, DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), event_data.value('(event/@timestamp)[1]', 'datetime2')),
    database_id = COALESCE(event_data.value('(event/data[@name="database_id"]/value)[1]', 'int'), event_data.value('(event/action[@name="database_id"]/value)[1]', 'int')),
    [session_id] = event_data.value('(event/action[@name="session_id"]/value)[1]', 'int'),
    [wait_type]	= event_data.value('(event/data[@name="wait_type"]/text)[1]', 'nvarchar(4000)'),
    [opcode]	= event_data.value('(event/data[@name="opcode"]/text)[1]', 'nvarchar(4000)'),
    [duration]	= event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint'),
    [max_duration] = event_data.value('(event/data[@name="max_duration"]/value)[1]', 'bigint'),
    [total_duration] = event_data.value('(event/data[@name="total_duration"]/value)[1]', 'bigint'),
    [signal_duration] = event_data.value('(event/data[@name="signal_duration"]/value)[1]', 'bigint'),
    [completed_count] = event_data.value('(event/data[@name="completed_count"]/value)[1]', 'bigint') ,
    [plan_handle] = event_data.value('(event/action[@name="plan_handle"]/value)[1]', 'nvarchar(4000)') ,
    [sql_text] = event_data.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(4000)'),
    event_data
FROM 
(    SELECT XEvent.query('.') AS event_data 
    FROM SystemHealthSessionData
    -- Split out the Event Nodes 
    CROSS APPLY XmlData.nodes ('RingBufferTarget/event') AS XEventData (XEvent) 
) AS tab (event_data)
	Cross Apply (Select event_data.value('(event/@name)[1]', 'varchar(50)')) Event(Name)
Where Event.Name != 'error_reported'
ORDER BY 2 DESC



--select convert(datetime, '2015-10-20T18:28:02.271Z', 127)

--SELECT LEN('2015-10-20T18:28:02.271Z')



SELECT 
    [event_name]	= event_data.value('(event/@name)[1]', 'varchar(50)'),
    [collect_system_time] = convert(datetime, event_data.value('(event/action[@name="collect_system_time"]/text)[1]', 'varchar(24)'), 127),
    [timestamp]		= DATEADD(hh, DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), event_data.value('(event/@timestamp)[1]', 'datetime2')),
    database_id		= COALESCE(event_data.value('(event/data[@name="database_id"]/value)[1]', 'int'), event_data.value('(event/action[@name="database_id"]/value)[1]', 'int')),
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



SELECT 
	FUNCAO_ID, COUNT(1)
--INTO	LOG_EXECUCAO2
FROM	LOG_EXECUCAO LE WITH (NOLOCK)
GROUP BY FUNCAO_ID
ORDER BY 2 DESC

SELECT	TS.TABELA_SISTEMA_ID, TS.NOME_TABELA, COUNT(1)
FROM	LOG_SISTEMA LS WITH (NOLOCK)
	INNER JOIN TABELA_SISTEMA TS ON TS.TABELA_SISTEMA_ID = LS.TABELA_SISTEMA_ID
GROUP BY TS.TABELA_SISTEMA_ID, TS.nome_tabela
ORDER BY 3 DESC

137.106.829
58.923.841
29.589.037