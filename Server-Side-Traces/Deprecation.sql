SET NOCOUNT ON;

DECLARE
   @trace_id INT,
   @sql      NVARCHAR(MAX),
                                                                                                        -- this will create C:\traces\deprecated_n.trc:
   @path     NVARCHAR(256) = N'E:\MS SQL Database\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\Deprecated';


DECLARE @events TABLE(event_id SMALLINT);

INSERT  @events(event_id) SELECT *
   FROM sys.trace_events WHERE trace_event_id IN (126);

DECLARE @columns TABLE(column_id SMALLINT);

INSERT  @columns(column_id) SELECT trace_column_id
   FROM sys.trace_columns WHERE trace_column_id IN (1, 3, 8, 10, 11, 12, 14, 34, 63);

--SELECT *
--FROM sys.trace_columns WHERE trace_column_id IN (1, 3, 8, 10, 11, 12, 14, 34, 63);

--Select * From @columns
--Select * From @columns

-- create the trace
EXEC sp_trace_create @traceid = @trace_id OUTPUT, @options = 2, @tracefile = @path;

exec sp_trace_setfilter @traceid = @trace_id, @columnid = 3, @logical_operator = 0, @comparison_operator = 0, @value = 5

-- build dynamic SQL will all the setevent calls
SELECT @sql = COALESCE(@sql, N'') + N'EXEC sp_trace_setevent @traceid = '
       + CONVERT(VARCHAR(5), @trace_id)   + ', @eventid = ' 
       + CONVERT(VARCHAR(5), e.event_id)  + ', @columnid = ' 
       + CONVERT(VARCHAR(5), c.column_id) + ', @on = 1;
   ' FROM @events AS e CROSS JOIN @columns AS c;

Print @sql

EXEC sp_executesql @sql;

-- turn the trace on
EXEC sp_trace_setstatus @traceid = @trace_id, @status = 1;

SELECT trace_id = @trace_id;

--EXEC sp_trace_setstatus @traceid = 11, @status = 2;