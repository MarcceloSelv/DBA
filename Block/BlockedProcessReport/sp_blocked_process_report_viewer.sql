USE master
GO

IF OBJECT_ID('sp_blocked_process_report_viewer') IS NULL
	EXEC ('
	CREATE PROCEDURE dbo.sp_blocked_process_report_viewer 
	AS 
	SELECT ''Replace Me''')
GO

ALTER PROCEDURE dbo.sp_blocked_process_report_viewer
(
	@Trace nvarchar(max),
	@Type varchar(10) = 'FILE' 
)

AS

SET NOCOUNT ON

-- Validate @Type
IF (@Type NOT IN ('FILE', 'TABLE', 'XMLFILE'))
	RAISERROR ('The @Type parameter must be ''FILE'', ''TABLE'' or ''XMLFILE''', 11, 1)

IF (@Trace LIKE '%.trc' AND @Type <> 'FILE')
	RAISERROR ('Warning: You specified a .trc trace. You should also specify @Type = ''FILE''', 10, 1)

IF (@Trace LIKE '%.xml' AND @Type <> 'XMLFILE')
	RAISERROR ('Warning: You specified a .xml trace. You should also specify @Type = ''XMLFILE''', 10, 1)
	

CREATE TABLE #ReportsXML
(
	monitorloop nvarchar(100) NOT NULL,
	endTime datetime NULL,
	blocking_spid INT NOT NULL,
	blocking_ecid INT NOT NULL,
	blocked_spid INT NOT NULL,
	blocked_ecid INT NOT NULL,
	blocked_hierarchy_string as CAST(blocked_spid as varchar(20)) + '.' + CAST(blocked_ecid as varchar(20)) + '/',
	blocking_hierarchy_string as CAST(blocking_spid as varchar(20)) + '.' + CAST(blocking_ecid as varchar(20)) + '/',
	bpReportXml xml not null,
	primary key clustered (monitorloop, blocked_spid, blocked_ecid),
	unique nonclustered (monitorloop, blocking_spid, blocking_ecid, blocked_spid, blocked_ecid)
)

DECLARE @SQL NVARCHAR(max);
DECLARE @TableSource nvarchar(max);

-- define source for table
IF (@Type = 'TABLE')
BEGIN
	-- everything input by users get quoted
	SET @TableSource = ISNULL(QUOTENAME(PARSENAME(@Trace,4)) + N'.', '')
		+ ISNULL(QUOTENAME(PARSENAME(@Trace,3)) + N'.', '')
		+ ISNULL(QUOTENAME(PARSENAME(@Trace,2)) + N'.', '')
		+ QUOTENAME(PARSENAME(@Trace,1));
END

-- define source for trc file
IF (@Type = 'FILE')
BEGIN	
	SET @TableSource = N'sys.fn_trace_gettable(N' + QUOTENAME(@Trace, '''') + ', -1)';
END

-- load table or file
IF (@Type IN ('TABLE', 'FILE'))
BEGIN
	SET @SQL = N'		
		INSERT #ReportsXML(blocked_ecid,blocked_spid,blocking_ecid,blocking_spid,
			monitorloop,bpReportXml,endTime)
		SELECT blocked_ecid,blocked_spid,blocking_ecid,blocking_spid,
			COALESCE(monitorloop, CONVERT(nvarchar(100), endTime, 120), ''unknown''),
			bpReportXml,EndTime
		FROM ' + @TableSource + N'
		CROSS APPLY (
			SELECT CAST(TextData as xml)
			) AS bpReports(bpReportXml)
		CROSS APPLY (
			SELECT 
				monitorloop = bpReportXml.value(''(//@monitorLoop)[1]'', ''nvarchar(100)''),
				blocked_spid = bpReportXml.value(''(/blocked-process-report/blocked-process/process/@spid)[1]'', ''int''),
				blocked_ecid = bpReportXml.value(''(/blocked-process-report/blocked-process/process/@ecid)[1]'', ''int''),
				blocking_spid = bpReportXml.value(''(/blocked-process-report/blocking-process/process/@spid)[1]'', ''int''),
				blocking_ecid = bpReportXml.value(''(/blocked-process-report/blocking-process/process/@ecid)[1]'', ''int'')
			) AS bpShredded
		WHERE EventClass = 137';
		
	EXEC (@SQL);
END 

IF (@Type = 'XMLFILE')
BEGIN
	CREATE TABLE #TraceXML (
		id int identity primary key,
		ReportXML xml NOT NULL	
	)
	
	SET @SQL = N'
		INSERT #TraceXML(ReportXML)
		SELECT col FROM OPENROWSET (
				BULK ' + QUOTENAME(@Trace, '''') + N', SINGLE_BLOB
			) as xmldata(col)';

	EXEC (@SQL);
	
	CREATE PRIMARY XML INDEX PXML_TraceXML ON #TraceXML(ReportXML);

	WITH XMLNAMESPACES 
	(
		'http://tempuri.org/TracePersistence.xsd' AS MY
	),
	ShreddedWheat AS 
	(
		SELECT
			bpShredded.blocked_ecid,
			bpShredded.blocked_spid,
			bpShredded.blocking_ecid,
			bpShredded.blocking_spid,
			bpShredded.monitorloop,
			bpReports.bpReportXml,
			bpReports.bpReportEndTime
		FROM #TraceXML
		CROSS APPLY 
			ReportXML.nodes('/MY:TraceData/MY:Events/MY:Event[@name="Blocked process report"]')
			AS eventNodes(eventNode)
		CROSS APPLY 
			eventNode.nodes('./MY:Column[@name="EndTime"]')
			AS endTimeNodes(endTimeNode)
		CROSS APPLY
			eventNode.nodes('./MY:Column[@name="TextData"]')
			AS bpNodes(bpNode)
		CROSS APPLY (
			SELECT CAST(bpNode.value('(./text())[1]', 'nvarchar(max)') as xml),
				CAST(LEFT(endTimeNode.value('(./text())[1]', 'varchar(max)'), 19) as datetime)
		) AS bpReports(bpReportXml, bpReportEndTime)
		CROSS APPLY (
			SELECT 
				monitorloop = bpReportXml.value('(//@monitorLoop)[1]', 'nvarchar(100)'),
				blocked_spid = bpReportXml.value('(/blocked-process-report/blocked-process/process/@spid)[1]', 'int'),
				blocked_ecid = bpReportXml.value('(/blocked-process-report/blocked-process/process/@ecid)[1]', 'int'),
				blocking_spid = bpReportXml.value('(/blocked-process-report/blocking-process/process/@spid)[1]', 'int'),
				blocking_ecid = bpReportXml.value('(/blocked-process-report/blocking-process/process/@ecid)[1]', 'int')
		) AS bpShredded
	)
	INSERT #ReportsXML(blocked_ecid,blocked_spid,blocking_ecid,blocking_spid,
		monitorloop,bpReportXml,endTime)
	SELECT blocked_ecid,blocked_spid,blocking_ecid,blocking_spid,
		COALESCE(monitorloop, CONVERT(nvarchar(100), bpReportEndTime, 120), 'unknown'),
		bpReportXml,bpReportEndTime
	FROM ShreddedWheat;
	
	DROP TABLE #TraceXML

END

-- Organize and select blocked process reports
;WITH Blockheads AS
(
	SELECT blocking_spid, blocking_ecid, monitorloop, blocking_hierarchy_string
	FROM #ReportsXML
	EXCEPT
	SELECT blocked_spid, blocked_ecid, monitorloop, blocked_hierarchy_string
	FROM #ReportsXML
), 
Hierarchy AS
(
	SELECT monitorloop, blocking_spid as spid, blocking_ecid as ecid, 
		cast('/' + blocking_hierarchy_string as varchar(max)) as chain,
		0 as level
	FROM Blockheads
	
	UNION ALL
	
	SELECT irx.monitorloop, irx.blocked_spid, irx.blocked_ecid,
		cast(h.chain + irx.blocked_hierarchy_string as varchar(max)),
		h.level+1
	FROM #ReportsXML irx
	JOIN Hierarchy h
		ON irx.monitorloop = h.monitorloop
		AND irx.blocking_spid = h.spid
		AND irx.blocking_ecid = h.ecid
)
SELECT 
	ISNULL(CONVERT(nvarchar(30), irx.endTime, 120), 
		'Lead') as traceTime,
	SPACE(4 * h.level) 
		+ CAST(h.spid as varchar(20)) 
		+ CASE h.ecid 
			WHEN 0 THEN ''
			ELSE '(' + CAST(h.ecid as varchar(20)) + ')' 
		END AS blockingTree,
	irx.bpReportXml
from Hierarchy h
left join #ReportsXML irx
	on irx.monitorloop = h.monitorloop
	and irx.blocked_spid = h.spid
	and irx.blocked_ecid = h.ecid
order by h.monitorloop, h.chain

DROP TABLE #ReportsXML

