CREATE MESSAGE TYPE
       [//AWDB/InternalAct/RequestMessage]
       VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE
       [//AWDB/InternalAct/ReplyMessage]
       VALIDATION = WELL_FORMED_XML;
GO


CREATE CONTRACT [//AWDB/InternalAct/SampleContract]
      ([//AWDB/InternalAct/RequestMessage]
       SENT BY INITIATOR,
       [//AWDB/InternalAct/ReplyMessage]
       SENT BY TARGET
      );
GO

CREATE QUEUE TargetQueueIntAct;

CREATE SERVICE
       [//AWDB/InternalAct/TargetService]
       ON QUEUE TargetQueueIntAct
          ([//AWDB/InternalAct/SampleContract]);
GO

CREATE QUEUE InitiatorQueueIntAct;

CREATE SERVICE
       [//AWDB/InternalAct/InitiatorService]
       ON QUEUE InitiatorQueueIntAct;
GO

DROP TABLE ##TraceTest2

SELECT 
	[conversation_handle] = [conversation_handle],
	message_body = CAST(message_body AS nvarchar(200)),
	message_type_name = message_type_name
INTO	##TraceTest2
FROM 
	TargetQueueIntAct


go
ALTER PROCEDURE TargetActivProc
AS
DECLARE @RecvReqDlgHandle UNIQUEIDENTIFIER;
DECLARE @RecvReqMsg NVARCHAR(200);
DECLARE @RecvReqMsgName sysname;
DECLARE @RecTable as Table ([conversation_handle] UNIQUEIDENTIFIER, message_body varbinary(max), message_type_name sysname);

	WHILE (1=1)
	    BEGIN
		BEGIN TRANSACTION;

		BEGIN TRY

			WAITFOR
			(	RECEIVE TOP(1)
					conversation_handle,
					message_body,
					message_type_name
				FROM
					TargetQueueIntAct
				INTO
					@RecTable
			), TIMEOUT 1000;

			IF (@@ROWCOUNT = 0)
			    BEGIN
				ROLLBACK TRANSACTION;
				BREAK;
			    END

			Select Top 1 @RecvReqDlgHandle = @RecTable

			--IF @RecvReqMsgName = N'//AWDB/InternalAct/RequestMessage'
			IF EXISTS(SELECT 1 FROM @RecTable WHERE message_type_name = N'//AWDB/InternalAct/RequestMessage')
			    BEGIN
				PRINT 'AQUI'
				WAITFOR DELAY '00:00:02'

				INSERT INTO ##TraceTest2
				SELECT 
					conversation_handle,
					CAST(message_body AS nvarchar(200)),
					message_type_name
				FROM 
					@RecTable
			    END
			ELSE IF @RecvReqMsgName =
				N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
			    BEGIN
				INSERT ##TraceTest2 (message_body)
				SELECT 'TESTE'

				END CONVERSATION @RecvReqDlgHandle;
			    END
			ELSE IF @RecvReqMsgName =
				N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
			    BEGIN
				INSERT ##TraceTest2 (message_body)
				SELECT 'TESTE2'

				END CONVERSATION @RecvReqDlgHandle;
			    END
		END TRY
		BEGIN CATCH
				--INSERT ##TraceTest2 (message_body)
				--SELECT TESTE = CAST( ERROR_MESSAGE() AS varchar(200))
				--INTO ##TESTE
		
                  declare @error int, @message nvarchar(4000);

                  select @error = ERROR_NUMBER(), @message = ERROR_MESSAGE();

		  Select @RecvReqDlgHandle

                  end conversation @RecvReqDlgHandle with error = @error description = @message;

		END CATCH
      
		COMMIT TRANSACTION;
	    END
GO

ALTER QUEUE TargetQueueIntAct
    WITH ACTIVATION
    ( STATUS = ON,
      --PROCEDURE_NAME = TargetActivProc,
      --MAX_QUEUE_READERS = 10,
      EXECUTE AS SELF
    );
GO



DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
DECLARE @RequestMsg NVARCHAR(100);

BEGIN TRANSACTION;

BEGIN DIALOG @InitDlgHandle
     FROM SERVICE
      [//AWDB/InternalAct/InitiatorService]
     TO SERVICE
      N'//AWDB/InternalAct/TargetService'
     ON CONTRACT
      [//AWDB/InternalAct/SampleContract]
     WITH
         ENCRYPTION = OFF;

-- Send a message on the conversation
SELECT @RequestMsg =
       N'<RequestMsg>Message for Target service.</RequestMsg>';

SEND ON CONVERSATION @InitDlgHandle
     MESSAGE TYPE 
     [//AWDB/InternalAct/RequestMessage]
     (@RequestMsg);

-- Diplay sent request.
--SELECT @RequestMsg AS SentRequestMsg;

--select * from TargetQueueIntAct

COMMIT TRANSACTION;

--select * from TargetQueueIntAct
GO 10

EXEC TargetActivProc

--truncate table ##TraceTest2
select * from ##TraceTest2
--select CAST(message_body AS NVARCHAR(4000)), * from InitiatorQueueIntAct
select * from TargetQueueIntAct

--select * from sys.service_queues
--select * from sys.dm_server_services
--select * from sys.dm_broker_queue_monitors
--select * from sys.dm_broker_connections
select * FROM sys.transmission_queue AS tq