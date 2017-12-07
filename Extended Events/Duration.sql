--https://www.brentozar.com/archive/2014/03/finding-one-problem-query-extended-events/

CREATE EVENT SESSION [Web_20sec] ON SERVER
ADD EVENT sqlserver.sp_statement_completed(
ACTION(package0.collect_system_time,
sqlserver.client_app_name,
sqlserver.client_hostname,
sqlserver.database_id,
sqlserver.sql_text)
WHERE (duration >= 20000 /* And sqlserver.client_app_name = 'Web%'*/)),
ADD EVENT sqlserver.sql_statement_completed(
ACTION(package0.collect_system_time,
sqlserver.client_app_name,
sqlserver.client_hostname,
sqlserver.database_id,
sqlserver.sql_text)
WHERE (duration >= 20000))
ADD TARGET package0.asynchronous_file_target
(SET filename = 'E:\MSSQLSERVER\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ExtendedEvents\Web_20sec.xel',
metadatafile = 'E:\MSSQLSERVER\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ExtendedEvents\Web_20sec.xem',
max_file_size=5,
max_rollover_files=5)
WITH (MAX_DISPATCH_LATENCY = 5SECONDS);
GO

ALTER EVENT SESSION [Web_20sec] ON SERVER STATE = START





WITH events_cte AS (
SELECT
DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP),
xevents.event_data.value('(event/@timestamp)[1]','datetime2')) AS [event time] ,
xevents.event_data.value('(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(128)')
AS [client app name],
xevents.event_data.value('(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(max)')
AS [client host name],
xevents.event_data.value('(event/action[@name="database_id"]/value)[1]', 'int')
AS [database_id],
xevents.event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint')
AS [duration (ms)],
xevents.event_data.value('(event/data[@name="object_id"]/value)[1]', 'bigint')
AS [object_id],
xevents.event_data.value('(event/data[@name="cpu"]/value)[1]', 'bigint')
AS [cpu time (ms)],
xevents.event_data.value('(event/data[@name="logical_reads"]/value)[1]', 'bigint') AS [logical reads],
xevents.event_data.value('(event/data[@name="row_count"]/value)[1]', 'bigint') AS [row count]
,xevents.event_data.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)')
AS [text]
,xevents.event_data
FROM sys.fn_xe_file_target_read_file
('E:\MSSQLSERVER\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ExtendedEvents\Web_20sec*.xel',
--Web_20sec_0_131009685629610000
'E:\MSSQLSERVER\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ExtendedEvents\Web_20sec*.xem',
null, null)
CROSS APPLY (select CAST(event_data as XML) as event_data) as xevents
)
SELECT object_name(object_id, database_id), db_name(database_id), *
FROM events_cte
Where [client app name] not like 'SQLAgent%'
ORDER BY [event time] DESC;


/* Stop the Extended Events session */
ALTER EVENT SESSION [query hash] ON SERVER
STATE = STOP;
/* Remove the session from the server.
This step is optional - I clear them out on my dev SQL Server
because I'm constantly doing stupid things to my dev SQL Server. */
DROP EVENT SESSION [query hash] ON SERVER;