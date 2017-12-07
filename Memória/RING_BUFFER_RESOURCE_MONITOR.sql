SET ANSI_NULLS, QUOTED_IDENTIFIER, CONCAT_NULL_YIELDS_NULL, ANSI_WARNINGS, ANSI_PADDING, ARITHABORT on

SELECT  
    EventTime, 
    record.value('(/Record/ResourceMonitor/Notification)[1]', 'varchar(max)') as [Type], 
    record.value('(/Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') AS [Avail Phys Mem, Kb], 
    record.value('(/Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') AS [Avail VAS, Kb],
    record.value('(/Record/ResourceMonitor/IndicatorsProcess)[1]','tinyint') AS IndicatorsProcess,
    record.value('(/Record/ResourceMonitor/IndicatorsSystem)[1]','tinyint') AS IndicatorsSystem
FROM ( 
    SELECT 
        DATEADD (ss, (-1 * ((cpu_ticks / CONVERT (float, ( cpu_ticks / ms_ticks ))) - [timestamp])/1000), GETDATE()) AS EventTime, 
        CONVERT (xml, record) AS record 
    FROM sys.dm_os_ring_buffers 
    CROSS JOIN sys.dm_os_sys_info 
    WHERE ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR') AS tab 
ORDER BY EventTime DESC





SELECT  
    EventTime, 
    record.value('(/Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'bigint') as [Type], 
    record.value('(/Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'bigint') AS [Avail Phys Mem, Kb], 
    record.value('(/Record/SchedulerMonitorEvent/SystemHealth/KernelModeTime)[1]', 'bigint') AS [Avail VAS, Kb],
    record.value('(/Record/SchedulerMonitorEvent/SystemHealth/PageFaults)[1]','bigint') AS IndicatorsProcess,
    record.value('(/Record/SchedulerMonitorEvent/SystemHealth/WorkingSetDelta)[1]','bigint') AS IndicatorsSystem,
    record.value('(/Record/SchedulerMonitorEvent/SystemHealth/MemoryUtilization)[1]','bigint') AS IndicatorsSystem
FROM ( 
    SELECT 
        DATEADD (ss, (-1 * ((cpu_ticks / CONVERT (float, ( cpu_ticks / ms_ticks ))) - [timestamp])/1000), GETDATE()) AS EventTime, 
        CONVERT (xml, record) AS record 
    FROM sys.dm_os_ring_buffers 
    CROSS JOIN sys.dm_os_sys_info 
    WHERE ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR') AS tab 
ORDER BY EventTime DESC



;WITH RingBufferConnectivity as
(   SELECT
        records.record.value('(/Record/@id)[1]', 'int') AS [RecordID],
        records.record.value('(/Record/ConnectivityTraceRecord/RecordType)[1]', 'varchar(max)') AS [RecordType],
        records.record.value('(/Record/ConnectivityTraceRecord/RecordTime)[1]', 'datetime') AS [RecordTime],
        records.record.value('(/Record/ConnectivityTraceRecord/SniConsumerError)[1]', 'int') AS [Error],
        records.record.value('(/Record/ConnectivityTraceRecord/State)[1]', 'int') AS [State],
        records.record.value('(/Record/ConnectivityTraceRecord/Spid)[1]', 'int') AS [Spid],
        records.record.value('(/Record/ConnectivityTraceRecord/RemoteHost)[1]', 'varchar(max)') AS [RemoteHost],
        records.record.value('(/Record/ConnectivityTraceRecord/RemotePort)[1]', 'varchar(max)') AS [RemotePort],
        records.record.value('(/Record/ConnectivityTraceRecord/LocalHost)[1]', 'varchar(max)') AS [LocalHost]
    FROM
    (   SELECT CAST(record as xml) AS record_data
        FROM sys.dm_os_ring_buffers
        WHERE ring_buffer_type= 'RING_BUFFER_CONNECTIVITY'
    ) TabA
    CROSS APPLY record_data.nodes('//Record') AS records (record)
)
SELECT RBC.*, m.text
FROM RingBufferConnectivity RBC
LEFT JOIN sys.messages M ON
    RBC.Error = M.message_id AND M.language_id = 1033
WHERE RBC.RecordType='Error' --Comment Out to see all RecordTypes
And m.text not like 'Login%'
ORDER BY RBC.RecordTime DESC



