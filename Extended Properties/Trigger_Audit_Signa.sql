USE [ECARGO]
GO
/****** Object:  DdlTrigger [Trigger_Audit_Signa]    Script Date: 08/05/2017 19:01:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter TRIGGER [Trigger_Audit_Signa]
    ON DATABASE
    FOR DDL_PROCEDURE_EVENTS, DDL_TRIGGER_EVENTS, DDL_VIEW_EVENTS, DDL_FUNCTION_EVENTS, CREATE_EXTENDED_PROPERTY, DROP_EXTENDED_PROPERTY--, DDL_TABLE_EVENTS
AS
BEGIN
	SET NOCOUNT ON;
	SET ANSI_WARNINGS, ANSI_PADDING ON;
	SET ARITHABORT ON


	DECLARE
	@EventXml XML = EVENTDATA();

	Declare @ProcName Varchar(500) = (@EventXml.value('(/EVENT_INSTANCE/ObjectName)[1]',  'NVARCHAR(255)'))

	Declare @HasExProperty Bit = IsNull((Select Top 1 1 From dbo.DDLEvents Where ObjectName = @ProcName And EventType Like '%EXTENDED_PROPERTY%'), 0)
	
	If (@EventXml.value('(/EVENT_INSTANCE/EventType)[1]',   'NVARCHAR(100)') Like 'Drop%' And @HasExProperty = 1)
		Begin
			Throw 51000, 'Procedure com propriedade estendida', 1
			Rollback
			Return
		End

	--Retiro o texto da coluna para não causar armazenamento duplicado na coluna EventDDL.
    SET @EventXml.modify('delete /EVENT_INSTANCE/TSQLCommand/CommandText');
 
	DECLARE 
	@ip VARCHAR(32); Set @ip =
	(
	    SELECT client_net_address
		FROM sys.dm_exec_connections
		WHERE session_id = @@SPID
	);

	INSERT dbo.DDLEvents
	(
		EventType,
		EventDDL,
		EventXML,
		DatabaseName,
		SchemaName,
		ObjectName,
		HostName,
		IPAddress,
		ProgramName,
		LoginName
	)
	SELECT
		EventType	= @EventXml.value('(/EVENT_INSTANCE/EventType)[1]',   'NVARCHAR(100)'), 
		EventDDL	= EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)'),
		EventXML	= @EventXml, --Dados adicionais
		DatabaseName	= DB_NAME(),
		SchemaName	= @EventXml.value('(/EVENT_INSTANCE/SchemaName)[1]',  'NVARCHAR(255)'), 
		ObjectName	= @EventXml.value('(/EVENT_INSTANCE/ObjectName)[1]',  'NVARCHAR(255)'),
		HostName	= HOST_NAME(),
		IPAddress	= @ip,
		ProgramName	= PROGRAM_NAME(),
		LoginName	= SUSER_SNAME();
END


GO

ENABLE TRIGGER [Trigger_Audit_Signa] ON DATABASE
GO


