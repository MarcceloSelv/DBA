SP_SPACEUSED 'fulltext_thesaurus_metadata_table'

SELECT * FROM sys.objects


SELECT SUM(unallocated_extent_page_count) AS [free pages], 
(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM sys.dm_db_file_space_usage;


SELECT
    sys.dm_exec_sessions.session_id AS [SESSION ID],
    DB_NAME(database_id) AS [DATABASE Name],
    HOST_NAME AS [System Name],
    program_name AS [Program Name],
    login_name AS [USER Name],
    status,
    cpu_time AS [CPU TIME (in milisec)],
    total_scheduled_time AS [Total Scheduled TIME (in milisec)],
    total_elapsed_time AS    [Elapsed TIME (in milisec)],
    (memory_usage * 8)      AS [Memory USAGE (in KB)],
    (user_objects_alloc_page_count * 8) AS [SPACE Allocated FOR USER Objects (in KB)],
    (user_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR USER Objects (in KB)],
    (internal_objects_alloc_page_count * 8) AS [SPACE Allocated FOR Internal Objects (in KB)],
    (internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR Internal Objects (in KB)],
    CASE is_user_process
                         WHEN 1      THEN 'user session'
                         WHEN 0      THEN 'system session'
    END         AS [SESSION Type], row_count AS [ROW COUNT]
FROM 
	sys.dm_db_session_space_usage
	INNER join sys.dm_exec_sessions ON sys.dm_db_session_space_usage.session_id = sys.dm_exec_sessions.session_id
ORDER BY row_count

SELECT * FROM msdb.dbo.sysjobs WHERE job_id = 414538d8-1323-4c2e-8a75-a6da13bd552b

160

dbcc inputbuffer (391)
sp_who2 391

;WITH s AS
(
    SELECT 
        s.session_id,
        [pages] = SUM(s.user_objects_alloc_page_count 
          + s.internal_objects_alloc_page_count) 
    FROM sys.dm_db_session_space_usage AS s
    GROUP BY s.session_id
    HAVING SUM(s.user_objects_alloc_page_count 
      + s.internal_objects_alloc_page_count) > 0
)
SELECT s.session_id, s.[pages], t.[text], 
  [statement] = COALESCE(NULLIF(
    SUBSTRING(
        t.[text], 
        r.statement_start_offset / 2, 
        CASE WHEN r.statement_end_offset < r.statement_start_offset 
        THEN 0 
        ELSE( r.statement_end_offset - r.statement_start_offset ) / 2 END
      ), ''
    ), t.[text])
FROM s
LEFT OUTER JOIN 
sys.dm_exec_requests AS r
ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.plan_handle) AS t
ORDER BY s.[pages] DESC;

SELECT tdt.database_transaction_log_bytes_reserved,tst.session_id,
t.[text], [statement] = COALESCE(NULLIF(
 SUBSTRING(
   t.[text],
   r.statement_start_offset / 2,
   CASE WHEN r.statement_end_offset < r.statement_start_offset
     THEN 0
     ELSE( r.statement_end_offset - r.statement_start_offset ) / 2 END
 ), ''
), t.[text])
FROM sys.dm_tran_database_transactions AS tdt
INNER JOIN sys.dm_tran_session_transactions AS tst
ON tdt.transaction_id = tst.transaction_id
 LEFT OUTER JOIN sys.dm_exec_requests AS r
 ON tst.session_id = r.session_id
 OUTER APPLY sys.dm_exec_sql_text(r.plan_handle) AS t
WHERE tdt.database_id = 2;


;WITH task_space_usage AS (
    -- SUM alloc/delloc pages
    SELECT session_id,
           request_id,
           SUM(internal_objects_alloc_page_count) AS alloc_pages,
           SUM(internal_objects_dealloc_page_count) AS dealloc_pages
    FROM sys.dm_db_task_space_usage WITH (NOLOCK)
    WHERE session_id <> @@SPID
    GROUP BY session_id, request_id
)
SELECT TSU.session_id,
       TSU.alloc_pages * 1.0 / 128 AS [internal object MB space],
       TSU.dealloc_pages * 1.0 / 128 AS [internal object dealloc MB space],
       EST.text,
       -- Extract statement from sql text
       ISNULL(
           NULLIF(
               SUBSTRING(
                 EST.text, 
                 ERQ.statement_start_offset / 2, 
                 CASE WHEN ERQ.statement_end_offset < ERQ.statement_start_offset 
                  THEN 0 
                 ELSE( ERQ.statement_end_offset - ERQ.statement_start_offset ) / 2 END
               ), ''
           ), EST.text
       ) AS [statement text],
       EQP.query_plan
FROM task_space_usage AS TSU
INNER JOIN sys.dm_exec_requests ERQ WITH (NOLOCK)
    ON  TSU.session_id = ERQ.session_id
    AND TSU.request_id = ERQ.request_id
OUTER APPLY sys.dm_exec_sql_text(ERQ.sql_handle) AS EST
OUTER APPLY sys.dm_exec_query_plan(ERQ.plan_handle) AS EQP
WHERE EST.text IS NOT NULL OR EQP.query_plan IS NOT NULL
ORDER BY 3 DESC;




SELECT
  sys.dm_exec_sessions.session_id AS [SESSION ID]
  ,DB_NAME(database_id) AS [DATABASE Name]
  ,HOST_NAME AS [System Name]
  ,program_name AS [Program Name]
  ,login_name AS [USER Name]
  ,status
  ,cpu_time AS [CPU TIME (in milisec)]
  ,total_scheduled_time AS [Total Scheduled TIME (in milisec)]
  ,total_elapsed_time AS    [Elapsed TIME (in milisec)]
  ,(memory_usage * 8)      AS [Memory USAGE (in KB)]
  ,(user_objects_alloc_page_count * 8) AS [SPACE Allocated FOR USER Objects (in KB)]
  ,(user_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR USER Objects (in KB)]
  ,(internal_objects_alloc_page_count * 8) AS [SPACE Allocated FOR Internal Objects (in KB)]
  ,(internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR Internal Objects (in KB)]
  ,CASE is_user_process
             WHEN 1      THEN 'user session'
             WHEN 0      THEN 'system session'
  END         AS [SESSION Type], row_count AS [ROW COUNT]
FROM 
  sys.dm_db_session_space_usage
INNER join
  sys.dm_exec_sessions
ON  sys.dm_db_session_space_usage.session_id = sys.dm_exec_sessions.session_id
order by internal_objects_dealloc_page_count desc

select current_timestamp, ssu.session_id, 
db_name(ssu.database_id) , 
substring(st.text,1,100), 
ssu.user_objects_alloc_page_count, 
ssu.user_objects_dealloc_page_count, 
ssu.internal_objects_alloc_page_count, 
ssu.internal_objects_dealloc_page_count,es.login_name from sys.dm_db_session_space_usage as ssu 
inner join sys.dm_exec_connections ec on ssu.session_id = ec.session_id 
join sys.dm_exec_sessions as es on es.session_id=ec.session_id 
cross apply sys.dm_exec_sql_text(ec.most_recent_sql_handle) AS st 
where ssu.user_objects_alloc_page_count != 0 




SELECT
	*
FROM
	sys.dm_db_file_space_usage;

go
select * from  sys.dm_db_file_space_usage 
go 
select * from  sys.dm_db_session_space_usage
go
select * from sys.dm_db_task_space_usage








SELECT
	SessionId					= TasksSpaceUsage.SessionId ,
	RequestId					= TasksSpaceUsage.RequestId ,
	InternalObjectsAllocPageCount		= TasksSpaceUsage.InternalObjectsAllocPageCount ,
InternalObjectsDeallocPageCount	= TasksSpaceUsage.InternalObjectsDeallocPageCount ,
	RequestText					= RequestsText.text ,
	RequestPlan					= RequestsPlan.query_plan
FROM
	(
		SELECT
			SessionId					= session_id ,
			RequestId					= request_id ,
	InternalObjectsAllocPageCount		= SUM (internal_objects_alloc_page_count) ,
InternalObjectsDeallocPageCount	= SUM (internal_objects_dealloc_page_count)
		FROM
			sys.dm_db_task_space_usage
		GROUP BY
			session_id ,
			request_id
	)
	AS
		TasksSpaceUsage
INNER JOIN
	sys.dm_exec_requests AS Requests
ON
	TasksSpaceUsage.SessionId = Requests.session_id
AND
	TasksSpaceUsage.RequestId = Requests.request_id
OUTER APPLY
	sys.dm_exec_sql_text (Requests.sql_handle) AS RequestsText
OUTER APPLY
	sys.dm_exec_query_plan (Requests.plan_handle) AS RequestsPlan
ORDER BY
	SessionId	ASC ,
	RequestId	ASC;