SELECT	OBJECT_NAME(TXT.OBJECTID, DB_ID('ECARGO')), * 
FROM	SYS.dm_exec_procedure_stats stat
	Cross Apply Sys.dm_exec_sql_text(stat.sql_handle) txt
	CROSS APPLY sys.dm_exec_query_plan(stat.plan_handle) AS p
WHERE
	TXT.OBJECTID = OBJECT_ID('ECARGO..SP_040_MON_LISTA_CONHEC_VFRETE22')

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
 And	OBJECT_NAME(qt.objectid, qt.dbid) = 'SP_040_BATCH_AGENDA_GERACAO_SVM'
 ORDER BY qs.total_logical_reads / qs.execution_count desc--qs.total_elapsed_time/qs.execution_count DESC