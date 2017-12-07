Use <DATABASE>
Go
-- VERIFICAR CHECK WITH CHECK

/*
Created By Vimal Lohani
*/
Declare @data nvarchar(max)
-- RECREATE CONSTRAINTS
SELECT ROW_NUMBER() over(order by f.object_id) 'rno', 'ALTER TABLE [' + OBJECT_NAME(f.parent_object_id)+ ']' +
' ADD CONSTRAINT ' + '[' +  f.name  +']'+ ' FOREIGN KEY'+'('+COL_NAME(fc.parent_object_id,fc.parent_column_id)+')'
+'REFERENCES ['+OBJECT_NAME (f.referenced_object_id)+']('+COL_NAME(fc.referenced_object_id,
fc.referenced_column_id)+')' as Scripts
--into #tempcreate
FROM .sys.foreign_keys AS f
INNER JOIN .sys.foreign_key_columns AS fc
ON f.[object_id] = fc.constraint_object_id
WHERE f.parent_object_id = OBJECT_ID('DOCTO_TRANSPORTE' )

-- DROP CONSTRAINTS table 
SELECT ROW_NUMBER() over(order by f.object_id) 'rowno','ALTER TABLE ' + '[' + OBJECT_NAME(f.parent_object_id)+ ']'+
' DROP  CONSTRAINT ' + '[' + f.name  + ']' as dropscript
--into #tempdrop
FROM .sys.foreign_keys AS f
INNER JOIN .sys.foreign_key_columns AS fc
ON f.OBJECT_ID = fc.constraint_object_id
WHERE f.parent_object_id = OBJECT_ID('DOCTO_TRANSPORTE' )
--select * from #tempdrop
--Drop Constraints process
Declare @max int=(Select max(rowno) from #tempdrop)

While(@max > 0)
	Begin
		Select  @data = dropscript From #tempdrop Where rowno = @max
		Exec(@data)
		--PRINT @data
		Set @max=@max-1
	End

--Type your all Truncate Code Here

truncate table [dbo].[fact_Employee]



--Complete Truncate Code


--Create Constraints Process
declare @maxx int=(Select max(rno) from #tempcreate)
		while(@maxx>0)
		Begin
				Select  @data=Scripts from #tempcreate where rno=@maxx
				Exec(@data) 
				--PRINT @data
				Set @maxx=@maxx-1
		End

		drop table #tempdrop
		drop table #tempcreate