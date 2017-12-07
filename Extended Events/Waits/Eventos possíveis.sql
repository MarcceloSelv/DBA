SELECT [name], * FROM sys.dm_xe_object_columns
  WHERE [object_name] = 'sql_statement_completed';
GO

SELECT xp.[name], xo.*
FROM sys.dm_xe_objects xo, sys.dm_xe_packages xp
WHERE xp.[guid] = xo.[package_guid]
   AND xo.[object_type] = 'action'
ORDER BY xp.[name];