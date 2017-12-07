--Before you can plan a better file structure for your user database, you may want to know read/write ratio of user database tables.

--Here you are

	SELECT object_name(s.object_id) as usertable,
       SUM(user_seeks + user_scans + user_lookups) as reads, 
	   SUM(user_updates) as writes, 
	   SUM(user_seeks + user_scans + user_lookups+user_updates)  as totalIO,
	
		CASE 
			WHEN SUM(user_seeks + user_scans + user_lookups+user_updates) >0
				then round(SUM(user_seeks + user_scans + user_lookups)*100/SUM(user_seeks + user_scans + user_lookups+user_updates),0)
				else 0
		END
		AS readratio,
		CASE 
			WHEN SUM(user_seeks + user_scans + user_lookups+user_updates) >0
				then SUM(user_updates)*100/SUM(user_seeks + user_scans + user_lookups+user_updates)
				else 0
		END
		AS writeratio
FROM sys.dm_db_index_usage_stats AS s
INNER JOIN sys.indexes AS i
ON s.object_id = i.object_id
AND i.index_id = s.index_id
WHERE objectproperty(s.object_id,'IsUserTable') = 1
--AND s.database_id = @dbid
--GROUP BY object_name(s.object_id)

GROUP BY s.object_id

--order by totalIO desc,readratio desc,reads desc,writeratio desc,writes desc

order by totalIO DESC, writes desc,writeratio desc
