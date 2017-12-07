--create the table and service broker

CREATE TABLE test
(
id int identity(1,1),
contents varchar(100)
)

CREATE MESSAGE TYPE test

CREATE CONTRACT mycontract
(
test sent by initiator
)
GO
CREATE PROCEDURE dostuff
AS
BEGIN
    DECLARE @msg varchar(100);
    RECEIVE TOP (1) @msg = message_body FROM myQueue
    IF @msg IS NOT NULL
    BEGIN
        WAITFOR DELAY '00:00:02'
        INSERT INTO test(contents)values(@msg)
    END
END
GO
ALTER QUEUE myQueue
    WITH STATUS = ON,
    ACTIVATION (
        STATUS = ON,
        PROCEDURE_NAME = dostuff,
        MAX_QUEUE_READERS = 10,
        EXECUTE AS SELF
    )

create service senderService
on queue myQueue
(
mycontract
)

create service receiverService
on queue myQueue
(
mycontract
)
GO

--**********************************************************

--now insert lots of messages to the queue

DECLARE @dialog_handle uniqueidentifier

    BEGIN DIALOG @dialog_handle
        FROM SERVICE senderService
        TO SERVICE 'receiverService'
        ON CONTRACT mycontract;

    SEND
        ON CONVERSATION @dialog_handle
        MESSAGE TYPE test
        ('<test>1</test>');

    BEGIN DIALOG @dialog_handle
        FROM SERVICE senderService
        TO SERVICE 'receiverService'
        ON CONTRACT mycontract;

    SEND
        ON CONVERSATION @dialog_handle
        MESSAGE TYPE test
        ('<test>2</test>')

    BEGIN DIALOG @dialog_handle
        FROM SERVICE senderService
        TO SERVICE 'receiverService'
        ON CONTRACT mycontract;

    SEND
        ON CONVERSATION @dialog_handle
        MESSAGE TYPE test
        ('<test>3</test>')

BEGIN DIALOG @dialog_handle
        FROM SERVICE senderService
        TO SERVICE 'receiverService'
        ON CONTRACT mycontract;

    SEND
        ON CONVERSATION @dialog_handle
        MESSAGE TYPE test
        ('<test>4</test>')

BEGIN DIALOG @dialog_handle
        FROM SERVICE senderService
        TO SERVICE 'receiverService'
        ON CONTRACT mycontract;

    SEND
        ON CONVERSATION @dialog_handle
        MESSAGE TYPE test
        ('<test>5</test>')

BEGIN DIALOG @dialog_handle
        FROM SERVICE senderService
        TO SERVICE 'receiverService'
        ON CONTRACT mycontract;

    SEND
        ON CONVERSATION @dialog_handle
        MESSAGE TYPE test
        ('<test>6</test>')

    SEND
        ON CONVERSATION @dialog_handle
        MESSAGE TYPE test
        ('<test>7</test>')