-- Capture query activity against a table using DMVs
DECLARE @TableName VARCHAR(255);

-- Specify the table you want to monitor
SET @TableName = 'Sales.SalesOrderDetail';

DECLARE @ObjectID INT;
SET @ObjectID = (SELECT OBJECT_ID(@TableName));

IF OBJECT_ID('tempdb..##Activity') IS NOT NULL
BEGIN
    DROP TABLE ##Activity;
END;

-- Create table
SELECT TOP 0 *
INTO ##Activity
FROM sys.dm_tran_locks WITH (NOLOCK);

-- Add additional columns
ALTER TABLE ##Activity
ADD SQLStatement VARCHAR(MAX),
SQLText VARCHAR(MAX),
LoginName VARCHAR(200),
HostName VARCHAR(50),
Transaction_Isolation VARCHAR(100),
DateTimeAdded DATETIME;

DECLARE @Rowcount INT = 0;

WHILE 1 = 1
BEGIN

    INSERT INTO ##Activity
    SELECT dtl.*
            ,SQLStatement       =
                SUBSTRING
                (
                    qt.text,
                    er.statement_start_offset/2,
                    (CASE WHEN er.statement_end_offset = -1
                        THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
                        ELSE er.statement_end_offset
                        END - er.statement_start_offset)/2
                )
            ,qt.text
            ,ses.login_name
            ,ses.host_name
            ,ses.transaction_isolation_level
            ,DateTimeAdded = GETDATE()
    FROM sys.dm_tran_locks dtl WITH (NOLOCK)
    LEFT JOIN sys.dm_exec_sessions ses
        ON ses.session_id = dtl.request_session_id
    LEFT JOIN sys.dm_exec_requests er WITH (NOLOCK)
        ON er.session_id = dtl.request_session_id
    OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
    WHERE dtl.resource_associated_entity_id = @ObjectID;


    SET @Rowcount = (SELECT @@ROWCOUNT)
    IF @Rowcount > 100 
    BEGIN
        BREAK;
    END;
    -- Wait 50 milliseconds
    WAITFOR DELAY '00:00:00.50';
    
END

SELECT *
FROM ##Activity