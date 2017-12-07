

drop table temp_trace_table
go
SELECT id = row_number()over(order by (select 1)), t.*
INTO temp_trace_table
FROM ::fn_trace_gettable('D:\Signa\Traces\Trace_Block_DeadLock.trc', default) t
go
Select	top 300 id, Cast(TextData as xml), StartTime, EndTime, Duration
From	temp_trace_table
Where   TextData not like '%sp_MSforeachdb%'
And EndTime < '2015-10-28 16:47:20.557' --2015-10-28 17:54:54.757 / 2015-10-28 17:46:16.410 / 2015-10-28 17:38:20.377 / 2015-10-28 16:48:40.670 / 2015-10-28 17:33:14.843
Order By id desc

select * from sys.traces


exec sp_trace_setstatus 2, 0 ---start trace


SELECT @@ServerName, * FROM :: fn_trace_getinfo(default)


SELECT 
 	e.name AS Event_Name, 
 	c.name AS Column_Name
FROM fn_trace_geteventinfo(1) ei
JOIN sys.trace_events e ON ei.eventid = e.trace_event_id 
JOIN sys.trace_columns c ON ei.columnid = c.trace_column_id

SELECT 
 	*
FROM fn_trace_getfilterinfo(1) ei
JOIN sys.trace_columns c ON ei.columnid = c.trace_column_id


exec sp_trace_getdata 2, 1