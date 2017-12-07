SELECT TOP 5 SQLtxt.text AS 'SQL',
qstats.execution_count
AS 'Execution Count',
qstats.total_logical_writes/DATEDIFF(second, qstats.creation_time,
GetDate()) AS 'Logical Writes Per Second',
qstats.total_physical_reads AS [Total Physical Reads],
qstats.total_worker_time/qstats.execution_count AS [Average WorkerTime],
qstats.total_worker_time AS 'Total Worker Time',
DATEDIFF(hour, qstats.creation_time,
GetDate()) AS 'TimeInCache in Hours'
FROM sys.dm_exec_query_stats AS qstats
CROSS APPLY sys.dm_exec_sql_text(qstats.sql_handle) AS SQLtxt
WHERE SQLtxt.dbid = db_id()
ORDER BY qstats.execution_count DESC

use master

SELECT TOP 5 object_name(SQLtxt.objectid, db_id('ECARGO')) AS 'SQL',
qstats.execution_count
AS 'Execution Count',
qstats.total_logical_writes/DATEDIFF(second, qstats.creation_time,
GetDate()) AS 'Logical Writes Per Second',
qstats.total_physical_reads AS [Total Physical Reads],
qstats.total_worker_time/qstats.execution_count AS [Average WorkerTime],
qstats.total_worker_time AS 'Total Worker Time',
DATEDIFF(hour, qstats.creation_time,
GetDate()) AS 'TimeInCache in Hours'
FROM sys.dm_exec_query_stats AS qstats
CROSS APPLY sys.dm_exec_sql_text(qstats.sql_handle) AS SQLtxt
WHERE SQLtxt.dbid = db_id('ECARGO')
ORDER BY [Average WorkerTime] DESC