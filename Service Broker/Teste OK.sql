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

SELECT 
	[conversation_handle] = [conversation_handle],
	message_body = CAST(message_body AS nvarchar(100)),
	message_type_name = message_type_name
INTO	##TraceTest2
FROM 
	TargetQueueIntAct

go
alter PROCEDURE TargetActivProc
AS
DECLARE @RecvReqDlgHandle UNIQUEIDENTIFIER;
DECLARE @RecvReqMsg NVARCHAR(100);
DECLARE @RecvReqMsgName sysname;

	WHILE (1=1)
	    BEGIN
		BEGIN TRANSACTION;

		WAITFOR
		( RECEIVE TOP(1)
			@RecvReqDlgHandle = conversation_handle,
			@RecvReqMsg = message_body,
			@RecvReqMsgName = message_type_name
		FROM	TargetQueueIntAct
		), TIMEOUT 5000;

		IF (@@ROWCOUNT = 0)
		    BEGIN
			ROLLBACK TRANSACTION;
			BREAK;
		    END

		IF @RecvReqMsgName = N'//AWDB/InternalAct/RequestMessage'
		    BEGIN
			WAITFOR DELAY '00:00:02'

			INSERT INTO ##TraceTest2
			SELECT @RecvReqDlgHandle, @RecvReqMsg, @RecvReqMsgName;
		    END
		ELSE IF @RecvReqMsgName = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
		    BEGIN
			END CONVERSATION @RecvReqDlgHandle;
		    END
		ELSE IF @RecvReqMsgName = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
		    BEGIN
			END CONVERSATION @RecvReqDlgHandle;
		    END
      
		COMMIT TRANSACTION;
	    END
GO

ALTER QUEUE TargetQueueIntAct
    WITH ACTIVATION
    ( STATUS = ON,
      PROCEDURE_NAME = TargetActivProc,
      MAX_QUEUE_READERS = 10,
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

COMMIT TRANSACTION;
GO 10


--truncate table ##TraceTest2
select * from ##TraceTest2
select * from InitiatorQueueIntAct
select * from TargetQueueIntAct