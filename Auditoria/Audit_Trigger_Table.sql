if Exists (Select 1 From sys.objects o Where o.name = 'Lancamento_Operacao_Audit' And type = 'U')
	Drop Table Lancamento_Operacao_Audit

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

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
ALTER TRIGGER TR_ECR_AUDIT_ALT_LANC_OPER ON LANCAMENTO_OPERACAO
AFTER UPDATE
AS
    BEGIN
	IF UPDATE(VALOR_LANC_RS)
	    BEGIN
		Set Nocount ON

		Declare @Command Xml
		Declare	@IP	Varchar(32) = (SELECT client_net_address FROM sys.dm_exec_connections WHERE session_id = @@SPID);
		Declare	@buffer Table (eventtype nvarchar(30), parameters int, eventinfo nvarchar(4000))

		Insert @buffer
		Exec sp_executesql N'DBCC INPUTBUFFER(@@spid) WITH NO_INFOMSGS'

		Select @Command = eventinfo From @buffer

		INSERT	Lancamento_Operacao_Audit
		Select	d.*, s.host_name, s.program_name, s.session_id, s.client_interface_name, s.login_name, @Command, @IP, Sysdatetime()
		From	deleted d
			Cross Join sys.dm_exec_sessions s Where s.session_id = @@SPID
	    END
    END