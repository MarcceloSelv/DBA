USE master;

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET NOCOUNT ON;
-- --------------------------------------------------------------------------------------------------------
-- DROP OBJECTS IF THEY EXIST
-- --------------------------------------------------------------------------------------------------------
IF EXISTS ( SELECT  *
           FROM    sys.server_triggers
           WHERE   name = N'Logon_Audit' )
   BEGIN
       DROP TRIGGER Logon_Audit ON ALL SERVER;
   END;
GO
IF EXISTS ( SELECT  1
           FROM    sys.tables
           WHERE   [object_id] = OBJECT_ID(N'dbo.Logon_Events') )
   BEGIN;
       DROP TABLE dbo.Logon_Events;
   END;
-- --------------------------------------------------------------------------------------------------------
-- CREATE THE LOGGING TABLE
-- --------------------------------------------------------------------------------------------------------
CREATE TABLE dbo.Logon_Events
   (
     ServerName NVARCHAR(100) NOT NULL ,
     LoginName NVARCHAR(100) NOT NULL ,
     LoginType NVARCHAR(100) NOT NULL ,
     AppName NVARCHAR(128) NOT NULL ,
     PostTime_Minimum DATETIME NOT NULL ,
     PostTime_Maximum DATETIME NOT NULL ,
     Logon_Count BIGINT NOT NULL,
);

ALTER TABLE dbo.Logon_Events ADD CONSTRAINT pkLogon_Events PRIMARY KEY CLUSTERED (ServerName, LoginName, LoginType, AppName) WITH FILLFACTOR = 90;
GO
DECLARE @extended_property_value NVARCHAR(300);
SET @extended_property_value = SYSTEM_USER + N' '
   + CONVERT(CHAR(23), CURRENT_TIMESTAMP, 126)
   + N': audit table to log all DDL events on the server.';
EXECUTE sp_addextendedproperty @name = N'MS_Description',
   @value = @extended_property_value, @level0type = 'SCHEMA',
   @level0name = N'dbo', @level1type = 'TABLE', @level1name = N'logon_Events',
   @level2type = NULL, @level2name = NULL;
GO
-- --------------------------------------------------------------------------------------------------------
-- SET UP SECURITY
-- --------------------------------------------------------------------------------------------------------
--LOGIN
IF NOT EXISTS ( SELECT  *
               FROM    sys.server_principals
               WHERE   name = N'Auditor'
                       AND type_desc = N'SQL_LOGIN' )
   BEGIN;
       CREATE LOGIN Auditor WITH PASSWORD = 'y%&pQNGR*7@Mv5';
   END;
--USER
IF NOT EXISTS ( SELECT  *
               FROM    sys.database_principals
               WHERE   name = N'Auditor'
                       AND type_desc = N'SQL_USER' )
   BEGIN;
       CREATE USER Auditor FROM LOGIN Auditor;
   END;
--ROLE
IF NOT EXISTS ( SELECT  *
               FROM    sys.database_principals
               WHERE   name = N'db_auditor'
                       AND type_desc = N'DATABASE_ROLE' )
   BEGIN;
       CREATE ROLE db_auditor;
   END;
--ADD ROLE MEMBER
ALTER ROLE db_auditor ADD MEMBER Auditor;
--GRANT
GRANT INSERT,UPDATE,SELECT ON dbo.Logon_Events TO db_auditor;
GO
-- --------------------------------------------------------------------------------------------------------
-- CREATE THE SERVER TRIGGER
-- --------------------------------------------------------------------------------------------------------
/*
Name:
(C) Andy Jones
mailto:andrew@aejsoftware.co.uk

Example usage: -
Perform a DDL action and then run: -
USE master;
SELECT * FROM dbo.Logon_Events;

Description: -

Change History: -
1.0 01/09/2015 Created.
*/
CREATE TRIGGER Logon_Audit ON ALL SERVER
   WITH EXECUTE AS 'Auditor'
   FOR LOGON
AS
   SET NOCOUNT ON;

   DECLARE @data XML = EVENTDATA();

   MERGE dbo.Logon_Events AS TargetTable
   USING
       ( SELECT    PostTime = COALESCE(@data.value('(/EVENT_INSTANCE/PostTime)[1]',
                                                   'datetime'), '19000101') ,
                   ServerName = COALESCE(@data.value('(/EVENT_INSTANCE/ServerName)[1]',
                                                     'nvarchar(100)'),
                                         N'UNKNOWN') ,
                   AppName = COALESCE(APP_NAME(), N'UNKNOWN') ,
                   LoginName = COALESCE(@data.value('(/EVENT_INSTANCE/LoginName)[1]',
                                                    'nvarchar(100)'),
                                        N'UNKNOWN') ,
                   LoginType = COALESCE(@data.value('(/EVENT_INSTANCE/LoginType)[1]',
                                                    'nvarchar(100)'),
                                        N'UNKNOWN')
       ) AS SourceData
   ON TargetTable.ServerName = SourceData.ServerName
       AND TargetTable.LoginName = SourceData.LoginName
       AND TargetTable.LoginType = SourceData.LoginType
       AND TargetTable.AppName = SourceData.AppName
   WHEN MATCHED THEN
       UPDATE SET
              TargetTable.PostTime_Maximum = SourceData.PostTime ,
              TargetTable.Logon_Count = TargetTable.Logon_Count + 1
   WHEN NOT MATCHED THEN
       INSERT ( ServerName ,
                LoginName ,
                LoginType ,
                AppName ,
                PostTime_Minimum ,
                PostTime_Maximum ,
                Logon_Count 
              )
       VALUES ( SourceData.ServerName ,
                SourceData.LoginName ,
                SourceData.LoginType ,
                SourceData.AppName ,
                SourceData.PostTime ,
                SourceData.PostTime ,
                1
              );
GO