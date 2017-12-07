Select *
Into	Lancamento_Operacao_Audit
From	Lancamento_Operacao
Where	1=2
go

Alter Table Lancamento_Operacao_Audit Add HostName Varchar(300) Null
Alter Table Lancamento_Operacao_Audit Add ProgramName Varchar(300) Null
Alter Table Lancamento_Operacao_Audit Add SessionId Int Null
Alter Table Lancamento_Operacao_Audit Add ClientInterfaceName Varchar(300) Null
Alter Table Lancamento_Operacao_Audit Add LoginName Varchar(300) Null
Alter Table Lancamento_Operacao_Audit Add Command Xml Null
Alter Table Lancamento_Operacao_Audit Add IP Varchar(32) Null
Alter Table Lancamento_Operacao_Audit Add Data Datetime2 Null

go

ALTER TRIGGER TR_ECR_AUDIT_ALT_LANC_OPER ON LANCAMENTO_OPERACAO
AFTER UPDATE
AS
    BEGIN
	IF UPDATE(VALOR_LANC_RS)
	    BEGIN
		Declare @Command Xml
			--,@sql_handle varbinary(64) = (SELECT s.sql_handle FROM sys.dm_exec_requests s WHERE s.session_id = @@SPID)
		Declare	@ip	Varchar(32) = (SELECT client_net_address FROM sys.dm_exec_connections WHERE session_id = @@SPID);
		Declare	@buffer Table (eventtype nvarchar(30), parameters int, eventinfo nvarchar(4000))

		insert @buffer
		Exec sp_executesql N'DBCC INPUTBUFFER(@@spid) WITH NO_INFOMSGS'

		select @Command = eventinfo from @buffer

		--Select @Command = (SELECT st.text as [processing-instruction(x)] FROM sys.dm_exec_sql_text(@sql_handle) st For Xml Path(''))
			
		INSERT	Lancamento_Operacao_Audit
		Select	d.*, s.host_name, s.program_name, s.session_id, s.client_interface_name, s.login_name, @Command, @ip, Sysdatetime()
		From	deleted d
			Join sys.dm_exec_sessions s On s.session_id = @@SPID
	    END
    END

    --DBCC INPUTBUFFER(108)

--update LANCAMENTO_OPERACAO set valor_lanc_rs = Isnull(valor_lanc_rs,0) + 1 where LANCAMENTO_OPERACAO_id = 1031305
--update LANCAMENTO_OPERACAO set TAB_STATUS_ID = TAB_STATUS_ID where LANCAMENTO_OPERACAO_id = 1031305

select valor_lanc_rs, * from LANCAMENTO_OPERACAO WHERE LANCAMENTO_OPERACAO_ID = 1031305

select	Lo_Old.valor_lanc_rs valor_lanc_rs_old, lo.valor_lanc_rs valor_lanc_rs_atual, Lo_Old.Data, Lo_Old.* 
from	LANCAMENTO_OPERACAO LO
	Inner Join Lancamento_Operacao_Audit Lo_Old On Lo_Old.LANCAMENTO_OPERACAO_ID = Lo.LANCAMENTO_OPERACAO_ID
Where	Lo.LANCAMENTO_OPERACAO_id = 1031305
Order By Lo_Old.Data Desc


SELECT
    SPID                = er.session_id
    ,STATUS             = ses.STATUS
    ,[Login]            = ses.login_name
    ,Host               = ses.host_name
    ,BlkBy              = er.blocking_session_id
    ,DBName             = DB_Name(er.database_id)
    ,CommandType        = er.command
    ,SQLStatement       = st.text
    ,ObjectName         = OBJECT_NAME(st.objectid)
    ,ElapsedMS          = er.total_elapsed_time
    ,CPUTime            = er.cpu_time
    ,IOReads            = er.logical_reads + er.reads
    ,IOWrites           = er.writes
    ,LastWaitType       = er.last_wait_type
    ,StartTime          = er.start_time
    ,Protocol           = con.net_transport
    ,ConnectionWrites   = con.num_writes
    ,ConnectionReads    = con.num_reads
    ,ClientAddress      = con.client_net_address
    ,Authentication     = con.auth_scheme
FROM sys.dm_exec_requests er
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) st
LEFT JOIN sys.dm_exec_sessions ses
ON ses.session_id = er.session_id
LEFT JOIN sys.dm_exec_connections con
ON con.session_id = ses.session_id
and ses.session_id = @@SPID


DECLARE @sqltext VARBINARY(128)
SELECT @sqltext = sql_handle
FROM sys.sysprocesses
WHERE spid = @@SPID
SELECT TEXT
FROM ::fn_get_sql(@sqltext)
GO