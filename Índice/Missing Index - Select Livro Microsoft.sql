SELECT	
	index_advantage,
	Banco		= db_name(database_id), 
	Tabela		= object_name(object_id, database_id), 
	Comando		= 'CREATE INDEX [missing_index_' + CONVERT (varchar, mig.index_group_handle) + '_' + CONVERT (varchar, mid.index_handle) + '_' + LEFT (PARSENAME(mid.statement, 1), 32) + '] ON ' + mid.statement + ' ( ' + IsNull(mid.equality_columns, '') + CASE WHEN mid.inequality_columns IS NULL 
				THEN ''  
			    ELSE CASE WHEN mid.equality_columns IS NULL 
					     THEN ''  
				ELSE ',' END + mid.inequality_columns END + ' ) ' + CASE WHEN mid.included_columns IS NULL 
					THEN ''  
			    ELSE 'INCLUDE (' + mid.included_columns + ')' END + ';',
	*
FROM	(
	SELECT	user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) as index_advantage, migs.*
	From	sys.dm_db_missing_index_group_stats migs
	) as migs_adv
	Inner Join sys.dm_db_missing_index_groups as mig On migs_adv.group_handle = mig.index_group_handle
	Inner Join sys.dm_db_missing_index_details as mid On mig.index_handle = mid.index_handle
Where
	Migs_adv.index_advantage > 50000
And	database_id = db_id()
Order By Migs_adv.index_advantage desc
