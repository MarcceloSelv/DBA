-- SQL Server Dangerous Settings
--
-- If any of the below setting are used (other than default) you will experience issues. 
-- Only use these settings if recommended by Microsoft Suppport. 

SET NOCOUNT ON;
GO  
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
    SELECT [name], [description], [value_in_use]	
	INTO #SQL_Server_Settings	
	FROM master.sys.configurations		
	where [name] = 'affinity64 mask'
			or [name] = 'affinity I/O mask'
			or [name] = 'affinity64 I/O mask'
			or [name] = 'lightweight pooling'
			or [name] = 'priority boost'
			or [name] = 'max worker threads'
GO

EXEC sp_configure 'show advanced options', 0;
GO
RECONFIGURE;
GO	
-----------------------------------------------------
-- Testing area - unremark this section of the script to test outputs

--update #SQL_Server_Settings	 set [value_in_use]	 = 1 where [name] = 'affinity64 mask'
--GO
--update #SQL_Server_Settings	 set [value_in_use]	 = 1 where [name] = 'affinity64 I/O mask'
--GO
--update #SQL_Server_Settings	 set [value_in_use]	 = 1 where [name] = 'affinity I/O mask'
--GO
--update #SQL_Server_Settings	 set [value_in_use]	 = 1 where [name] = 'lightweight pooling'
--GO
--update #SQL_Server_Settings	 set [value_in_use]	 = 1 where [name] = 'priority boost'
--GO
--update #SQL_Server_Settings	 set [value_in_use]	 = 1 where [name] = 'max worker threads'
--GO
-- remark the above section to run against actual values
-----------------------------------------------------

PRINT '  '
PRINT '  '
PRINT '	Analyzing Dangerous Settings in SQL Server '
PRINT '  '
DECLARE 
			 @Valuedescript VARCHAR(100), @ValueName VARCHAR (100), @ValueInUse VARCHAR (100)

DECLARE DangerousSettings 
CURSOR FOR SELECT  [description] ,[name] ,CONVERT(VARCHAR (100),[value_in_use]) FROM #SQL_Server_Settings	

OPEN DangerousSettings 
	FETCH NEXT FROM DangerousSettings INTO @Valuedescript, @ValueName,@ValueInUse
	WHILE @@FETCH_STATUS = 0
	BEGIN
	IF @ValueInUse = 0
		BEGIN
			PRINT @Valuedescript +'  -  '+ @ValueName +'  =  '+ @ValueInUse + ' --> Setting is good'
		END
	ELSE
	BEGIN
		PRINT '*** WARNING!!! DO NOT USE!  ' + @Valuedescript +': is set to '+@ValueInUse + ' --> Change this setting back to default! ***'
			
	IF @ValueName = 'max worker threads' 
	BEGIN
		PRINT '  '
		PRINT 'Max Work Threads setting my cause blocking and thread pool issues/errors.'
		PRINT 'When all worker threads are active with long running queries, SQL Server may appear unresponsive until' 
		PRINT 'a worker thread completes and becomes available. Though not a defect, this can sometimes be undesirable.'
		PRINT 'If a process appears to be unresponsive and no new queries can be processed, then connect to SQL Server'
		PRINT 'using the dedicated administrator connection (DAC), and kill the process.' 
		PRINT '** Only use if requested by Microsoft Support **'
		PRINT 'The default value for this option in sp_configure is 0.'
	END

	IF @ValueName = 'priority boost' 
		BEGIN
		PRINT '  '
		PRINT '"Boost SQL Server priority" setting will drain OS and network functions and causes issues/errors.' 
		PRINT 'Raising the priority too high may drain resources from essential operating system and network functions, '
		PRINT 'resulting in problems shutting down SQL Server or using other operating system tasks on the server. '
		PRINT '** Only use if requested by Microsoft Support ** '
		PRINT 'The default value for this option in sp_configure is 0.'
	END

	IF @ValueName = 'lightweight pooling' 
	BEGIN
		PRINT ' '
		PRINT '"Use Windows fibers (lightweight pooling)". By setting lightweight pooling to 1 causes SQL Server to switch to fiber mode scheduling. '
		PRINT 'Common language runtime (CLR) execution is not supported under lightweight pooling. Disable one of two options: "clr enabled" or "lightweight pooling". '
		PRINT 'Features that rely upon CLR and that do not work properly in fiber mode include the hierarchy data type, replication, and Policy-Based Management.'
		PRINT 'CLR, replication and extended stored procedures will fail and/or not work.'
		PRINT '** Only use if requested by Microsoft Support **' 
		PRINT 'The default value for this option in sp_configure is 0.'
	END

	IF @ValueName like 'affinity%' 
	BEGIN
		PRINT ' '
		PRINT 'I/O and processor affinity changes will cause strange issues/errors and is not necessary on and 64 bit server.'
		PRINT 'Do not configure CPU affinity in the Windows operating system and also configure the affinity mask in SQL Server.'
		PRINT 'These settings are attempting to achieve the same result, and if the configurations are inconsistent, you may have'
		PRINT 'unpredictable results. SQL Server CPU affinity is best configured using the sp_configure option in SQL Server.'
		PRINT 'Using the GUI, under server properties select the "Automatically set processor affinity mask for all processors" and'
		PRINT 'select the "Automatically set I/O affinity mask for all processors". This will correct the issues.'
		PRINT '** Only use if requested by Microsoft Support **' 
		PRINT 'The default value for this option in sp_configure is 0.'
	END
	
 END
PRINT  ' '
FETCH NEXT FROM DangerousSettings INTO @Valuedescript, @ValueName,@ValueInUse
END

CLOSE DangerousSettings
DEALLOCATE DangerousSettings

PRINT ' ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ '
PRINT 'If any of the settings are used (other than default) you will experience issues. Only use these settings if recommended by Microsoft Suppport.' 
PRINT 'You can change the settings with SP_CONFIGURE or the GUI (right click on server, select properties and select Processors'

DROP table #SQL_Server_Settings	
GO