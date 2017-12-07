select	object_name(sm.object_id)-- top 5 * 
from	sys.dm_exec_query_stats qs 
		cross apply sys.dm_exec_sql_text(qs.sql_handle) st
		inner join sys.sql_modules sm on sm.object_id = st.objectid
where st.dbid = db_id()
and	sm.definition like '%SAOVW312%'
