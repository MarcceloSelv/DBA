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


SELECT
	S.[host_name], 
	DB_NAME(R.database_id) as [database_name],
	(CASE WHEN S.program_name like 'SQLAgent - TSQL JobStep (Job %' THEN  j.name ELSE S.program_name END) as Name , 
	S.login_name, 
	cast(('<?query --'+b.text+'--?>') as XML) as sql_text,
	R.blocking_session_id, 
	R.session_id,
	COALESCE(R.CPU_time, S.CPU_time) AS CPU_ms,
	isnull(DATEDIFF(mi, S.last_request_start_time, getdate()), 0) [MinutesRunning],
	GETDATE()
FROM sys.dm_exec_requests R with (nolock)
INNER JOIN sys.dm_exec_sessions S with (nolock)
	ON R.session_id = S.session_id
OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) b
OUTER APPLY sys.dm_exec_query_plan (R.plan_handle) AS qp
LEFT OUTER JOIN msdb.dbo.sysjobs J with (nolock)
	ON (substring(left(j.job_id,8),7,2) +
		substring(left(j.job_id,8),5,2) +
		substring(left(j.job_id,8),3,2) +
		substring(left(j.job_id,8),1,2))  = substring(S.program_name,32,8)
WHERE R.session_id <> @@SPID
	and S.[host_name] IS NOT NULL
ORDER BY COALESCE(R.CPU_time, S.CPU_time)desc