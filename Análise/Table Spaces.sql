SELECT
    SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(p.object_id) AS NAME,
    SUM(reserved_page_count) * 8 AS total_space_used_kb,
    SUM(CASE WHEN index_id < 2 THEN reserved_page_count ELSE 0 END ) * 8 AS table_space_used_kb,
    SUM(CASE WHEN index_id > 1 THEN reserved_page_count ELSE 0 END ) * 8 AS nonclustered_index_spaced_used_kb,
    MAX(row_count) AS row_count
FROM    
    sys.dm_db_partition_stats AS p
		INNER JOIN sys.all_objects AS o ON p.object_id = o.object_id
WHERE
	o.is_ms_shipped = 0
GROUP BY
    SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(p.object_id)
ORDER BY
	NAME







SELECT Database_ID = DB_ID()
    , Database_Name = DB_NAME()
    , Schema_Name = a3.name
    , TableName = a2.name
    , TableSize_MB = (a1.reserved + ISNULL(a4.reserved,0)) / 128
    , RowCounts = a1.rows
    , DataSize_MB = a1.data / 128
    , IndexSize_MB = (CASE WHEN (a1.used + ISNULL(a4.used,0)) > a1.data 
                        THEN (a1.used + ISNULL(a4.used,0)) - a1.data 
                        ELSE 0 
                    END) /128
    , Free_MB = (CASE WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used 
                        THEN (a1.reserved + ISNULL(a4.reserved,0)) - a1.used 
                        ELSE 0 
                    END) / 128
FROM (SELECT ps.object_id
            , [rows] = SUM(CASE
                                WHEN (ps.index_id < 2) THEN row_count
                                ELSE 0
                            END)
            , reserved = SUM(ps.reserved_page_count)
            , data = SUM(CASE
                            WHEN (ps.index_id < 2) 
                                THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
                            ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count)
                        END)
            , used = SUM (ps.used_page_count) 
        FROM sys.dm_db_partition_stats ps
        GROUP BY ps.object_id) AS a1
    INNER JOIN sys.all_objects a2  ON a1.object_id = a2.object_id
    INNER JOIN sys.schemas a3 ON a2.schema_id = a3.schema_id
    LEFT JOIN (SELECT it.parent_id
            , reserved = SUM(ps.reserved_page_count)
            , used = SUM(ps.used_page_count)
        FROM sys.dm_db_partition_stats ps
            INNER JOIN sys.internal_tables it ON it.object_id = ps.object_id
        WHERE it.internal_type IN (202,204)
        GROUP BY it.parent_id) AS a4 ON a4.parent_id = a1.object_id
WHERE a2.type <> 'S' and a2.type <> 'IT'
    --AND a2.name IN ('spt_values')
ORDER BY a1.reserved desc