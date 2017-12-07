DECLARE @ownername SYSNAME 
DECLARE @tablename SYSNAME 
DECLARE @statsname SYSNAME 
DECLARE @sql NVARCHAR(4000) 
DECLARE dropstats CURSOR FOR 

SELECT stats.name, objects.name, schemas.name, stats.*
FROM sys.stats		stats
JOIN sys.objects	objects ON stats.OBJECT_ID = objects.OBJECT_ID 
JOIN sys.schemas	schemas ON objects.schema_id = schemas.schema_id 
JOIN sys.tables t		ON objects.OBJECT_ID = t.OBJECT_ID 
WHERE stats.stats_id > 0 
  AND stats.stats_id < 255 
  AND objects.is_ms_shipped = 0 
AND Exists (Select 1 From sys.columns c Where c.Collation_Name is not null And Not c.Collation_Name = 'Latin1_General_CI_AS' And c.object_id = t.object_id)
And t.name not like '%027%'
And t.name not like '%[_]fil[_]%'
And t.name not like 'sysdiagrams'
And t.name not like 'sysssislog'
And stats.name not like '%PK%'
ORDER BY objects.OBJECT_ID, stats.stats_id DESC 

OPEN dropstats 
FETCH NEXT FROM dropstats INTO @statsname, @tablename, @ownername 
WHILE @@fetch_status = 0 
BEGIN 
  SET @sql = N'DROP STATISTICS '+QUOTENAME(@ownername)+'.'+QUOTENAME(@tablename)+'.'+QUOTENAME(@statsname) 
  --EXEC sp_executesql @sql   
  PRINT @sql 
  FETCH NEXT FROM dropstats INTO @statsname, @tablename, @ownername 
END 
CLOSE dropstats 
DEALLOCATE dropstats 