CREATE TABLE dbo.DDLEvents
(
    EventDate		DATETIME NOT NULL DEFAULT GETDATE(),
    EventType		NVARCHAR(64),
    EventDDL		NVARCHAR(MAX),
    EventXML		XML,
    DatabaseName	NVARCHAR(255),
    SchemaName		NVARCHAR(255),
    ObjectName		NVARCHAR(255),
    HostName		VARCHAR(64),
    IPAddress		VARCHAR(32),
    ProgramName		NVARCHAR(255),
    LoginName		NVARCHAR(255)--,
    --SetOptions		NVARCHAR(255)
);

GO
INSERT dbo.DDLEvents
(
	EventType,
	EventDDL,
	DatabaseName,
	SchemaName,
	ObjectName,
	LoginName,
	HostName,
	EventDate
)
SELECT
	'CREATE_PROCEDURE',
	sm.definition,
	DB_NAME(),
	OBJECT_SCHEMA_NAME(pr.[object_id]),
	pr.name,
	'SISTEMA',
	'CARGA INICIAL',
	pr.modify_date
FROM
	sys.procedures pr
	Inner Join sys.sql_modules sm On sm.object_id = pr.object_id
WHERE
	is_ms_shipped != 1
UNION
SELECT
	'CREATE_TRIGGER',
	sm.definition,
	DB_NAME(),
	OBJECT_SCHEMA_NAME(tr.[object_id]),
	tr.name,
	'SISTEMA',
	'CARGA INICIAL',
	tr.modify_date
FROM
	sys.triggers tr
	Inner Join sys.sql_modules sm On sm.object_id = tr.object_id
WHERE
	is_ms_shipped != 1
UNION
SELECT
	'CREATE_VIEW',
	sm.definition,
	DB_NAME(),
	OBJECT_SCHEMA_NAME(v.[object_id]),
	v.name,
	'SISTEMA',
	'CARGA INICIAL',
	v.modify_date
FROM
	sys.views v
	Inner Join sys.sql_modules sm On sm.object_id = v.object_id
WHERE
	v.is_ms_shipped != 1
UNION
SELECT
	'CREATE_FUNCTION',
	sm.definition,
	DB_NAME(),
	OBJECT_SCHEMA_NAME(o.[object_id]),
	o.name,
	'SISTEMA',
	'CARGA INICIAL',
	o.modify_date
FROM
	sys.objects o
	Inner Join sys.sql_modules sm On sm.object_id = o.object_id
WHERE
	o.is_ms_shipped != 1
And	o.[type] IN (N'FN', N'IF', N'TF', N'FS', N'FT')
ORDER BY
	1, name;

go
SET ANSI_WARNINGS, ANSI_PADDING ON
GO
CREATE TRIGGER Trigger_Audit_Signa
    ON DATABASE
    FOR DDL_PROCEDURE_EVENTS, DDL_TRIGGER_EVENTS, DDL_VIEW_EVENTS, DDL_FUNCTION_EVENTS--, DDL_TABLE_EVENTS
AS
BEGIN
	SET NOCOUNT ON;
	SET ANSI_WARNINGS, ANSI_PADDING ON;
	SET ARITHABORT ON


	DECLARE
	@EventXml XML = EVENTDATA();

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
ENABLE TRIGGER [Trigger_Audit_Signa] ON DATABASE;


GO

--;WITH [Events] AS
--(
--    SELECT
--        EventDate,
--        DatabaseName,
--        SchemaName,
--        ObjectName,
--        EventDDL,
--        rnLatest = ROW_NUMBER() OVER 
--        (
--            PARTITION BY DatabaseName, SchemaName, ObjectName
--            ORDER BY     EventDate DESC
--        ),
--        rnEarliest = ROW_NUMBER() OVER
--        (
--            PARTITION BY DatabaseName, SchemaName, ObjectName
--            ORDER BY     EventDate
--        ) 
--    FROM
--        dbo.DDLEvents
--)
--SELECT
--    Original.DatabaseName,
--    Original.SchemaName,
--    Original.ObjectName,
--    OriginalCode = Original.EventDDL,
--    NewestCode   = COALESCE(Newest.EventDDL, ''),
--    LastModified = COALESCE(Newest.EventDate, Original.EventDate)
--FROM
--    [Events] AS Original
--LEFT OUTER JOIN
--    [Events] AS Newest
--    ON  Original.DatabaseName = Newest.DatabaseName
--    AND Original.SchemaName   = Newest.SchemaName
--    AND Original.ObjectName   = Newest.ObjectName
--    AND Newest.rnEarliest = Original.rnLatest
--    AND Newest.rnLatest = Original.rnEarliest
--    AND Newest.rnEarliest > 1
--WHERE
--    Original.rnEarliest = 1
--    AND Original.OBJECTNAME = 'sp_teste_ddl'


--Backup inicial
--INSERT DDLEvents 
--Select	Getdate(), 'CREATE_PROCEDURE', OBJECT_DEFINITION(obj.object_id) , NULL, 'ECARGO', 'dbo', obj.NAME, 'PIQUETURDB', NULL, NULL, NULL
--FROM	SYS.objects obj
--	CROSS APPLY (SELECT TOP 1 TYPE FROM SYS.dm_exec_procedure_stats ps WHERE ps.object_id = obj.object_id and ps.database_id = db_id('ECARGO')) ps
--WHERE	obj.TYPE = 'P'

--select count(distinct object_id) from SYS.dm_exec_procedure_stats where database_id = db_id('CARGOSOL')

ALTER FUNCTION UDF_Get_DataXml (@xData varchar(max))
RETURNS xml
BEGIN
   RETURN (SELECT @xData AS [processing-instruction(x)]  FOR XML PATH(''))
END
GO

ALTER TABLE DDLEVENTS ADD EventDDLXml AS dbo.UDF_Get_DataXml(EventDDL)
go
