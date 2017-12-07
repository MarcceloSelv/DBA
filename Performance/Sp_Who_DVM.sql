Select
	StatementText	= SUBSTRING(st.text, (r.statement_start_offset/2)+1, 
		((CASE r.statement_end_offset
		  WHEN -1 THEN DATALENGTH(st.text)
		 ELSE r.statement_end_offset
		 END - r.statement_start_offset)/2) + 1),
	s.CPU_Time, s.Memory_Usage, s.Total_Scheduled_time, s.Last_Request_Start_Time, s.last_request_end_time, s.reads, s.writes, s.logical_reads, s.status, s.Host_Name, s.program_name, s.client_interface_name, s.login_name, s.is_user_process, st.text, object_name = object_name(st.objectid, st.dbid), r.*
From
	sys.dm_exec_sessions s
	Inner Join sys.dm_exec_requests r on r.session_id = s.session_id
	Outer Apply sys.dm_exec_sql_text (r.sql_handle) st
--Where
--	is_user_process = 1
Order By s.CPU_Time desc


SELECT	OBJECT_NAME(TXT.OBJECTID, DB_ID('PENSKE')), * 
FROM	SYS.dm_exec_procedure_stats stat
	Cross Apply Sys.dm_exec_sql_text(stat.sql_handle) txt
	CROSS APPLY sys.dm_exec_query_plan(stat.plan_handle) AS p
WHERE
	TXT.OBJECTID = OBJECT_ID('PENSKE..SP_040_GERA_DADO_AUDIT_CONEMB')


SELECT	txt.*, p.*
FROM	SYS.dm_exec_query_stats qs
	Cross Apply Sys.dm_exec_sql_text(qs.sql_handle) txt
	OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) AS p
WHERE
	txt.dbid = db_id('PENSKE')
and	txt.text like '%SP_040_GERA_DADO_AUDIT_CONEMB%'

AND	txt.objectid = OBJECT_ID('PENSKE..SP_040_GERA_DADO_AUDIT_CONEMB')