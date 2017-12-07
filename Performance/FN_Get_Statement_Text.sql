ALTER FUNCTION FN_Get_Statement_Text(@statement_start_offset int, @statement_end_offset int, @text varchar(max))
Returns Table
as
Return	
	Select 
		StatementTextXml = Cast(StatementText As Xml),
		StatementText	 = StatementText
	From
		(
		Select Case
				When @statement_end_offset > 0 Then
				Substring
				(@text, 
				(@statement_start_offset / 2) + 1, 
				(CASE @statement_end_offset 
					WHEN -1 THEN DATALENGTH(@text) 
					ELSE @statement_end_offset 
				 END - @statement_start_offset) / 2 + 1)
			Else @text
			End as [processing-instruction(x)]
		FOR XML PATH('')
		) t(StatementText)