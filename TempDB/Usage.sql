--http://www.sqlservercentral.com/scripts/tempdb/146629/

IF OBJECT_ID('tempdb..##TMP') IS NOT NULL
  /*Then it exists*/
  DROP TABLE ##TMP

IF OBJECT_ID('tempdb..##TMP2') IS NOT NULL
  /*Then it exists*/
  DROP TABLE ##TMP2

SELECT DISTINCT 
	p.spid, 
	j.name as JobName
INTO 
	##TMP
FROM
	master.dbo.sysprocesses p INNER JOIN msdb.dbo.sysjobs j ON master.dbo.fn_varbintohexstr(CONVERT(varbinary(16), job_id)) = SUBSTRING(REPLACE(PROGRAM_NAME, 'SQLAgent - TSQL JobStep (Job ', ''), 1, 34)


;WITH tempdb_space_usage AS (
    SELECT 
		session_id,
		request_id,
		SUM(internal_objects_alloc_page_count) AS alloc_pages,
		SUM(internal_objects_dealloc_page_count) AS dealloc_pages
    FROM 
		sys.dm_db_task_space_usage WITH (NOLOCK)
    WHERE 
		session_id <> @@SPID
    GROUP BY 
		session_id, request_id
)
SELECT 
	TSU.session_id,
	DES.login_name,
	TSU.alloc_pages * 1.0 / 128 AS [internal object MB space],
	TSU.dealloc_pages * 1.0 / 128 AS [internal object dealloc MB space],
	EST.text,
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
INTO
	##TMP2
FROM 
	tempdb_space_usage AS TSU INNER JOIN sys.dm_exec_requests ERQ WITH (NOLOCK) ON  TSU.session_id = ERQ.session_id AND TSU.request_id = ERQ.request_id
	INNER JOIN sys.dm_exec_sessions DES ON TSU.session_id = DES.session_id
	OUTER APPLY sys.dm_exec_sql_text(ERQ.sql_handle) AS EST
	OUTER APPLY sys.dm_exec_query_plan(ERQ.plan_handle) AS EQP
WHERE 
	EST.text IS NOT NULL 
	OR EQP.query_plan IS NOT NULL
ORDER BY 
	3 DESC;


SELECT 
	a.session_id, 
	a.login_name,
	ISNULL(b.JobName, 'N/A') AS [Job Name],	 
	a.[internal object MB space], 
	a.[internal object dealloc MB space], 
	a.[text], 
	a.[statement text], 
	a.[query_plan] 
FROM 
	##TMP2 a LEFT OUTER JOIN ##TMP b ON a.session_id = b.spid
WHERE
	(a.[internal object MB space] + a.[internal object dealloc MB space]) > 0
