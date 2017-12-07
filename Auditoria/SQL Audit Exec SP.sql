--https://www.mssqltips.com/sqlservertip/3259/several-methods-to-collect-sql-server-stored-procedure-execution-history/

USE [master]
GO
alter SERVER AUDIT [Sig_Audit_SP_Execution]
TO FILE 
( FILEPATH = N'E:\Signa\DBA\Audit'
 ,MAXSIZE = 8 MB
 ,MAX_ROLLOVER_FILES = 2
 ,RESERVE_DISK_SPACE = OFF
)
WITH
( QUEUE_DELAY = 2000  -- equal to 1 second
 ,ON_FAILURE = CONTINUE
)
GO

CREATE DATABASE AUDIT SPECIFICATION [DBAudit_sp_execution_Sig]
FOR SERVER AUDIT [Sig_Audit_SP_Execution]
GO


SET NOCOUNT ON
SELECT '
ALTER DATABASE AUDIT SPECIFICATION [DBAudit_sp_execution_Sig]
FOR SERVER AUDIT [Sig_Audit_SP_Execution]
    ADD (EXECUTE ON OBJECT::dbo.' + name + ' BY [public]) ' FROM sys.objects WHERE type = 'P'

go
USE master
ALTER SERVER AUDIT [Sig_Audit_SP_Execution]
WITH (STATE = ON);
GO

USE ECARGO
GO
ALTER DATABASE AUDIT SPECIFICATION [DBAudit_sp_execution_Sig]
FOR SERVER AUDIT [Sig_Audit_SP_Execution]   
    WITH (STATE = ON);
GO


SELECT *
FROM sys.fn_get_audit_file 
('E:\Signa\DBA\Audit\Sig_Audit_SP_Execution*.sqlaudit',default,default) 

SELECT MAX(event_time) last_exec_time, [object_name] 
FROM sys.fn_get_audit_file 
('E:\Signa\DBA\Audit\Sig_Audit_SP_Execution*.sqlaudit',default,default) 
 WHERE action_id = 'EX'
 GROUP BY [object_name]
UNION ALL
SELECT MAX(event_time) last_exec_time, [object_name] 
FROM sys.fn_get_audit_file 
('E:\Signa\DBA\Audit\Sig_Audit_SP_Execution-...0.sqlaudit',default,default) 
 WHERE action_id = 'EX'
 GROUP BY [object_name]

go

--DROP TABLE dba.PROCEDURE_EXEC
GO
USE ECARGO
GO
CREATE TABLE dba.PROCEDURE_EXEC (ObjectId Int Not Null Primary Key, LastExecution Datetime2, [Statement] NVarchar(Max))
go
USE ECARGO
GO
Insert dba.PROCEDURE_EXEC
SELECT [object_id], [last_exec_time] = MAX(event_time), null --(Select Max([Statement]) Where F.event_time )
FROM sys.fn_get_audit_file 
('E:\Signa\DBA\Audit\Sig_Audit_SP_Execution*.sqlaudit',default, default) f
 WHERE action_id = 'EX'
 And Not Exists (Select 1 From dba.PROCEDURE_EXEC P Where P.[ObjectId] = F.[object_id])
 GROUP BY [object_id]