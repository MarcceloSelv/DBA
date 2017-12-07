SELECT TOP 10

    query_hash, query_plan_hash,

    cached_plan_object_count,

    execution_count,

    total_cpu_time_ms, total_elapsed_time_ms,

    total_logical_reads, total_logical_writes, total_physical_reads,

    sample_database_name, sample_object_name,

    sample_statement_text

FROM

(

    SELECT

        query_hash, query_plan_hash,

        COUNT (*) AS cached_plan_object_count,

        MAX (plan_handle) AS sample_plan_handle,

        SUM (execution_count) AS execution_count,

        SUM (total_worker_time)/1000 AS total_cpu_time_ms,

        SUM (total_elapsed_time)/1000 AS total_elapsed_time_ms,

        SUM (total_logical_reads) AS total_logical_reads,

        SUM (total_logical_writes) AS total_logical_writes,

        SUM (total_physical_reads) AS total_physical_reads

    FROM sys.dm_exec_query_stats

    GROUP BY query_hash, query_plan_hash

) AS plan_hash_stats

CROSS APPLY

(

    SELECT --TOP 1

        qs.sql_handle AS sample_sql_handle,

        qs.statement_start_offset AS sample_statement_start_offset,

        qs.statement_end_offset AS sample_statement_end_offset,

        CASE

            WHEN [database_id].value = 32768 THEN 'ResourceDb'

            ELSE DB_NAME (CONVERT (int, [database_id].value))

        END AS sample_database_name,

        OBJECT_NAME (CONVERT (int, [object_id].value), CONVERT (int, [database_id].value)) AS sample_object_name,

        t.StatementTextXml AS sample_statement_text

    FROM sys.dm_exec_sql_text(plan_hash_stats.sample_plan_handle) AS sql 

    INNER JOIN sys.dm_exec_query_stats AS qs ON qs.plan_handle = plan_hash_stats.sample_plan_handle
	
	CROSS APPLY dbo.FN_Get_Statement_Text(qs.statement_start_offset, qs.statement_end_offset, sql.[text]) t

    CROSS APPLY sys.dm_exec_plan_attributes (plan_hash_stats.sample_plan_handle) AS [object_id]

    CROSS APPLY sys.dm_exec_plan_attributes (plan_hash_stats.sample_plan_handle) AS [database_id]
	

    WHERE [object_id].attribute = 'objectid'

        AND [database_id].attribute = 'dbid'

) AS sample_query_text

ORDER BY total_logical_reads / execution_count DESC;