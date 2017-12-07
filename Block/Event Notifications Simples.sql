CREATE QUEUE sysEventQueue
go

CREATE SERVICE sysEventService
    ON QUEUE sysEventQueue ( [http://schemas.microsoft.com/SQL/Notifications/PostEventNotification] )
go

DROP EVENT NOTIFICATION Notify_Locks ON SERVER

CREATE EVENT NOTIFICATION Notify_Locks
    ON SERVER
    WITH fan_in
    FOR blocked_process_report
    TO SERVICE 'sysEventService', 'current database';
go

CREATE EVENT NOTIFICATION Notify_Alter
ON DATABASE
FOR ALTER_TABLE
TO SERVICE 'sysEventService', 'current database';

SELECT  *
FROM	syseventqueue

select * from sys.dm_broker_queue_monitors
select * from sys.service_queues
select is_broker_enabled, * from sys.databases



ALTER DATABASE ECARGO SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE

/****** Script do comando SelectTopNRows de SSMS  ******/
SELECT TOP 1000 *, casted_message_body = 
CASE message_type_name WHEN 'X' 
  THEN CAST(message_body AS NVARCHAR(MAX)) 
  ELSE message_body 
END 
FROM [ECARGO].[dbo].[BlockedProcessNotificationQueue] WITH(NOLOCK)


CREATE ROUTE NotifyRoute
WITH SERVICE_NAME = 'sysEventService',
ADDRESS = 'LOCAL';
GO

SELECT * FROM sys.server_event_notifications

SP_CONFIGURE 'blocked process threshold (s)'


DECLARE @msgs TABLE (   message_body xml not null,
                        message_sequence_number int not null );
 
RECEIVE message_body, message_sequence_number
FROM syseventqueue
INTO @msgs;
 
SELECT message_body,
       DatabaseId = cast( message_body as xml ).value( '(/EVENT_INSTANCE/DatabaseID)[1]', 'int' ),
       Process    = cast( message_body as xml ).query( '/EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process' )
FROM @msgs
ORDER BY message_sequence_number

SELECT * FROM sys.server_event_notifications

SELECT cast( message_body as xml ), *
FROM syseventqueue