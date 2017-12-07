WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
SELECT  stmt.StatementTextXml, qs.total_worker_time / qs.execution_count , *
FROM    (
    SELECT  TOP 500 *
    FROM    sys.dm_exec_query_stats
    ORDER BY total_worker_time DESC
) AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
CROSS APPLY dbo.FN_Get_Statement_Text(qs.statement_start_offset, qs.statement_end_offset, st.text) [Stmt]
WHERE qp.query_plan.exist('//p:StmtSimple/@StatementOptmEarlyAbortReason[.="TimeOut"]') = 1
order by qs.total_worker_time / qs.execution_count 