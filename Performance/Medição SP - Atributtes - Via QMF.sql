use master

SELECT	top 50 Object = OBJECT_NAME(st.objectid, st.dbid), execution_count, elapsed_time = total_elapsed_time / execution_count, worker_time = total_worker_time / execution_count 
	--,'<pre>' + st.text + '</pre>'
	,'<pre>' + Replace(Replace([Stmt].StatementText, '<?x', ''), '?>', '') + '</pre>'
	--ts.plan_handle,
--	,qp.query_plan
	,'<pre>' + Cast(qpa.value as varchar(max)) + '</pre>'
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
And	st.objectid = object_id('ECARGO..SP_040_INC_NF_EDI_ABS2_v58')