SELECT pkg.name, pkg.description, mod.* 
FROM sys.dm_os_loaded_modules mod 
INNER JOIN sys.dm_xe_packages pkg 
ON mod.base_address = pkg.module_address

select pkg.name as PackageName, obj.name as EventName 
from sys.dm_xe_packages pkg 
inner join sys.dm_xe_objects obj on pkg.guid = obj.package_guid 
where obj.object_type = 'event' 
order by 1, 2

select pkg.name as PackageName, obj.name as ActionName 
from sys.dm_xe_packages pkg 
inner join sys.dm_xe_objects obj on pkg.guid = obj.package_guid 
where obj.object_type = 'action' 
order by 1, 2

select pkg.name as PackageName, obj.name as TargetName 
from sys.dm_xe_packages pkg 
inner join sys.dm_xe_objects obj on pkg.guid = obj.package_guid 
where obj.object_type = 'target' 
order by 1, 2

select pkg.name as PackageName, obj.name as PredicateName 
from sys.dm_xe_packages pkg 
inner join sys.dm_xe_objects obj on pkg.guid = obj.package_guid 
where obj.object_type = 'pred_source' 
order by 1, 2

CREATE EVENT SESSION [query hash] ON SERVER
ADD EVENT sqlserver.sp_statement_completed(
    ACTION(package0.collect_system_time,
           sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name)
    WHERE ([sqlserver].[query_hash]=(3117177188303046689.))),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(package0.collect_system_time,
           sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name)
    WHERE ([sqlserver].[query_hash]=(3117177188303046689.)))
ADD TARGET package0.asynchronous_file_target
(SET filename = 'C:\temp\XEventSessions\query_hash.xel',
     metadatafile = 'C:\temp\XEventSessions\query_hash.xem',
     max_file_size=5,
     max_rollover_files=5)
WITH (MAX_DISPATCH_LATENCY = 5SECONDS);
GO




drop event session [Waits] on server
go
Create Event Session [Waits]
on server
add event sqlserver.sql_statement_starting
(action
            (sqlserver.session_id, package0.collect_system_time,
package0.collect_cpu_cycle_time,sqlserver.sql_text,
sqlserver.plan_handle, sqlos.task_address, sqlos.worker_address)
         /*where sqlserver.session_id = 53*/  ),
add event sqlserver.sql_statement_completed
(action
(sqlserver.session_id, package0.collect_system_time, package0.collect_cpu_cycle_time, sqlserver.sql_text,
sqlserver.plan_handle, sqlos.task_address, sqlos.worker_address)
      /*where sqlserver.session_id = 53*/
     ),
add event sqlos.wait_info
            (action (sqlserver.session_id,  package0.collect_system_time, package0.collect_cpu_cycle_time, sqlos.task_address, sqlos.worker_address)
	    WHERE (duration > 5000)
       /*where sqlserver.session_id = 53*/)
--
--          async file, read with: sys.fn_xe_file_target_read_file
--
 ADD TARGET package0.asynchronous_file_target
(SET	filename = N'E:\SIGNA\Waits.xel', 
	metadatafile = N'E:\SIGNA\Waits.xem',
	max_file_size = 50, 
	max_rollover_files = 5)
--ADD TARGET package0.asynchronous_bucketizer
--(     SET source_type=1, -- specifies bucketing on Action 
--         source='sqlserver.database_id' -- Action to bucket on
--)
Alter Event Session [Waits] on Server State = start
--go
--xp_dirtree 'E:\Signa\', 0 ,1 

--xp_cmdshell 'del e:\signa\waits*'


IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='Waits')
    DROP EVENT SESSION [Waits] ON SERVER;

CREATE EVENT SESSION [Waits]
ON SERVER
ADD EVENT sqlos.wait_info
(    ACTION (sqlserver.database_id, sqlserver.session_id,  package0.collect_system_time, package0.collect_cpu_cycle_time, sqlos.task_address, sqlos.worker_address)
    WHERE (duration > 5000)) 
ADD TARGET package0.ring_buffer(
 SET max_memory=12096)
GO
ALTER EVENT SESSION [Waits]
ON SERVER
STATE=START


SELECT 
    mv.map_value AS WaitType,
    n.value('(@count)[1]', 'int') AS EventCount,
    n.value('(@trunc)[1]', 'int') AS EventsTrunc,
    n.value('(value)[1]', 'int') AS MapKey,
    target_data
FROM
(SELECT CAST(target_data as XML) target_data
FROM sys.dm_xe_sessions AS s 
JOIN sys.dm_xe_session_targets t
    ON s.address = t.event_session_address
WHERE s.name = 'Waits'
  AND t.target_name = 'asynchronous_bucketizer') as tab
outer APPLY target_data.nodes('BucketizerTarget/Slot') as q(n)
JOIN sys.dm_xe_map_values as mv
    ON mv.map_key = n.value('(value)[1]', 'int')
WHERE mv.name = 'wait_types'



select top 5 cast(event_data as xml), * from sys.fn_xe_file_target_read_file ('E:\SIGNA\Waits*.xel', 'E:\SIGNA\Waits*.xem', null, null)

SELECT * FROM sys.dm_xe_sessions AS s 