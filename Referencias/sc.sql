WITH DepTree (referenced_id, referenced_name, referencing_id, referencing_name, NestLevel)
 AS 
(
    SELECT  o.[object_id] AS referenced_id , 
     o.name AS referenced_name, 
     o.[object_id] AS referencing_id, 
     o.name AS referencing_name,  
     0 AS NestLevel
 FROM  sys.objects o 
    WHERE o.name = 'SP_040_CALC_MFRETE_ICMS7'
    
    UNION ALL
    
    SELECT  d1.referenced_id,  
     OBJECT_NAME( d1.referenced_id) , 
     d1.referencing_id, 
     OBJECT_NAME( d1.referencing_id) , 
     NestLevel + 1
     FROM  sys.sql_expression_dependencies d1 
		JOIN DepTree r ON d1.referenced_id =  r.referencing_id
)
SELECT DISTINCT referenced_id, referenced_name, referencing_id, referencing_name, NestLevel
 FROM DepTree 
 --WHERE NestLevel > 0
ORDER BY NestLevel, referencing_id;

SELECT TOP 40 * FROM DDLEvents WHERE EventDate >= GETDATE()-5

SP_040_BATCH_MANIFESTO_AUTOMATICO_CALC_AGRUP_A3_POR_CTE_PREST003
SP_040_CALC_MFRETE_CALCULO42
SP_040_CALC_MFRETE_ICMS7


SELECT  d1.referenced_id,  
    OBJECT_NAME( d1.referenced_id) , 
    d1.referencing_id, 
    OBJECT_NAME( d1.referencing_id)
    FROM  sys.sql_expression_dependencies d1 
WHERE d1.referencing_id = 156668868


--https://www.mssqltips.com/sqlservertip/2999/different-ways-to-find-sql-server-object-dependencies/

WITH DepTree 
 AS 
(
    SELECT  o.name, o.[object_id] AS referenced_id , 
   o.name AS referenced_name, 
   o.[object_id] AS referencing_id, 
   o.name AS referencing_name,  
   0 AS NestLevel
  FROM  sys.objects o 
    WHERE o.is_ms_shipped = 0 AND o.type = 'V'
    
    UNION ALL
    
    SELECT  r.name, d1.referenced_id,  
   OBJECT_NAME( d1.referenced_id) , 
   d1.referencing_id, 
   OBJECT_NAME( d1.referencing_id) , 
   NestLevel + 1
     FROM  sys.sql_expression_dependencies d1 
  JOIN DepTree r 
   ON d1.referenced_id =  r.referencing_id
)
 SELECT DISTINCT name as ViewName, MAX(NestLevel) AS MaxNestLevel
  FROM DepTree
 GROUP BY name
 HAVING MAX(NestLevel) > 2
 ORDER BY MAX(NestLevel) DESC; 


 SELECT  DB_NAME() AS dbname, 
 o.type_desc AS referenced_object_type, 
 d1.referenced_entity_name, 
 d1.referenced_id, 
        STUFF( (SELECT ', ' + OBJECT_NAME(d2.referencing_id)
   FROM sys.sql_expression_dependencies d2
         WHERE d2.referenced_id = d1.referenced_id
                ORDER BY OBJECT_NAME(d2.referencing_id)
                FOR XML PATH('')), 1, 1, '') AS dependent_objects_list
FROM sys.sql_expression_dependencies  d1 JOIN sys.objects o 
  ON  d1.referenced_id = o.[object_id]
GROUP BY o.type_desc, d1.referenced_id, d1.referenced_entity_name
ORDER BY o.type_desc, d1.referenced_entity_name