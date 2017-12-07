--https://www.mssqltips.com/sqlservertip/1853/sql-server-tempdb-usage-and-bottlenecks-tracked-with-extended-events/

--Declare @Directory Varchar(100) =  'E:\Database\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ExtendedEvents\'

--Drop the event if it already exists
DROP EVENT SESSION Monitor_wait_info_tempdb ON SERVER; 
GO 
--Create the event 
CREATE EVENT SESSION Monitor_wait_info_tempdb ON SERVER 
--We are looking at wait info only
ADD EVENT sqlos.wait_info
( 
   --Add additional columns to track
   ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.session_id, sqlserver.tsql_stack)  
    WHERE sqlserver.database_id = 2 --filter database id = 2 i.e tempdb
    --This allows us to track wait statistics at database granularity
) --As a best practise use asynchronous file target, reduces overhead.
ADD TARGET package0.asynchronous_file_target(
     SET filename='E:\Database\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ExtendedEvents\Monitor_wait_info_tempdb.etl', metadatafile='E:\Database\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ExtendedEvents\Monitor_wait_info_tempdb.mta')
GO
--Now start the session
ALTER EVENT SESSION Monitor_wait_info_tempdb ON SERVER
STATE = START;
GO


SELECT wait_typeName 
      , SUM(total_duration) AS total_duration
      , SUM(signal_duration) AS total_signal_duration
FROM (
SELECT
  FinalData.R.value ('@name', 'nvarchar(50)') AS EventName,  
  FinalData.R.value ('data(data/value)[1]', 'nvarchar(50)') AS wait_typeValue,
  FinalData.R.value ('data(data/text)[1]', 'nvarchar(50)') AS wait_typeName,
  FinalData.R.value ('data(data/value)[5]', 'bigint') AS total_duration,
  FinalData.R.value ('data(data/value)[6]', 'bigint') AS signal_duration,
  FinalData.R.value ('(action/.)[1]', 'nvarchar(50)') AS DatabaseID,
  FinalData.R.value ('(action/.)[2]', 'nvarchar(50)') AS SQLText,
  FinalData.R.value ('(action/.)[3]', 'nvarchar(50)') AS SessionID
  
FROM
( SELECT CONVERT(xml, event_data) AS xmldata
   FROM sys.fn_xe_file_target_read_file
   ('\Monitor_wait_info_tempdb*.etl', 'E:\Database\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ExtendedEvents\Monitor_wait_info_tempdb*.mta', NULL, NULL)
) AsyncFileData
CROSS APPLY xmldata.nodes ('//event') AS FinalData (R)) xyz
WHERE wait_typeName NOT IN ('SLEEP_TASK')
 GROUP BY wait_typeName
 ORDER BY total_duration
 GO