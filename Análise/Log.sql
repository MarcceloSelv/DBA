

use master
SELECT instance_name AS DatabaseName,
       [Data File(s) Size (KB)] as 'dbfilekb',
       [LOG File(s) Size (KB)] as 'logfilesizekb',
       [Log File(s) Used Size (KB)] as 'logfileusage',
       [Percent Log Used]
          into LogUsage
FROM
(
   SELECT *
   FROM sys.dm_os_performance_counters
   WHERE counter_name IN
   (
       'Data File(s) Size (KB)',
       'Log File(s) Size (KB)',
       'Log File(s) Used Size (KB)',
       'Percent Log Used'
   )
     AND instance_name != '_Total'
) AS Src
PIVOT
(
   MAX(cntr_value)
   FOR counter_name IN
   (
       [Data File(s) Size (KB)],
       [LOG File(s) Size (KB)],
       [Log File(s) Used Size (KB)],
       [Percent Log Used]
   )
) AS pvt

Select * from LogUsage



--Generiere Script um Logfiles zu shrinken
declare @DatabaseName varchar(255)
declare @logfilename varchar(255)
declare c cursor for Select DatabaseName,m.name
from LogUsage l join sys.master_files m on l.DatabaseName = DB_NAME(m.database_id) where type_desc = 'LOG'
and Databasename not in ('master','model','msdb','tempdb')
open c
fetch next from c into @DatabaseName,@logfilename
while @@FETCH_STATUS = 0
begin
       print 'USE [' + RTRIM(LTRIM(@DatabaseName)) + ']'
       print 'GO'
       print 'DBCC SHRINKFILE (N'''+@logfilename+''', 0, TRUNCATEONLY)'
       print 'GO'
  fetch next from c into @DatabaseName,@logfilename
end
close c
deallocate c
 
--Generiere Script um die Logfiles neu zu sizen:
 
declare @DatabaseName varchar(255)
declare @logfilename varchar(255)
declare @newsize varchar(255)
declare c cursor for Select DatabaseName,m.name,logfilesizekb*1.2
from LogUsage l join sys.master_files m on l.DatabaseName = DB_NAME(m.database_id) where type_desc = 'LOG'
and Databasename not in ('master','model','msdb','tempdb')
open c
fetch next from c into @DatabaseName,@logfilename,@newsize
while @@FETCH_STATUS = 0
begin
print 'USE [' + RTRIM(LTRIM(@DatabaseName)) + ']'
print 'GO'
print 'ALTER DATABASE ['+RTRIM(LTRIM(@DatabaseName)) +'] MODIFY FILE ( NAME = N'''+@logfilename+''', SIZE = '+@newsize+'KB )'
print 'GO'   
  fetch next from c into @DatabaseName,@logfilename,@newsize
end
close c
deallocate c