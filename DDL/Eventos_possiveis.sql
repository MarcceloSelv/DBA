SELECT HOST_NAME() NOME_MAQUINA, client_net_address, local_net_address
FROM sys.dm_exec_connections
WHERE session_id = @@SPID


WITH DirectReports(name, parent_type, type, level, sort) AS 
(
    SELECT CONVERT(varchar(255),type_name), parent_type, type, 1, CONVERT(varchar(255),type_name)
    FROM sys.trigger_event_types
    WHERE parent_type IS NULL
    UNION ALL
SELECT  CONVERT(varchar(255), REPLICATE ('|   ' , level) + e.type_name),
e.parent_type, e.type, level + 1,
    CONVERT (varchar(255), RTRIM(sort) + '|   ' + e.type_name)
    FROM sys.trigger_event_types AS e
        INNER JOIN DirectReports AS d
        ON e.parent_type = d.type
)
SELECT parent_type, type, name
FROM DirectReports
ORDER BY sort;


