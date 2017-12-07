--SELECT * FROM master.sys.objects where type = 'fn' order by create_date desc

Select	IsNull('ALTER TABLE ' + QuoteName(Object_Name(col.object_id)) + ' DROP CONSTRAINT ' + QuoteName(chk.name) + Char(13) + Char(10) + 'go' + Char(13) + Char(10), '') 
		+ 'Exec SP_Rename ''dbo.' + Object_Name(col.object_id) + '.' + col.Name + ''', ''' + master.dbo.udf_TitleCase(col.Name) + '''' + ', ''COLUMN''' + Char(13) + Char(10) + 'go' + Char(13) + Char(10) 
		+ IsNull('ALTER TABLE ' + QuoteName(Object_Name(col.object_id)) + ' ADD CONSTRAINT ' + QuoteName(chk.name) + ' CHECK(' + chk.definition + ')' + Char(13) + Char(10) + 'go' + Char(13) + Char(10), '')
From	sys.columns col
		Left Join sys.check_constraints chk ON chk.parent_object_id = col.object_id and chk.parent_column_id = col.column_id And chk.Type = 'c'
Where	col.object_id = Object_id('TABELA')

SP_RENAME_SIG