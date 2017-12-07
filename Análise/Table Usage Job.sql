-- You have a TOOLS database, right?
-- If not, create one, you will thank me later
USE TOOLS;
GO

-- A place for everything, everything in its place
IF SCHEMA_ID('meta') IS NULL
	EXEC('CREATE SCHEMA meta;')
GO

-- This table will hold index usage summarized at table level
CREATE TABLE meta.index_usage(
       db_name sysname,
       schema_name sysname,
       object_name sysname,
       read_count bigint,
       last_read datetime,
       write_count bigint,
       last_write datetime,
       PRIMARY KEY CLUSTERED (db_name, schema_name, object_name)
)

-- This table will hold the last snapshot taken
-- It will be used to capture the snapshot and
-- merge it with the destination table
CREATE TABLE meta.index_usage_last_snapshot(
       db_name sysname,
       schema_name sysname,
       object_name sysname,
       read_count bigint,
       last_read datetime,
       write_count bigint,
       last_write datetime,
       PRIMARY KEY CLUSTERED (db_name, schema_name, object_name)
)
GO

-- This procedure captures index usage stats
-- and merges the stats with the ones already captured
CREATE PROCEDURE meta.record_index_usage
AS
BEGIN

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#stats') IS NOT NULL
       DROP TABLE #stats;

-- We will use the index stats multiple times, so parking
-- them in a temp table is convenient
CREATE TABLE #stats(
       db_name sysname,
       schema_name sysname,
       object_name sysname,
       read_count bigint,
       last_read datetime,
       write_count bigint,
       last_write datetime,
       PRIMARY KEY CLUSTERED (db_name, schema_name, object_name)
);

-- Reads index usage stats and aggregates stats at table level
-- Aggregated data is saved in the temporary table
WITH index_stats AS (
       SELECT DB_NAME(database_id) AS db_name,
              OBJECT_SCHEMA_NAME(object_id,database_id) AS schema_name,
              OBJECT_NAME(object_id, database_id) AS object_name,
              user_seeks + user_scans + user_lookups AS read_count,
              user_updates AS write_count,
              last_read = (
                  SELECT MAX(value)
                  FROM (
                      VALUES(last_user_seek),(last_user_scan),(last_user_lookup)
                  ) AS v(value)
              ),
              last_write = last_user_update
       FROM sys.dm_db_index_usage_stats
       WHERE DB_NAME(database_id) NOT IN ('master','model','tempdb','msdb')
)
INSERT INTO #stats
SELECT db_name,
       schema_name,
       object_name,
       SUM(read_count) AS read_count,
       MAX(last_read) AS last_read,
       SUM(write_count) AS write_count,
       MAX(last_write) AS last_write
FROM index_stats
GROUP BY db_name,
       schema_name,
       object_name;

DECLARE @last_date_in_snapshot datetime;
DECLARE @sqlserver_start_date datetime;

-- reads maximum read/write date from the data already saved in the last snapshot table
SELECT @last_date_in_snapshot = MAX(CASE WHEN last_read > last_write THEN last_read ELSE last_write END)
FROM meta.index_usage_last_snapshot;

-- reads SQL Server start time
SELECT @sqlserver_start_date = sqlserver_start_time FROM sys.dm_os_sys_info;

-- handle restarted server: last snapshot is before server start time
IF (@last_date_in_snapshot) < (@sqlserver_start_date)
       TRUNCATE TABLE meta.index_usage_last_snapshot;

-- handle snapshot table empty
IF NOT EXISTS(SELECT * FROM meta.index_usage_last_snapshot)
       INSERT INTO meta.index_usage_last_snapshot
       SELECT * FROM #stats;

-- merges data in the target table with the new collected data
WITH offset_stats AS (
       SELECT newstats.db_name,
              newstats.schema_name,
              newstats.object_name,
              -- if new < old, the stats have been reset
              newstats.read_count -
                  CASE
                      WHEN newstats.read_count < ISNULL(oldstats.read_count,0) THEN 0
                      ELSE ISNULL(oldstats.read_count,0)
                  END
                  AS read_count,
              newstats.last_read,
              -- if new < old, the stats have been reset
              newstats.write_count -
                  CASE
                      WHEN newstats.write_count < ISNULL(oldstats.write_count,0) THEN 0
                      ELSE ISNULL(oldstats.write_count,0)
                  END
              AS write_count,
              newstats.last_write
       FROM #stats AS newstats
       LEFT JOIN meta.index_usage_last_snapshot AS oldstats
              ON newstats.db_name = oldstats.db_name
              AND newstats.schema_name = oldstats.schema_name
              AND newstats.object_name = oldstats.object_name
)
MERGE INTO meta.index_usage AS dest
USING offset_stats AS src
       ON src.db_name = dest.db_name
       AND src.schema_name = dest.schema_name
       AND src.object_name = dest.object_name
WHEN MATCHED THEN
       UPDATE SET read_count += src.read_count,
              last_read = src.last_read,
              write_count += src.write_count,
              last_write = src.last_write
WHEN NOT MATCHED BY TARGET THEN
       INSERT VALUES (
           src.db_name,
           src.schema_name,
           src.object_name,
           src.read_count,
           src.last_read,
           src.write_count,
           src.last_write
       );

-- empty the last snapshot
TRUNCATE TABLE meta.index_usage_last_snapshot;

-- replace it with the new collected data
INSERT INTO meta.index_usage_last_snapshot
SELECT * FROM #stats;

END

GO