/*************************************************************************************************************************************************
Sr. DBA 

Date		:	- Dec 9 2015
				

Comments	:	- Tested on SQL Server 2008R2 SP1 and up

Gist link	:	https://gist.githubusercontent.com/TheRockStarDBA/298a99e8c82378ac7cd4/raw/a471574681bfc3749d1d56667f9f79538b1f16e4/GetSQLServerInfo.sql


Usage		:	- You can use this script free unless you keep this header and give due credit to the author of this script which is ME :-)
				- This script can be run on any sql server 2008R2 SP1 and up version.

Disclaimer	: 
				- The views expressed on my posts on this site are mine alone and do not reflect the views of my company. All posts of mine are provided "AS IS" with no warranties, and confers no rights.
 
				- The following disclaimer applies to all code, scripts and demos available on my posts:
 				 
				- This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. 
 				 
				- I grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: 
 				 
					- (i) 	to use my name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
					- (ii) 	to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
					- (iii) to indemnify, hold harmless, and defend me from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
**************************************************************************************************************************************************/
if exists (
		select 1
		from (
			select CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') as nvarchar(128)), 4) as int) as Major
				,CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') as nvarchar(128)), 3) as int) as Minor
				,CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') as nvarchar(128)), 2) as int) as Build
				,CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') as nvarchar(128)), 1) as int) as Revision
			) as p
		-- remember the new dmvs sys.dm_server_services, sys.dm_server_memory_dumps and sys.dm_server_registry
		-- were introduced in SQL Server 2008R2 SP1 and up - Build 10.50.2500.0
		where (
				p.Major >= 10
				and p.Minor >= 50
				and p.Build >= 2500
				) -- equal to or more than 10.50.2500 which is 2008R2 SP1	(10.50.1600.1 is RTM)
			or (
				p.Major >= 11
				and p.Minor >= 0
				and p.Build >= 2100
				) -- equal to or more than 11.0.3000  which is 2012 SP1	(11.0.2100.60 is RTM)
			or (
				p.Major >= 12
				and p.Minor >= 0
				and p.Build >= 2000
				) -- equal to or more than 12.0.4100  which is 2014 SP1	(12.0.2000.8 is RTM)
		)
begin
	select @@SERVERNAME as [ServerName]
		,servicename as [Name]
		,startup_type_desc as [StartType]
		,status_desc as [Status]
		,process_id as [ProcessID]
		,service_account as [Service_Account]
		,[filename] as [SQLServer_Installation_Location]
		,CONVERT(varchar(20), last_startup_time, 100) as [Local_Server_Last_Startup_Time]
		,datediff(d, last_startup_time, getdate()) as [Server_UP_Days]
		,'Trace_Flags_Enabled_At_Startup' = (
			select distinct replace(STUFF((
							select ' ' + cast(value_data as varchar(max))
							from sys.dm_server_registry
							where cast(value_data as varchar(max)) like '%-T%'
							for xml PATH('') -- select it as XML
							), 1, 1, ' ') -- This will remove the first character ";" from the result
					, '�', '') -- This will remove the "�" else you will get  -traceFlag�
			from sys.dm_server_registry
			where cast(value_data as varchar(max)) like '%-T%'
			)
		,'Port_Number' = (
			select distinct value_data
			from sys.dm_server_registry
			where registry_key like N'%SuperSocketNetLib%ipall'
				and value_name = 'TcpPort'
				and value_data <> ''
			)
	from sys.dm_server_services
end
else
	print 'the server is running on a lower build than 2008R2 SP1'
