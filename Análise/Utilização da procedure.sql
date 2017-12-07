Select	object_name(object_id, db_id('ECARGO')) [Procedure], execution_count, total_elapsed_time, (total_elapsed_time / execution_count) Average
From	(
	select	object_id, sql_handle
	from	sys.dm_exec_procedure_stats 
	where	database_id = db_id('ECARGO')
	group by object_id, sql_handle
	) as proc_stats
	Cross Apply (Select Sum(execution_count) execution_count, Sum(total_elapsed_time) total_elapsed_time From sys.dm_exec_procedure_stats ps Where ps.object_id = proc_stats.object_id) As St
	Cross apply sys.dm_exec_sql_text(sql_handle) as txt
Where	txt.text like '%tracking%usuario_incl_id%3%'
