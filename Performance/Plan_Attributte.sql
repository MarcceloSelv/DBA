Select Cast(((Cast(135015 as numeric(15,3))/1000)/1000) as numeric(15,3)) AS [Duration (sec)]

SELECT	attribute = '<xmp>' + Cast(pa.attribute as varchar) + '</xmp>',
		value = '<xmp>' + Cast(pa.value as varchar) + '</xmp>',
		ps.max_elapsed_time,
		ps.max_worker_time,
		ps.execution_count,
		ps.cached_time,
		ps.last_execution_time,
		qp.query_plan,
		Opt.*
FROM	sys.dm_exec_procedure_stats ps
		Cross Apply sys.dm_exec_plan_attributes(ps.plan_handle) pa
		Cross Apply sys.dm_exec_query_plan(ps.plan_handle) qp
		Cross Apply dbo.Get_SetOptions(Cast(pa.value as varchar)) Opt
WHERE	ps.object_id = Object_Id('penske..SP_040_INC_NF_EDI_ABS2_v58')
and		pa.attribute = 'set_options'



SELECT
P.plan_handle,
S.statement_start_offset, S.statement_end_offset,
S.plan_generation_num,
S.execution_count,
P.usecounts,
S.creation_time,
S.last_execution_time,
sqlSmt = SUBSTRING(T2.text, (S.statement_start_offset/2) + 1, ((CASE WHEN S.statement_end_offset > 0 THEN S.statement_end_offset ELSE DATALENGTH(T2.text) END - S.statement_start_offset)/2) + 1),
L.query_plan,
TL.query_plan,
obj = OBJECT_NAME(T.objectid),
T.objectid,
P.cacheobjtype,
P.objtype,
T.text
FROM sys.dm_exec_cached_plans P
INNER JOIN sys.dm_exec_query_stats S
ON P.plan_handle = S.plan_handle
OUTER APPLY sys.dm_exec_sql_text(P.plan_handle) T
CROSS APPLY sys.dm_exec_query_plan(P.plan_handle) L
OUTER APPLY sys.dm_exec_sql_text(S.sql_handle) T2
CROSS APPLY sys.dm_exec_text_query_plan (P.plan_handle, DEFAULT, DEFAULT) TL
WHERE P.cacheobjtype = 'Compiled Plan' AND
T.text NOT LIKE '%dm_exec_cached_plans%' AND
P.objtype = 'Proc' AND T.dbid = DB_ID('PENSKE')
AND OBJECT_NAME(T.objectid) = 'PENSKE..SP_040_INC_NF_EDI_ABS2_v58'
ORDER BY P.plan_handle, S.statement_start_offset, S.statement_end_offset