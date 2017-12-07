--http://dba.stackexchange.com/questions/34313/identify-blocking-and-send-alert

ALTER DATABASE msdb set ENABLE_BROKER WITH ROLLBACK IMMEDIATE


select service_broker_guid, * from sys.databases WHERE NAME = 'msdb'

use msdb

CREATE QUEUE BlockedProcessQueue

CREATE SERVICE BlockedProcessService ON QUEUE BlockedProcessQueue ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification])
GO

USE MASTER
GO
ALTER PROCEDURE StartBlockedProcessNotification
AS
CREATE EVENT NOTIFICATION BlockedProcessNotification 
	ON SERVER 
	FOR BLOCKED_PROCESS_REPORT 
	TO SERVICE 'BlockedProcessService',
	'A76A1B13-D585-42EB-A68B-218570961783' --Substituir
GO

EXEC sp_procoption 'StartBlockedProcessNotification', 'startup', 'on'
GO
EXEC StartBlockedProcessNotification
GO

use msdb
GO

/****** Object:  Table [dbo].[BlockNotification]    Script Date: 11/19/2015 6:29:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[BlockNotification](
	[Mensagem] [xml] NULL,
	[DataHora] [datetime] NULL,
	[Duration] [int] NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[ObjectID] [int] NULL,
	[BlockingSQLText] [xml] NULL,
	[BlockedSQLText] [xml] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO



SET ANSI_NULLS ON 
SET QUOTED_IDENTIFIER ON
/*
If Object_ID('SB_DBA_Blocked_Notifications', 'P') Is Not Null
        Drop Procedure SB_DBA_Blocked_Notifications
*/
go
 
CREATE Proc SB_DBA_Blocked_Notifications
as
declare
		@Msg varbinary(max)
		,@Ch uniqueidentifier
		,@MsgType sysname      
		,@Report xml
		,@EventDate datetime
		,@DBID smallint
		,@EventType varchar(128)
		,@Sql_handle varbinary(max)
		,@StmtStart int
		,@StmtEnd int
		,@BlockedSQLText xml
		,@BlockingSQLText xml
		,@InputBuffer xml
       
	while 1 = 1
		begin
			begin try
				begin tran
				-- for simplicity sake of that example
				-- we are processing data in one-by-one facion
				-- rather than load everything to the temporary
				-- table variable
				waitfor 
				(
					receive top (1)
						@ch = conversation_handle
						,@Msg = message_body
						,@MsgType = message_type_name
					from dbo.BlockedProcessQueue
				), timeout 10000

				if @@ROWCOUNT = 0
					begin
						rollback
						break
					end

				if @MsgType = N'http://schemas.microsoft.com/SQL/Notifications/EventNotification'
					begin
						select 
						@EventDate = convert(xml,@Msg).value('/EVENT_INSTANCE[1]/StartTime[1]','datetime')
						,@DBID = convert(xml,@Msg).value('/EVENT_INSTANCE[1]/DatabaseID[1]','smallint')
						,@EventType = convert(xml,@Msg).value('/EVENT_INSTANCE[1]/EventType[1]','varchar(128)')
						
						if @EventType = 'BLOCKED_PROCESS_REPORT'
							begin
								/*
								
								Implementar

								Declare @Text varchar(max) = ''

								Select 
									@Text += Ltrim(Rtrim(Isnull(txt.StatementText, ''))) + CHAR(13) + CHAR(10) + REPLICATE('-', 200) + CHAR(13) + CHAR(10) 
								From
									@Report.nodes('/blocked-process-report[1]/blocking-process[1]/process[1]/executionStack/frame') t(frame)
									Cross Apply (Select	stmtstart = isnull(t.frame.value('@stmtstart','int'), 0),
												stmtend = isnull(t.frame.value('@stmtend','int'), 0),
												sqlhandle = t.frame.value('xs:hexBinary(substring((@sqlhandle)[1],3))','varbinary(max)')
									) x
									Cross Apply master.dbo.FN_Get_Statement_SQL_Handle(stmtstart, stmtend, sqlhandle) txt

								Select Cast(@Text as xml)

								*/


								select            
									@Report = convert(xml,@Msg).query('/EVENT_INSTANCE[1]/TextData[1]/*')

								Select 
									@Sql_handle = @Report.value('xs:hexBinary(substring((/blocked-process-report[1]/blocked-process[1]/process[1]/executionStack[1]/frame[1]/@sqlhandle)[1],3))','varbinary(max)')
									,@StmtStart = isnull(@Report.value('/blocked-process-report[1]/blocked-process[1]/process[1]/executionStack[1]/frame[1]/@stmtstart','int'), 0)
									,@StmtEnd = isnull(@Report.value('/blocked-process-report[1]/blocked-process[1]/process[1]/executionStack[1]/frame[1]/@stmtend','int'), -1)
									,@InputBuffer = Cast(@Report.value('/blocked-process-report[1]/blocked-process[1]/process[1]/inputbuf[1]','varchar(max)') as xml)

								If Not IsNull(@Sql_handle,0x) = 0x
								    Begin
										Select	@BlockedSQLText = t.StatementTextXml
										From	master.dbo.FN_Get_Statement_Sql_Handle(@StmtStart, @StmtEnd, @Sql_handle) t
									End
								Else
									Set @BlockedSQLText = @InputBuffer

								Select 
									@Sql_handle = @Report.value('xs:hexBinary(substring((/blocked-process-report[1]/blocking-process[1]/process[1]/executionStack[1]/frame[1]/@sqlhandle)[1],3))','varbinary(max)')
									,@StmtStart = isnull(@Report.value('/blocked-process-report[1]/blocking-process[1]/process[1]/executionStack[1]/frame[1]/@stmtstart','int'), 0)
									,@StmtEnd = isnull(@Report.value('/blocked-process-report[1]/blocking-process[1]/process[1]/executionStack[1]/frame[1]/@stmtend','int'), -1)
									,@InputBuffer = Cast(@Report.value('/blocked-process-report[1]/blocking-process[1]/process[1]/inputbuf[1]','varchar(max)') as xml)

								If Not IsNull(@Sql_handle,0x) = 0x
								    Begin
										Select	@BlockingSQLText = t.StatementTextXml
										From	master.dbo.FN_Get_Statement_Sql_Handle(@StmtStart, @StmtEnd, @Sql_handle) t
									End
								Else
									Set @BlockingSQLText = @InputBuffer

								Insert BlockNotification
								Select
										Mensagem = @Report--x.message_body_xml.query('/EVENT_INSTANCE/TextData/*')
										,DataHora = ev.c.value('(PostTime)[1]', 'datetime')
										,Duration = ev.c.value('(Duration)[1]', 'int')
										,StartTime = ev.c.value('(StartTime)[1]', 'datetime')
										,EndTime = ev.c.value('(EndTime)[1]', 'datetime')
										,ObjectID = ev.c.value('(ObjectID)[1]', 'int')
										,BlockingSQLText = @BlockingSQLText
										,BlockedSQLText = @BlockedSQLText
								From
										(Select message_body_xml = Cast(@Msg as xml)) x
										Cross Apply x.message_body_xml.nodes('/EVENT_INSTANCE') ev(c)


								Delete From BlockNotification Where DataHora < Getdate()-15
								-- Perhaps send email here?
							end -- @EventType = BLOCKED_PROCESS_REPORT
					end -- @MsgType = http://schemas.microsoft.com/SQL/Notifications/EventNotification
				else if @MsgType = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
					end conversation @ch
				-- else handle errors here
			commit
		end try
		begin catch
			-- capture info about error message here      
			if @@TRANCOUNT > 0
				rollback;      

			Select Error_Message()

			Begin Try
				Insert BlockNotification (Mensagem)
				Select Cast(@Msg as xml)
			End Try
			Begin Catch
				Insert BlockNotification (Mensagem)
				Select @Msg
			End Catch

			end conversation @ch

			-- perhaps add some Email Notification here
			-- Do not forget about the fact that SP is running from Service Broker
			-- you need to either setup certificate based security or set TRUSTWORTHY ON
			-- in order to use DB Mail
			break
		end catch
	end
 
 
 
 
go
 
Grant Execute On dbo.SB_DBA_Blocked_Notifications To Public
go


ALTER QUEUE BlockedProcessQueue WITH ACTIVATION (
    STATUS = ON,
    PROCEDURE_NAME = [SB_DBA_Blocked_Notifications],
    MAX_QUEUE_READERS = 2,
    EXECUTE AS OWNER
)

--select * from BlockedProcessQueue
--select * from BlockNotification

--truncate table BlockNotification