SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT TOP 10 
              total_elapsed_time/1000.0 as total_elapsed_time
              ,execution_count
              ,(total_elapsed_time/execution_count)/1000.0 AS [avg_elapsed_time_ms]
              ,last_elapsed_time/1000.0 as last_elapsed_time
              ,total_logical_reads/execution_count AS [avg_logical_reads]
              ,st1.text
              ,qp.query_plan
              ,qs.plan_handle
	      ,Db_Name(qp.dbid)
FROM	sys.dm_exec_query_stats AS qs
	CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) as qp
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st1
--WHERE st1.text like '%sys.sql_modules%'
WHERE execution_count > 5
ORDER BY last_elapsed_time DESC;

--sp_logmsg @texto = 'timeout'

select top 30
	SUBSTRING(st.text, (qs.statement_start_offset/2)+1, 
        ((CASE qs.statement_end_offset
          WHEN -1 THEN DATALENGTH(st.text)
         ELSE qs.statement_end_offset
         END - qs.statement_start_offset)/2) + 1) AS statement_text, 

	(SELECT TOP 1 SUBSTRING(st.text,statement_start_offset / 2+1 , 
	( (CASE WHEN statement_end_offset = -1 
         THEN (LEN(CONVERT(nvarchar(max),st.text)) * 2) 
         ELSE statement_end_offset END)  - statement_start_offset) / 2+1))  AS sql_statement,
	 OBJECT_NAME(st.objectid, st.dbid) [Object_name],
	Db_Name(st.dbid), 
	qp.query_plan, 
	last_elapsed_time /1000000 last_elapsed_time_sec, 
	total_elapsed_time / execution_count as elapsed_time_avg, 
	execution_count, 
	total_elapsed_time, 
	last_logical_reads, 
	last_logical_writes, 
	last_worker_time
FROM	sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) as qp
WHERE execution_count > 5
--AND	st1.text NOT LIKE '%MSPARAM%'
and	st.dbid = db_id('ECARGO')
ORDER BY last_elapsed_time DESC;

