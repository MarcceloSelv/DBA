DROP TABLE #SystemHealthSessionData

SELECT CAST(xet.target_data AS XML) AS XMLDATA
INTO #SystemHealthSessionData
FROM sys.dm_xe_session_targets xet
JOIN sys.dm_xe_sessions xe
ON (xe.address = xet.event_session_address)
WHERE xe.name = 'system_health'

-- Gets the Deadlock Event Time and Victim Process
SELECT C.query('.').value('(/event/@timestamp)[1]', 'datetime') as EventTime,
CAST(C.query('.').value('(/event/data/value)[1]', 'varchar(MAX)') AS XML).value('(/deadlock/victim-list/victimProcess/@id)[1]','varchar(100)') VictimProcess
FROM #SystemHealthSessionData a
CROSS APPLY a.XMLDATA.nodes('/RingBufferTarget/event') as T(C)
WHERE C.query('.').value('(/event/@name)[1]', 'varchar(255)') = 'xml_deadlock_report'
-- Drop the temporary table
DROP TABLE #SystemHealthSessionData
GO
-- Fetch the Health Session data into a temporary table
 
SELECT CAST(xet.target_data AS XML) AS XMLDATA
INTO #SystemHealthSessionData
FROM sys.dm_xe_session_targets xet
JOIN sys.dm_xe_sessions xe
ON (xe.address = xet.event_session_address)
WHERE xe.name = 'system_health'
 
-- Parses the process list for a specific deadlock once provided with an event time for the deadlock from the above output
 
;WITH CTE_HealthSession (EventXML) AS
(
SELECT CAST(C.query('.').value('(/event/data/value)[1]', 'varchar(MAX)') AS XML) EventXML
FROM #SystemHealthSessionData a
CROSS APPLY a.XMLDATA.nodes('/RingBufferTarget/event') as T(C)
WHERE C.query('.').value('(/event/@name)[1]', 'varchar(255)') = 'xml_deadlock_report'
--AND C.query('.').value('(/event/@timestamp)[1]', 'datetime') = '2011-09-28 06:24:44.700' -- Replace with relevant timestamp
)
SELECT DeadlockProcesses.value('(@id)[1]','varchar(50)') as id
,DeadlockProcesses.value('(@taskpriority)[1]','bigint') as taskpriority
,DeadlockProcesses.value('(@logused)[1]','bigint') as logused
,DeadlockProcesses.value('(@waitresource)[1]','varchar(100)') as waitresource
,DeadlockProcesses.value('(@waittime)[1]','bigint') as waittime
,DeadlockProcesses.value('(@ownerId)[1]','bigint') as ownerId
,DeadlockProcesses.value('(@transactionname)[1]','varchar(50)') as transactionname
,DeadlockProcesses.value('(@lasttranstarted)[1]','varchar(50)') as lasttranstarted
,DeadlockProcesses.value('(@XDES)[1]','varchar(20)') as XDES
,DeadlockProcesses.value('(@lockMode)[1]','varchar(5)') as lockMode
,DeadlockProcesses.value('(@schedulerid)[1]','bigint') as schedulerid
,DeadlockProcesses.value('(@kpid)[1]','bigint') as kpid
,DeadlockProcesses.value('(@status)[1]','varchar(20)') as status
,DeadlockProcesses.value('(@spid)[1]','bigint') as spid
,DeadlockProcesses.value('(@sbid)[1]','bigint') as sbid
,DeadlockProcesses.value('(@ecid)[1]','bigint') as ecid
,DeadlockProcesses.value('(@priority)[1]','bigint') as priority
,DeadlockProcesses.value('(@trancount)[1]','bigint') as trancount
,DeadlockProcesses.value('(@lastbatchstarted)[1]','varchar(50)') as lastbatchstarted
,DeadlockProcesses.value('(@lastbatchcompleted)[1]','varchar(50)') as lastbatchcompleted
,DeadlockProcesses.value('(@clientapp)[1]','varchar(150)') as clientapp
,DeadlockProcesses.value('(@hostname)[1]','varchar(50)') as hostname
,DeadlockProcesses.value('(@hostpid)[1]','bigint') as hostpid
,DeadlockProcesses.value('(@loginname)[1]','varchar(150)') as loginname
,DeadlockProcesses.value('(@isolationlevel)[1]','varchar(150)') as isolationlevel
,DeadlockProcesses.value('(@xactid)[1]','bigint') as xactid
,DeadlockProcesses.value('(@currentdb)[1]','bigint') as currentdb
,DeadlockProcesses.value('(@lockTimeout)[1]','bigint') as lockTimeout
,DeadlockProcesses.value('(@clientoption1)[1]','bigint') as clientoption1
,DeadlockProcesses.value('(@clientoption2)[1]','bigint') as clientoption2
FROM (select EventXML as DeadlockEvent FROM CTE_HealthSession) T
CROSS APPLY DeadlockEvent.nodes('//deadlock/process-list/process') AS R(DeadlockProcesses)

DROP TABLE #SystemHealthSessionData