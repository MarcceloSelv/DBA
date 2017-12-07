
-- Find queries that have the highest average CPU usage per object
SELECT TOP 50
	ObjectName          = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
	--,TextData           = qt.text
	--,[Stmt].StatementText
	--, qs.query_hash
	--,[Stmt].StatementTextXml
	--,qs.statement_start_offset, qs.statement_end_offset
	,DiskReadsAvg		= SUM(qs.total_physical_reads) / SUM(qs.execution_count)  -- The worst reads, disk reads
	,MemoryReadsAvg		= SUM(qs.total_logical_reads) / SUM(qs.execution_count)    --Logical Reads are memory reads
	,Executions		= SUM(qs.execution_count)
	,TotalCPUTime		= SUM(qs.total_worker_time)
	,AverageCPUTime		= SUM(qs.total_worker_time) / SUM(qs.execution_count)
	,DiskWaitAndCPUTimeAvg	= SUM(qs.total_elapsed_time) / SUM(qs.execution_count)
	,MemoryWrites		= SUM(qs.max_logical_writes)
	--,DateCached		= qs.creation_time
	,DatabaseName		= DB_Name(qt.dbid)
	,MaxExecutionTime	= Max(qs.max_elapsed_time)
 FROM
	sys.dm_exec_query_stats AS qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
	--CROSS APPLY dbo.FN_Get_Statement_Text(qs.statement_start_offset, qs.statement_end_offset, qt.text) [Stmt]
 WHERE
	qt.dbid = DB_ID('ECARGO')
 --and	qs.execution_count > 1
 AND	qs.query_hash <> 0x0
 GROUP BY qt.objectid, qt.dbid
 --ORDER BY qs.total_elapsed_time/qs.execution_count DESC
 --ORDER BY SUM(qs.total_elapsed_time) / SUM(qs.execution_count) DESC
 ORDER BY Max(qs.max_elapsed_time) Desc

 OPTION(MAXDOP 2)
 
 --SELECT * FROM ECARGO..DDLEvents WHERE EventDate >= GETDATE()-1 AND HostName = HOST_NAME()
 
 --SELECT * FROM ECARGO..DDLEvents WHERE ObjectName = 'SP_040_DELETA_SHIPMENT_COMPLEMENTO'
 
 
 
 RETURN
 
 
 
-- Find queries that have the highest average CPU usage
SELECT TOP 50
	ObjectName          = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
	--,TextData           = qt.text
	,[Stmt].StatementText
	--, qs.query_hash
	,[Stmt].StatementTextXml
	--,qs.statement_start_offset, qs.statement_end_offset
	,DiskReadsAvg		= qs.total_physical_reads / qs.execution_count   -- The worst reads, disk reads
	,MemoryReadsAvg		= qs.total_logical_reads /qs.execution_count    --Logical Reads are memory reads
	,Executions		= qs.execution_count
	,TotalCPUTime		= qs.total_worker_time 
	,AverageCPUTime		= qs.total_worker_time/qs.execution_count
	,DiskWaitAndCPUTimeAvg	= qs.total_elapsed_time / qs.execution_count
	,MemoryWrites		= qs.max_logical_writes
	,DateCached		= qs.creation_time
	,DatabaseName		= DB_Name(qt.dbid)
	,LastExecutionTime	= qs.last_execution_time
 FROM
	sys.dm_exec_query_stats AS qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
	CROSS APPLY dbo.FN_Get_Statement_Text(qs.statement_start_offset, qs.statement_end_offset, qt.text) [Stmt]
 WHERE
	qt.dbid = DB_ID('ECARGO')
 and	qs.execution_count > 1
 AND	qs.query_hash <> 0x0
 ORDER BY qs.total_logical_reads / qs.execution_count desc--qs.total_elapsed_time/qs.execution_count DESC
 OPTION(MAXDOP 2)
 
 --SELECT * FROM ECARGO..DDLEvents WHERE EventDate >= GETDATE()-1 AND HostName = HOST_NAME()
 
 --SELECT * FROM ECARGO..DDLEvents WHERE ObjectName = 'SP_040_DELETA_SHIPMENT_COMPLEMENTO'
 
 
--Por Procedure
-- Find queries that have the highest average CPU usage
SELECT TOP 50
	ObjectName          = OBJECT_SCHEMA_NAME(qs.object_id,database_id) + '.' + OBJECT_NAME(qs.object_id, qs.database_id)
	--,TextData           = qt.text
	--,[Stmt].StatementText
	--, qs.query_hash
	--,[Stmt].StatementTextXml
	--,qs.statement_start_offset, qs.statement_end_offset
	,DiskReadsAvg		= SUM(qs.total_physical_reads) / SUM(qs.execution_count)  -- The worst reads, disk reads
	,MemoryReadsAvg		= SUM(qs.total_logical_reads) / SUM(qs.execution_count)    --Logical Reads are memory reads
	,Executions		= SUM(qs.execution_count)
	,TotalCPUTime		= SUM(qs.total_worker_time)
	,AverageCPUTime		= SUM(qs.total_worker_time) / SUM(qs.execution_count)
	,DiskWaitAndCPUTimeAvg	= SUM(qs.total_elapsed_time) / SUM(qs.execution_count)
	,MemoryWrites		= SUM(qs.max_logical_writes)
	--,DateCached		= qs.creation_time
	,DatabaseName		= DB_Name(qs.database_id)
	,MaxExecutionTime	= Max(qs.max_elapsed_time)
	,qs.type_desc
 FROM
	sys.dm_exec_procedure_stats AS qs
	--CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
	--CROSS APPLY dbo.FN_Get_Statement_Text(qs.statement_start_offset, qs.statement_end_offset, qt.text) [Stmt]
 WHERE
	qs.database_id = DB_ID('ECARGO')
 --and	qs.execution_count > 1
 --AND	qs.query_hash <> 0x0
 --AND	qs.object_id = OBJECT_ID('ECARGO..SP_040_CON_PESQ_NF_CT20')
 --And qs.type_desc != 'SQL_STORED_PROCEDURE'
 GROUP BY qs.object_id, qs.database_id, qs.type_desc
 --ORDER BY qs.total_elapsed_time/qs.execution_count DESC
 ORDER BY SUM(qs.total_logical_reads) / SUM(qs.execution_count) DESC
 --ORDER BY Max(qs.max_elapsed_time) Desc
 OPTION(MAXDOP 2)
 
 
 --Por Trigger
-- Find queries that have the highest average CPU usage
SELECT TOP 50
	ObjectName          = OBJECT_SCHEMA_NAME(qs.object_id,database_id) + '.' + OBJECT_NAME(qs.object_id, qs.database_id)
	--,TextData           = qt.text
	--,[Stmt].StatementText
	--, qs.query_hash
	--,[Stmt].StatementTextXml
	--,qs.statement_start_offset, qs.statement_end_offset
	,DiskReadsAvg		= SUM(qs.total_physical_reads) / SUM(qs.execution_count)  -- The worst reads, disk reads
	,MemoryReadsAvg		= SUM(qs.total_logical_reads) / SUM(qs.execution_count)    --Logical Reads are memory reads
	,Executions		= SUM(qs.execution_count)
	,TotalCPUTime		= SUM(qs.total_worker_time)
	,AverageCPUTime		= SUM(qs.total_worker_time) / SUM(qs.execution_count)
	,DiskWaitAndCPUTimeAvg	= SUM(qs.total_elapsed_time) / SUM(qs.execution_count)
	,MemoryWrites		= SUM(qs.max_logical_writes)
	--,DateCached		= qs.creation_time
	,DatabaseName		= DB_Name(qs.database_id)
	,MaxExecutionTime	= Max(qs.max_elapsed_time)
	,qs.type_desc
 FROM
	sys.dm_exec_trigger_stats AS qs
	--CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
	--CROSS APPLY dbo.FN_Get_Statement_Text(qs.statement_start_offset, qs.statement_end_offset, qt.text) [Stmt]
 WHERE
	qs.database_id = DB_ID('ECARGO')
 --and	qs.execution_count > 1
 --AND	qs.query_hash <> 0x0
 --AND	qs.object_id = OBJECT_ID('ECARGO..SP_040_CON_PESQ_NF_CT20')
 --And qs.type_desc != 'SQL_STORED_PROCEDURE'
 GROUP BY qs.object_id, qs.database_id, qs.type_desc
 --ORDER BY qs.total_elapsed_time/qs.execution_count DESC
 ORDER BY SUM(qs.total_worker_time) / SUM(qs.execution_count) DESC
 --ORDER BY Max(qs.max_elapsed_time) Desc
 OPTION(MAXDOP 2)