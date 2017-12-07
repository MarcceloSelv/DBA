SELECT sqlserver_start_time AS [SQLRestart], *
FROM sys.dm_os_sys_info

SELECT DATEADD(ms, -ms_ticks, GETDATE()) AS [ServerRestart]
FROM sys.dm_os_sys_info

SELECT *
FROM	sys.dm_os_wait_stats
ORDER BY 3 DESC

SELECT DATEADD(ms, -wait_time_ms, GETDATE()) AS [DMVRestart]
FROM sys.dm_os_wait_stats
WHERE wait_type = 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP'