--This query will give details about event session, its events, actions, targets 
SELECT sessions.name AS SessionName, sevents.package as PackageName, 
sevents.name AS EventName, 
sevents.predicate, sactions.name AS ActionName, stargets.name AS TargetName 
FROM sys.server_event_sessions sessions 
INNER JOIN sys.server_event_session_events sevents 
ON sessions.event_session_id = sevents.event_session_id 
INNER JOIN sys.server_event_session_actions sactions
ON sessions.event_session_id = sactions.event_session_id 
INNER JOIN sys.server_event_session_targets stargets 
ON sessions.event_session_id = stargets.event_session_id 
--WHERE sessions.name = 'MonitorExpensiveQuery' 
GO

--We need to enable event session to capture event and event data 
ALTER EVENT SESSION MonitorExpensiveQuery 
ON SERVER STATE = START
--GO
----Run a test query against AdventureWorks database
--SELECT * FROM AdventureWorks.Sales.SalesOrderHeader H 
--INNER JOIN AdventureWorks.Sales.SalesOrderDetail D ON H.SalesOrderID = D.SalesOrderID 
--GO 

drop table #temp


SELECT xe.*, x.event_date
into #temp
FROM sys.fn_xe_file_target_read_file 
('C:\Signa\Trace Results\Extended Events\ExpensiveQuery*.xet', 
'C:\Signa\Trace Results\Extended Events\ExpensiveQuery*.xem', NULL, NULL) xe
CROSS APPLY ( SELECT event_data_xml	= CAST(event_data AS XML) ) e
CROSS APPLY ( SELECT event_date		= e.event_data_xml.value('(/event/@timestamp)[1]', 'datetime') ) x

--This query will display the captured event data for specified event session 
SELECT TOP 300 event_date, event_data_xml, duration, reads, cpu, client_app_name, sql_text, X.object_id , OBJECT_NAME(Cast(X.object_id as int), Cast(database_id as int))
FROM #temp
CROSS APPLY ( SELECT event_data_xml = CAST(event_data AS XML) ) e
CROSS APPLY ( SELECT	duration		= Cast(e.event_data_xml.query('event/data[@name="duration"]/value/text()') as varchar)
			, object_id		= Cast(e.event_data_xml.query('event/data[@name="object_id"]/value/text()') as varchar)
			, database_id		= Cast(e.event_data_xml.query('event/data[@name="database_id"]/value/text()') as varchar)
			, reads			= Cast(e.event_data_xml.query('event/data[@name="reads"]/value/text()') as varchar)
			, cpu			= Cast(e.event_data_xml.query('event/data[@name="cpu"]/value/text()') as varchar)
			, sql_text		= e.event_data_xml.query('event/action[@name="sql_text"]/value/text()')
			, client_app_name	= Cast(e.event_data_xml.query('event/action[@name="client_app_name"]/value/text()') as varchar(200))
			--, event_date		= e.event_data_xml.value('(/event/@timestamp)[1]', 'datetime')
 ) x
 ORDER BY 1 DESC
GO 
--You can stop event session to capture event data 
ALTER EVENT SESSION MonitorExpensiveQuery 
ON SERVER STATE = STOP 
GO 
--To remove a event session, use DROP EVENT SESSION command 
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='MonitorExpensiveQuery') 
DROP EVENT SESSION MonitorExpensiveQuery ON SERVER 
GO