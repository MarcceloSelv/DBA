sp_lock

select * from sys.dm_tran_locks where resource_associated_entity_id = OBJECT_ID('Resultados') and resource_database_id = DB_ID()

dbcc inputbuffer (52)

BEGIN TRAN

UPDATE Resultados SET Texto =  Texto

ROLLBACK

select OBJECT_ID('Resultados')

SELECT	*
FROM
	sys.dm_tran_locks l
	JOIN sys.dm_exec_sessions s ON l.request_session_id = s.session_id
	LEFT JOIN
	(
		SELECT  *
		FROM    sys.dm_exec_requests r
		CROSS APPLY sys.dm_exec_sql_text(sql_handle)
	) a ON s.session_id = a.session_id


SELECT 
    objname = object_name(p.object_id), *
FROM sys.partitions p
JOIN sys.dm_tran_locks t1
ON p.hobt_id = t1.resource_associated_entity_id

USE master
GO
CREATE PROCEDURE SP_LOCK_SIG
	@SQLStatement Varchar(Max) Output
AS
SELECT
    --spid
    --,sp.STATUS
    --,loginame   = SUBSTRING(loginame, 1, 12)
    --,hostname   = SUBSTRING(hostname, 1, 12)
    --,blk        = CONVERT(CHAR(3), blocked)
    --,open_tran
    --,dbname     = SUBSTRING(DB_NAME(sp.dbid),1,10)
    --,cmd
    --,waittype
    --,waittime
    --,last_batch
    @SQLStatement = qt.text
FROM master.dbo.sysprocesses sp
LEFT JOIN sys.dm_exec_requests er
    ON er.session_id = sp.spid
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
WHERE spid IN (SELECT blocked FROM master.dbo.sysprocesses)
AND blocked = 0


declare @SQLStatement nvarchar(max)

exec master..SP_LOCK_SIG @SQLStatement output

select @SQLStatement



SELECT 
    SQLStatement       =
        SUBSTRING
        (
            qt.text,
            er.statement_start_offset/2,
            (CASE WHEN er.statement_end_offset = -1
                THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2
                ELSE er.statement_end_offset
                END - er.statement_start_offset)/2
        )
        
FROM sys.dm_exec_requests er
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
WHERE er.session_id = 54

