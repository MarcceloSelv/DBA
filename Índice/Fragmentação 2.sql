/*
http://sqlmonitormetrics.red-gate.com/percentage-of-fragmented-indexes/
*/

DECLARE @frag DECIMAL(10, 2) ,
    @tot INT;
  
SELECT  @frag = COUNT(*)
FROM    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL,
                                       NULL, 'LIMITED') ps
WHERE   ps.avg_fragmentation_in_percent >= 5
        AND ps.page_count > 100
        AND OBJECTPROPERTY(ps.[object_id], 'IsUserTable') = 1;
 
SELECT  @tot = COUNT(*)
FROM    sys.indexes i
WHERE   OBJECTPROPERTY(i.[object_id], 'IsUserTable') = 1;
 
SELECT  @tot = CASE WHEN @tot = 0 THEN 1
                    ELSE @tot
               END;
 
SELECT  CAST(( @frag / @tot ) AS DECIMAL(10, 2)) * 100;
