set nocount on
if isnull(object_id('tempdb.dbo.#t'),0)<>0
	drop table #t
create table #t (column1 int,column2 int,column3 int)
declare @i int
set @i=1
while @i<=10
begin
	insert #t select @i,@i+1,@i+2
	set @i=@i+1
end

select * from #t

declare @sql nvarchar(1024)
set @sql='select <%col1%>,<%col2%> from <%table%> where <%col_where_1%>=<%col_where_1_val%>'

declare @keywords table(keyword varchar(255),value varchar(1024))
insert @keywords select 'table','#t'
insert @keywords select 'col1','column1'
insert @keywords select 'col2','column2'
insert @keywords select 'col3','column3'
insert @keywords select 'col_where_1','column3'
insert @keywords select 'col_where_1_val',6
	
select @sql=replace(@sql,'<%'+keyword+'%>',value) from @keywords where charindex('<%'+keyword+'%>',@sql)>1
print @sql
exec sp_executesql @sql
drop table #t
set nocount off

--http://www.sqlservercentral.com/scripts/sp_executesql/109652/