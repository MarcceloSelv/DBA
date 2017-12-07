Select
	Tabela		= object_name(ius.object_id, ius.database_id), 
	Indice		= 'Drop Index ' + QuoteName(idx.name) + ' ON ' + QuoteName(object_name(ius.object_id, ius.database_id)),
	Colunas		= col.Colunas,
	(ius.user_updates * 1.00000 / (ISNULL(NULLIF(ius.user_seeks + ius.user_scans + ius.user_lookups, 0), 1))),
	*
From
	sys.dm_db_index_usage_stats ius
	Inner Join sys.Indexes Idx on ius.index_id = idx.Index_id And ius.object_id = idx.object_id
	Cross Apply (
		Select	Colunas = REPLACE(
		(	Select	col.name as [data()] 
			From	sys.index_columns ic 
				Inner Join sys.columns col on ic.column_id = col.column_id and col.object_id = ic.object_id
			Where	idx.index_id = ic.Index_id And idx.object_id = ic.object_id
			And	ic.is_included_column = 0
			Order By ic.index_column_id
			For Xml Path('')
		) + IsNull( ' Include: ' +
		(	Select	col.name as [data()] 
			From	sys.index_columns ic 
				Inner Join sys.columns col on ic.column_id = col.column_id and col.object_id = ic.object_id
			Where	idx.index_id = ic.Index_id And idx.object_id = ic.object_id
			And	ic.is_included_column = 1
			Order By ic.index_column_id
			For Xml Path('')
		), '')
		, ' ' , ' | ')
	) as col
where	ius.database_id = db_id('AUTOLOG')
--And	(ius.user_seeks + ius.user_scans + ius.user_lookups) < ius.user_updates
and	ius.object_id = object_id('[TRACKING]')
--And	(ius.user_seeks + ius.user_scans + ius.user_lookups) = 0
And	Type <> 1
Order By 4

--sp_WhoIsActive @get_full_inner_text=0, @get_plans=1, @get_outer_command=1, @get_transaction_info=1, @get_task_info=2, @get_locks=1, @get_additional_info=2, @find_block_leaders=1