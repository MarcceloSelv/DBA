SELECT  TOP 10 *
FROM ecargo.sys.dm_exec_query_stats s
   CROSS APPLY ecargo.sys.dm_exec_query_plan(s.plan_handle) AS p
WHERE  p.query_plan.exist(
'declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan";
/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan//MissingIndexes') = 1
AND p.dbid = db_id('ecargo')
ORDER BY s.total_elapsed_time DESC