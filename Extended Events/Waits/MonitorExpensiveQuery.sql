--Check if the event session is already exisiting, if yes then drop it first
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='MonitorExpensiveQuery') 
DROP EVENT SESSION MonitorExpensiveQuery ON SERVER 
GO 
--Creating a Extended Event session with CREATE EVENT SESSION command 
CREATE EVENT SESSION MonitorExpensiveQuery ON SERVER 
--Add events to this seesion with ADD EVENT clause 
ADD EVENT sqlserver.sql_statement_completed 
( 
--Specify what all additional information you want to capture 
--event data with ACTION Clause 
ACTION 
( 
sqlserver.database_id, 
sqlserver.session_id, 
sqlserver.username, 
sqlserver.client_hostname, 
sqlserver.sql_text, 
sqlserver.tsql_stack,
sqlserver.client_app_name,
sqlserver.plan_handle
) 
--Specify predicates to filter out your events 
WHERE (
sqlserver.sql_statement_completed.reads > 1500
OR sqlserver.sql_statement_completed.duration > 10000
OR sqlserver.sql_statement_completed.cpu > 2000
)
AND sqlserver.database_id = 7
)
--Specify the target where event data will be written with ADD TARGET clause
ADD TARGET package0.asynchronous_file_target
( 
SET FILENAME = N'C:\Signa\Trace Results\Extended Events\ExpensiveQuery.xet', 
METADATAFILE = 'C:\Signa\Trace Results\Extended Events\ExpensiveQuery.xem' 
) 
GO 