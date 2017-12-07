select	OBJECT_NAME(object_id, db_id('mercosul')), 
	SUBSTRING(st.text, (qsta.statement_start_offset/2)+1, 
        ((CASE qsta.statement_end_offset
          WHEN -1 THEN DATALENGTH(st.text)
         ELSE qsta.statement_end_offset
         END - qsta.statement_start_offset)/2) + 1) AS statement_text
from	sys.dm_exec_trigger_stats trg
	Inner join sys.dm_exec_query_stats qsta on qsta.sql_handle = trg.sql_handle
	CROSS APPLY sys.dm_exec_sql_text(trg.sql_handle) AS st
where	database_id = db_id('mercosul') 
ORDER BY trg.total_worker_time/trg.execution_count DESC;


SELECT TOP 5 total_worker_time/execution_count AS [Avg CPU Time],
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1, 
        ((CASE qs.statement_end_offset
          WHEN -1 THEN DATALENGTH(st.text)
         ELSE qs.statement_end_offset
         END - qs.statement_start_offset)/2) + 1) AS statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
where	st.dbid = db_id('mercosul') 
ORDER BY total_worker_time/execution_count DESC;

SELECT TOP 5 d.object_id, d.database_id, DB_NAME(database_id) AS 'database_name', 
    OBJECT_NAME(object_id, database_id) AS 'trigger_name', d.cached_time,
    d.last_execution_time, d.total_elapsed_time, 
    d.total_elapsed_time/d.execution_count AS [avg_elapsed_time], 
    d.last_elapsed_time, d.execution_count
FROM sys.dm_exec_trigger_stats AS d
where	d.database_id = db_id('mercosul') 
ORDER BY [total_worker_time] DESC;


