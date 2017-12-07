SET NOCOUNT ON
IF (CHARINDEX ('9.00', @@VERSION) = 0) BEGIN
  PRINT ''
  PRINT '**** NOTE ****'
  PRINT '**** This script is for SQL Server 2005.  Errors are expected when run on earlier versions.'
  PRINT '**************'
  PRINT ''
END
ELSE BEGIN
  PRINT 'This script captures a one-time snapshot of SQL performance-related info. It is executed '
  PRINT 'once at collector startup, and again at shutdown. For the perf stats script that remains '
  PRINT 'running and captures regular shapshots of server state, see the output file named '
  PRINT '[SERVER]_[INSTANCE]_SQL_2005_Perf_Stats_Startup.OUT'
  PRINT ''
END
GO
DECLARE @runtime datetime 
DECLARE @cpu_time_start bigint, @cpu_time bigint, @elapsed_time_start bigint, @rowcount bigint
DECLARE @queryduration int, @qrydurationwarnthreshold int
DECLARE @querystarttime datetime
SET @runtime = GETDATE()
SET @qrydurationwarnthreshold = 5000

PRINT ''
PRINT ''
PRINT ''
PRINT 'Start time: ' + CONVERT (varchar, @runtime, 126)
PRINT ''
PRINT '==============================================================================================='
PRINT 'Top N Query Plan Statistics: '
PRINT 'For certain workloads, the sys.dm_exec_query_stats DMV can be a very useful way to identify '
PRINT 'the most expensive queries without a profiler trace. The query output below shows the top 50 '
PRINT 'query plans by CPU, physical reads, and total query execution time. However, be cautious of '
PRINT 'relying on this DMV alone, as it has some sigificant limitations. In particular: '
PRINT ' - This query provides a view of query plans in the procedure cache. However, not every query '
PRINT '   plan will be inserted into the cache. For example, a DBCC DBREINDEX might be an extremely '
PRINT '   expensive operation, but the plan for this query will not be cached, and its execution '
PRINT '   statistics will therefore not be reflected by this query. '
PRINT ' - A plan can be removed from cache at any time. The sys.dm_exec_query_stats DMV can only show ' 
PRINT '   statistics for plans that are still in cache.'
PRINT ' - The statistics exposed by sys.dm_exec_query_stats are cumulative for the lifetime for the '
PRINT '   query plan, but not all plans in cache have the same lifetime. For example, the query plan '
PRINT '   that is the most expensive right now might not appear to be the most expensive if it has '
PRINT '   only been in cache for a short period. Another query plan that is less expensive over any '
PRINT '   given period of time might seem more expensive because its statistics have been '
PRINT '   accumulating for a longer period. '
PRINT ' - Execution statistics are only recorded in the DMV at the end of query execution. Thge DMV '
PRINT '   may not reflect the execution cost for a long-running query that is still in-progress. ' 
PRINT ' - sys.dm_exec_query_stats only reflects the cost of query execution. Query compilation, plan ' 
PRINT '   lookup, and other pre-execution costs are not reflected in statistics.' 
PRINT ' - Any query plan that contains inline literals and is not explicitly or implicitly ' 
PRINT '   parameterized will not be reused. Every execution of this query with different parameter '
PRINT '   values will get a new compiled plan. If a query does not see consistent plan reuse, the '
PRINT '   sys.dm_exec_query_stats DMV will not show the cumulative cost of that query in a single row.'
PRINT ''
PRINT '-- Top N Query Plan Statistics --'
SELECT @cpu_time_start = cpu_time FROM sys.dm_exec_requests WHERE session_id = @@SPID
SET @querystarttime = GETDATE()
SELECT 
  CONVERT (varchar, @runtime, 126) AS runtime, 
  LEFT (p.cacheobjtype + ' (' + p.objtype + ')', 35) AS cacheobjtype,
  p.usecounts, p.size_in_bytes / 1024 AS size_in_kb, 
  PlanStats.total_worker_time/1000 AS tot_cpu_ms, PlanStats.total_elapsed_time/1000 AS tot_duration_ms, 
  PlanStats.total_physical_reads, PlanStats.total_logical_writes, PlanStats.total_logical_reads,
  PlanStats.CpuRank, PlanStats.PhysicalReadsRank, PlanStats.DurationRank, 
  LEFT (CASE 
    WHEN pa.value=32767 THEN 'ResourceDb' 
    ELSE ISNULL (DB_NAME (CONVERT (sysname, pa.value)), CONVERT (sysname,pa.value))
  END, 40) AS dbname,
  sql.objectid, 
  CONVERT (nvarchar(50), CASE 
    WHEN sql.objectid IS NULL THEN NULL 
    ELSE REPLACE (REPLACE (sql.[text],CHAR(13), ' '), CHAR(10), ' ')
  END) AS procname, 
  REPLACE (REPLACE (SUBSTRING (sql.[text], PlanStats.statement_start_offset/2 + 1, 
      CASE WHEN PlanStats.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), sql.[text])) 
        ELSE PlanStats.statement_end_offset/2 - PlanStats.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' ') AS stmt_text 
FROM 
(
  SELECT 
    stat.plan_handle, statement_start_offset, statement_end_offset, 
    stat.total_worker_time, stat.total_elapsed_time, stat.total_physical_reads, 
    stat.total_logical_writes, stat.total_logical_reads, 
    ROW_NUMBER() OVER (ORDER BY stat.total_worker_time DESC) AS CpuRank, 
    ROW_NUMBER() OVER (ORDER BY stat.total_physical_reads DESC) AS PhysicalReadsRank, 
    ROW_NUMBER() OVER (ORDER BY stat.total_elapsed_time DESC) AS DurationRank 
  FROM sys.dm_exec_query_stats stat 
) AS PlanStats 
INNER JOIN sys.dm_exec_cached_plans p ON p.plan_handle = PlanStats.plan_handle 
OUTER APPLY sys.dm_exec_plan_attributes (p.plan_handle) pa 
OUTER APPLY sys.dm_exec_sql_text (p.plan_handle) AS sql
WHERE (PlanStats.CpuRank < 50 OR PlanStats.PhysicalReadsRank < 50 OR PlanStats.DurationRank < 50)
  AND pa.attribute = 'dbid' 
ORDER BY tot_cpu_ms DESC

SET @rowcount = @@ROWCOUNT
SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
IF @queryduration > @qrydurationwarnthreshold
BEGIN
  SELECT @cpu_time = cpu_time - @cpu_time_start FROM sys.dm_exec_requests WHERE session_id = @@SPID
  PRINT ''
  PRINT 'DebugPrint: perfstats_snapshot_querystats - ' + CONVERT (varchar, @queryduration) + 'ms, ' 
    + CONVERT (varchar, @cpu_time) + 'ms cpu, '
    + 'rowcount=' + CONVERT(varchar, @rowcount) 
  PRINT ''
END


PRINT ''
PRINT '==============================================================================================='
PRINT 'Missing Indexes: '
PRINT 'The "improvement_measure" column is an indicator of the (estimated) improvement that might '
PRINT 'be seen if the index was created.  This is a unitless number, and has meaning only relative '
PRINT 'the same number for other indexes.  The measure is a combination of the avg_total_user_cost, '
PRINT 'avg_user_impact, user_seeks, and user_scans columns in sys.dm_db_missing_index_group_stats.'
PRINT ''
PRINT '-- Missing Indexes --'
SELECT CONVERT (varchar, @runtime, 126) AS runtime, 
  mig.index_group_handle, mid.index_handle, 
  CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) AS improvement_measure, 
  'CREATE INDEX missing_index_' + CONVERT (varchar, mig.index_group_handle) + '_' + CONVERT (varchar, mid.index_handle) 
  + ' ON ' + mid.statement 
  + ' (' + ISNULL (mid.equality_columns,'') 
    + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END + ISNULL (mid.inequality_columns, '')
  + ')' 
  + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement, 
  migs.*, mid.database_id, mid.[object_id]
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) > 10
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC
PRINT ''
GO

PRINT ''
PRINT '-- Current database options --'
SELECT LEFT ([name], 128) AS [name], 
  dbid, cmptlevel, 
  CONVERT (int, (SELECT SUM (CONVERT (bigint, [size])) * 8192 / 1024 / 1024 FROM master.dbo.sysaltfiles f WHERE f.dbid = d.dbid)) AS db_size_in_mb, 
  LEFT (
  'Status=' + CONVERT (sysname, DATABASEPROPERTYEX ([name],'Status')) 
  + ', Updateability=' + CONVERT (sysname, DATABASEPROPERTYEX ([name],'Updateability')) 
  + ', UserAccess=' + CONVERT (varchar(40), DATABASEPROPERTYEX ([name], 'UserAccess')) 
  + ', Recovery=' + CONVERT (varchar(40), DATABASEPROPERTYEX ([name], 'Recovery')) 
  + ', Version=' + CONVERT (varchar(40), DATABASEPROPERTYEX ([name], 'Version')) 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAutoCreateStatistics') = 1 THEN ', IsAutoCreateStatistics' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAutoUpdateStatistics') = 1 THEN ', IsAutoUpdateStatistics' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsShutdown') = 1 THEN '' ELSE ', Collation=' + CONVERT (varchar(40), DATABASEPROPERTYEX ([name], 'Collation'))  END
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAutoClose') = 1 THEN ', IsAutoClose' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAutoShrink') = 1 THEN ', IsAutoShrink' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsInStandby') = 1 THEN ', IsInStandby' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsTornPageDetectionEnabled') = 1 THEN ', IsTornPageDetectionEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAnsiNullDefault') = 1 THEN ', IsAnsiNullDefault' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAnsiNullsEnabled') = 1 THEN ', IsAnsiNullsEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAnsiPaddingEnabled') = 1 THEN ', IsAnsiPaddingEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAnsiWarningsEnabled') = 1 THEN ', IsAnsiWarningsEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsArithmeticAbortEnabled') = 1 THEN ', IsArithmeticAbortEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsCloseCursorsOnCommitEnabled') = 1 THEN ', IsCloseCursorsOnCommitEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsFullTextEnabled') = 1 THEN ', IsFullTextEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsLocalCursorsDefault') = 1 THEN ', IsLocalCursorsDefault' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsNumericRoundAbortEnabled') = 1 THEN ', IsNumericRoundAbortEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsQuotedIdentifiersEnabled') = 1 THEN ', IsQuotedIdentifiersEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsRecursiveTriggersEnabled') = 1 THEN ', IsRecursiveTriggersEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsMergePublished') = 1 THEN ', IsMergePublished' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsPublished') = 1 THEN ', IsPublished' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsSubscribed') = 1 THEN ', IsSubscribed' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsSyncWithBackup') = 1 THEN ', IsSyncWithBackup' ELSE '' END
  , 512) AS status
FROM master.dbo.sysdatabases d
GO

-- Get stats_date for all db's
PRINT ''
PRINT '==== STATS_DATE and rowmodctr for indexes in all databases ===='
EXEC master..sp_MSforeachdb @command1 = '
PRINT ''''
PRINT ''-- STATS_DATE and rowmodctr for [?].sysindexes --''', 
  @command2 = '
use [?]
select db_id() as dbid, 
  case 
    when indid IN (0, 1) then convert (char (12), rows)
    else (select rows from [?].dbo.sysindexes i2 where i2.id =  i.id and i2.indid in (0,1)) -- ''-''
  end as rowcnt, 
  case 
    when indid IN (0, 1) then rowmodctr
    else convert (bigint, rowmodctr) + (select rowmodctr from [?].dbo.sysindexes i2 where i2.id =  i.id and i2.indid in (0,1))
  end as row_mods, 
  case rows when 0 then 0 else convert (bigint, 
    case 
      when indid IN (0, 1) then convert (bigint, rowmodctr)
      else rowmodctr + (select convert (bigint, rowmodctr) from [?].dbo.sysindexes i2 where i2.id =  i.id and i2.indid in (0,1))
    end / convert (numeric (20,2), (select case convert (bigint, rows) when 0 then 0.01 else rows end from [?].dbo.sysindexes i2 where i2.id =  i.id and i2.indid in (0,1))) * 100) 
  end as pct_mod, 
  convert (nvarchar, u.name + ''.'' + o.name) as objname, 
  case when i.status&0x800040=0x800040 then ''AUTOSTATS''
    when i.status&0x40=0x40 and i.status&0x800000=0 then ''STATS''
    else ''INDEX'' end as type, 
  convert (nvarchar, i.name) as idxname, i.indid, 
  stats_date (o.id, i.indid) as stats_updated, 
  case i.status & 0x1000000 when 0 then ''no'' else ''*YES*'' end as norecompute, 
  o.id as objid , rowcnt, i.status 
from [?].dbo.sysobjects o, [?].dbo.sysindexes i, [?].dbo.sysusers u 
where o.id = i.id and o.uid = u.uid and i.indid between 1 and 254 and o.type = ''U''
order by pct_mod desc, convert (nvarchar, u.name + ''.'' + o.name), indid
'
GO

PRINT 'End time: ' + CONVERT (varchar, GETDATE(), 126)
PRINT 'Done.'
GO

