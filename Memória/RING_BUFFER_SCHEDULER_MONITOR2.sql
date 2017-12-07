-- Check the Ring Buffer in SQL Server 2008
 
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET ANSI_WARNINGS ON
SET ANSI_PADDING ON
 
SELECT CONVERT (varchar(30), GETDATE(), 121) as Run_Time,
dateadd (ms, (ST.[RecordTime] - sys.ms_ticks), GETDATE()) as [Notification_Time],
ST.* , sys.ms_ticks AS [Current Time]
FROM
(SELECT
RBXML.value('(//Record/Error/ErrorCode)[1]', 'varchar(30)') AS [ErrorCode],
RBXML.value('(//Record/Error/CallingAPIName)[1]', 'varchar(255)') AS [CallingAPIName],
RBXML.value('(//Record/Error/APIName)[1]', 'varchar(255)') AS [APIName],
RBXML.value('(//Record/Error/SPID)[1]', 'int') AS [SPID],
RBXML.value('(//Record/@id)[1]', 'bigint') AS [Record Id],
RBXML.value('(//Record/@type)[1]', 'varchar(30)') AS [Type],
RBXML.value('(//Record/@time)[1]', 'bigint') AS [RecordTime],
RBXML
FROM (SELECT CAST (record as xml) FROM sys.dm_os_ring_buffers
WHERE ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR') AS RB(RBXML)) ST
CROSS JOIN sys.dm_os_sys_info sys
ORDER BY ST.[RecordTime] ASC


Select top 50 * from sys.dm_os_performance_counters
Where object_name Like '%Memory%'

Select * from sys.dm_os_performance_counters
Where counter_name In ('SQL Cache Memory (KB)', 'Total Server Memory (KB)')



SELECT [object_name], [counter_name],  
   [instance_name], [cntr_value] 
FROM sys.[dm_os_performance_counters] 
WHERE [object_name] = 'SQLServer:Wait Statistics'



SELECT (a.cntr_value * 1.0 / b.cntr_value) * 100.0 [BufferCacheHitRatio]
FROM (SELECT * FROM sys.dm_os_performance_counters
WHERE counter_name = 'Buffer cache hit ratio'
AND object_name = CASE WHEN @@SERVICENAME = 'MSSQLSERVER'
THEN 'SQLServer:Buffer Manager'
ELSE 'MSSQL$' + rtrim(@@SERVICENAME) +
':Buffer Manager' END ) a
CROSS JOIN
(SELECT * from sys.dm_os_performance_counters
WHERE counter_name = 'Buffer cache hit ratio base'
and object_name = CASE WHEN @@SERVICENAME = 'MSSQLSERVER'
THEN 'SQLServer:Buffer Manager'
ELSE 'MSSQL$' + rtrim(@@SERVICENAME) +
':Buffer Manager' END ) b;

select * from sys.dm_os_wait_stats


sp_server_diagnostics


sp_BlitzCache

-- Note: querying sys.dm_os_buffer_descriptors
-- requires the VIEW_SERVER_STATE permission.

DECLARE @total_buffer INT;

SELECT @total_buffer = cntr_value
   FROM sys.dm_os_performance_counters 
   WHERE RTRIM([object_name]) LIKE '%Buffer Manager'
   AND counter_name = 'Total Pages';

;WITH src AS
(
   SELECT 
       database_id, db_buffer_pages = COUNT_BIG(*)
       FROM sys.dm_os_buffer_descriptors
       --WHERE database_id BETWEEN 5 AND 32766
       GROUP BY database_id
)
SELECT
   [db_name] = CASE [database_id] WHEN 32767 
       THEN 'Resource DB' 
       ELSE DB_NAME([database_id]) END,
   db_buffer_pages,
   db_buffer_MB = db_buffer_pages / 128,
   db_buffer_percent = CONVERT(DECIMAL(6,3), 
       db_buffer_pages * 100.0 / @total_buffer)
FROM src
ORDER BY db_buffer_MB DESC;


;WITH src AS
(
   SELECT
       [Object] = o.name,
       [Type] = o.type_desc,
       [Index] = COALESCE(i.name, ''),
       [Index_Type] = i.type_desc,
       p.[object_id],
       p.index_id,
       au.allocation_unit_id
   FROM
       sys.partitions AS p
   INNER JOIN
       sys.allocation_units AS au
       ON p.hobt_id = au.container_id
   INNER JOIN
       sys.objects AS o
       ON p.[object_id] = o.[object_id]
   INNER JOIN
       sys.indexes AS i
       ON o.[object_id] = i.[object_id]
       AND p.index_id = i.index_id
   WHERE
       au.[type] IN (1,2,3)
       AND o.is_ms_shipped = 0
)
SELECT
   src.[Object],
   src.[Type],
   --src.[Index],
   --src.Index_Type,
   buffer_pages = COUNT_BIG(b.page_id),
   buffer_mb = COUNT_BIG(b.page_id) / 128
FROM
   src
INNER JOIN
   sys.dm_os_buffer_descriptors AS b
   ON src.allocation_unit_id = b.allocation_unit_id
WHERE
   b.database_id = DB_ID()
GROUP BY
   src.[Object],
   src.[Type]
   --,src.[Index]
   --,src.Index_Type
ORDER BY
   buffer_pages DESC;


SELECT type, name, pages_kb, virtual_memory_reserved_kb, virtual_memory_committed_kb, shared_memory_reserved_kb, shared_memory_committed_kb, page_size_in_bytes
FROM sys.dm_os_memory_clerks

select * from sys.dm_os_process_memory

SELECT
    distinct mcc.name, 
    mcc.type,
    mcc.single_pages_kb,
    mcc.multi_pages_kb, 
    mcc.single_pages_in_use_kb,
    mcc.multi_pages_in_use_kb, 
    mcc.entries_count, 
    mcc.entries_in_use_count,
    mcch.removed_all_rounds_count, 
    mcch.removed_last_round_count
FROM sys.dm_os_memory_cache_counters mcc 
    JOIN sys.dm_os_memory_cache_clock_hands mcch 
 ON (mcc.cache_address = mcch.cache_address)
 
 select * from sys.dm_os_virtual_address_dump