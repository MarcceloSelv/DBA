-- Find queries that take the most CPU overall
SELECT TOP 10
	ObjectName		= OBJECT_SCHEMA_NAME(qt.objectid,qt.dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
	--,TextData		= qt.text
	,[Stmt].StatementTextXml
	,qs.execution_count
	,DiskReads          	= qs.total_physical_reads/qs.execution_count   -- The worst reads, disk reads
	,MemoryReads        	= qs.total_logical_reads/qs.execution_count    --Logical Reads are memory reads
	,Executions         	= qs.execution_count
	,TotalCPUTime       	= qs.total_worker_time
	,AverageCPUTime     	= qs.total_worker_time/qs.execution_count
	,DiskWaitAndCPUTime 	= qs.total_elapsed_time/qs.execution_count
	,MemoryWrites       	= qs.max_logical_writes
	,DateCached         	= qs.creation_time
	,DatabaseName       	= DB_Name(qt.dbid)
	,LastExecutionTime  	= qs.last_execution_time
	,qp.query_plan
FROM
	sys.dm_exec_query_stats AS qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
	CROSS APPLY dbo.FN_Get_Statement_Text(qs.statement_start_offset, qs.statement_end_offset, qt.text) [Stmt]
	--CROSS APPLY sys.dm_exec_query_memory_grants mg
	CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
	--CROSS APPLY sys.dm_exec_plan_attributes(qs.sql_handle) pa
	--CROSS APPLY (
	--	Select SUBSTRING(qt.text, (qs.statement_start_offset / 2) + 1, 
	--				  (CASE qs.statement_end_offset 
	--				     WHEN -1 THEN DATALENGTH(qt.text) 
	--				     ELSE qs.statement_end_offset 
	--				   END - qs.statement_start_offset) / 2 + 1) as [processing-instruction(x)]
	--	FOR XML PATH('')
	-- ) [Stmt](StatementText)
WHERE 
	qt.dbid = DB_ID('ECARGO')
And	qs.execution_count > 20
ORDER BY 
	qs.total_logical_reads/qs.execution_count DESC
 
-- Find queries that have the highest average CPU usage
SELECT TOP 50
	ObjectName          = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
	--,TextData           = qt.text
	,[Stmt].StatementText
	,DiskReads          = qs.total_physical_reads   -- The worst reads, disk reads
	,MemoryReads        = qs.total_logical_reads    --Logical Reads are memory reads
	,Executions         = qs.execution_count
	,TotalCPUTime       = qs.total_worker_time
	,AverageCPUTime     = qs.total_worker_time/qs.execution_count
	,DiskWaitAndCPUTime = qs.total_elapsed_time
	,MemoryWrites       = qs.max_logical_writes
	,DateCached         = qs.creation_time
	,DatabaseName       = DB_Name(qt.dbid)
	,LastExecutionTime  = qs.last_execution_time
 FROM	sys.dm_exec_query_stats AS qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
	CROSS APPLY dbo.FN_Get_Statement_Text(qs.statement_start_offset, qs.statement_end_offset, qt.text) [Stmt]
 WHERE qt.dbid = DB_ID('ECARGO')
 ORDER BY qs.total_worker_time/qs.execution_count DESC
 

 SELECT
	StatementText	= SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1, 
				  (CASE qs.statement_end_offset 
				     WHEN -1 THEN DATALENGTH(st.text) 
				     ELSE qs.statement_end_offset 
				   END - qs.statement_start_offset) / 2 + 1),
	(qs.total_worker_time / qs.execution_count), pp.query_plan, st.*, qs.*
 FROM	SYS.dm_exec_procedure_stats ps
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(ps.sql_handle) st
	INNER JOIN SYS.dm_exec_query_stats qs ON qs.sql_handle = ps.sql_handle
	OUTER APPLY ECARGO.SYS.dm_exec_query_plan(qs.plan_handle) pp
 WHERE	ps.DATABASE_ID = DB_ID('ECARGO') 
 AND	ps.object_id = object_id('ECARGO..SP_040_CON_DADOS_DIVERGENCIA4')
 ORDER BY (qs.total_worker_time / qs.execution_count) desc
