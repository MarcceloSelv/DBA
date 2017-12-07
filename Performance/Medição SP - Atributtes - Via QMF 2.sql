use master

SELECT	Object = OBJECT_NAME(st.objectid, st.dbid), execution_count, elapsed_time = total_elapsed_time / execution_count, worker_time = total_worker_time / execution_count 
, [max_elapsed_time (sec)]= ((Cast(max_elapsed_time as numeric(15,5))/1000)/1000)
, [max_worker_time (sec)]= ((Cast(max_worker_time as numeric(15,5))/1000)/1000)
, [max_physical_reads]= ((Cast(max_physical_reads as numeric(15,5))/1000)/1000)
, [max_logical_reads]= ((Cast(max_logical_reads as numeric(15,5))/1000)/1000)
, [max_logical_writes]= ((Cast(max_logical_writes as numeric(15,5))/1000)/1000)
	--,'<pre>' + st.text + '</pre>'
	,'<xmp>' + Cast([Stmt].StatementText as varchar(max)) + '</xmp>'
	,'<xmp>' + Cast(qpa.value as varchar(max)) + '</xmp>'
	,qpa.attribute
	,Opt.*
FROM	sys.dm_exec_query_stats qs
	CROSS APPLY SYS.dm_exec_sql_text(qs.sql_handle) st
	CROSS APPLY SYS.dm_exec_query_plan(qs.plan_handle) qp
	CROSS APPLY SYS.dm_exec_plan_attributes(qs.plan_handle) qpa
	--Cross apply dbo.Get_SetOptions(Cast(qpa.value as int)) Opt
	CROSS APPLY dbo.FN_Get_Statement_Text(qs.statement_start_offset, qs.statement_end_offset, st.text) [Stmt]
	CROSS APPLY (
		Select Options = Replace ( (Case When ((1 & Cast(qpa.value as int)) = 1) Then 'ANSI_PADDING ' Else '' End +
			Case When  ((4 & Cast(qpa.value as int)) = 4) Then 'FORCEPLAN ' Else '' End +
			Case When  ((8 & Cast(qpa.value as int)) = 8) Then 'CONCAT_NULL_YIELDS_NULL ' Else '' End +
			Case When  ((16 & Cast(qpa.value as int)) = 16) Then 'ANSI_WARNINGS ' Else '' End +
			Case When  ((32 & Cast(qpa.value as int)) = 32) Then 'ANSI_NULLS ' Else '' End +
			Case When  ((64 & Cast(qpa.value as int)) = 64) Then 'QUOTED_IDENTIFIER ' Else '' End +
			Case When  ((128 & Cast(qpa.value as int)) = 128) Then 'ANSI_NULL_DFLT_ON ' Else '' End +
			Case When  ((256 & Cast(qpa.value as int)) = 256) Then 'ANSI_NULL_DFLT_OFF ' Else '' End +
			Case When  ((512 & Cast(qpa.value as int)) = 512) Then 'NoBrowseTable ' Else '' End +
			Case When  ((4096 & Cast(qpa.value as int)) = 4096) Then 'ARITH_ABORT ' Else '' End +
			Case When  ((8192 & Cast(qpa.value as int)) = 8192) Then 'NUMERIC_ROUNDABORT ' Else '' End +
			Case When  ((16384 & Cast(qpa.value as int)) = 16384) Then 'DATEFIRST ' Else '' End +
			Case When  ((32768 & Cast(qpa.value as int)) = 32768) Then 'DATEFORMAT ' Else '' End +
			Case When  ((65536 & Cast(qpa.value as int)) = 65536) Then 'LanguageID ' Else '' End), ' ', '<br/>')
	) Opt
WHERE
	qpa.attribute = 'set_options'
And	st.objectid = object_id('ECARGO..SP_040_CON_EMISSAO_FATURA12')


use master

SELECT	Object = OBJECT_NAME(st.objectid, st.dbid), execution_count, [elapsed_time (sec)] = ((Cast( (total_elapsed_time / execution_count) as numeric(15,5))/1000)/1000), [worker_time (sec)] = ((Cast( (total_worker_time / execution_count) as numeric(15,5))/1000)/1000), [max_elapsed_time (sec)]= ((max_elapsed_time/1000)/1000)
FROM	sys.dm_exec_procedure_stats qs
	OUTER APPLY SYS.dm_exec_sql_text(qs.sql_handle) st
WHERE
	st.objectid = object_id('ECARGO..SP_040_CON_EMISSAO_FATURA12')
--GROUP BY st.objectid, st.dbid



use master

SELECT	Object = OBJECT_NAME(st.objectid, st.dbid), SUM(execution_count), elapsed_time = SUM(total_elapsed_time) / SUM(execution_count), worker_time = SUM(total_worker_time) / SUM(execution_count), max_elapsed_time = sum(max_elapsed_time)
FROM	sys.dm_exec_procedure_stats qs
	OUTER APPLY SYS.dm_exec_sql_text(qs.sql_handle) st
WHERE
	st.objectid = object_id('ECARGO..SP_040_INC_NF_EDI_ABS2_v58')
GROUP BY st.objectid, st.dbid


use master

SELECT	Object = OBJECT_NAME(st.objectid, st.dbid), execution_count, [elapsed_time (sec)] = ((Cast( (total_elapsed_time / execution_count) as numeric(15,5))/1000)/1000), [worker_time (sec)] = ((Cast( (total_worker_time / execution_count) as numeric(15,5))/1000)/1000), [max_elapsed_time (sec)]= ((Cast(max_elapsed_time as numeric(15,5))/1000)/1000)
FROM	sys.dm_exec_procedure_stats qs
	OUTER APPLY SYS.dm_exec_sql_text(qs.sql_handle) st
WHERE
	st.objectid = object_id('ECARGO..SP_040_ALT_STATUS_DCT_PENSKE5')
Order By max_elapsed_time Desc