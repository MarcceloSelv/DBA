USE [ECARGO]

SELECT
    'ECARGO' AS [Database],
    OBJECT_NAME (p.[object_id]) AS [Object],
    p.[index_id],
    i.[name] AS [Index],
    i.[type_desc] AS [Type],
    --au.[type_desc] AS [AUType],
    --DPCount AS [DirtyPageCount],
    --CPCount AS [CleanPageCount],
    --DPCount * 8 / 1024 AS [DirtyPageMB],
    --CPCount * 8 / 1024 AS [CleanPageMB],
    (DPCount + CPCount) * 8 / 1024 AS [TotalMB],
    --DPFreeSpace / 1024 / 1024 AS [DirtyPageFreeSpace],
    --CPFreeSpace / 1024 / 1024 AS [CleanPageFreeSpace],
    ([DPFreeSpace] + [CPFreeSpace]) / 1024 / 1024 AS [FreeSpaceMB],
    CAST (ROUND (100.0 * (([DPFreeSpace] + [CPFreeSpace]) / 1024) / (([DPCount] + [CPCount]) * 8), 1) AS DECIMAL (4, 1)) AS [FreeSpacePC]
FROM
    (SELECT
        allocation_unit_id,
        SUM (CASE WHEN ([is_modified] = 1)
            THEN 1 ELSE 0 END) AS [DPCount],
        SUM (CASE WHEN ([is_modified] = 1)
            THEN 0 ELSE 1 END) AS [CPCount],
        SUM (CASE WHEN ([is_modified] = 1)
            THEN CAST ([free_space_in_bytes] AS BIGINT) ELSE 0 END) AS [DPFreeSpace],
        SUM (CASE WHEN ([is_modified] = 1)
            THEN 0 ELSE CAST ([free_space_in_bytes] AS BIGINT) END) AS [CPFreeSpace]
    FROM sys.dm_os_buffer_descriptors
    WHERE [database_id] = DB_ID ('ECARGO')
    GROUP BY [allocation_unit_id]) AS buffers
INNER JOIN sys.allocation_units AS au
    ON au.[allocation_unit_id] = buffers.[allocation_unit_id]
INNER JOIN sys.partitions AS p
    ON au.[container_id] = p.[partition_id]
INNER JOIN sys.indexes AS i
    ON i.[index_id] = p.[index_id] AND p.[object_id] = i.[object_id]
WHERE p.[object_id] > 100 AND ([DPCount] + [CPCount]) > 12800 -- Taking up more than 100MB
ORDER BY [FreeSpacePC] DESC;



SELECT TOP 50 st.text, cp.objtype, cp.cacheobjtype, cp.size_in_bytes, cp.refcounts, cp.usecounts, qp.query_plan --, *
FROM sys.dm_exec_cached_plans AS cp
        CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
        CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
WHERE cp.objtype IN ('Adhoc', 'Prepared')
        --AND st.text LIKE '%member%'
ORDER BY cp.size_in_bytes DESC
go


SELECT objtype AS [CacheType]
        , count_big(*) AS [Total Plans]
        , sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 AS [Total MBs]
        , avg(usecounts) AS [Avg Use Count]
        , sum(cast((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) as decimal(18,2)))/1024/1024 AS [Total MBs – USE Count 1]
        , sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Total Plans – USE Count 1]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY [Total MBs – USE Count 1] DESC
go