-- Create datbaase
CREATE DATABASE [EventNotificationsDB]
GO

-- Enable Service Broker
ALTER DATABASE [EventNotificationsDB]
SET ENABLE_BROKER;
GO

USE [EventNotificationsDB];
GO

-- Add previous Certificate to EventNotificationsDB
CREATE CERTIFICATE [DBMailCertificate]
FROM FILE = 'd:\Backup\DBMailCertificate.CER';
GO


/*  If the DBMailCertificate doesn't exist at all run this block of code. */
/*

-- Create a certificate to sign stored procedures with
CREATE CERTIFICATE [DBMailCertificate]
ENCRYPTION BY PASSWORD = '$tr0ngp@$$w0rd'
WITH SUBJECT = 'Certificate for signing TestSendMail Stored Procedure';
GO

-- Backup certificate so it can be create in master database
BACKUP CERTIFICATE [DBMailCertificate]
TO FILE = 'd:\Backup\DBMailCertificate.CER';
GO

-- Add Certificate to Master Database
USE [master]
GO
CREATE CERTIFICATE [DBMailCertificate]
FROM FILE = 'd:\Backup\DBMailCertificate.CER';
GO

-- Create a login from the certificate
CREATE LOGIN [DBMailLogin]
FROM CERTIFICATE [DBMailCertificate];
GO

-- The Login must have Authenticate Sever to access server scoped system tables
-- per http://msdn.microsoft.com/en-us/library/ms190785.aspx
GRANT AUTHENTICATE SERVER TO [DBMailLogin]
GO

-- Create a MSDB User for the Login
USE [msdb]
GO
CREATE USER [DBMailLogin] FROM LOGIN [DBMailLogin]
GO

-- Add msdb login/user to the DatabaseMailUserRole
EXEC msdb.dbo.sp_addrolemember @rolename = 'DatabaseMailUserRole', @membername = 'DBMailLogin';
GO

USE [EventNotificationsDB];
GO

*/



--  Create a service broker queue to hold the events
CREATE QUEUE EventNotificationQueue
GO

--  Create a service broker service receive the events
CREATE SERVICE EventNotificationService
    ON QUEUE EventNotificationQueue ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification])
GO

-- Create the event notification for ERRORLOG trace events on the service
CREATE EVENT NOTIFICATION CaptureErrorLogEvents
    ON SERVER
    WITH FAN_IN
    FOR ERRORLOG, DDL_TABLE_EVENTS
    TO SERVICE 'EventNotificationService', 'current database';
GO

-- Query the catalog to see the queue
SELECT *
FROM sys.service_queues
WHERE name = 'EventNotificationQueue';
GO

-- Query the catalog to see the service
SELECT *
FROM sys.services
WHERE name = 'EventNotificationService';
GO

-- Query the catalog to see the notification
SELECT * 
FROM sys.server_event_notifications 
WHERE name = 'CaptureErrorLogEvents';
GO

-- Test the Event Notification by raising an Error
RAISERROR (N'Test ERRORLOG Event Notifications', 10, 1) WITH LOG;
GO

-- View Queue Contents
SELECT *
FROM EventNotificationQueue;
GO

-- Cast message_body to XML
SELECT CAST(message_body AS XML) AS message_body_xml
FROM EventNotificationQueue;
GO

-- Receive the next available message FROM the queue
DECLARE @message_body xml;

RECEIVE TOP(1) -- just handle one message at a time
 @message_body=message_body
 FROM EventNotificationQueue;

SELECT @message_body;
GO

-- View Queue Contents
SELECT CAST(message_body AS XML), *
FROM EventNotificationQueue
ORDER BY queuing_order;
GO

-- Declare the table variable to hold the XML messages
DECLARE @messages TABLE
( message_data xml );

-- Receive the next available message FROM the queue
RECEIVE cast(message_body as xml)
FROM EventNotificationQueue
INTO @messages;

-- Parse the XML from the table variable
SELECT 
	message_data.value('(/EVENT_INSTANCE/EventType)[1]', 'varchar(128)' ) as EventType,
	message_data.value('(/EVENT_INSTANCE/PostTime)[1]', 'varchar(128)') AS PostTime,
	message_data.value('(/EVENT_INSTANCE/TextData)[1]', 'varchar(128)' ) AS TextData,
	message_data.value('(/EVENT_INSTANCE/Severity)[1]', 'varchar(128)' ) AS Severity,
	message_data.value('(/EVENT_INSTANCE/Error)[1]', 'varchar(128)' ) AS Error
FROM @messages;

SELECT * FROM @messages;
GO


-- Create an Activation Procedure for the Queue
CREATE PROCEDURE [dbo].[ProcessEventNotifications]
WITH EXECUTE AS OWNER
AS 
SET NOCOUNT ON
DECLARE @message_body xml 
DECLARE @email_message nvarchar(MAX)
WHILE (1 = 1)
BEGIN
	BEGIN TRANSACTION
	-- Receive the next available message FROM the queue
	WAITFOR (
		RECEIVE TOP(1) -- just handle one message at a time
			@message_body=message_body
			FROM dbo.EventNotificationQueue
	), TIMEOUT 1000  -- if the queue is empty for one second, give UPDATE and go away
	-- If we didn't get anything, bail out
	IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK TRANSACTION
			BREAK
		END 

	IF (@message_body.value('(/EVENT_INSTANCE/Severity)[1]', 'int' ) > 10) -- Error is not Informational
	BEGIN

	-- Generate formatted email message
	SELECT @email_message = 'The following event was logged in the SQL Server ErrorLog:' + CHAR(10) +
	'PostTime: ' + @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'varchar(128)') + CHAR(10) +
	'Error: ' + @message_body.value('(/EVENT_INSTANCE/Error)[1]', 'varchar(20)' )  + CHAR(10) +
	'Severity: ' + @message_body.value('(/EVENT_INSTANCE/Severity)[1]', 'varchar(20)' ) + CHAR(10) +
	'TextData: ' + @message_body.value('(/EVENT_INSTANCE/TextData)[1]', 'varchar(4000)' );
	-- Send email using Database Mail
    EXEC msdb.dbo.sp_send_dbmail
             @profile_name = 'SQL Monitor', -- your defined email profile 
             @recipients = 'dbagroup@domain.com', -- your email
             @subject = 'SQL Server Error Log Event',
             @body = @email_message;

	END
--  Commit the transaction.  At any point before this, we could roll 
--  back - the received message would be back on the queue AND the response
--  wouldn't be sent.
	COMMIT TRANSACTION
END
GO

-- Sign the procedure with the certificate's private key
ADD SIGNATURE TO OBJECT::[ ProcessEventNotifications]
BY CERTIFICATE [DBMailCertificate] 
WITH PASSWORD = '$tr0ngp@$$w0rd';
GO

--  Alter the Queue to add Activation Procedure
ALTER QUEUE EventNotificationQueue
WITH 
 ACTIVATION -- Setup Activation Procedure
	(STATUS=ON,
	 PROCEDURE_NAME = [ProcessEventNotifications],  -- Procedure to execute
	 MAX_QUEUE_READERS = 1, -- maximum concurrent executions of the procedure
	 EXECUTE AS OWNER) -- account to execute procedure under
GO

-- Test the Event Notification by raising an Error
RAISERROR (N'Test ERRORLOG Event Notifications', 10, 1)WITH LOG;

-- View Queue Contents
SELECT *
FROM EventNotificationQueue;

-- Test the Event Notification by raising an Error
RAISERROR (N'Test ERRORLOG Event Notifications', 16, 1) WITH LOG;

-- View Queue Contents
SELECT *
FROM EventNotificationQueue;

/*
-- Cleanup
USE [msdb]
GO
DROP USER [DBMailLogin]
GO
DROP EVENT NOTIFICATION CaptureErrorLogEvents ON SERVER
DROP SERVICE EventNotificationService
DROP QUEUE EventNotificationQueue
GO
USE [master]
GO
DROP LOGIN [DBMailLogin]
DROP CERTIFICATE [DBMailCertificate]
GO
DROP DATABASE [EventNotificationsDB]
GO

-- Delete the certificate backup from disk
*/
