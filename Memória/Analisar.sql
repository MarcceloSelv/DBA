EXEC sp_who3 1
GO
EXEC SP_LOGMSG @TEXTO = TIMEOUT
GO
SELECT * FROM sys.dm_os_memory_allocations
SELECT * FROM sys.dm_os_memory_objects
SELECT * FROM sys.dm_os_sys_memory
SELECT * FROM sys.dm_os_wait_stats
SELECT * FROM sys.dm_os_virtual_address_dump
SELECT * FROM sys.dm_os_sys_info
SELECT * FROM sys.dm_os_windows_info 
SELECT * FROM sys.dm_server_registry;
SELECT * FROM sys.dm_server_services
SELECT top 5 cast(record as xml), * FROM sys.dm_os_ring_buffers WHERE ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR';

SELECT TOP 50 * FROM sys.dm_os_performance_counters

SELECT TOP 50 type,
	 name,
	 max_free_entries_count,
	 free_entries_count,
	 removed_in_all_rounds_count
FROM sys.dm_os_memory_pools
ORDER BY removed_in_all_rounds_count DESC



SELECT COUNT(*)AS cached_pages_count
    ,CASE database_id 
        WHEN 32767 THEN 'ResourceDb' 
        ELSE db_name(database_id) 
        END AS database_name
FROM sys.dm_os_buffer_descriptors
GROUP BY DB_NAME(database_id) ,database_id
ORDER BY cached_pages_count DESC;



SELECT COUNT(*)AS cached_pages_count 
    ,name ,index_id 
FROM sys.dm_os_buffer_descriptors AS bd 
    INNER JOIN 
    (
        SELECT object_name(object_id) AS name 
            ,index_id ,allocation_unit_id
        FROM sys.allocation_units AS au
            INNER JOIN sys.partitions AS p 
                ON au.container_id = p.hobt_id 
                    AND (au.type = 1 OR au.type = 3)
        UNION ALL
        SELECT object_name(object_id) AS name   
            ,index_id, allocation_unit_id
        FROM sys.allocation_units AS au
            INNER JOIN sys.partitions AS p 
                ON au.container_id = p.partition_id 
                    AND au.type = 2
    ) AS obj 
        ON bd.allocation_unit_id = obj.allocation_unit_id
WHERE database_id = DB_ID()
GROUP BY name, index_id 
ORDER BY cached_pages_count DESC;



-- Hardware information from SQL Server Denali
SELECT cpu_count AS [Logical CPU Count], hyperthread_ratio
AS [Hyperthread Ratio],
cpu_count/hyperthread_ratio AS [Physical CPU Count],
physical_memory_kb/1024 AS [Physical Memory (MB)],
affinity_type_desc, virtual_machine_type_desc,
sqlserver_start_time
FROM sys.dm_os_sys_info OPTION (RECOMPILE);


-- Hardware information from SQL Server 2008
SELECT cpu_count AS [Logical CPU Count], hyperthread_ratio AS [Hyperthread Ratio],
cpu_count/hyperthread_ratio AS [Physical CPU Count], 
physical_memory_in_bytes/1048576 AS [Physical Memory (MB)], sqlserver_start_time
FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE);