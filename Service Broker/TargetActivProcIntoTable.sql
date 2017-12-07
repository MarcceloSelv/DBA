ALTER PROCEDURE TargetActivProcIntoTable
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