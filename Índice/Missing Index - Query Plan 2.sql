SELECT total_worker_time/execution_count as AvgCPU  
, total_elapsed_time/execution_count as AvgDuration  
, (total_logical_reads+total_physical_reads)/execution_count as AvgReads 
, execution_count   
, substring(st.text, (qs.statement_start_offset/2)+1 , ((case qs.statement_end_offset when -1 then datalength(st.text) else qs.statement_end_offset end - qs.statement_start_offset)/2) + 1) as txt  
, qp.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/@Impact)[1]' , 'decimal(18,4)') * execution_count AS TotalImpact
, qp.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Database)[1]' , 'varchar(100)') AS [Database]
, qp.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Table)[1]' , 'varchar(100)') AS [Table]
    
from sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text(sql_handle) st
cross apply sys.dm_exec_query_plan(plan_handle) qp
where cast(query_plan as varchar(max)) like '%missing%'
order by TotalImpact desc