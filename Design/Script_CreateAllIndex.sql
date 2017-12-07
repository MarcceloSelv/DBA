SET NOCOUNT ON

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
AND Exists (Select 1 From sys.columns c Where c.Collation_Name is not null And Not c.Collation_Name = 'Latin1_General_CI_AS' And c.object_id = t.object_id)
And t.name not like '%027%'
And t.name not like '%[_]fil[_]%'
And t.name not like 'sysdiagrams'
And t.name not like 'sysssislog'
And t.schema_id = 1
And Exists (	SELECT 1
		from information_schema.columns isc
		WHERE isc.table_name = t.name 
		AND  (isc.Data_Type LIKE '%char%' OR isc.Data_Type LIKE '%text%')
		AND isc.COLLATION_NAME <> 'Latin1_General_CI_AS')

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
AND Exists (Select 1 From sys.columns c Where c.Collation_Name is not null And Not c.Collation_Name = 'Latin1_General_CI_AS' And c.object_id = t.object_id)
And t.name not like '%027%'
And t.name not like '%[_]fil[_]%'
And t.name not like 'sysdiagrams'
And t.name not like 'sysssislog'
And t.schema_id = 1
And Exists (	SELECT 1
		from information_schema.columns isc
		WHERE isc.table_name = t.name 
		AND  (isc.Data_Type LIKE '%char%' OR isc.Data_Type LIKE '%text%')
		AND isc.COLLATION_NAME <> 'Latin1_General_CI_AS')
