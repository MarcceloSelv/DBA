 SELECT TOP(100) [text], [Size (mb)] = (cp.size_in_bytes / 1024) / 1024
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
WHERE cp.cacheobjtype = 'Compiled Plan' 
AND not cp.objtype = 'Adhoc' 
AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC;

SELECT Sum(size_in_bytes)--(SUM(size_in_bytes)/1024)/1024 as 'MB'  
FROM sys.dm_exec_cached_plans
order by 1 desc

SELECT COUNT(*) FROM sys.dm_exec_cached_plans;

-- Plans which have only been used once
SELECT * FROM sys.dm_exec_cached_plans 
SELECT (SUM(size_in_bytes)/1024)/1024 FROM sys.dm_exec_cached_plans
WHERE objtype = 'ADHOC' and usecounts < 2;


SELECT plan_handle, ecp.memory_object_address AS CompiledPlan_MemoryObject, 
    omo.memory_object_address, pages_allocated_count, type, page_size_in_bytes 
FROM sys.dm_exec_cached_plans AS ecp 
JOIN sys.dm_os_memory_objects AS omo 
    ON ecp.memory_object_address = omo.memory_object_address 
    OR ecp.memory_object_address = omo.parent_address
WHERE cacheobjtype = 'Compiled Plan';


-- This statement will show you how much of your cache is 
-- allocated to single use plans
SELECT objtype AS [CacheType]
        , count_big(*) AS [Total Plans]
        , sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 AS [Total MBs]
        , avg(usecounts) AS [Avg Use Count]
        , sum(cast((CASE WHEN usecounts = 1 
        THEN size_in_bytes ELSE 0 END) as decimal(18,2)))/1024/1024 
                AS [Total MBs - USE Count 1]
        , sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) 
                AS [Total Plans - USE Count 1]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY [Total MBs - USE Count 1] DESC


--Details for plans with usecount of 1
SELECT    bucketid, refcounts, usecounts, (size_in_bytes)/1024 as 'Size in KB', 
        cacheobjtype, objtype, [text] 
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
WHERE objtype = 'ADHOC' and usecounts < 2;