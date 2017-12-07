ALTER PROCEDURE dbo.spGetKpi_Top14
    (
   @iDelay AS INT = 10
    )
AS

/***********************************************************************************************************
 Purpose:      Gets top 14 Key Performance Indicators (KPI).   This is a replacement for various perfmons statistics.  
               DMV's are used which are a lower resource use than perfmon.
               The statistics are collected over a specified interval and returned as a recordset.  This may show up 
               as a long running process on some monitoring systems due to the WAITFOR verb being used.

                Information on sys.dm_os_performance_counters can be found here: 
                http://technet.microsoft.com/en-us/library/ms187743.aspx
                http://technet.microsoft.com/en-us/library/ms189628.aspx
                http://technet.microsoft.com/en-us/library/ms189628.aspx
 
 Created Date: 06/29/2012
 Written by:   Monte Kottman

 Modification:

 Proc Name:    spGetKPI_Top14

 Inputs:       iDelay                     Number of seconds to delay while collecting statistics.

 Outputs:      [Event Date]               Starting Date / Time of the reporting period.
               [SQL Proc Utiliz %]        Percentage of the CPU that SQL is utilizing.
               [CPU Idle %]               Percentage of the CPU that is doing nothing.
               [Other Proc Utiliz %]      Percentage of the CPU used by other processes.
               [User Connections]         The number of users currently connected to the SQL Server. 
               [Logins Per Sec]           The number of logins per second.
               [Logouts Per Sec]          The number of logouts per second.
               [% Page Splits Per Batch]  Number of page splits per second that occur as the result of overflowing index pages. 
               [Buffer Cache Hit Ratio]   Percentage of pages found in the buffer cache without having to read from disk. 
               [Page Life Expectancy]     How long data pages are staying in the buffer. 
               [Latch Waits Per Sec]      Number of latch requests that could not be granted immediately. 
               [Total Latch Wait Time]    Total latch wait time (in milliseconds) for latch requests in the last second
               [Lock Waits Per Sec]       How many users waited to acquire a lock over the past second.  
               [Number of Deadlocks/sec]  The number of lock requests that resulted in a deadlock. 
               [Batch Requests Per sec]   Number of batch requests that SQL Server receives per second. 

 Dependencies: NONE

 Tested on:    SQL Server 2005, 2008, 2012

 Usage:        Standalone

 Example:      EXEC spGetKPI_Top14 10

***********************************************************************************************************/
SET NOCOUNT ON
                                                          /***********************
                                                          ** Declare supporting data structures
                                                         ***********************/
DECLARE
   @sDelayDuration   AS CHAR(8),
   @nBuffCachHit     AS Numeric(10,2),
   @iPageLife        AS BIGINT,
   @biDeadLock       AS BIGINT,
   @iUserCon         AS BIGINT,
   @dtStart          AS DATETIME,
   @sStartDate       AS VARCHAR(20),
   @fSeconds         AS FLOAT,
   @iBatchStart      AS BIGINT,
   @iBatchEnd        AS BIGINT,
   @iLogInStart      AS BIGINT,
   @iLogInEnd        AS BIGINT,
   @iLogOutStart     AS BIGINT,
   @iLogOutEnd       AS BIGINT,
   @iPageSplitStr    AS BIGINT,
   @iPageSplitEnd    AS BIGINT,
   @iLatchStart      AS BIGINT,
   @iLatchEnd        AS BIGINT,
   @iLatchTmStart    AS BIGINT,
   @iLatchTmEnd      AS BIGINT,
   @iLockWaitStart   AS BIGINT,
   @iLockWaitEnd     AS BIGINT
                                                          /***********************
                                                          ** Assign Variables.
                                                         ***********************/
SET @dtStart = GETDATE()

SET @sDelayDuration ='00:00:' + CAST(@iDelay AS VARCHAR)

SET @iBatchStart = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='Batch Requests/sec')
SET @iLogInStart = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='Logins/sec')
SET @iLogOutStart = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='Logouts/sec')
SET @iPageSplitStr =  (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='page splits/sec')
SET @iUserCon = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='User Connections');
SET @iLatchStart = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='Latch Waits/sec');
SET @iLatchTmStart = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='Total Latch Wait Time (ms)');
SET @iLockWaitStart = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='Lock Waits/sec' And Instance_Name = '_Total');


SET @nBuffCachHit = 
   (SELECT cast(cntr_value as float) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio') 
   /
   (SELECT cast(cntr_value AS FLOAT) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio base') *100

SET @biDeadLock = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name = 'Number of Deadlocks/sec' AND instance_name = 'Database')
SET @iPageLife = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE object_name LIKE '%Buffer Manager%' AND counter_name = 'Page life expectancy')
SET @sStartDate = @dtStart;

WAITFOR DELAY @sDelayDuration

SET @fSeconds = DATEDIFF(ss, @dtStart, GETDATE())
SET @iBatchEnd = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='Batch Requests/sec')
SET @iLogInEnd = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='Logins/sec')
SET @iLogOutEnd = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='Logouts/sec')
SET @iPageSplitEnd = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='page splits/sec')
SET @iLatchEnd = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='Latch Waits/sec')
SET @iLatchTmEnd = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='Total Latch Wait Time (ms)');
SET @iLockWaitEnd = (SELECT cntr_value FROM sys.dm_os_performance_counters WHERE counter_name ='Lock Waits/sec' And Instance_Name = '_Total');
                                                          /***********************
                                                          ** Display Results.
                                                         ***********************/
SELECT TOP 1
   @dtStart                                                                                        AS [Event DateTime],
   SQLProcessUtilization                                                                           AS [SQL Proc Utiliz %],
   SystemIdle                                                                                      AS [CPU Idle %],
   100 - SystemIdle - SQLProcessUtilization                                                        AS [Other Proc Utiliz %],
   @iUserCon                                                                                       AS [User Connections],
   CAST((@iLogInEnd - @iLogInStart)/ @fSeconds AS Numeric(10,2))                                   AS [Logins Per Sec],
   CAST((@iLogOutEnd - @iLogOutStart)/ @fSeconds AS Numeric(10,2))                                 AS [Logouts Per Sec],
   CASE WHEN (@ibatchEnd - @iBatchStart) = 0 THEN 
      CAST(0.00 AS Numeric(10,2))
   ELSE
         CAST((CAST((@iPageSplitEnd -@iPageSplitStr) AS FLOAT)/
               CAST((@ibatchEnd - @iBatchStart) AS FLOAT) * 100) AS Numeric(10,2))  
   END                                                                                             AS [% Page Splits Per Batch],
   CAST(@nBuffCachHit AS VARCHAR)                                                                  AS [Buffer Cache Hit Ratio %],     
   @iPageLife                                                                                      AS [Page Life Expectancy],   
   CAST((@iLatchEnd - @iLatchStart)/ @fSeconds AS Numeric(10,2))                                   AS [Latch Waits Per Sec],
   CAST((@iLatchTmEnd - @iLatchTmStart)/ @fSeconds AS Numeric(10,2))                               AS [Total Latch Wait Time (ms)],
   CAST((@iLockWaitEnd - @iLockWaitStart)/ @fSeconds AS Numeric(10,2))                             AS [Lock Waits Per Sec],
   CAST(@biDeadLock AS NUMERIC(10,2))                                                              AS [Number of Deadlocks/sec],
   CAST((@ibatchEnd - @iBatchStart)/ @fSeconds AS Numeric(10,2))                                   AS [Batch Requests Per sec]
FROM
   (
   SELECT
      record.value('(./Record/@id)[1]', 'int')                                                     AS record_id,
      record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int')           AS SystemIdle,
      record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int')   AS SQLProcessUtilization,
      timestamp
   FROM
      (
      SELECT
         timestamp, CONVERT(xml, record) AS record
      FROM
         sys.dm_os_ring_buffers
      WHERE
         ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' AND
         record LIKE '%<SystemHealth>%'
      ) AS x
   ) AS y
ORDER BY
   record_id desc
GO



exec dbo.spGetKpi_Top14 @iDelay = 10