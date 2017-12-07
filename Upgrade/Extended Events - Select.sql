
SELECT top 500 * FROM DeprecationFeatures WHERE feature = 'Non-ANSI *= or =* outer join operators'  order by 1 desc

--TRUNCATE TABLE DeprecationFeatures
go
exec SP_WHO3 1
go
INSERT DeprecationFeatures
 SELECT 
   data.value ('(/event/@timestamp)[1]', 'datetime') - 0.0833333 AS [timestamp],-- GETUTCDATE();
   data.value ('(/event/@name)[1]', 'varchar(100)') AS [event.name],
   data.value ('(/event/data[@name=''feature'']/value)[1]', 'varchar(300)') AS [feature],
   --data.value ('(/event[@name=''sql_statement_completed'']/@timestamp)[1]', 'DATETIME') AS [Time],
   data.value ('(/event/data[@name=''message'']/value)[1]', 'varchar(500)') AS [message],
   data.value ('(/event/action[@name=''database_id'']/value)[1]', 'int') AS [database_id],
   data.value ('(/event/action[@name=''sql_text'']/value)[1]', 'VARCHAR(MAX)') AS [SQL Statement],
   data.value ('(/event/action[@name=''tsql_stack'']/value)[1]', 'VARCHAR(MAX)') AS [tsql_stack],
   data.value ('(/event/action[@name=''client_app_name'']/value)[1]', 'VARCHAR(300)') AS [client_app_name],
      --SUBSTRING (data.value ('(/event/action[@name=''plan_handle'']/value)[1]', 'VARCHAR(100)'), 15, 50)
      --AS [Plan Handle]
   data.query('.') text_xml
FROM
   (
	SELECT CONVERT (XML, event_data) AS data 
	FROM sys.fn_xe_file_target_read_file
		  ('E:\Database\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ExtendedEvents\Monitor_Deprecated_Discontinued_features*.xel', 
		  'E:\Database\MSSQL10_50.MSSQLSERVER\MSSQL\Log\ExtendedEvents\Monitor_Deprecated_Discontinued_features*.xem', null, null)
	) entries
	--Outer Apply
Where data.value ('(/event/@timestamp)[1]', 'datetime') - 0.0833333 > '20160210 16:14'
And	not exists(select 1 from DeprecationFeatures DF Where df.[timestamp] = data.value ('(/event/@timestamp)[1]', 'datetime') - 0.0833333)
ORDER BY 1 DESC;
GO
--SELECT * FROM sys.dm_exec_sql_text(0x050007004FFA2C0440E1294F020000000000000000000000)
--SELECT * FROM MASTER.DBO.FN_Get_Statement_Sql_Handle(1252, 1502, 0x020000004F5CFB233BCD3EE4B6BB355169BEDCEA3AA8EA5C)
EXEC SP_TRIGGER lancamento_operacao
EXEC SP_TRIGGER pessoa

--begin try
--	raiserror(13000, 16,1)

--end try 
--begin catch
--	select ERROR_MESSAGE()
--end catch

select * from DeprecationFeatures where [sql statement] NOT like '%exec%sp[_]%' AND [sql statement] NOT LIKE '%PESQ_MONITOR%'
--NOT FEATURE = 'Non-ANSI *= or =* outer join operators' 
AND NOT [sql statement] LIKE 'Select DISTINCT VF.VALE_FRETE_ID%'
ORDER BY 1

select * from DeprecationFeatures where [sql statement] like '%exec%sp[_]%' AND [sql statement] NOT LIKE '%PESQ_MONITOR%'
select * from DeprecationFeatures where [timestamp] >= dateadd(d, -1, sysdatetime()) AND NOT [sql statement] LIKE 'Select DISTINCT VF.VALE_FRETE_ID%'

--CREATE NONCLUSTERED INDEX IDX_FEATURE ON DeprecationFeatures(Feature,[event.name], timestamp)
--CREATE CLUSTERED INDEX IDX_TIMESTAMP ON DeprecationFeatures([TIMESTAMP])

--select * from ddlevents where objectname = 'SP_040_PIQ_REL_DIN_FAT_CTE_N_CONSOLIDADO'
