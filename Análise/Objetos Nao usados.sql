SELECT
    A.name AS [object_name],
    A.type_desc,
    C.name AS index_name,
    (
        SELECT MAX(Ultimo_Acesso)
        FROM (VALUES (B.last_user_seek),(B.last_user_scan),(B.last_user_lookup),(B.last_user_update)) AS DataAcesso(Ultimo_Acesso)
    ) AS last_access,
    B.last_user_seek,
    B.last_user_scan,
    B.last_user_lookup,
    B.last_user_update,
    NULLIF(
        (CASE WHEN B.last_user_seek IS NOT NULL THEN 'Seek, ' ELSE '' END) +
        (CASE WHEN B.last_user_scan IS NOT NULL THEN 'Scan, ' ELSE '' END) +
        (CASE WHEN B.last_user_lookup IS NOT NULL THEN 'Lookup, ' ELSE '' END) +
        (CASE WHEN B.last_user_update IS NOT NULL THEN 'Update, ' ELSE '' END)
    , '') AS operations
FROM
    sys.objects                    A
    LEFT JOIN sys.dm_db_index_usage_stats            B    ON    B.[object_id] = A.[object_id]
    LEFT JOIN sys.indexes                C    ON    C.index_id = B.index_id AND C.[object_id] = B.[object_id]
WHERE
    A.type_desc IN ('VIEW', 'USER_TABLE')
	And	A.is_ms_shipped = 0
ORDER BY
    last_access desc


SELECT
    'Drop Procedure ' + Quotename(A.name) AS [object_name],
    A.type_desc,
    MAX(B.last_execution_time) AS last_execution_time
FROM
    mercosul.sys.objects    A 
    LEFT JOIN (
        mercosul.sys.dm_exec_query_stats B
        CROSS APPLY mercosul.sys.dm_exec_sql_text(B.sql_handle) C 
    ) ON A.[object_id] = C.objectid
WHERE
    A.type_desc LIKE '%_PROCEDURE'
GROUP BY
    A.name,
    A.type_desc
ORDER BY
    3 DESC,
    1

