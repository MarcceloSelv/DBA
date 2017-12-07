--http://www.sqlservercentral.com/scripts/Performance+Tuning/123190/

WITH cte AS (
  SELECT 
    r.session_id
  , r.blocking_session_id
  , r.request_id
  , r.database_id
  , t.objectid
  , t.[text]
  , r.statement_start_offset/2 AS StatementStartOffset
  , CASE
      WHEN r.statement_end_offset > r.statement_start_offset THEN r.statement_end_offset/2
      ELSE LEN(t.[text])
    END AS StatementEndOffset
  , p.query_plan
  FROM sys.dm_exec_requests r 
    CROSS APPLY sys.dm_exec_sql_text(r.[sql_handle]) t
    OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) p
    --OUTER APPLY sys.dm_exec_text_query_plan(r.plan_handle, r.statement_end_offset, r.statement_end_offset) p
  WHERE r.[sql_handle] IS NOT NULL
  AND t.[text] NOT LIKE '%9ow34ytghehl3q94wg%'
), spaceUsage AS (
  SELECT 
    session_id
  , blocking_session_id = null
  , request_id
  , SUM(user_objects_alloc_page_count - user_objects_dealloc_page_count) / 128 AS UserObjMB
  , SUM(internal_objects_alloc_page_count - internal_objects_dealloc_page_count) / 128 AS InternalObjMB
  FROM sys.dm_db_task_space_usage 
  GROUP BY
    session_id
  , request_id
)
SELECT 
  r.session_id
, r.blocking_session_id
, s.login_name
, DB_NAME(r.database_id) AS DbName
, COALESCE(
    '[' + OBJECT_SCHEMA_NAME(r.objectid, r.database_id) + '].[' + OBJECT_NAME(r.objectid, r.database_id) + ']'
  , LEFT(LTRIM(r.[text]), 128)) AS QueryBatch
, SUBSTRING(
    r.[text]
  , r.StatementStartOffset
  , r.StatementEndOffset - r.StatementStartOffset
  ) AS CurrentStatement
, LEN(LEFT(r.[text], r.StatementStartOffset)) 
    - LEN(REPLACE(LEFT(r.[text], r.StatementStartOffset), CHAR(10), '')) 
    + 1 AS LineNumber
, u.UserObjMB AS [UserObjMB*]
, u.InternalObjMB
, r.query_plan
FROM cte r
  INNER JOIN sys.dm_exec_sessions s ON s.session_id = r.session_id
  LEFT JOIN spaceUsage u
    ON r.session_id = u.session_id
    AND r.request_id = u.request_id
/*
UNION ALL
 
SELECT 
  9999
, NULL
, 'tempdb'
, CAST(SUM(unallocated_extent_page_count)/128 AS VARCHAR) + ' MB free'
, NULL
, NULL
, SUM(user_object_reserved_page_count) / 128
, SUM(internal_object_reserved_page_count) / 128
, NULL
FROM tempdb.sys.dm_db_file_space_usage

ORDER BY 1
--*/