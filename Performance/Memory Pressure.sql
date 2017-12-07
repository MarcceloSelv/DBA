-- SQL Server 2008 and R2 Memory Related Queries
-- Glenn Berry 
-- October 2010
-- http://glennberrysqlperformance.spaces.live.com/
-- Twitter: GlennAlanBerry

-- Instance Level queries

-- Good basic information about memory amounts and state (SQL 2008 and 2008 R2)
SELECT total_physical_memory_kb, available_physical_memory_kb, 
       total_page_file_kb, available_page_file_kb, 
       system_memory_state_desc
FROM sys.dm_os_sys_memory;

-- You want to see "Available physical memory is high"


-- SQL Server Process Address space info (SQL 2008 and 2008 R2)
--(shows whether locked pages is enabled, among other things)
SELECT physical_memory_in_use_kb,locked_page_allocations_kb, 
       page_fault_count, memory_utilization_percentage, 
       available_commit_limit_kb, process_physical_memory_low, 
       process_virtual_memory_low
FROM sys.dm_os_process_memory;

-- You want to see 0 for process_physical_memory_low
-- You want to see 0 for process_virtual_memory_low


-- Page Life Expectancy (PLE) value for default instance (SQL 2005, 2008 and 2008 R2)
SELECT cntr_value AS [Page Life Expectancy]
FROM sys.dm_os_performance_counters
WHERE OBJECT_NAME = N'SQLServer:Buffer Manager' -- Modify this if you have named instances
AND counter_name = N'Page life expectancy';

-- PLE is a good measurement of memory pressure.
-- Higher PLE is better. Below 300 is generally bad.
-- Watch the trend, not the absolute value.


-- Get total buffer usage by database for current instance (SQL 2005, 2008 and 2008 R2)
-- Note: This is a fairly expensive query
SELECT DB_NAME(database_id) AS [Database Name],
COUNT(*) * 8/1024.0 AS [Cached Size (MB)]
FROM sys.dm_os_buffer_descriptors
WHERE database_id > 4 -- system databases
AND database_id <> 32767 -- ResourceDB
GROUP BY DB_NAME(database_id)
ORDER BY [Cached Size (MB)] DESC;

-- Helps determine which databases are using the most memory on an instance


-- Memory Clerk Usage for instance
-- Look for high value for CACHESTORE_SQLCP (Ad-hoc query plans)
-- (SQL 2005, 2008 and 2008 R2)
SELECT TOP(20) [type], [name], SUM(single_pages_kb) AS [SPA Mem, Kb] 
FROM sys.dm_os_memory_clerks 
GROUP BY [type], [name]  
ORDER BY SUM(single_pages_kb) DESC;

-- CACHESTORE_SQLCP  SQL Plans         These are cached SQL statements or batches that aren't in 
--                                     stored procedures, functions and triggers
-- CACHESTORE_OBJCP  Object Plans      These are compiled plans for stored procedures, 
--                                     functions and triggers
-- CACHESTORE_PHDR   Algebrizer Trees  An algebrizer tree is the parsed SQL text that 
--                                     resolves the table and column names


-- Find single-use, ad-hoc queries that are bloating the plan cache
SELECT TOP(100) [text], cp.size_in_bytes
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
WHERE cp.cacheobjtype = N'Compiled Plan' 
AND cp.objtype = N'Adhoc' 
AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC;

-- Gives you the text and size of single-use ad-hoc queries that waste space in the plan cache
-- Enabling 'optimize for ad hoc workloads' for the instance can help (SQL Server 2008 and 2008 R2 only)
-- Enabling forced parameterization for the database can help, but test first!


-- Database level queries (switch to your database)
--USE YourDatabaseName;
--GO

-- Breaks down buffers used by current database by object (table, index) in the buffer cache
-- (SQL 2008 and 2008 R2) Note: This is a fairly expensive query
SELECT OBJECT_NAME(p.[object_id], DB_ID('ECARGO')) AS [ObjectName], 
p.index_id, COUNT(*)/128 AS [Buffer size(MB)],  COUNT(*) AS [BufferCount], 
p.data_compression_desc AS [CompressionType]
FROM ECARGO.sys.allocation_units AS a
INNER JOIN ECARGO.sys.dm_os_buffer_descriptors AS b
ON a.allocation_unit_id = b.allocation_unit_id
INNER JOIN ECARGO.sys.partitions AS p
ON a.container_id = p.hobt_id
WHERE b.database_id = CONVERT(int,DB_ID('ECARGO'))
AND p.[object_id] > 100
GROUP BY p.[object_id], p.index_id, p.data_compression_desc
ORDER BY [BufferCount] DESC;


-- Top Cached SPs By Total Logical Reads (SQL 2008 and 2008 R2). Logical reads relate to memory pressure
SELECT TOP(25) p.name AS [SP Name], qs.total_logical_reads AS [TotalLogicalReads], 
qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],qs.execution_count, 
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second], 
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count 
AS [avg_elapsed_time], qs.cached_time
FROM ecargo.sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID('ecargo')
ORDER BY qs.total_logical_reads DESC;

-- This helps you find the most expensive cached stored procedures from a memory perspective
-- You should look at this if you see signs of memory pressure