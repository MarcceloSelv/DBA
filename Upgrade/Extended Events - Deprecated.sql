--Create an Extended Event Session to track Features that are deprecated and will be removed in next major release 

DROP EVENT SESSION [find_deprecation_final_support] ON SERVER 
GO
CREATE EVENT SESSION [find_deprecation_final_support] ON SERVER 
ADD EVENT sqlserver.deprecation_final_support
(ACTION (package0.collect_system_time, sqlserver.sql_text, sqlserver.database_id, sqlserver.tsql_stack) )
ADD TARGET package0.ring_buffer
WITH (MAX_DISPATCH_LATENCY=3 SECONDS)
GO


--Start Event Session
ALTER EVENT SESSION [find_deprecation_final_support]
ON SERVER
STATE=start
GO

SELECT * FROM SYS.DM
 
--Change compatibility level of AdventureWorks2012 from 110 to 90
USE [master]
GO
ALTER DATABASE [AdventureWorks2012] SET COMPATIBILITY_LEVEL = 90
GO
 
--database compatibility level 90 will be removed from the next version of sql server
--so extended event will capture this when we use a database with compatibility level 90
USE [AdventureWorks2012]
GO
 
--ROWCOUNT is another deprecated feature that will be removed in the next version
SET ROWCOUNT 4;
SELECT *
FROM Production.ProductInventory
WHERE Quantity < 300;
GO
 
-- Wait for Event buffering to Target
WAITFOR DELAY '00:00:05';
GO
 
--Get Event Session result from ring buffer 
DECLARE @xml_holder XML;
SELECT @xml_holder = CAST(target_data AS XML)
FROM sys.dm_xe_sessions AS s 
JOIN sys.dm_xe_session_targets AS t 
    ON t.event_session_address = s.address
WHERE s.name = N'find_deprecation_final_support'
  AND t.target_name = N'ring_buffer';
  --SELECT @xml_holder
SELECT
	node.value('(data[@name="feature_id"]/value)[1]', 'int')as feature_id,
	feature.value as feature,
	Cast(sql_text.value as xml) as [sql_text.value],
	node.value('(data[@name="message"]/value)[1]', 'varchar(200)') as message,
	node.value('(@name)[1]', 'varchar(50)') AS event_name
FROM	@xml_holder.nodes('RingBufferTarget/event') AS p(node)
	Cross Apply (Select node.value('(action[@name="sql_text"]/value)[1]', 'varchar(5000)') as [processing-instruction(x)]  For Xml Path('')) sql_text(value)
	Cross Apply (Select node.value('(data[@name="feature"]/value)[1]', 'varchar(50)')) feature(value)
Where
	feature.value != 'Oldstyle RAISERROR'
And	feature.value != 'SET ROWCOUNT'
GO


SELECT xo.name, xo.description, *
FROM sys.dm_xe_objects xo INNER JOIN sys.dm_xe_packages xp
ON xp.[guid] = xo.[package_guid]
WHERE xo.[object_type] = 'event' AND xo.name LIKE '%deprecation%'
ORDER BY xp.[name];


--Find the additional columns that can be tracked
SELECT *
FROM sys.dm_xe_objects xo INNER JOIN sys.dm_xe_packages xp
ON xp.[guid] = xo.[package_guid]
WHERE xo.[object_type] = 'action'
ORDER BY xp.[name];
GO

--Find the columns that are  available to track for the 
--deprecation_announcement event
SELECT * FROM sys.dm_xe_object_columns
WHERE [object_name] = 'deprecation_announcement';
GO

--Find the columns that are  available to track for the 
--deprecation_final_support event
SELECT * FROM sys.dm_xe_object_columns
WHERE [object_name] = 'deprecation_final_support';
GO

--https://www.mssqltips.com/sqlservertip/1857/identify-deprecated-sql-server-code-with-extended-events/

--Create the event 
CREATE EVENT SESSION Monitor_Deprecated_Discontinued_features ON SERVER
--We are looking at discontinued features
ADD EVENT sqlserver.deprecation_final_support
( 
--Add additional columns to track
ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.session_id, sqlserver.tsql_stack, package0.collect_system_time))

--As a best practice use asynchronous file target, reduces overhead.
ADD TARGET package0.asynchronous_file_target(
SET filename='c:\Monitor_Deprecated_Discontinued_features.etl', metadatafile='c:\Monitor_Deprecated_Discontinued_features.mta')
GO

--Now start the session
ALTER EVENT SESSION Monitor_Deprecated_Discontinued_features ON SERVER
STATE = START;
GO

SELECT FinalData.R.value ('@name', 'nvarchar(50)') AS EventName,
FinalData.R.value ('@timestamp', 'nvarchar(50)') AS TIMESTAMP,
FinalData.R.value ('data(data/value)[1]', 'nvarchar(500)') AS Feature,
FinalData.R.value ('data(data/value)[2]', 'nvarchar(500)') AS MESSAGE,
FinalData.R.value ('(action/.)[1]', 'nvarchar(50)') AS DatabaseID,
FinalData.R.value ('(action/.)[2]', 'nvarchar(50)') AS SQLText,
FinalData.R.value ('(action/.)[3]', 'nvarchar(50)') AS SessionID,
FinalData.R.value ('(action[@name="collect_system_time"]/value)[1]', 'varchar(50)') as collect_system_time
FROM ( SELECT CONVERT(XML, event_data) AS xmldata
FROM sys.fn_xe_file_target_read_file
('c:\Monitor_Deprecated_Discontinued_features*.etl', 'c:\Monitor_Deprecated_Discontinued_features*.mta', NULL, NULL)
) AsyncFileData
CROSS APPLY xmldata.nodes ('//event') AS FinalData (R)
ORDER BY collect_system_time, Feature ASC
GO


SELECT * FROM sys.dm_os_performance_counters 
WHERE [object_name] LIKE '%:Deprecated%' AND cntr_value > 0

SELECT NAME FROM MSDB..SYSJOBS WHERE NAME LIKE '%MONITOR%'


SELECT
(physical_memory_in_use_kb/1024) AS Memory_usedby_Sqlserver_MB,
(locked_page_allocations_kb/1024) AS Locked_pages_used_Sqlserver_MB,
(total_virtual_address_space_kb/1024) AS Total_VAS_in_MB,
process_physical_memory_low,
process_virtual_memory_low
FROM sys.dm_os_process_memory;

sp_configure 'max server memory'

Exec sp_configure 'max server memory'