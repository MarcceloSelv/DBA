SELECT
	worker_time_avg = qs.total_worker_time/ qs.execution_count,
	physical_reads_avg = qs.total_physical_reads/ qs.execution_count,
	logical_reads_avg = qs.total_logical_reads/ qs.execution_count,
	logical_writes_avg = qs.total_logical_writes/ qs.execution_count,
    --sql_handle, 
    --plan_handle, 
    --execution_count, 
    --total_logical_reads, 
    --total_elapsed_time, 
    --dbid, 
    --objectid
    *
FROM
(
	SELECT TOP 15 
		query_hash
	FROM sys.dm_exec_query_stats AS qs
	--CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp 
	--WHERE query_hash = CONVERT(BINARY(8), CONVERT(BIGINT, 1640387627010439277));
	GROUP BY query_hash
	ORDER BY MAX(qs.total_logical_reads/ qs.execution_count) DESC
) h
INNER JOIN sys.dm_exec_query_stats qs ON qs.query_hash = h.query_hash
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
CROSS APPLY master.dbo.FN_Get_Statement_Text(qs.statement_start_offset, qs.statement_end_offset, st.text) AS t
ORDER BY 2 desc


--SELECT * FROM sys.dm_exec_query_stats WHERE sql_handle = 0x0200000075D05C19CB300FB2B7B3A7C37DB2A7445739F194
--SELECT * FROM sys.dm_exec_query_stats WHERE query_hash = 0x29BEBE55B8586ABC

--SELECT * FROM TraceDuration Where TextData like '%2014%'
