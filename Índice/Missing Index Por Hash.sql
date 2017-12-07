DROP TABLE #MissingIndexInfo

;WITH XMLNAMESPACES  
   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
    
SELECT query_plan, 
       n.value('(@StatementText)[1]', 'VARCHAR(4000)') AS sql_text, 
       n.value('(//MissingIndexGroup/@Impact)[1]', 'FLOAT') AS Impact, 
       DB_ID(REPLACE(REPLACE(n.value('(//MissingIndex/@Database)[1]', 'VARCHAR(128)'),'[',''),']','')) AS database_id, 
       OBJECT_ID(n.value('(//MissingIndex/@Database)[1]', 'VARCHAR(128)') + '.' + 
           n.value('(//MissingIndex/@Schema)[1]', 'VARCHAR(128)') + '.' + 
           n.value('(//MissingIndex/@Table)[1]', 'VARCHAR(128)')) AS OBJECT_ID, 
       n.value('(//MissingIndex/@Database)[1]', 'VARCHAR(128)') + '.' + 
           n.value('(//MissingIndex/@Schema)[1]', 'VARCHAR(128)') + '.' + 
           n.value('(//MissingIndex/@Table)[1]', 'VARCHAR(128)')  
       AS statement, 
       (   SELECT DISTINCT c.value('(@Name)[1]', 'VARCHAR(128)') + ', ' 
           FROM n.nodes('//ColumnGroup') AS t(cg) 
           CROSS APPLY cg.nodes('Column') AS r(c) 
           WHERE cg.value('(@Usage)[1]', 'VARCHAR(128)') = 'EQUALITY' 
           FOR  XML PATH('') 
       ) AS equality_columns, 
        (  SELECT DISTINCT c.value('(@Name)[1]', 'VARCHAR(128)') + ', ' 
           FROM n.nodes('//ColumnGroup') AS t(cg) 
           CROSS APPLY cg.nodes('Column') AS r(c) 
           WHERE cg.value('(@Usage)[1]', 'VARCHAR(128)') = 'INEQUALITY' 
           FOR  XML PATH('') 
       ) AS inequality_columns, 
       (   SELECT DISTINCT c.value('(@Name)[1]', 'VARCHAR(128)') + ', ' 
           FROM n.nodes('//ColumnGroup') AS t(cg) 
           CROSS APPLY cg.nodes('Column') AS r(c) 
           WHERE cg.value('(@Usage)[1]', 'VARCHAR(128)') = 'INCLUDE' 
           FOR  XML PATH('') 
       ) AS include_columns,
	   QueryHash = Convert(binary(8), n.value('(@QueryHash)[1]', 'VARCHAR(4000)'), 1),
	   QueryPlanHash = Convert(binary(8), n.value('(@QueryPlanHash)[1]', 'VARCHAR(4000)'), 1),
	   StatementType = n.value('(@StatementType)[1]', 'VARCHAR(4000)')
INTO #MissingIndexInfo 
FROM  
( 
   SELECT query_plan 
   FROM (    
           SELECT DISTINCT plan_handle 
           FROM sys.dm_exec_query_stats WITH(NOLOCK)  
         ) AS qs 
       OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) tp     
   WHERE tp.query_plan.exist('//MissingIndex')=1 
) AS tab (query_plan) 
CROSS APPLY query_plan.nodes('//StmtSimple') AS q(n) 
WHERE n.exist('QueryPlan/MissingIndexes') = 1

-- Trim trailing comma from lists 
UPDATE #MissingIndexInfo 
SET equality_columns = LEFT(equality_columns,LEN(equality_columns)-1), 
	inequality_columns = LEFT(inequality_columns,LEN(inequality_columns)-1), 
	include_columns = LEFT(include_columns,LEN(include_columns)-1) 
   
--Drop table MissingIndexInfo
--Alter Table #MissingIndexInfo Alter column QueryHash Binary(8)

--Select count(*) From #MissingIndexInfo
--Select top 1 * From #MissingIndexInfo

--Select top 5 *
----Into	MissingIndexInfo
--From	#MissingIndexInfo

SELECT top 30 Object_name = OBJECT_NAME(object_id, database_id), M.QueryHash, QueryPlanHash, Texto = dbo.UDF_Get_DataXml(m.sql_text), m.Impact, m.StatementType, qs.*, qsp.execution_count--, m.query_plan
Into	MissingIndexInfo
FROM	#MissingIndexInfo M
		Outer Apply (
			Select	worker_time = Sum(qs.total_worker_time/ qs.execution_count),
					physical_reads = Sum(qs.total_physical_reads/ qs.execution_count),
					logical_reads = Sum(qs.total_logical_reads/ qs.execution_count),
					elapsed_time = Sum(qs.total_elapsed_time/ qs.execution_count),
					execution_count = Sum(qs.execution_count)
			From	sys.dm_exec_query_stats AS qs 
			Where	qs.Query_Hash = Convert(binary(8), M.QueryHash, 1)
			Group By qs.Query_Hash
		) qs
		Outer Apply (
			Select	execution_count = Sum(qs.execution_count)
			From	sys.dm_exec_query_stats AS qs 
			Where	qs.Query_Hash = M.QueryHash
			--And		Convert(binary(8), M.QueryPlanHash, 1) = qs.query_plan_hash
			And		M.QueryPlanHash = qs.query_plan_hash
		) qsp
		--left Join sys.dm_exec_query_stats AS qsp on qsp.Query_Plan_Hash = Convert(binary(8), M.QueryPlanHash, 1)
Where	database_id = 5
Order By logical_reads Desc

--DROP TABLE #MissingIndexInfo