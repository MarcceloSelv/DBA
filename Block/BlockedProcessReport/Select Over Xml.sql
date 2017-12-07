use master

--SET ANSI_DEFAULTS OFF
--SET ARITHABORT ON
--SET ANSI_NULLS ON
--SET QUOTED_IDENTIFIER ON
--SET CONCAT_NULL_YIELDS_NULL, ANSI_WARNINGS, ANSI_PADDING ON

--select * from sys.traces

--select * from Blocked
--select * from Duration Where ApplicationName Like 'Web%'
--select * from Duration Where textdata like '%#TEMP_DCT%'
--Drop Table Blocked
--Drop Table Duration

--select * into Blocked from dbo.fn_trace_gettable('E:\MS SQL Database\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\Block2.trc', default) --Where StartTime >= Getdate() -2
--select * into Duration from dbo.fn_trace_gettable('E:\MS SQL Database\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\Duration10.trc', default) --Where StartTime >= Getdate() -2

--BEGIN TRY
SELECT --TOP 5000
	B.Duration,
	B.StartTime,
	B.EndTime,
	bpBlocked.clientapp, 
	bpBlocked.isolationlevel, 
	bpBlocked.hostname, 
	bpBlocked.lockMode, 
	bpBlocked.inputbuf, 
	(SELECT TOP 1 SUBSTRING(st_blocked.text, bpBlocked.stmtstart / 2+1 , 
	( (CASE WHEN bpBlocked.stmtend = -1 
	 THEN (LEN(CONVERT(nvarchar(max), st_blocked.text)) * 2) 
	 ELSE bpBlocked.stmtend END)  - bpBlocked.stmtstart) / 2+1))  AS sql_statement,
	 
	bpBlocking.clientapp, 
	bpBlocking.isolationlevel, 
	bpBlocking.hostname, 
	bpBlocking.lockMode, 
	bpBlocking.inputbuf,  
	(SELECT TOP 1 SUBSTRING(st_blocking.text, bpBlocking.stmtstart / 2+1 , 
	( (CASE WHEN bpBlocking.stmtend = -1 
	 THEN (LEN(CONVERT(nvarchar(max), st_blocking.text)) * 2) 
	 ELSE bpBlocking.stmtend END)  - bpBlocking.stmtstart) / 2+1))  AS sql_statement,
	
	Blocked_Object_Name = OBJECT_NAME(st_blocked.objectid, st_blocked.dbid), 
	Blocking_Object_Name = OBJECT_NAME(st_blocking.objectid, st_blocking.dbid)
	,bpReports.*
FROM	[Blocked] B
CROSS APPLY (
	SELECT CAST(TextData as xml)
	) AS bpReports(bpReportXml)
CROSS APPLY (
	SELECT 
		clientapp = bpReportXml.value('(//blocked-process/process/@clientapp)[1]', 'nvarchar(200)'),
		waitresource = bpReportXml.value('(//blocked-process/process/@waitresource)[1]', 'nvarchar(200)'),
		isolationlevel = bpReportXml.value('(//blocked-process/process/@isolationlevel)[1]', 'nvarchar(200)'),
		hostname = bpReportXml.value('(//blocked-process/process/@hostname)[1]', 'nvarchar(200)'),
		lockMode = bpReportXml.value('(//blocked-process/process/@lockMode)[1]', 'nvarchar(200)'),
		stmtstart = bpReportXml.value('(//blocked-process/process/executionStack/frame/@stmtstart)[1]', 'int'),
		stmtend = bpReportXml.value('(//blocked-process/process/executionStack/frame/@stmtend)[1]', 'int'),
		sqlhandle = Convert(varbinary(64), bpReportXml.value('(//blocked-process/process/executionStack/frame/@sqlhandle)[1]', 'nvarchar(max)'), 1),
		inputbuf = bpReportXml.value('(//blocked-process/process/inputbuf)[1]', 'varchar(1000)')
	) AS bpBlocked
	CROSS APPLY (
	SELECT 
		clientapp = bpReportXml.value('(//blocking-process/process/@clientapp)[1]', 'nvarchar(200)'),
		waitresource = bpReportXml.value('(//blocking-process/process/@waitresource)[1]', 'nvarchar(200)'),
		isolationlevel = bpReportXml.value('(//blocking-process/process/@isolationlevel)[1]', 'nvarchar(200)'),
		hostname = bpReportXml.value('(//blocking-process/process/@hostname)[1]', 'nvarchar(200)'),
		lockMode = bpReportXml.value('(//blocking-process/process/@lockMode)[1]', 'nvarchar(200)'),
		stmtstart = bpReportXml.value('(//blocking-process/process/executionStack/frame/@stmtstart)[1]', 'int'),
		stmtend = bpReportXml.value('(//blocking-process/process/executionStack/frame/@stmtend)[1]', 'int'),
		sqlhandle = Convert(varbinary(64), bpReportXml.value('(//blocking-process/process/executionStack/frame/@sqlhandle)[1]', 'nvarchar(max)'), 1),
		inputbuf = bpReportXml.value('(//blocking-process/process/inputbuf)[1]', 'varchar(1000)')
	) AS bpBlocking
	OUTER APPLY sys.dm_exec_sql_text(bpBlocked.sqlhandle) st_blocked
	OUTER APPLY sys.dm_exec_sql_text(bpBlocking.sqlhandle) st_blocking
--WHERE
--	B.EventClass = 137
----And NOT OBJECT_NAME(st_blocking.objectid, st_blocking.dbid) IN ('SP_040_GRA_ULT_STATUS_DOCTO07')
----AND NOT bpBlocking.inputbuf LIKE '%SP_040_BATCH_GERA_SHIPMENT_CTE6%'
----AND NOT bpBlocking.inputbuf LIKE '%SP_040_GERA_CTRC_AUTOM10%'
--AND NOT bpBlocking.inputbuf LIKE '%SP_040_EXC_TRACK_MANIF_TF2%'
ORDER BY B.StarEndTimetTime DESC