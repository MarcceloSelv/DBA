/*

Leia:

			Execute no management Studio gerando arquivo texto

		O script deve levar em média 10 min para ser gerado dependendo do servidor.

*/

SET NOCOUNT ON

-- view results in text, to make copying and pasting easier
-- Drop Check Constraints
SELECT
    'ALTER TABLE  ' +
     QuoteName(OBJECT_NAME(so.parent_obj)) +
     CHAR(10) +
     ' DROP CONSTRAINT ' +
     QuoteName(CONSTRAINT_NAME) + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10)
 FROM
     INFORMATION_SCHEMA.CHECK_CONSTRAINTS cc
     INNER JOIN sys.sysobjects so
     ON cc.CONSTRAINT_NAME = so.[name]

GO
/*  Functions - Podem haver mais  */

--DROP TABLE #FUNCTION_IDS

IF OBJECT_ID('tempdb..#FUNCTION_IDS') IS NOT NULL
BEGIN
    DROP TABLE #FUNCTION_IDS
END

SELECT	O.OBJECT_ID
INTO 	#FUNCTION_IDS
FROM	sys.objects o
Where	O.type IN ('FN', 'IF', 'TF')
And	Exists(Select 1 From sys.parameters p Inner Join sys.types t On T.User_Type_Id = p.User_Type_Id Where T.collation_name is not null And o.object_id = p.object_id And p.is_output = 1)

SELECT	'DROP FUNCTION ' + QUOTENAME(Schema_Name(schema_id)) + '.' + QUOTENAME(NAME) + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10)
FROM	SYS.OBJECTS O
WHERE	EXISTS(SELECT 1 FROM #FUNCTION_IDS F WHERE F.OBJECT_ID = O.OBJECT_ID)

GO

SET NOCOUNT ON

DECLARE @COLLATE_DESTINO VARCHAR(100) = 'SQL_Latin1_General_CP1_CI_AS'

SELECT ' DROP INDEX ' +  QUOTENAME(I.name) + ' ON '  +   
    Schema_name(T.Schema_id)+'.'+ QUOTENAME(T.name) + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10)
FROM sys.indexes I    
 JOIN sys.tables T ON T.Object_id = I.Object_id     
 JOIN sys.sysindexes SI ON I.Object_id = SI.id AND I.index_id = SI.indid    
 JOIN (SELECT * FROM (   
    SELECT IC2.object_id , IC2.index_id ,   
        STUFF((SELECT ' , ' + C.name + CASE WHEN MAX(CONVERT(INT,IC1.is_descending_key)) = 1 THEN ' DESC ' ELSE ' ASC ' END 
    FROM sys.index_columns IC1   
    JOIN Sys.columns C    
       ON C.object_id = IC1.object_id    
       AND C.column_id = IC1.column_id    
       AND IC1.is_included_column = 0   
    WHERE IC1.object_id = IC2.object_id    
       AND IC1.index_id = IC2.index_id    
    GROUP BY IC1.object_id,C.name,index_id   
    ORDER BY MAX(IC1.key_ordinal)   
       FOR XML PATH('')), 1, 2, '') KeyColumns    
    FROM sys.index_columns IC2    
    --WHERE IC2.Object_id = object_id('Person.Address') --Comment for all tables   
    GROUP BY IC2.object_id ,IC2.index_id) tmp3 )tmp4    
  ON I.object_id = tmp4.object_id AND I.Index_id = tmp4.index_id   
 JOIN sys.stats ST ON ST.object_id = I.object_id AND ST.stats_id = I.index_id    
 JOIN sys.data_spaces DS ON I.data_space_id=DS.data_space_id    
 JOIN sys.filegroups FG ON I.data_space_id=FG.data_space_id    
 LEFT JOIN (SELECT * FROM (    
    SELECT IC2.object_id , IC2.index_id ,    
        STUFF((SELECT ' , ' + C.name  
    FROM sys.index_columns IC1    
    JOIN Sys.columns C     
       ON C.object_id = IC1.object_id     
       AND C.column_id = IC1.column_id     
       AND IC1.is_included_column = 1    
    WHERE IC1.object_id = IC2.object_id     
       AND IC1.index_id = IC2.index_id     
    GROUP BY IC1.object_id,C.name,index_id    
       FOR XML PATH('')), 1, 2, '') IncludedColumns     
   FROM sys.index_columns IC2     
   --WHERE IC2.Object_id = object_id('Person.Address') --Comment for all tables    
   GROUP BY IC2.object_id ,IC2.index_id) tmp1    
   WHERE IncludedColumns IS NOT NULL ) tmp2     
ON tmp2.object_id = I.object_id AND tmp2.index_id = I.index_id    
WHERE I.is_primary_key = 0 AND I.is_unique_constraint = 0 
--AND I.Object_id = object_id('Person.Address') --Comment for all tables  
--AND I.name = 'IX_Address_PostalCode' --comment for all indexes  
AND Exists (Select 1 From sys.columns c Where c.Collation_Name is not null And Not c.Collation_Name = @COLLATE_DESTINO And c.object_id = t.object_id)
And t.name not like '%027%'
And t.name not like '%[_]fil[_]%'
And t.name not like 'sysdiagrams'
And t.name not like 'sysssislog'
And t.schema_id = 1
And Exists (	SELECT 1
		from information_schema.columns isc
		WHERE isc.table_name = t.name 
		AND  (isc.Data_Type LIKE '%char%' OR isc.Data_Type LIKE '%text%')
		AND isc.COLLATION_NAME <> @COLLATE_DESTINO)


GO


DECLARE @TableName nvarchar(255)
DECLARE MyTableCursor Cursor
FOR 
SELECT name FROM sys.tables WHERE [type] = 'U' and name <> 'sysdiagrams' ORDER BY name 
OPEN MyTableCursor

FETCH NEXT FROM MyTableCursor INTO @TableName
WHILE @@FETCH_STATUS = 0
    BEGIN
     EXEC ScriptDropTableKeys @TableName

    FETCH NEXT FROM MyTableCursor INTO @TableName
END
CLOSE MyTableCursor
DEALLOCATE MyTableCursor

GO


DECLARE @ownername SYSNAME 
DECLARE @tablename SYSNAME 
DECLARE @statsname SYSNAME 
DECLARE @sql NVARCHAR(4000) 
DECLARE dropstats CURSOR FOR 

SELECT stats.name, objects.name, schemas.name--, stats.*
FROM sys.stats		stats
JOIN sys.objects	objects ON stats.OBJECT_ID = objects.OBJECT_ID 
JOIN sys.schemas	schemas ON objects.schema_id = schemas.schema_id 
JOIN sys.tables t		ON objects.OBJECT_ID = t.OBJECT_ID 
WHERE stats.stats_id > 0 
  AND stats.stats_id < 255 
  AND objects.is_ms_shipped = 0 
AND Exists (Select 1 From sys.columns c Where c.Collation_Name is not null And Not c.Collation_Name = 'SQL_Latin1_General_CP1_CI_AS' And c.object_id = t.object_id)
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
  SET @sql = N'DROP STATISTICS '+QUOTENAME(@ownername)+'.'+QUOTENAME(@tablename)+'.'+QUOTENAME(@statsname)+ CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10)
  --EXEC sp_executesql @sql   
  PRINT @sql 
  FETCH NEXT FROM dropstats INTO @statsname, @tablename, @ownername 
END 
CLOSE dropstats 
DEALLOCATE dropstats 


GO

--- SCRIPT TO GENERATE THE CREATION SCRIPT OF ALL UNIQUE CONSTRAINTS.
declare @SchemaName varchar(100)
declare @TableName varchar(256)
declare @IndexName varchar(256)
declare @ColumnName varchar(100)
declare @is_unique_constraint varchar(100)
declare @IndexTypeDesc varchar(100)
declare @FileGroupName varchar(100)
declare @is_disabled varchar(100)
declare @IndexOptions varchar(max)
declare @IndexColumnId int
declare @IsDescendingKey int 
declare @IsIncludedColumn int
declare @TSQLScripCreationIndex varchar(max)
declare @TSQLScripDisableIndex varchar(max)
declare @is_primary_key varchar(100)

declare CursorIndex cursor for
 select schema_name(t.schema_id) [schema_name], t.name, ix.name,
 case when ix.is_unique_constraint = 1 then ' UNIQUE ' else '' END 
    ,case when ix.is_primary_key = 1 then ' PRIMARY KEY ' else '' END 
 , ix.type_desc,
  case when ix.is_padded=1 then 'PAD_INDEX = ON, ' else 'PAD_INDEX = OFF, ' end
 + case when ix.allow_page_locks=1 then 'ALLOW_PAGE_LOCKS = ON, ' else 'ALLOW_PAGE_LOCKS = OFF, ' end
 + case when ix.allow_row_locks=1 then  'ALLOW_ROW_LOCKS = ON, ' else 'ALLOW_ROW_LOCKS = OFF, ' end
 + case when INDEXPROPERTY(t.object_id, ix.name, 'IsStatistics') = 1 then 'STATISTICS_NORECOMPUTE = ON, ' else 'STATISTICS_NORECOMPUTE = OFF, ' end
 + case when ix.ignore_dup_key=1 then 'IGNORE_DUP_KEY = ON, ' else 'IGNORE_DUP_KEY = OFF, ' end
 + 'SORT_IN_TEMPDB = OFF' + Case When ix.fill_factor > 0 Then ', FILLFACTOR =' + CAST(ix.fill_factor AS VARCHAR(3)) ELSE '' END  + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10) AS IndexOptions
 , FILEGROUP_NAME(ix.data_space_id) FileGroupName
 from sys.tables t 
 inner join sys.indexes ix on t.object_id=ix.object_id
 where ix.type >0 and  (ix.is_unique_constraint=1) --and schema_name(tb.schema_id)= @SchemaName and tb.name=@TableName
 and t.is_ms_shipped=0 and t.name<>'sysdiagrams'
 order by schema_name(t.schema_id), t.name, ix.name
open CursorIndex
fetch next from CursorIndex into  @SchemaName, @TableName, @IndexName, @is_unique_constraint, @is_primary_key, @IndexTypeDesc, @IndexOptions, @FileGroupName
while (@@fetch_status=0)
begin
 declare @IndexColumns varchar(max)
 declare @IncludedColumns varchar(max)
 set @IndexColumns=''
 set @IncludedColumns=''
 declare CursorIndexColumn cursor for 
 select col.name, ixc.is_descending_key, ixc.is_included_column
 from sys.tables tb 
 inner join sys.indexes ix on tb.object_id=ix.object_id
 inner join sys.index_columns ixc on ix.object_id=ixc.object_id and ix.index_id= ixc.index_id
 inner join sys.columns col on ixc.object_id =col.object_id  and ixc.column_id=col.column_id
 where ix.type>0 and (ix.is_primary_key=1 or ix.is_unique_constraint=1)
 and schema_name(tb.schema_id)=@SchemaName and tb.name=@TableName and ix.name=@IndexName
 order by ixc.index_column_id
 open CursorIndexColumn 
 fetch next from CursorIndexColumn into  @ColumnName, @IsDescendingKey, @IsIncludedColumn
 while (@@fetch_status=0)
 begin
  if @IsIncludedColumn=0 
    set @IndexColumns=@IndexColumns + @ColumnName  + case when @IsDescendingKey=1  then ' DESC, ' else  ' ASC, ' end
  else 
   set @IncludedColumns=@IncludedColumns  + @ColumnName  +', ' 
     
  fetch next from CursorIndexColumn into @ColumnName, @IsDescendingKey, @IsIncludedColumn
 end
 close CursorIndexColumn
 deallocate CursorIndexColumn
 set @IndexColumns = substring(@IndexColumns, 1, len(@IndexColumns)-1)
 set @IncludedColumns = case when len(@IncludedColumns) >0 then substring(@IncludedColumns, 1, len(@IncludedColumns)-1) else '' end
--  print @IndexColumns
--  print @IncludedColumns

set @TSQLScripCreationIndex =''
set @TSQLScripDisableIndex =''
set  @TSQLScripCreationIndex='ALTER TABLE '+  QUOTENAME(@SchemaName) +'.'+ QUOTENAME(@TableName)+ ' DROP CONSTRAINT ' +  QUOTENAME(@IndexName) + ';'  

print @TSQLScripCreationIndex + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10)
print @TSQLScripDisableIndex

fetch next from CursorIndex into  @SchemaName, @TableName, @IndexName, @is_unique_constraint, @is_primary_key, @IndexTypeDesc, @IndexOptions, @FileGroupName

end
close CursorIndex
deallocate CursorIndex


GO
PRINT 'ALTER DATABASE ' + QuoteName(db_name()) + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE' + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10)

PRINT 'ALTER DATABASE ' + QuoteName(db_name()) + ' COLLATE SQL_Latin1_General_CP1_CI_AS' + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10)

PRINT 'ALTER DATABASE ' + QuoteName(db_name()) + ' SET MULTI_USER WITH ROLLBACK IMMEDIATE' + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10)
GO



Declare @TableName Varchar(300),
	@CollationName Varchar(50) = 'SQL_Latin1_General_CP1_CI_AS',
	@ColumnName Varchar(100),
	@DataType Varchar(100),
	@CharacterMaxLen int,
	@IsNullable varchar(10),
	@SQLText Varchar(max),
	@TableNamed Varchar(300)

Declare MyTableCursor Cursor Local For

Select Name, QuoteName(SCHEMA_NAME(t.schema_id)) + '.' + QuoteName(Name)
From sys.tables t
Where Exists (Select 1 From sys.columns c Where c.Collation_Name is not null And Not c.Collation_Name = @CollationName And c.object_id = t.object_id)
And t.name not like '%027%'
And t.name not like '%[_]fil[_]%'
And t.name not like 'sysdiagrams'
And t.name not like 'sysssislog'
And t.schema_id = 1
order by 1

OPEN MyTableCursor

FETCH NEXT FROM MyTableCursor INTO @TableName, @TableNamed
WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE MyColumnCursor Cursor
        FOR 
        SELECT COLUMN_NAME,DATA_TYPE, CHARACTER_MAXIMUM_LENGTH,
            IS_NULLABLE from information_schema.columns
            WHERE table_name = @TableName AND  (Data_Type LIKE '%char%' 
            OR Data_Type LIKE '%text%') AND COLLATION_NAME <> @CollationName
            ORDER BY ordinal_position 
        Open MyColumnCursor

        FETCH NEXT FROM MyColumnCursor INTO @ColumnName, @DataType, 
              @CharacterMaxLen, @IsNullable
        WHILE @@FETCH_STATUS = 0
            BEGIN
            SET @SQLText = 'ALTER TABLE ' + @TableNamed + ' ALTER COLUMN [' + @ColumnName + '] ' + 
              Replace(@DataType, 'text', 'varchar') + '(' + CASE WHEN @CharacterMaxLen in ( -1, 1073741823, 2147483647) THEN 'MAX' ELSE Cast(@CharacterMaxLen as varchar) END + 
              ') COLLATE ' + @CollationName + ' ' + 
              CASE WHEN @IsNullable = 'NO' THEN 'NOT NULL' ELSE 'NULL' END

            PRINT @SQLText + Char(13) + Char(10) + 'go' + Char(13) + Char(10)

        FETCH NEXT FROM MyColumnCursor INTO @ColumnName, @DataType, 
              @CharacterMaxLen, @IsNullable
        END
        CLOSE MyColumnCursor
        DEALLOCATE MyColumnCursor

FETCH NEXT FROM MyTableCursor INTO @TableName, @TableNamed
END
CLOSE MyTableCursor
DEALLOCATE MyTableCursor

GO

DECLARE @TableName nvarchar(255)
DECLARE MyTableCursor Cursor
FOR 
SELECT top 50 name FROM sys.tables WHERE [type] = 'U' and name <> 'sysdiagrams' ORDER BY name 
OPEN MyTableCursor

FETCH NEXT FROM MyTableCursor INTO @TableName
WHILE @@FETCH_STATUS = 0
    BEGIN
    EXEC ScriptCreateTableKeys @TableName

    FETCH NEXT FROM MyTableCursor INTO @TableName
END
CLOSE MyTableCursor
DEALLOCATE MyTableCursor

GO

DECLARE @SQLTEXT VARCHAR(MAX); SET @SQLTEXT = ''

SELECT	@SQLTEXT = @SQLTEXT + ' EXEC SP_HELPTEXT_SIG ''' + NAME + ''' ' + CHAR(13) + CHAR(10) --+ 'GO' + CHAR(13) + CHAR(10)
--SELECT	@SQLTEXT = @SQLTEXT + ' EXEC SP_HELPTEXT_SIG ''' + QUOTENAME(Schema_Name(schema_id)) + '.' + QUOTENAME(NAME) + ''' ' + CHAR(13) + CHAR(10) --+ 'GO' + CHAR(13) + CHAR(10)
FROM	SYS.OBJECTS O
WHERE	EXISTS(SELECT 1 FROM #FUNCTION_IDS F WHERE F.OBJECT_ID = O.OBJECT_ID)

EXEC (@SQLTEXT)

--DROP TABLE #FUNCTION_IDS
GO


 -- Recreate Check Constraints
 SELECT
     'ALTER TABLE  ' +
     QuoteName(OBJECT_NAME(so.parent_obj)) +
     CHAR(10) +
     ' ADD CONSTRAINT ' +
     QuoteName(CONSTRAINT_NAME) +
     ' CHECK ' +
     CHECK_CLAUSE + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10)
 FROM
     INFORMATION_SCHEMA.CHECK_CONSTRAINTS cc
     INNER JOIN sys.sysobjects so
     ON cc.CONSTRAINT_NAME = so.[name]
GO
--- SCRIPT TO GENERATE THE CREATION SCRIPT OF ALL PK AND UNIQUE CONSTRAINTS.
declare @SchemaName varchar(100)
declare @TableName varchar(256)
declare @IndexName varchar(256)
declare @ColumnName varchar(100)
declare @is_unique_constraint varchar(100)
declare @IndexTypeDesc varchar(100)
declare @FileGroupName varchar(100)
declare @is_disabled varchar(100)
declare @IndexOptions varchar(max)
declare @IndexColumnId int
declare @IsDescendingKey int 
declare @IsIncludedColumn int
declare @TSQLScripCreationIndex varchar(max)
declare @TSQLScripDisableIndex varchar(max)
declare @is_primary_key varchar(100)

declare CursorIndex cursor for
 select schema_name(t.schema_id) [schema_name], t.name, ix.name,
 case when ix.is_unique_constraint = 1 then ' UNIQUE ' else '' END 
    ,case when ix.is_primary_key = 1 then ' PRIMARY KEY ' else '' END 
 , ix.type_desc,
  case when ix.is_padded=1 then 'PAD_INDEX = ON, ' else 'PAD_INDEX = OFF, ' end
 + case when ix.allow_page_locks=1 then 'ALLOW_PAGE_LOCKS = ON, ' else 'ALLOW_PAGE_LOCKS = OFF, ' end
 + case when ix.allow_row_locks=1 then  'ALLOW_ROW_LOCKS = ON, ' else 'ALLOW_ROW_LOCKS = OFF, ' end
 + case when INDEXPROPERTY(t.object_id, ix.name, 'IsStatistics') = 1 then 'STATISTICS_NORECOMPUTE = ON, ' else 'STATISTICS_NORECOMPUTE = OFF, ' end
 + case when ix.ignore_dup_key=1 then 'IGNORE_DUP_KEY = ON, ' else 'IGNORE_DUP_KEY = OFF, ' end
 + 'SORT_IN_TEMPDB = OFF, FILLFACTOR =' + CAST(ix.fill_factor AS VARCHAR(3)) AS IndexOptions
 , FILEGROUP_NAME(ix.data_space_id) FileGroupName
 from sys.tables t 
 inner join sys.indexes ix on t.object_id=ix.object_id
 where ix.type >0 and  (ix.is_unique_constraint=1) --and schema_name(tb.schema_id)= @SchemaName and tb.name=@TableName
 and t.is_ms_shipped=0 and t.name<>'sysdiagrams'
 order by schema_name(t.schema_id), t.name, ix.name
open CursorIndex
fetch next from CursorIndex into  @SchemaName, @TableName, @IndexName, @is_unique_constraint, @is_primary_key, @IndexTypeDesc, @IndexOptions, @FileGroupName
while (@@fetch_status=0)
begin
 declare @IndexColumns varchar(max)
 declare @IncludedColumns varchar(max)
 set @IndexColumns=''
 set @IncludedColumns=''
 declare CursorIndexColumn cursor for 
 select col.name, ixc.is_descending_key, ixc.is_included_column
 from sys.tables tb 
 inner join sys.indexes ix on tb.object_id=ix.object_id
 inner join sys.index_columns ixc on ix.object_id=ixc.object_id and ix.index_id= ixc.index_id
 inner join sys.columns col on ixc.object_id =col.object_id  and ixc.column_id=col.column_id
 where ix.type>0 and (ix.is_primary_key=1 or ix.is_unique_constraint=1)
 and schema_name(tb.schema_id)=@SchemaName and tb.name=@TableName and ix.name=@IndexName
 order by ixc.index_column_id
 open CursorIndexColumn 
 fetch next from CursorIndexColumn into  @ColumnName, @IsDescendingKey, @IsIncludedColumn
 while (@@fetch_status=0)
 begin
  if @IsIncludedColumn=0 
    set @IndexColumns=@IndexColumns + @ColumnName  + case when @IsDescendingKey=1  then ' DESC, ' else  ' ASC, ' end
  else 
   set @IncludedColumns=@IncludedColumns  + @ColumnName  +', ' 
     
  fetch next from CursorIndexColumn into @ColumnName, @IsDescendingKey, @IsIncludedColumn
 end
 close CursorIndexColumn
 deallocate CursorIndexColumn
 set @IndexColumns = substring(@IndexColumns, 1, len(@IndexColumns)-1)
 set @IncludedColumns = case when len(@IncludedColumns) >0 then substring(@IncludedColumns, 1, len(@IncludedColumns)-1) else '' end
--  print @IndexColumns
--  print @IncludedColumns

set @TSQLScripCreationIndex =''
set @TSQLScripDisableIndex =''
set  @TSQLScripCreationIndex='ALTER TABLE '+  QUOTENAME(@SchemaName) +'.'+ QUOTENAME(@TableName)+ ' ADD CONSTRAINT ' +  QUOTENAME(@IndexName) + @is_unique_constraint + @is_primary_key + +@IndexTypeDesc +  '('+@IndexColumns+') '+ 
 case when len(@IncludedColumns)>0 then CHAR(13) +'INCLUDE (' + @IncludedColumns+ ')' else '' end + CHAR(13)+'WITH (' + @IndexOptions+ ') ON ' + QUOTENAME(@FileGroupName) + ';'  

print @TSQLScripCreationIndex + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10)
print @TSQLScripDisableIndex 

fetch next from CursorIndex into  @SchemaName, @TableName, @IndexName, @is_unique_constraint, @is_primary_key, @IndexTypeDesc, @IndexOptions, @FileGroupName

end
close CursorIndex
deallocate CursorIndex


GO

DECLARE @COLLATE_DESTINO VARCHAR(100) = 'SQL_Latin1_General_CP1_CI_AS1'

SELECT ' CREATE ' +  
    CASE WHEN I.is_unique = 1 THEN ' UNIQUE ' ELSE '' END  +   
    I.type_desc COLLATE DATABASE_DEFAULT +' INDEX ' +    
    QUOTENAME(I.name)  + ' ON '  +   
    Schema_name(T.Schema_id)+'.'+ QUOTENAME(T.name) + ' ( ' +  
    KeyColumns + ' )  ' +  
    ISNULL(' INCLUDE ('+IncludedColumns+' ) ','') +  
    ISNULL(' WHERE  '+I.Filter_definition,'') + ' WITH ( ' +  
    CASE WHEN I.is_padded = 1 THEN ' PAD_INDEX = ON ' ELSE ' PAD_INDEX = OFF ' END + ','  +  
    'FILLFACTOR = '+CONVERT(CHAR(5),CASE WHEN I.Fill_factor = 0 THEN 100 ELSE I.Fill_factor END) + ','  +  
    -- default value  
    'SORT_IN_TEMPDB = OFF '  + ','  +  
    CASE WHEN I.ignore_dup_key = 1 THEN ' IGNORE_DUP_KEY = ON ' ELSE ' IGNORE_DUP_KEY = OFF ' END + ','  +  
    CASE WHEN ST.no_recompute = 0 THEN ' STATISTICS_NORECOMPUTE = OFF ' ELSE ' STATISTICS_NORECOMPUTE = ON ' END + ','  +  
    -- default value   
    ' DROP_EXISTING = ON '  + ','  +  
    -- default value   
    ' ONLINE = OFF '  + ','  +  
   CASE WHEN I.allow_row_locks = 1 THEN ' ALLOW_ROW_LOCKS = ON ' ELSE ' ALLOW_ROW_LOCKS = OFF ' END + ','  +  
   CASE WHEN I.allow_page_locks = 1 THEN ' ALLOW_PAGE_LOCKS = ON ' ELSE ' ALLOW_PAGE_LOCKS = OFF ' END  + ' ) ON [' +  
   DS.name + ' ] ' + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10) [--CreateIndexScript]  
FROM sys.indexes I    
 JOIN sys.tables T ON T.Object_id = I.Object_id     
 JOIN sys.sysindexes SI ON I.Object_id = SI.id AND I.index_id = SI.indid    
 JOIN (SELECT * FROM (   
    SELECT IC2.object_id , IC2.index_id ,   
        STUFF((SELECT ' , ' + C.name + CASE WHEN MAX(CONVERT(INT,IC1.is_descending_key)) = 1 THEN ' DESC ' ELSE ' ASC ' END 
    FROM sys.index_columns IC1   
    JOIN Sys.columns C    
       ON C.object_id = IC1.object_id    
       AND C.column_id = IC1.column_id    
       AND IC1.is_included_column = 0   
    WHERE IC1.object_id = IC2.object_id    
       AND IC1.index_id = IC2.index_id    
    GROUP BY IC1.object_id,C.name,index_id   
    ORDER BY MAX(IC1.key_ordinal)   
       FOR XML PATH('')), 1, 2, '') KeyColumns    
    FROM sys.index_columns IC2    
    --WHERE IC2.Object_id = object_id('Person.Address') --Comment for all tables   
    GROUP BY IC2.object_id ,IC2.index_id) tmp3 )tmp4    
  ON I.object_id = tmp4.object_id AND I.Index_id = tmp4.index_id   
 JOIN sys.stats ST ON ST.object_id = I.object_id AND ST.stats_id = I.index_id    
 JOIN sys.data_spaces DS ON I.data_space_id=DS.data_space_id    
 JOIN sys.filegroups FG ON I.data_space_id=FG.data_space_id    
 LEFT JOIN (SELECT * FROM (    
    SELECT IC2.object_id , IC2.index_id ,    
        STUFF((SELECT ' , ' + C.name  
    FROM sys.index_columns IC1    
    JOIN Sys.columns C     
       ON C.object_id = IC1.object_id     
       AND C.column_id = IC1.column_id     
       AND IC1.is_included_column = 1    
    WHERE IC1.object_id = IC2.object_id     
       AND IC1.index_id = IC2.index_id     
    GROUP BY IC1.object_id,C.name,index_id    
       FOR XML PATH('')), 1, 2, '') IncludedColumns     
   FROM sys.index_columns IC2     
   --WHERE IC2.Object_id = object_id('Person.Address') --Comment for all tables    
   GROUP BY IC2.object_id ,IC2.index_id) tmp1    
   WHERE IncludedColumns IS NOT NULL ) tmp2     
ON tmp2.object_id = I.object_id AND tmp2.index_id = I.index_id    
WHERE I.is_primary_key = 0 AND I.is_unique_constraint = 0 
--AND I.Object_id = object_id('Person.Address') --Comment for all tables  
--AND I.name = 'IX_Address_PostalCode' --comment for all indexes  
AND Exists (Select 1 From sys.columns c Where c.Collation_Name is not null And Not c.Collation_Name = @COLLATE_DESTINO And c.object_id = t.object_id)
And t.name not like '%027%'
And t.name not like '%[_]fil[_]%'
And t.name not like 'sysdiagrams'
And t.name not like 'sysssislog'
And t.schema_id = 1
And Exists (	SELECT 1
		from information_schema.columns isc
		WHERE isc.table_name = t.name 
		AND  (isc.Data_Type LIKE '%char%' OR isc.Data_Type LIKE '%text%')
		AND isc.COLLATION_NAME <> @COLLATE_DESTINO)
GO


Declare @CollationName Varchar(50) = 'SQL_Latin1_General_CP1_CI_AS'
DECLARE @SQLTEXT VARCHAR(MAX); SET @SQLTEXT = ''

SELECT	@SQLTEXT = @SQLTEXT + ' EXEC SP_HELPTEXT_SIG ''' + NAME + ''', @Alter = 1' + CHAR(13) + CHAR(10) --+ 'GO' + CHAR(13) + CHAR(10)
From	sys.objects o
Where	Exists (Select 1 From sys.columns c Where c.Collation_Name is not null And Not c.Collation_Name = @CollationName And c.object_id = o.object_id)
And o.type = 'V'


EXEC (@SQLTEXT)
 
GO