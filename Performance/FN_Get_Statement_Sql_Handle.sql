CREATE FUNCTION FN_Get_Statement_Sql_Handle(@statement_start_offset int, @statement_end_offset int, @sql_Handle varbinary(max))
Returns Table
as
Return
	Select 
		StatementTextXml = Cast(txt.Stmt As Xml),
		StatementText	 = txt.Stmt
	From
		(
		Select Case
				When @statement_end_offset > 0 Then
				Substring
				(st.text, 
				(@statement_start_offset / 2) + 1, 
				(CASE @statement_end_offset 
					WHEN -1 THEN DATALENGTH(st.text)
					ELSE @statement_end_offset 
				 END - @statement_start_offset) / 2 + 1)
			Else st.text
			End as [processing-instruction(x)]
		From
			 sys.dm_exec_sql_text(@sql_Handle) st
		FOR XML PATH('')
		) t(StatementText)
		Cross Apply(Select Stmt = Replace(Replace(StatementText, '<?x', ''), '?>', '') ) txt
 
 
 
 
go
 
