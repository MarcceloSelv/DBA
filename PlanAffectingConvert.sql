;WITH XMLNAMESPACES(DEFAULT
N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT
cp.query_hash, cp.query_plan_hash,
ConvertIssue =
  operators.value('@ConvertIssue','nvarchar(250)'),
Expression =
  operators.value('@Expression','nvarchar(250)'),
  qp.query_plan
FROM sys.dm_exec_query_stats cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
CROSS APPLY query_plan.nodes('//Warnings/PlanAffectingConvert')
  rel(operators)  