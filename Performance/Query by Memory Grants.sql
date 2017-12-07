--http://blogs.msdn.com/b/sqlqueryprocessing/archive/2010/02/16/understanding-sql-server-memory-grant.aspx

SELECT top 50
	r.session_id 
    ,mg.granted_memory_kb 
    ,mg.requested_memory_kb 
    ,mg.ideal_memory_kb 
    ,mg.request_time 
    ,mg.grant_time 
    ,mg.query_cost 
    ,mg.dop 
    ,( 
        SELECT SUBSTRING(TEXT, statement_start_offset / 2 + 1, ( 
                    CASE 
                        WHEN statement_end_offset = - 1 
                            THEN LEN(CONVERT(NVARCHAR(MAX), TEXT)) * 2 
                        ELSE statement_end_offset 
                        END - statement_start_offset 
                    ) / 2) 
        FROM sys.dm_exec_sql_text(r.sql_handle) 
        ) AS query_text 
    ,qp.query_plan 
FROM sys.dm_exec_query_memory_grants AS mg 
INNER JOIN sys.dm_exec_requests r ON mg.session_id = r.session_id 
CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) AS qp 
ORDER BY mg.required_memory_kb DESC;