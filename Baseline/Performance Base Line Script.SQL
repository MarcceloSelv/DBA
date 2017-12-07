USE [master]
GO
if exists(select 1 from sys.sysobjects where name=N'InstanceAnalysis_PerformanceBaseLine' and type=N'P')
begin
Drop procedure [dbo].[InstanceAnalysis_PerformanceBaseLine]
end

/****** Object:  StoredProcedure [dbo].[InstanceAnalysis_PerformanceBaseLine]    
Script Date: 1/17/2013 10:28:04 PM 
Created By Nirav Joshi
Copy Right By Nirav Joshi
Subject:This script will collect the performancebase line data from the diffrent DMV and performacen counter of the SQL Server.
Please let me know your feedback about the script any suggestion comment are most welcome 
Please drop me line at nirav.j05@gmail.com

******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[InstanceAnalysis_PerformanceBaseLine]
as

declare @ts_now bigint,
		@start_time varchar(20),
		@Server_Name varchar(100),
		@Server_ver varchar(500),
		@SQLSer_OSInfo varchar(500),
		@SQL_inst_date varchar(100),
		@MachineName varchar(100),
		@ServerName varchar(100),
		@SrvName_prop varchar(100),
		@Srv_Machine varchar(100),
		@InstName varchar(100),
		@IsCluster varchar(10),
		@CompNetbios varchar(200),
		@SqlEdition varchar(100),
		@SqlProductLevel varchar(10),
		@SqlProdVer varchar(10),
		@SqlProid varchar(10),
		@Sql_Ins_collation varchar(100),
		@IsfullText varchar(10),
		@IsInterSec varchar(10),
		@LogicalCPUCount varchar(10),
		@HTRatio varchar(10),
		@PhyCPUCount varchar(10),
		@PhyRAM_MB varchar(10),
		@Proc_Value varchar(200),
		@Proc_date Varchar(500),
		@Sp_config_Name varchar(500),
		@Sp_config_value varchar(10),
		@Sp_config_inusevalue varchar(10),
		@Sp_config_des varchar(1000),
		@db_det_name varchar(400),
		@db_det_fileid varchar(200),
		@db_det_filename varchar(200),
		@db_det_phyfilename varchar(4000),
		@db_det_filedesc varchar(100),
		@db_det_statedesc varchar(200),
		@db_det_filesizeMB varchar(20),
		@db_log_info_dbname varchar(500),
		@db_log_info_rmodle varchar(500),
		@db_log_info_logreusewait varchar(500),
		@db_log_info_logsizekb varchar(200),
		@db_log_info_logusedkb varchar(200),
		@db_log_info_logusedper varchar(200),
		@db_log_info_dbcmptlevel varchar(200),
		@db_log_info_pageverify varchar(200),
		@db_log_info_autstats varchar(10),
		@db_log_info_autoupdstats varchar(10),
		@db_log_info_autstatsasyncon varchar(10),
		@db_log_info_parameterrizatio varchar(10),
		@db_log_info_snapshotisolation varchar(50),
		@db_log_info_readcommitedsnapshot varchar(50),
		@db_log_info_autoclose varchar(10),
		@db_log_info_autoshrink varchar(10),
		@IO_DBName varchar(100),
		@IO_PhyName varchar(5000),
		@io_stall_read_ms real,
		@io_num_of_reads bigint,
		@io_avg_read_stall_ms real,
		@io_stall_write_ms real,
		@io_num_of_writes bigint,
		@io_avg_write_stall_ms real,
		@io_stalls bigint,
		@io_total bigint,
		@avg_io_stall_ms real,
		@row_cnt int,
		@Db_name varchar(500),
		@Db_cpu_time_ms bigint,
		@db_cpu_per real,
		@dbcache_Dbname varchar(500),
		@dbcache_dbcachesizeMB real,
		@waitType_WaitTypeName varchar(500),
		@WaitType_waittime_s real,
		@WaitType_resource_s real,
		@WaitType_Signal_s real,
		@WaitType_counts bigint,
		@WaitType_WaitingPct real,
		@WaitType_RunningPct real,
		@cpuwait_signal_cpu_waits real,
		@cpuwait_resource_wait real,
		@logindet_LoginName varchar(500),
		@logindet_session_count bigint,
		@avg_task_count varchar(200),
		@avg_runnable_task_count varchar(200),
		@avg_diskpendingio_count varchar(200),
		@sqlproc_cpu_Sql_proc int,
		@sqlproc_cpu_sysidle int,
		@sqlproc_cpu_otheros_proc int,
		@sqlproc_cpu_event_time datetime,
		@sqlmem_svr_name varchar(200),
		@sqlmem_obj_name varchar(200),
		@sqlmem_ins_name int,
		@sqlmem_Page_life_expe int,
		@sqlmem_svrm_name varchar(200),
		@sqlmem_sql_obj_name varchar(200),
		@sqlmem_sql_mem_grant_pend int,
		@sqlmemclerk_obj_name varchar(500),
		@sqlmemclerk_mem_kb bigint,
		@adhocQue_QueryText varchar(4000),
		@adhocQue_Qplan_size_byte bigint,
		@tokempermcachesizekb varchar(200),
		@clocktokenname varchar(200),
		@clocktyoe varchar(200),
		@clockhand varchar(200),
		@clock_status varchar(200),
		@clockroundcounts varchar(200),
		@clockremovedallroundcount varchar(200),
		@clockremovedlastroundcount varchar(200),
		@clockupdatedlastroundcount varchar(200),
		@clocklastroundstarttime varchar(200),
		@flagname varchar(20),
		@flagstatus varchar(20),
		@flagglobal varchar(20),
		@flagsesion varchar(20),
		@topspbycpu_spname varchar(4000),
		@topspbycpu_totalworkertimeinmicros varchar(200),
		@topspbycpu_Avgworkertimeinmicros varchar(200),
		@topspbycpu_Executioncount varchar(100),
		@topspbycpu_callsecond varchar(200),
		@topspbycpu_averageelapsedtimeinmicros varchar(200),
		@topspbycpu_maxlogicalread varchar(200),
		@topspbycpu_maxlogicalwrites varchar(200),
		@topspbycpu_ageincache varchar(200),
		@sqlschedule_parenenodeid varchar(10),
		@sqlschedule_schdulerid varchar(10),
		@sqlschedule_cpuid varchar(10),
		@sqlschedule_status varchar(30),
		@sqlschedule_isonline varchar(10),
		@sqlschedule_isidle varchar(10),
		@sqlschedule_preemptiveswtichescounts varchar(50),
		@sqlschedule_contextswtichescounts varchar(50),
		@sqlschedule_idleswtichescounts varchar(50),
		@sqlschedule_currenttaskcounts varchar(50),
		@sqlschedule_runnabletaskcounts varchar(50),
		@sqlschedule_currentworkercounts varchar(50),
		@sqlschedule_activeworkercounts varchar(50),
		@sqlschedule_pendingiocounts varchar(20),
		@sqlschedule_failedtocreate varchar(20),
		-- Listing 10 Locating physical read I/O pressure
		-- Get Top 20 executed SP's ordered by physical reads (read I/O pressure)
		@topsp_iopressure_spname varchar(1000),
		@topsp_iopressure_physicalread varchar(40),
		@topsp_iopressure_spname_avgphysicalread varchar(40),
		@topsp_iopressure_spname_Executioncount varchar(40),
		@topsp_iopressure_spname_callsecond varchar(40),
		@topsp_iopressure_spname_Avgworkertime varchar(40),
		@topsp_iopressure_spname_Totalworkertime varchar(40),
		@topsp_iopressure_spname_Avgelapsedtime varchar(40),
		@topsp_iopressure_spname_maxlogicalreads varchar(40),
		@topsp_iopressure_spname_maxlogicalwrite varchar(40),
		@topsp_iopressure_spname_ageincache varchar(40),

		-- Listing 14 Finding indexes and tables that use the most buffer space
		-- Breaks down buffers by object (table, index) in the buffer cache
		@object_spaceinmem_objname varchar(1000),
		@object_spaceinmem_objid varchar(10),
		@object_spaceinmem_indexid varchar(10),
		@object_spaceinmem_buffersizeinmb varchar(10),
		@object_spaceinmem_Buffcount varchar(100),
		-- Listing 16 Finding your 25 most expensive queries for memory
		-- Get Top 25 executed SP's ordered by logical reads (memory pressure)
		@topsp_mempressure_spname varchar(1000),
		@topsp_mempressure_totallogicalread varchar(30),
		@topsp_mempressure_executioncount varchar(30),
		@topsp_mempressure_Avglogicalreads varchar(30),
		@topsp_mempressure_callspersecond varchar(30),
		@topsp_mempressure_avgworkertime varchar(30),
		@topsp_mempressure_totalworkertime varchar(30),
		@topsp_mempressure_Avgelapsedtime varchar(30),
		@topsp_mempressure_totallogicalwrite varchar(30),
		@topsp_mempressure_maxlogicalread varchar(30),
		@topsp_mempressure_maxlogicalwrite varchar(30),
		@topsp_mempressure_totalphysicalread varchar(30),
		@topsp_mempressure_ageincache varchar(30),
		
		-- Missing Indexes by Index Advantage
		@msngidx_idxadv varchar(400),
		@msngidx_lastuser_seek varchar(140),
		@msngidx_dbschematable varchar(1000),
		@msngidx_equalitycols varchar(1000),
		@msngidx_inequalitycols varchar(1000),
		@msngidx_includedcols varchar(1000),
		@msngidx_uniquecompiles varchar(100),
		@msngidx_userseeks varchar(100),
		@msngidx_avgtotalusercost varchar(100),
		@msngidx_avguserimpact varchar(100),
		--Missing Indexes by Script
		@msgindx_idxgroup_handle varchar(200),
		@msgindx_idx_handle varchar(200),
		@msgindx_improvement_measures varchar(200),
		@msgindx_createidxstat varchar(5000),
		@msgindx_grphandle varchar(200),
		@msgindx_uniqcompiles varchar(200),
		@msgindx_userseeks varchar(200),
		@msgindx_usescans varchar(200),
		@msgindx_lastuserseek varchar(200),
		@msgindx_lastuserscan varchar(200),
		@msgindx_avgtotalusercost varchar(200),
		@msgindx_avguserimpact varchar(200),
		@msgindx_systemseek varchar(200),
		@msgindx_systemscan varchar(200),
		@msgindx_lastsysseek varchar(200),
		@msgindx_avgtotalsyscost varchar(200),
		@msgindx_avgsysimpact varchar(200),
		@msgindx_databaseid varchar(200),
		@msgindx_objid varchar(200),

		--MSDB Suspect pages
		@mscorrupt_dbid varchar(10),
		@mscorrupt_fileid varchar(20),
		@mscorrupt_pageid varchar(500),
		@mscorrupt_eventtype varchar(2000),
		@mscorrupt_errorcount varchar(5000),
		@mscorrupt_lastupdate varchar(2000),

		-- Listing 26 Detecting blocking (a more accurate and complete version)
		@blocking_lcktype varchar(200),
		@blocking_dbname varchar(500),
		@blocking_blockerobj varchar(500),
		@blocking_lckreque varchar(200),
		@blocking_waitersid varchar(10),
		@blocking_waitime varchar(10),
		@blocking_waitbatch varchar(20),
		@blocking_waiterstmt varchar(1000),
		@blocking_blockersid varchar(200),
		@blocking_blocker_stmt varchar(1000),

		-- Listing 27 Looking at locks that are causing problems
		@lockquery_restype varchar(100),
		@lockquery_resdbid varchar(10),
		@lockquery_resentryid varchar(100),
		@lockquery_reqmode varchar(100),
		@lockquery_reqsessid varchar(10),
		@lockquery_blocksid varchar(10),

		-- Database Growth Query
		@endDate datetime,
		@months smallint,
		@DBG_Dbname varchar(200),
		@DBG_YearMon varchar(50),
		@DBG_MinSizeMB varchar(200),
		@DBG_MaxSizeMB varchar(200),
		@DBG_AVGSizeMB varchar(200),
		@DBG_GrowthMB varchar(200),

		--- Memory Configuration 
@pg_size int,
@Instancename varchar(50),
--Physical Memory Details on Server along with VAS.
@phymem_onsrvinmb varchar(200),
@phymem_onsrvingb varchar(200),
@phymem_onsrvVAS varchar(200),
--Buffer Pool Usage at the Moment
@bpoolusg_commitedinmb varchar(20),
@bpoolusg_commitedintargetmb varchar(20),
@bpoolusg_visibleinMB varchar(20),
--Total Memory used by SQL Server instance from Perf Mon
@totalmemsql_usageinkb varchar(20),
@totalmemsql_usageinMB varchar(20),
@totalmemsql_usageinGB varchar(20),
--Memory needed as per current Workload for SQL Server instance
@memneed_curwl_meminkb varchar(20),
@memneed_curwl_meminmb varchar(20),
@memneed_curwl_meminGB varchar(20),
--Total amount of dynamic memory the server is using for maintaining connections
@memcon_usageinkb varchar(50),
@memcon_usageinmb varchar(50),
@memcon_usageingb varchar(50),
--'Total amount of dynamic memory the server is using for locks
@memlock_useinkb varchar(50),
@memlock_useinMb varchar(50),
@memlock_useinGb varchar(50),
--Total amount of dynamic memory the server is using for the dynamic SQL cache
@dynsqlcache_useinkb varchar(50),
@dynsqlcache_useinMb varchar(50),
@dynsqlcache_useinGb varchar(50),
--Total amount of dynamic memory the server is using for query optimization
@qryopt_useinkb varchar(50),
@qryopt_useinMb varchar(50),
@qryopt_useinGb varchar(50),
--Total amount of dynamic memory used for hash, sort and create index operations.
@idexsort_userinkb varchar(50),
@idexsort_userinMb varchar(50),
@idexsort_userinGb varchar(50),
--Total Amount of memory consumed by cursors.
@curmem_useinkb varchar(50),
@curmem_useinMb varchar(50),
@curmem_useinGb varchar(50),
--Number of pages in the buffer pool (includes database, free, and stolen)
@bpool_page_8kbno varchar(50),
@bpool_pages_inkb varchar(50),
@bpool_pages_inmb varchar(50),

--Number of Data pages in the buffer pool
@dbpagebpool_page_8kbno varchar(50),
@dbpagebpool_page_inkb varchar(50),
@dbpagebpool_page_inmb varchar(50),

--Number of Free pages in the buffer pool
@freepagebpool_page_8kbno varchar(50),
@freepagebpool_page_inkb varchar(50),
@freepagebpool_page_inmb varchar(50),

--Number of Reserved pages in the buffer pool
@respagebpool_page_8kbno varchar(50),
@respagebpool_page_inkb varchar(50),
@respagebpool_page_inmb varchar(50),

--Number of Stolen pages in the buffer pool
@stolenpbpool_page_8kbno varchar(50),
@stolenpbpool_page_inkb varchar(50),
@stolenpbpool_page_inmb varchar(50),

--Number of Plan Cache pages in the buffer pool
@plancachebpool_page_8kbno varchar(50),
@plancachebpool_page_inkb varchar(50),
@plancachebpool_page_inmb varchar(50),
--SQL Server Binary Module Information 
@DllFilePath varchar(2000),
@FileVer varchar(500),
@Productver varchar(200),
@Bin_Descrip varchar(5000),
@Modulesize_inkb varchar(200),

-- Version Stored Application
@verstorepage_used varchar(20),
@verstorepage_spaceinMB Varchar(20),

--Script to total tempdb usage by type across all files
@tempdb_user_obj_pages_inMB varchar(20),
@tempdb_internal_obj_pages_inMB varchar(20),
@tempdb_versionstore_obj_pages_inMB varchar(20),
@tempdb_total_pages_use_inMB varchar(20),
@tempdb_total_pages_free_inMB varchar(20),

--Script to find the top five sessions running tasks that use tempdb
@tempdbsession_sid varchar(20),
@tempdbsession_requ_sid varchar(20),
@tempdbsession_execontext_sid varchar(20),
@tempdbsession_dbid varchar(20),
@tempdbsession_usrobjallocpage_count varchar(20),
@tempdbsession_usrobjdeallocpage_count varchar(20),
@tempdbsession_internalallocpage_count varchar(20),
@tempdbsession_internaldeallocpage_count varchar(20),
--Script to find the top five sessions running tasks that use tempdb
@sessionact_sid varchar(10),
@sessionact_logintime varchar(100),
@sessionact_hostname varchar(100),
@sessionact_programname varchar(520),
@sessionact_cputime varchar(10),
@sessionact_memusginkb varchar(10),
@sessionact_totalschetime varchar(10),
@sessionact_totalelsapsedtime varchar(10),
@sessionact_lastrequestendtime varchar(50),
@sessionact_reads varchar(10),
@sessionact_write varchar(10),
@sessionact_conncount varchar(10),
--script for IO Result for file in min
@fileio_dbname varchar(200),
@fileio_filename varchar(4000),
@fileio_filetype varchar(200),
@fileio_filesizegb varchar(200),
@fileio_mbread varchar(200),
@fileio_mbwrite varchar(200),
@fileio_noofread varchar(200),
@fileio_noofwrite varchar(200),
@fileio_miniowritestall varchar(200),
@fileio_minioreadstall varchar(200),
--script to look for open transaction actual activity
@otran_spid varchar(10),
@otran_lasworkertime varchar(200),
@otran_lastphysicalread varchar(200),
@otran_totalphysicalread varchar(200),
@otran_totallogicalwrites varchar(200),
@otran_lastlogicalreads varchar(200),
@otran_currentwait varchar(200),
@otran_lastwaittype varchar(1000),
@otran_watiresource varchar(1000),
@otran_waittime varchar(100),
@otran_opentrancount varchar(100),
@otran_rowcount varchar(10),
@otran_granterqmem varchar(20),
@otran_sqltect varchar(4000)



		print'<HTML><head><Title>SQL Server Instance Detail Report.</Title>'+
			'<style type="text/css">'+
				'table {
				border-collapse:collapse;
				background:#EFF4FB url(http://www.roscripts.com/images/teaser.gif) repeat-x;
				border-left:1px solid #686868;
				border-right:1px solid #686868;
				font:0.8em/145% Trebuchet MS,helvetica,arial,verdana;
				color: #333;
				}'+

'td, th {
		padding:5px;
}'+

'caption {
		padding: 0 0 .5em 0;
		text-align: left;
		font-size: 1.4em;
		font-weight: bold;
		text-transform: uppercase;
		color: #333;
		background: transparent;
}'+

'table a {
		color:#950000;
		text-decoration:none;
}'+

'table a:link {}'+

'table a:visited {
		font-weight:normal;
		color:#666;
		text-decoration: line-through;
}'+

'table a:hover {
		border-bottom: 1px dashed #bbb;
}'+


'thead th, tfoot th, tfoot td {
		background:#333 url(http://www.roscripts.com/images/llsh.gif) repeat-x;
		color:#fff
}'+

'tfoot td {
		text-align:right
}'+

'tbody th, tbody td {
		border-bottom: dotted 1px #333;
}'+

'tbody th {
		white-space: nowrap;
}'+

'tbody th a {
		color:#333;
}'+

'.odd {}'+

'tbody tr:hover {
		background:#fafafa
}'+


'</style></head>'

/*
SQL Server Startup Time		
			
*/


print N'<h1>SQL Server Up Time</h1>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+

N'<tr><th><strong>Time</strong></th>'+'</tr>'

declare cur_uptime_sql cursor for
select CONVERT(VARCHAR(20), create_date, 100) 
  from sys.databases where database_id=2
open cur_uptime_sql
fetch from cur_uptime_sql into 
@start_time
while @@fetch_status>=0
begin 
print '<tr><td>'+@start_time+'</td>'+'</tr>'
fetch from cur_uptime_sql into 
@start_time
end
close cur_uptime_sql
deallocate cur_uptime_sql
print'</table><br/>'
/*
Instance Detail Information fetching Query
*/

print N'<h1>SQL Server Instance Detail</h1>'
print N'<H3>SQL Server Name and Version Detail</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+

N'<tr><th><strong>Server Name</strong></th>'+
N'<th><strong>Instance Version</strong></th></tr>'



declare cur_sql_info  cursor for SELECT @@SERVERNAME AS [Server Name], @@VERSION AS [SQL Server and OS Version Info]
open cur_sql_info
fetch next from cur_sql_info into @Server_Name,@Server_ver
while @@fetch_status>=0
begin 
print '<tr><td>'+@Server_Name+'</td><td>'+@Server_ver+'</td>'+'</tr>'
fetch next from cur_sql_info into @Server_Name,@Server_ver
end
close cur_sql_info
deallocate cur_sql_info
print'</table><br/>'

print '<table style="width: 100%">
	<tr>
		<td><span class="auto-style1"><strong>RECOMMENDATION:</strong></span><br>
		SQL Server 2005 fell out of Mainsteam Support on April 12, 2011 -- This 
		means no more Service Packs or Cumulative Updates.<br>-- The SQL Server 
		2005 builds that were released after SQL Server 2005 Service Pack 2 was 
		released<br>
		<a href="http://support.microsoft.com/kb/937137" target="_blank">
		http://support.microsoft.com/kb/937137</a><br>-- The SQL Server 2005 
		builds that were released after SQL Server 2005 Service Pack 3 was 
		released<br>
		<a href="http://support.microsoft.com/kb/960598" target="_blank">
		http://support.microsoft.com/kb/960598</a><br>-- The SQL Server 2005 
		builds that were released after SQL Server 2005 Service Pack 4 was 
		released <br>
		<a href="http://support.microsoft.com/kb/2485757" target="_blank">
		http://support.microsoft.com/kb/2485757</a></td>
	</tr>
</table>
'

/*
When was SQL Server last Installed date
*/

print N'<H3>SQL Server Name and Installation Detail</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+

N'<tr><th><strong>Server Name</strong></th>'+
N'<th><strong>SQL Installation Date</strong></th></tr>'


declare cur_sql_sqlinstall cursor for SELECT @@SERVERNAME AS [Server Name], createdate AS [SQL Server Install Date] 
FROM sys.syslogins WITH (NOLOCK)
WHERE [sid] = 0x010100000000000512000000;
open cur_sql_sqlinstall 
fetch next from cur_sql_sqlinstall into @SQLSer_OSInfo,@SQL_inst_date
while @@fetch_status>=0
begin 
print '<tr><td>'+@SQLSer_OSInfo+'</td><td>'+@SQL_inst_date+'</td>'+'</tr>'
fetch next from cur_sql_sqlinstall into @SQLSer_OSInfo,@SQL_inst_date
end
close cur_sql_sqlinstall
deallocate cur_sql_sqlinstall
print'</table><br/>'

/*
Get selected server properties (SQL Server 2005)
-- This gives you a lot of useful information about your instance of SQL Server

*/

print N'<H3>SQL Server Server properties</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+


N'<tr><th><strong>Machine Name</strong></th>'+
N'<th><strong>Server Name</strong></th>'+
N'<th><strong>Instance Name</strong></th>'+
N'<th><strong>Is Clustered</strong></th>'+
N'<th><strong>Computer Netbios Name</strong></th>'+
N'<th><strong>SQL Edition</strong></th>'+
N'<th><strong>SQL Product Patch Level</strong></th>'+
N'<th><strong>SQL Product Product Version</strong></th>'+
N'<th><strong>SQL Process ID</strong></th>'+
N'<th><strong>SQL Instance Collation</strong></th>'+
N'<th><strong>SQL FullText Installed</strong></th>'+
N'<th><strong>SQL IsIntegratedSecurityOnly</strong></th></tr>'

declare cur_sql_sqlpropties cursor for 
SELECT 
cast(SERVERPROPERTY('MachineName') as varchar(200)) AS [MachineName], 
cast(SERVERPROPERTY('ServerName') as varchar(200)) AS [ServerName],  
cast(SERVERPROPERTY('InstanceName') as varchar(200)) AS [Instance],
cast(SERVERPROPERTY('IsClustered') as varchar(200)) AS [IsClustered], 
CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') as varchar(200)) AS [ComputerNamePhysicalNetBIOS], 
cast(SERVERPROPERTY('Edition') as varchar(200)) AS [Edition],
cast(SERVERPROPERTY('ProductLevel') as varchar(200)) AS [ProductLevel], 
cast(SERVERPROPERTY('ProductVersion') as varchar(200)) AS [ProductVersion],
cast(SERVERPROPERTY('ProcessID') as varchar(200)) AS [ProcessID],
cast(SERVERPROPERTY('Collation') as varchar(200)) AS [Collation],
cast(SERVERPROPERTY('IsFullTextInstalled') as varchar(200)) AS [IsFullTextInstalled], 
cast(SERVERPROPERTY('IsIntegratedSecurityOnly') as varchar(200)) AS [IsIntegratedSecurityOnly]

open cur_sql_sqlpropties
fetch next from cur_sql_sqlpropties into 
@Srv_Machine,
@SrvName_prop,
@InstName,
@IsCluster,
@CompNetbios,
@SqlEdition,
@SqlProductLevel,
@SqlProdVer,
@SqlProid,
@Sql_Ins_collation,
@IsfullText,
@IsInterSec
while @@fetch_status>=0
begin 

if(@InstName IS NULL)
begin
set @InstName = 'Default'
end
print '<tr><td>'+@Srv_Machine+'</td><td>'+@SrvName_prop+'</td><td>'+@InstName+'</td><td>'+@IsCluster+'</td><td>'+@CompNetbios+'</td><td>'+@SqlEdition+'</td><td>'+@SqlProductLevel+'</td><td>'+@SqlProdVer+'</td><td>'+@SqlProid+'</td><td>'+@Sql_Ins_collation+'</td><td>'+@IsfullText+'</td><td>'+@IsInterSec+'</td>'+'</tr>'
--print 'I am in the cursor'
fetch next from cur_sql_sqlpropties into 
@Srv_Machine,
@SrvName_prop,
@InstName,
@IsCluster,
@CompNetbios,
@SqlEdition,
@SqlProductLevel,
@SqlProdVer,
@SqlProid,
@Sql_Ins_collation,
@IsfullText,
@IsInterSec
end
close cur_sql_sqlpropties
deallocate cur_sql_sqlpropties
print'</table><br/>'
print '<table style="width: 100%">
	<tr>
		<td>--In the configuration detail where 0 is disable and 1 is enable.</td>
	</tr>
</table>
<br/>'
/*

CPU Hardware Information for SQL Server 2005 
 
 */
print N'<H3>SQL Server Server CPU Information</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Logical CPU Count</strong></th>'+
N'<th><strong>Hyperthreading Ratio</strong></th>'+
N'<th><strong>Physical CPU Count</strong></th>'+
N'<th><strong>Physical RAM</strong></th></tr>'

declare sql_cpu_prop cursor for
SELECT cast(cpu_count as varchar(10)) AS [Logical CPU Count], cast(hyperthread_ratio as varchar(10)) AS [Hyperthread Ratio],
cast(cpu_count/hyperthread_ratio as varchar(10)) AS [Physical CPU Count], 
cast(physical_memory_in_bytes/1048576 as varchar(10)) AS [Physical Memory (MB)]
FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE)

 
open sql_cpu_prop

fetch from sql_cpu_prop into 
@LogicalCPUCount,
@HTRatio,
@PhyCPUCount,
@PhyRAM_MB
while @@fetch_status>=0
begin 
print '<tr><td>'+@LogicalCPUCount+'</td><td>'+@HTRatio+'</td><td>'+@PhyCPUCount+'</td><td>'+@PhyRAM_MB+'</td>'+'</tr>'
fetch from sql_cpu_prop into 
@LogicalCPUCount,
@HTRatio,
@PhyCPUCount,
@PhyRAM_MB
end
close sql_cpu_prop
deallocate sql_cpu_prop
print'</table><br/>'
print '<br>
<table style="width: 100%">
	<tr>
		<td>-- In this above Table we have mention table Server CPU 
		configuration along with  total physical RAM available on the 
		server.<br>-- It is good to to check Hyperthreading Ratio for CPU some 
		time CPU pressure can be contribute by it.<br>-- This does not 
		distinguish between multicore and hyperthreading.</td>
	</tr>
</table>'

/*
Server Model and Manufacturer and processor model
*/
set nocount on 
print N'<H3>Server Processor Information</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Processor Value</strong></th>'+
N'<th><strong>Processor Name</strong></th></tr>'
--declare @ProcName Table
--( Value varchar(200),
--  Name varchar(400)
-- )
set nocount on
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'#ProcName') AND type in (N'U'))
DROP TABLE #ProcName 
create table #ProcName( Value varchar(200),Name varchar(400))
 insert into #ProcName exec xp_instance_regread 
'HKEY_LOCAL_MACHINE', 'HARDWARE\DESCRIPTION\System\CentralProcessor\0',
'ProcessorNameString';

--select * from @ProcName

declare cur_proc_name cursor for select value,Name from #ProcName 

open cur_proc_name

fetch from cur_proc_name into 
@Proc_Value,
@Proc_date

while @@fetch_status>=0
begin 
print '<tr><td>'+@Proc_Value+'</td><td>'+@Proc_date+'</td>'+'</tr>'

fetch from cur_proc_name into 
@Proc_Value,
@Proc_date
end

close cur_proc_name
deallocate cur_proc_name
set nocount off
print'</table><br/>'
print '<br>
<table style="width: 100%">
	<tr>
		<td>--Above Table will give you information about the CPU make and moel 
		and clock speed information.</td>
	</tr>
</table>'



/*
SQL Server configuration setting Information.
*/

print N'<H3>SQL Server SP_CONFIGURE Information For Instance</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Parameter Name</strong></th>'+
'<th><strong>Parameter Value</strong></th>'+
'<th><strong>Parameter Running Vlaue</strong></th>'+
N'<th><strong>Parameter Description</strong></th></tr>'


declare cur_sql_spconfig cursor  for SELECT name, cast(value as varchar(10)) as value,CAST(value_in_use as varchar(10)) as valueinuse, [description] 
FROM sys.configurations WITH (NOLOCK)
ORDER BY name  OPTION (RECOMPILE);

open cur_sql_spconfig

fetch from cur_sql_spconfig into
@Sp_config_Name,
@Sp_config_value,
@Sp_config_inusevalue,
@Sp_config_des


while @@fetch_status>=0
begin 
print '<tr><td>'+@Sp_config_Name+'</td><td>'+@Sp_config_value+'</td><td>'+@Sp_config_inusevalue+'<td>'+@Sp_config_des+'</td>'+'</tr>'

fetch from cur_sql_spconfig into
@Sp_config_Name,
@Sp_config_value,
@Sp_config_inusevalue,
@Sp_config_des
end

close cur_sql_spconfig
deallocate cur_sql_spconfig
print'</table><br/>'

print'<table style="width: 100%">
	<tr>
		<td>--Above table will show you SQL Server Instance Level configuration 
		settings. Whic is very important to know and set it to proper according 
		value in the first will save you from lot of performance related issues 
		in the future.<br><strong><span class="auto-style1">-- Focus on the 
		following parameter.</span><br class="auto-style1">1.Max Degree of 
		Parallelism:-<br>--</strong>Set this option based on the your instance 
		database configuration whether you have OLTP databases or DSS(Reporting) 
		databases.For OLTP databases we dont need much processing power since 
		ammount of transaction would very small.<br>--While in DSS or Reporting 
		system we definetly need more CPU since many of queries doing select 
		with conditional logic and that would be always fast if it would get 
		benifited from parallel processing.<br>--Set this value  to 0 
		indicate SQL can use all available CPU on the server for processing 
		while setting to 1 indicate SQL can only use single CPU for processing.<br>
		--You can set this value based on the number of processsor you have and 
		type of your workload(OLTP,DSS).<br><strong>2.Max Server Memory:-<br>--</strong>This 
		option is also very important for setting working set size for the SQL 
		Server instance and also used to limit memory utilization on the server 
		by instance.<br>-- This option has to be set for your instnace in order 
		to avoid memory throtlling and memory bottleneck problem on the system. 
		This option set memory dynamic so no need to restart SQL Server in order 
		to take in to effect.<br>-- Hypothetical example of memory distribution 
		System with having 32 GB RAM with 64 bit OS Single Production SQL Server 
		instnace running on it then we can divide memory for OS to 6 GB rest 26 
		GB to SQL and if you have any other application on the same box other 
		than SQL then you have to further reduce SQL Server Max Server Memory.<br>
		-- For Better tunning of Max Server Memory use Performance Monitor to 
		examine the SQLServer:Buffer Manager performance object while under a 
		load, and note the current values of the Stolen pages and Reserved pages 
		counters. These counters report memory as the number of 8K pages. max 
		server memory should be set above the sum of these two values to avoid 
		out-of-memory errors.<br><strong>3. CLR Enabled:-</strong><br>--This 
		should be set to 0 if you don't use any .Net related commond language 
		run time.If you need it then enable it.<br><strong>4.lightweight 
		pooling:-<br>--</strong>Setting lightweight pooling to 1 causes SQL 
		Server to switch to fiber mode scheduling. The default value for this 
		option is 0.<br>--Use the lightweight pooling option to provide a means 
		of reducing the system overhead associated with the excessive context 
		switching sometimes seen in symmetric multiprocessing (SMP) 
		environments. When excessive context switching is present, lightweight 
		pooling can provide better throughput by performing the context 
		switching inline, thus helping to reduce user/kernel ring transitions.<br>
		<em>--We do not recommend that you use fiber mode scheduling for routine 
		operation. This is because it can decrease performance by inhibiting the 
		regular benefits of context switching, and because some components of 
		SQL Server that use Thread Local Storage (TLS) or thread-owned objects, 
		such as mutexes (a type of Win32 kernel object), cannot function 
		correctly in fiber mode.<br></em>5.Priority Boost:-<br>--By setting this 
		option to 1 allows SQL Server to run on Windows Server with highest 
		priority on Windows Scheduler. <br>-- If this option is enable then SQL 
		Server will run on Windows Scheduler with priority base of 13 and in 
		normal mode it will be running with priority base of 7<br>--We have seen 
		failover issues in the past on Failover Cluster system when you ran SQL 
		Server with High Priority boost.<br>-- So try to avoid configuring SQL 
		Server for this option.<br><strong>5.optimize for ad hoc workloads:-</strong><br>
		--The optimize for ad hoc workloads option is used to improve the 
		efficiency of the plan cache for workloads that contain many single use 
		ad hoc batches.<br>--When this option is set to 1, the Database Engine 
		stores a small compiled plan stub in the plan cache when a batch is 
		compiled for the first time, instead of the full compiled plan. <br>
		--This helps to relieve memory pressure by not allowing the plan cache 
		to become filled with compiled plans that are not reused.<br>--The 
		compiled plan stub allows the Database Engine to recognize that this ad 
		hoc batch has been compiled before but has only stored a compiled plan 
		stub, so when this batch is invoked (compiled or executed) again, the 
		Database Engine compiles the batch, removes the compiled plan stub from 
		the plan cache, and adds the full compiled plan to the plan cache.<br>
		--Setting the optimize for ad hoc workloads to 1 affects only new plans; 
		plans that are already in the plan cache are unaffected.</td>
	</tr>
</table>
<br/>'

/*
Database Data FIles Detail
*/



print N'<H3>SQL Server Databases Datafiles location size and status</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Database Name</strong></th>'+
'<th><strong>DB File Id</strong></th>'+
'<th><strong>DB File Name</strong></th>'+
'<th><strong>DB Physical File Name</strong></th>'+
'<th><strong>DB file Type</strong></th>'+
'<th><strong>DB File Status</strong></th>'+
N'<th><strong>DB File Size in (MB)</strong></th></tr>'


declare cur_db_datafiles cursor for 
SELECT cast(DB_NAME([database_id]) as varchar(400))AS [Database Name], 
       cast([file_id] as varchar(10)) as File_id,
       name, 
       physical_name,
       type_desc, 
       state_desc, 
       cast(CONVERT( bigint, size/128.0) as varchar(200)) AS [Total Size in MB]
FROM sys.master_files WITH (NOLOCK)
WHERE [database_id] > 4 
AND [database_id] <> 32767
OR [database_id] = 2
ORDER BY DB_NAME([database_id]) OPTION (RECOMPILE);

open cur_db_datafiles 

fetch from cur_db_datafiles into 
@db_det_name,
@db_det_fileid,
@db_det_filename,
@db_det_phyfilename,
@db_det_filedesc,
@db_det_statedesc,
@db_det_filesizeMB

while @@fetch_status>=0
begin
print '<tr><td>'+@db_det_name+'</td><td>'+@db_det_fileid+'</td><td>'+@db_det_filename+'</td><td>'+@db_det_phyfilename+'</td><td>'+@db_det_filedesc+'</td><td>'+@db_det_statedesc+'</td><td>'+@db_det_filesizeMB+'</td>'+'</tr>'
fetch from cur_db_datafiles into 
@db_det_name,
@db_det_fileid,
@db_det_filename,
@db_det_phyfilename,
@db_det_filedesc,
@db_det_statedesc,
@db_det_filesizeMB
end

close cur_db_datafiles
deallocate cur_db_datafiles

print'</table><br/>'

print'<table style="width: 100%">
	<tr>
		<td><span class="auto-style1"><strong>SQL Server Databases Datafiles 
		location size and status</strong></span><br>--The above table provides 
		you inforation about your databases Files and their respective location 
		with status of the file and along with FileSize.<br>--Things to look at 
		also Files for all Databases are on the same drive.<br>-- Files like 
		data file and log file are on diffrent drive.<br>-- How many files we 
		have for tempdb and are they at same size.<br>-- Is tempdb is on 
		dedicated drive.<br>-- Idle condition log file should be put on the very 
		fast drive so we will not have IO latency bottelneck while performing 
		transactions.</td>
	</tr>
</table>
<br/>'


/*
Database Congiuration Properties QUery.
*/

print '<H3>SQL Server Databases Configuration Properties</H3>'
print '<table cellspacing="1" cellpadding="1" border="1">'+
'<tr><th><strong>Database Name</strong></th>'+
'<th><strong>DB Recovery Model</strong></th>'+
'<th><strong>DB Log Reuse Wait Description</strong></th>'+
'<th><strong>DB Log File Size(KB)</strong></th>'+
'<th><strong>DB Log File Used Size(KB)</strong></th>'+
'<th><strong>DB Log File Used(%)</strong></th>'+
'<th><strong>DB Compatibility Level</strong></th>'+
'<th><strong>DB Page Verify Option</strong></th>'+
'<th><strong>DB is_auto_create_stats_on</strong></th>'+
'<th><strong>DB is_auto_update_stats_on</strong></th>'+
'<th><strong>DB is_auto_update_stats_async_on</strong></th>'+
'<th><strong>DB Force Parameterization</strong></th>'+
'<th><strong>DB Snapshot Isolation State</strong></th>'+
'<th><strong>DB Read Commited Snapshot On</strong></th>'+
'<th><strong>DB AutoClose On</strong></th>'+
'<th><strong>DB AutoShrink On</strong></th></tr>'


declare cur_db_log_info cursor for 
SELECT db.[name] AS [Database Name], db.recovery_model_desc AS [Recovery Model], 
db.log_reuse_wait_desc AS [Log Reuse Wait Description], 
ls.cntr_value AS [Log Size (KB)], lu.cntr_value AS [Log Used (KB)],
CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)AS DECIMAL(18,2)) * 100 AS [Log Used %], 
db.[compatibility_level] AS [DB Compatibility Level], 
db.page_verify_option_desc AS [Page Verify Option], db.is_auto_create_stats_on, db.is_auto_update_stats_on,
db.is_auto_update_stats_async_on, db.is_parameterization_forced, 
db.snapshot_isolation_state_desc, db.is_read_committed_snapshot_on,
db.is_auto_close_on, db.is_auto_shrink_on
FROM sys.databases AS db WITH (NOLOCK)
INNER JOIN sys.dm_os_performance_counters AS lu WITH (NOLOCK)
ON db.name = lu.instance_name
INNER JOIN sys.dm_os_performance_counters AS ls WITH (NOLOCK)
ON db.name = ls.instance_name
WHERE lu.counter_name LIKE N'Log File(s) Used Size (KB)%' 
AND ls.counter_name LIKE N'Log File(s) Size (KB)%'
AND ls.cntr_value > 0 OPTION (RECOMPILE);

open cur_db_log_info
fetch from cur_db_log_info into 
		@db_log_info_dbname, 
		@db_log_info_rmodle, 
		@db_log_info_logreusewait,
		@db_log_info_logsizekb, 
		@db_log_info_logusedkb, 
		@db_log_info_logusedper, 
		@db_log_info_dbcmptlevel,
		@db_log_info_pageverify, 
		@db_log_info_autstats, 
		@db_log_info_autoupdstats, 
		@db_log_info_autstatsasyncon, 
		@db_log_info_parameterrizatio, 
		@db_log_info_snapshotisolation, 
		@db_log_info_readcommitedsnapshot, 
		@db_log_info_autoclose,
		@db_log_info_autoshrink		

while @@fetch_status>=0
begin
print '<tr><td>'+cast(@db_log_info_dbname as varchar(500))+'</td><td>'+cast(@db_log_info_rmodle as varchar(500))+'</td><td>'+cast(@db_log_info_logreusewait as varchar(500))+'</td><td>'+cast(@db_log_info_logsizekb as varchar(500))+'</td><td>'+cast(@db_log_info_logusedkb as varchar(500))+'</td><td>'+cast(@db_log_info_logusedper as varchar(500))+'</td><td>'+cast(@db_log_info_dbcmptlevel as varchar(500))+'</td><td>'+cast(@db_log_info_pageverify as varchar(500))+'</td><td>'+cast(@db_log_info_autstats as varchar(500))+'</td><td>'+cast(@db_log_info_autoupdstats as varchar(500))+'</td><td>'+cast(@db_log_info_autstatsasyncon as varchar(500))+'</td><td>'+cast(@db_log_info_parameterrizatio as varchar(500))+'</td><td>'+cast(@db_log_info_snapshotisolation as varchar(500))+'</td><td>'+cast(@db_log_info_readcommitedsnapshot as varchar(500))+'</td><td>'+cast(@db_log_info_autoclose as varchar(500))+'</td><td>'+cast(@db_log_info_autoshrink as varchar(500))+'</td>'+'</tr>'
fetch from cur_db_log_info into 
		@db_log_info_dbname, 
		@db_log_info_rmodle, 
		@db_log_info_logreusewait,
		@db_log_info_logsizekb, 
		@db_log_info_logusedkb, 
		@db_log_info_logusedper, 
		@db_log_info_dbcmptlevel,
		@db_log_info_pageverify, 
		@db_log_info_autstats, 
		@db_log_info_autoupdstats, 
		@db_log_info_autstatsasyncon, 
		@db_log_info_parameterrizatio, 
		@db_log_info_snapshotisolation, 
		@db_log_info_readcommitedsnapshot, 
		@db_log_info_autoclose,
		@db_log_info_autoshrink		
end
close cur_db_log_info
deallocate cur_db_log_info

print'</table><br/>'
print'<table style="width: 100%">
	<tr>
		<td><span class="auto-style1"><strong>SQL Server Databases Configuration 
		Properties:-</strong></span><br>--In the above table will show you each 
		database properties configuration information like.<br>1.Recovery Model<br>
		2.Transaction Log Reuse Wait Description.<br>3. DB log file size in KB<br>
		4. DB log file used size in KB<br>5. DB log file percentage usage.<br>-- 
		Another parameter is also very important is DB Compatibility level this 
		parameter shows values like (80,90,100,110). Where if you have restored 
		any of SQL Server database from older version to new version you will 
		have to change this option.<br>--Consequnces of this option not set 
		could be SQL databases which having SQL 2000(80) compatibility version 
		can use old query optimization techniques on advance version of SQL 
		Server which intern may degraded performance of the SQL Server.<br>
		--Database Parameterization option is set to simple SQL Server query 
		optimizer may choose to parameterize the queries. This means that any 
		literal values that are contained in a query are substituted with 
		parameters.<br>--When SIMPLE parameterization is in effect, you cannot 
		control which queries are parameterized and which queries are not. 
		However, you can specify that all queries in a database be parameterized 
		by setting the PARAMETERIZATION database option to FORCED. This process 
		is referred to as forced parameterization.<br>--you can specify that 
		forced parameterization is attempted on a certain class of queries. You 
		do this by creating a TEMPLATE plan guide on the parameterized form of 
		the query, and specifying the PARAMETERIZATION FORCED query hint in the 
		sp_create_plan_guide stored procedure. You can consider this kind of 
		plan guide as a way to enable forced parameterization only on a certain 
		class of queries, instead of all queries.<br>--When the PARAMETERIZATION 
		database option is set to FORCED, you can specify that for a certain 
		class of queries, only simple parameterization is attempted, not forced 
		parameterization. You do this by creating a TEMPLATE plan guide on the 
		force-parameterized form of the query, and specifying the 
		PARAMETERIZATION SIMPLE query hint in <b>sp_create_plan_guide</b>.</td>
	</tr>
</table>
<br><br/>'



/*
SQL Server datafile read write stats in the min
*/


/*
SQL Server Databfiles Read/Write Stall and Average Read/Write Information
*/
print N'<H3>SQL Server Databases Datafiles Writes/Reads</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Database Name</strong></th>'+
'<th><strong>Physical File Name</strong></th>'+
'<th><strong>File Types</strong></th>'+
'<th><strong>File Size in MB</strong></th>'+
'<th><strong>Total Reads in MB</strong></th>'+
'<th><strong>Total Writes in MB</strong></th>'+
'<th><strong>Number of Reads</strong></th>'+
'<th><strong>Number of Writes</strong></th>'+
'<th><strong>IO Stall Write in Minute</strong></th>'+
N'<th><strong>IO Stall Read in Minute</strong></th></tr>'
declare cur_iom_info cursor for 
SELECT sys.master_files.name as DatabaseName,
sys.master_files.physical_name,
CASE WHEN sys.master_files.type_desc = 'ROWS' THEN 'Data Files'
WHEN sys.master_files.type_desc = 'LOG' THEN 'Log Files'
END as 'File Type',
((FileStats.size_on_disk_bytes/1024)/1024)/ 1024.0 as FileSize_GB,
(FileStats.num_of_bytes_read /1024)/1024.0 as MB_Read,
(FileStats.num_of_bytes_written /1024)/1024.0 as MB_Written,
FileStats.Num_of_reads, FileStats.Num_of_writes,
((FileStats.io_stall_write_ms /1000.0)/60) as
Minutes_of_IO_Write_Stalls,
((FileStats.io_stall_read_ms /1000.0)/60) as
Minutes_of_IO_Read_Stalls
FROM sys.dm_io_virtual_file_stats(null,null) as FileStats
JOIN sys.master_files ON
FileStats.database_id = sys.master_files.database_id
AND FileStats.file_id = sys.master_files.file_id

open cur_iom_info
fetch from cur_iom_info into 
@fileio_dbname,
@fileio_filename,
@fileio_filetype,
@fileio_filesizegb,
@fileio_mbread ,
@fileio_mbwrite,
@fileio_noofread,
@fileio_noofwrite,
@fileio_miniowritestall ,
@fileio_minioreadstall 

while @@fetch_status>=0
begin

print '<tr><td>'+cast(@fileio_dbname as varchar(500))+
	  '</td><td>'+cast(@fileio_filename as varchar(5000))+
	  '</td><td>'+cast(@fileio_filetype as varchar(500))+
	  '</td><td>'+cast(@fileio_filesizegb as varchar(500))+
	  '</td><td>'+cast(@fileio_mbread as varchar(150))+
	  '</td><td>'+cast(@fileio_mbwrite as varchar(150))+
	  '</td><td>'+cast(@fileio_noofread as varchar(150))+
	  '</td><td>'+cast(@fileio_noofwrite as varchar(150))+
	  '</td><td>'+cast(@fileio_miniowritestall as varchar(150))+
	  '</td><td>'+cast(@fileio_minioreadstall as varchar(150))+'</td>'+'</tr>'
fetch from cur_iom_info into 
@fileio_dbname,
@fileio_filename,
@fileio_filetype,
@fileio_filesizegb,
@fileio_mbread ,
@fileio_mbwrite,
@fileio_noofread,
@fileio_noofwrite,
@fileio_miniowritestall ,
@fileio_minioreadstall 
end

close cur_iom_info
deallocate cur_iom_info
print'</table><br/>'

print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Database Name</strong></th>'+
'<th><strong>Physical File Name</strong></th>'+
'<th><strong>IO stall READ in MS</strong></th>'+
'<th><strong>IO Num of READ</strong></th>'+
'<th><strong>IO Avg READ Stall in MS </strong></th>'+
'<th><strong>IO stall WRITE in MS</strong></th>'+
'<th><strong>IO Num of WRITE</strong></th>'+
'<th><strong>IO Avg WRITE Stall in MS</strong></th>'+
'<th><strong>IO Stalls in MS(Io stall read_MS+Io stall write_MS)</strong></th>'+
'<th><strong>Total IO(Total Read+Total Write)</strong></th>'+
N'<th><strong>IO Avg IO Stall</strong></th></tr>'


declare cur_db_io_readwrite cursor for SELECT DB_NAME(fs.database_id) AS [Database Name], mf.physical_name, io_stall_read_ms, num_of_reads,
CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1)) AS [avg_read_stall_ms],io_stall_write_ms, 
num_of_writes,CAST(io_stall_write_ms/(1.0+num_of_writes) AS NUMERIC(10,1)) AS [avg_write_stall_ms],
io_stall_read_ms + io_stall_write_ms AS [io_stalls], num_of_reads + num_of_writes AS [total_io],
CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1)) 
AS [avg_io_stall_ms]
FROM sys.dm_io_virtual_file_stats(null,null) AS fs 
INNER JOIN sys.master_files AS mf WITH (NOLOCK)
ON fs.database_id = mf.database_id
AND fs.[file_id] = mf.[file_id]
ORDER BY avg_io_stall_ms DESC OPTION (RECOMPILE);

open cur_db_io_readwrite
fetch from cur_db_io_readwrite into
@IO_DBName,
@IO_PhyName,
@io_stall_read_ms,
@io_num_of_reads,
@io_avg_read_stall_ms,
@io_stall_write_ms,
@io_num_of_writes,
@io_avg_write_stall_ms,
@io_stalls,
@io_total,
@avg_io_stall_ms
while @@fetch_status>=0
begin

print '<tr><td>'+cast(@IO_DBName as varchar(500))+
	  '</td><td>'+cast(@IO_PhyName as varchar(5000))+
	  '</td><td>'+cast(@io_stall_read_ms as varchar(50))+
	  '</td><td>'+cast(@io_num_of_reads as varchar(50))+
	  '</td><td>'+cast(@io_avg_read_stall_ms as varchar(50))+
	  '</td><td>'+cast(@io_stall_write_ms as varchar(50))+
	  '</td><td>'+cast(@io_num_of_writes as varchar(50))+
	  '</td><td>'+cast(@io_avg_write_stall_ms as varchar(50))+
	  '</td><td>'+cast(@io_stalls as varchar(50))+
	  '</td><td>'+cast(@io_total as varchar(50))+
	  '</td><td>'+cast(@avg_io_stall_ms as varchar(50))+'</td>'+'</tr>'

fetch from cur_db_io_readwrite into
@IO_DBName,
@IO_PhyName,
@io_stall_read_ms,
@io_num_of_reads,
@io_avg_read_stall_ms,
@io_stall_write_ms,
@io_num_of_writes,
@io_avg_write_stall_ms,
@io_stalls,
@io_total,
@avg_io_stall_ms

end

close cur_db_io_readwrite
deallocate cur_db_io_readwrite
print'</table><br/>'
print'<table style="width: 100%">
	<tr>
		<td><span class="auto-style1"><strong>SQL Server Databases Datafiles 
		Writes/Reads:-</strong></span><br>-- This above table will give you 
		detail about the Database DataFiles read/write operation information 
		along with Read Stall and Write Stall.<br>--  Helps you determine 
		which database files on the entire instance have the most I/O 
		bottlenecks.<br>-- This can help you decide whether certain LUNs are 
		overloaded and whether you might.<br>-- With help of this you can plan 
		to move some of very busy files to some another less busy locations.</td>
	</tr>
</table>'

/*
SQL Server database wise CPU Utilization Query
*/

print N'<H3>SQL Server Databases Wise CPU Utilization</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Row Count</strong></th>'+
'<th><strong>Database Name</strong></th>'+
'<th><strong>CPU Time in MS</strong></th>'+
N'<th><strong>CPU Usage in(%)</strong></th></tr>'


declare cur_db_cpuusage cursor for 
WITH DB_CPU_Stats
AS
(SELECT DatabaseID, DB_Name(DatabaseID) AS [DatabaseName], SUM(total_worker_time) AS [CPU_Time_Ms]
 FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
 CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID] 
              FROM sys.dm_exec_plan_attributes(qs.plan_handle)
              WHERE attribute = N'dbid') AS F_DB
 GROUP BY DatabaseID)
SELECT ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [row_num],
       DatabaseName, [CPU_Time_Ms], 
       CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPUPercent]
FROM DB_CPU_Stats
WHERE DatabaseID > 4 -- system databases
AND DatabaseID <> 32767 -- ResourceDB
ORDER BY row_num OPTION (RECOMPILE);

open cur_db_cpuusage

fetch cur_db_cpuusage into 
@row_cnt,
@Db_name,
@Db_cpu_time_ms,
@db_cpu_per

while @@fetch_status>=0
begin
print '<tr><td>'+cast(@row_cnt as varchar(50))+'</td><td>'+cast(@Db_name as varchar(500))+'</td><td>'+cast(@Db_cpu_time_ms as varchar(500))+'</td><td>'+cast(@db_cpu_per as varchar(500))+'</td>'+'</tr>'
fetch cur_db_cpuusage into 
@row_cnt,
@Db_name,
@Db_cpu_time_ms,
@db_cpu_per

end 
close cur_db_cpuusage
deallocate cur_db_cpuusage
print'</table><br/>'

print '<table style="width: 100%">
	<tr>
		<td><span class="auto-style1"><strong>SQL Server Databases Wise CPU 
		Utilization:-</strong></span><br>-- This above table helps you to 
		determine which database is using most of CPU.<br>-- With the help of 
		above table we can tune the database to reduce consumption of CPU( 
		Statistics Update,Weekly Indxe Rebuild)<br>-- If fesible tune most 
		expensive query by CPU utilization.</td>
	</tr>
</table>'

/*
SQL Server databases Cache Size Information in the bpool Query.
*/ 

print N'<H3>SQL Server Databases Cache Size Information in Buffer Pool</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Database Name</strong></th>'+
N'<th><strong>Cache Size in (MB)</strong></th></tr>'

declare cur_db_cacheinfo cursor for 
SELECT DB_NAME(database_id) AS [Database Name],
COUNT(*) * 8/1024.0 AS [Cached Size (MB)]
FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
WHERE database_id > 4 -- system databases
AND database_id <> 32767 -- ResourceDB
GROUP BY DB_NAME(database_id)
ORDER BY [Cached Size (MB)] DESC OPTION (RECOMPILE);

open cur_db_cacheinfo
 fetch from cur_db_cacheinfo into 
 @dbcache_Dbname,
 @dbcache_dbcachesizeMB
 while @@FETCH_STATUS>=0
 begin 
print '<tr><td>'+cast(@dbcache_Dbname as varchar(500))+'</td><td>'+cast(@dbcache_dbcachesizeMB as varchar(500))+'</td>'+'</tr>'
fetch from cur_db_cacheinfo into 
 @dbcache_Dbname,
 @dbcache_dbcachesizeMB
 end

 close cur_db_cacheinfo
 deallocate cur_db_cacheinfo

print'</table><br/>'
print '<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">SQL Server Databases Cache Size 
		Information in Buffer Pool:-</span><br class="auto-style1"></strong>
		--This above table tells you total buffer usage by the databases.<br>
		--It also tells you how much memory in the buffer pool is being used by 
		each database on the instance.</td>
	</tr>
</table>'


/*
SQL Server Instance Over all Wait Type information Query
*/

print N'<H3>SQL Server Instance Wait Type Information</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>WAIT Type Names</strong></th>'+
'<th><strong>WAIT Time in (S)</strong></th>'+
'<th><strong>Resource Time in (S)</strong></th>'+
'<th><strong>Signal Time (S)</strong></th>'+
'<th><strong>Wait Counts</strong></th>'+
'<th><strong>WAIT Perc(%)</strong></th>'+
N'<th><strong>Running in (%)</strong></th></tr>'

declare cur_inst_waitinfo cursor for 
WITH Waits AS
(SELECT 
wait_type,
wait_time_ms / 1000 AS waits,
(wait_time_ms-signal_wait_time_ms)/1000 as Resoruce_Wait_Time_S,
signal_wait_time_ms /1000.0 as signals_wait_time_s,
waiting_tasks_count as WaitCount,
100. * wait_time_ms / SUM(wait_time_ms) OVER() AS Percentage,
ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS RowNumber
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK'
,'SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR', 'LOGMGR_QUEUE','CHECKPOINT_QUEUE'
,'REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP','CLR_MANUAL_EVENT'
,'CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT'
,'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP'))
SELECT 
W1.wait_type as WaitType, 
CAST(W1.waits AS DECIMAL(12, 2)) AS wait_S,
CAST(W1.Resoruce_Wait_Time_S as decimal(12,2)) as Resource_S,
CAST(W1.signals_wait_time_s as decimal(12,2)) as Signal_S,
CAST(W1.WaitCount as varchar(20)) as WaitCounts,
CAST(W1.Percentage AS DECIMAL(12, 2)) AS Percentage_wait,
CAST(SUM(W2.Percentage) AS DECIMAL(12, 2)) AS running_Percentage
FROM Waits AS W1
INNER JOIN Waits AS W2
ON W2.RowNumber <= W1.RowNumber
GROUP BY 
W1.RowNumber,
W1.wait_type, 
W1.waits, 
W1.Percentage,
W1.Resoruce_Wait_Time_S,
W1.signals_wait_time_s,
W1.WaitCount
HAVING SUM(W2.Percentage) - W1.Percentage < 99;

open cur_inst_waitinfo
fetch cur_inst_waitinfo into 
	    @waitType_WaitTypeName,
		@WaitType_waittime_s,
		@WaitType_resource_s,
		@WaitType_Signal_s,
		@WaitType_counts,
		@WaitType_WaitingPct,
		@WaitType_RunningPct

while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@waitType_WaitTypeName as varchar(500))+
	 '</td><td>'+cast(@WaitType_waittime_s as varchar(500))+
	 '</td><td>'+cast(@WaitType_resource_s as varchar(500))+
	 '</td><td>'+cast(@WaitType_Signal_s as varchar(500))+
	 '</td><td>'+cast(@WaitType_counts as varchar(500))+
	 '</td><td>'+cast(@WaitType_WaitingPct as varchar(500))+
	 '</td><td>'+cast(@WaitType_RunningPct as varchar(500))+'</td>'+'</tr>'
fetch cur_inst_waitinfo into 
	    @waitType_WaitTypeName,
		@WaitType_waittime_s,
		@WaitType_resource_s,
		@WaitType_Signal_s,
		@WaitType_counts,
		@WaitType_WaitingPct,
		@WaitType_RunningPct
end

close cur_inst_waitinfo
deallocate cur_inst_waitinfo

print'</table><br/>'
print '<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">SQL Server Instance Wait Type 
		Information:-</span><br class="auto-style1"></strong>-- Common 
		Significant Wait types with BOL explanations<br><br>-- *** Network 
		Related Waits ***<br>-- ASYNC_NETWORK_IO Occurs on network writes when 
		the task is blocked behind the network<br><br>-- *** Locking Waits ***<br>
		-- LCK_M_IX Occurs when a task is waiting to acquire an Intent Exclusive 
		(IX) lock<br>-- LCK_M_IU Occurs when a task is waiting to acquire an 
		Intent Update (IU) lock<br>-- LCK_M_S Occurs when a task is waiting to 
		acquire a Shared lock<br><br>-- *** I/O Related Waits ***<br>-- 
		ASYNC_IO_COMPLETION Occurs when a task is waiting for I/Os to finish<br>
		-- IO_COMPLETION Occurs while waiting for I/O operations to complete.
		<br>-- This wait type generally represents non-data page I/Os. Data page 
		I/O completion waits appear <br>-- as PAGEIOLATCH_* waits<br>-- 
		PAGEIOLATCH_SH Occurs when a task is waiting on a latch for a buffer 
		that is in an I/O request. <br>-- The latch request is in Shared mode. 
		Long waits may indicate problems with the disk subsystem.<br>-- 
		PAGEIOLATCH_EX Occurs when a task is waiting on a latch for a buffer 
		that is in an I/O request. <br>-- The latch request is in Exclusive 
		mode. Long waits may indicate problems with the disk subsystem.<br>-- 
		WRITELOG Occurs while waiting for a log flush to complete. <br>-- Common 
		operations that cause log flushes are checkpoints and transaction 
		commits.<br>-- PAGELATCH_EX Occurs when a task is waiting on a latch for 
		a buffer that is not in an I/O request. <br>-- The latch request is in 
		Exclusive mode.<br>-- BACKUPIO Occurs when a backup task is waiting for 
		data, or is waiting for a buffer in which to store data<br><br>-- *** 
		CPU Related Waits ***<br>-- SOS_SCHEDULER_YIELD Occurs when a task 
		voluntarily yields the scheduler for other tasks to execute. <br>-- 
		During this wait the task is waiting for its quantum to be renewed.<br>
		<br>-- THREADPOOL Occurs when a task is waiting for a worker to run on.
		<br>-- This can indicate that the maximum worker setting is too low, or 
		that batch executions are taking <br>-- unusually long, thus reducing 
		the number of workers available to satisfy other batches.<br>-- 
		CX_PACKET Occurs when trying to synchronize the query processor exchange 
		iterator <br>-- You may consider lowering the degree of parallelism if 
		contention on this wait type becomes a problem<br></td>
	</tr>
</table>
<br/>'


/*
SQL Server Signal Wait Type Query
*/

print N'<H3>SQL Server Signal Wait in Percentage</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>%signal (cpu) waits</strong></th>'+
N'<th><strong>%resource waits</strong></th></tr>'

declare cur_sql_cpuwaitinfo cursor for
SELECT CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) AS [%signal (cpu) waits],
       CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) AS [%resource waits]
FROM sys.dm_os_wait_stats OPTION (RECOMPILE);

open cur_sql_cpuwaitinfo

fetch from cur_sql_cpuwaitinfo into 
@cpuwait_signal_cpu_waits,
@cpuwait_resource_wait

while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@cpuwait_signal_cpu_waits as varchar(500))+'</td><td>'+cast(@cpuwait_resource_wait as varchar(500))+'</td>'+'</tr>'

fetch from cur_sql_cpuwaitinfo into 
@cpuwait_signal_cpu_waits,
@cpuwait_resource_wait

end
close cur_sql_cpuwaitinfo
deallocate cur_sql_cpuwaitinfo

print'</table><br/>'
print '<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">SQL Server Signal Wait in (%):-</span><br class="auto-style1">
		</strong><br>-- Signal Waits above 10-15% is usually a sign of CPU 
		pressure</td>
	</tr>
</table>
<br/>'

/*

SQL Server Login Count and Session Detail.
*/

print N'<H3>SQL Server Login and session count detail</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>SQL Login Name</strong></th>'+
N'<th><strong>SQL Session Counts</strong></th></tr>'

declare cur_session_countinfo cursor for 
SELECT login_name, COUNT(session_id) AS [session_count] 
FROM sys.dm_exec_sessions WITH (NOLOCK)
GROUP BY login_name
ORDER BY COUNT(session_id) DESC OPTION (RECOMPILE);

open cur_session_countinfo
fetch from cur_session_countinfo into 
@logindet_LoginName,
@logindet_session_count
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@logindet_LoginName as varchar(500))+'</td><td>'+cast(@logindet_session_count as varchar(500))+'</td>'+'</tr>'
fetch from cur_session_countinfo into 
@logindet_LoginName,
@logindet_session_count
end
close cur_session_countinfo
deallocate cur_session_countinfo
print'</table><br/>'
print '<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">SQL Server Login and Session 
		Detail:-</span><br class="auto-style1"></strong>-- Get logins that are 
		connected and how many sessions they have <br>-- This can help 
		characterize your workload and determine whether you are seeing a normal 
		level of activity.</td>
	</tr>
</table>'


/*

SQL Server Average Task COunt
*/

print N'<H3>SQL Average Tasks count</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Avg Task Count</strong></th>'+
'<th><strong>Avg Runnable Task Count</strong></th>'+
N'<th><strong>Avg Pending IO Disk Count</strong></th></tr>'

declare cur_avgtask_count cursor for 
SELECT AVG(current_tasks_count) AS [Avg Task Count], 
AVG(runnable_tasks_count) AS [Avg Runnable Task Count],
AVG(pending_disk_io_count) AS [AvgPendingDiskIOCount]
FROM sys.dm_os_schedulers WITH (NOLOCK)
WHERE scheduler_id < 255 OPTION (RECOMPILE);

open cur_avgtask_count
fetch from cur_avgtask_count into 
		@avg_task_count,
		@avg_runnable_task_count,
		@avg_diskpendingio_count
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@avg_task_count as varchar(500))+'</td><td>'+cast(@avg_runnable_task_count as varchar(500))+'</td><td>'+cast(@avg_runnable_task_count as varchar(500))+'</td>'+'</tr>'
fetch from cur_avgtask_count into 
		@avg_task_count,
		@avg_runnable_task_count,
		@avg_diskpendingio_count
end
close cur_avgtask_count
deallocate cur_avgtask_count
print'</table><br/>'
print ' <table style="width: 100%">
	<tr>
		<td>SQL Average Tasks Count:<br>-- Sustained values above 10 suggest 
		further investigation in that area.<br>-- High current_tasks_count is 
		often an indication of locking/blocking problems.<br>-- High 
		runnable_tasks_count is an indication of CPU pressure.<br>-- High 
		pending_disk_io_count is an indication of I/O pressure.</td>
	</tr>
</table>
<br>'


/* 

SQL Server and OS Cpu utilization for last 4 hours

*/
print N'<H3>SQL and OS CPU Utilization from SQL Ring Buffer</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>SQL Server Process CPU Util</strong></th>'+
'<th><strong>System IDLE Process CPU Util</strong></th>'+
'<th><strong>Other Process CPU Util</strong></th>'+
N'<th><strong>CPU Time Stamp</strong></th></tr>'

select  @ts_now= (SELECT cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info)
declare cur_sqlos_cpu_usage cursor for 



SELECT TOP(256) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               SystemIdle AS [System Idle Process], 
               100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
FROM ( 
	  SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
			AS [SystemIdle], 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
			'int') 
			AS [SQLProcessUtilization], [timestamp] 
	  FROM ( 
			SELECT [timestamp], CONVERT(xml, record) AS [record] 
			FROM sys.dm_os_ring_buffers WITH (NOLOCK)
			WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
			AND record LIKE N'%<SystemHealth>%') AS x 
	  ) AS y 
ORDER BY record_id DESC OPTION (RECOMPILE);

open cur_sqlos_cpu_usage

fetch  from cur_sqlos_cpu_usage into
@sqlproc_cpu_Sql_proc,
@sqlproc_cpu_sysidle,
@sqlproc_cpu_otheros_proc,
@sqlproc_cpu_event_time

while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@sqlproc_cpu_Sql_proc as varchar(500))+'</td><td>'+cast(@sqlproc_cpu_sysidle as varchar(500))+'</td><td>'+cast(@sqlproc_cpu_otheros_proc as varchar(500))+'</td><td>'+cast(@sqlproc_cpu_event_time as varchar(500))+'</td>'+'</tr>'
fetch  from cur_sqlos_cpu_usage into
@sqlproc_cpu_Sql_proc,
@sqlproc_cpu_sysidle,
@sqlproc_cpu_otheros_proc,
@sqlproc_cpu_event_time
end
close cur_sqlos_cpu_usage
deallocate cur_sqlos_cpu_usage
print'</table><br/>'
print '<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">SQL and OS CPU Utilization from 
		SQL Ring Buffer:-</span><br class="auto-style1"><br></strong>-- Look at 
		the trend over the entire period. <br>-- Also look at high sustained 
		Other Process CPU Utilization values</td>
	</tr>
</table>
<br/>'

/*
SQL Server memory utilization History via PLE
*/
print N'<H3>SQL Memory Utilization History</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Server Name</strong></th>'+
'<th><strong>Object Name</strong></th>'+
'<th><strong>Instance Name</strong></th>'+
N'<th><strong>Page Life Expectancy</strong></th></tr>'

declare cur_sql_mem_info cursor for 
SELECT @@SERVERNAME AS [Server Name], [object_name], instance_name, cntr_value AS [Page Life Expectancy]
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Buffer Node%' -- Handles named instances
AND counter_name = N'Page life expectancy' OPTION (RECOMPILE);

open cur_sql_mem_info
fetch from cur_sql_mem_info into 
@sqlmem_svr_name,
@sqlmem_obj_name,
@sqlmem_ins_name,
@sqlmem_Page_life_expe
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@sqlmem_svr_name as varchar(500))+'</td><td>'+cast(@sqlmem_obj_name as varchar(500))+'</td><td>'+cast(@sqlmem_ins_name as varchar(500))+'</td><td>'+cast(@sqlmem_Page_life_expe as varchar(500))+'</td>'+'</tr>'
fetch from cur_sql_mem_info into 
@sqlmem_svr_name,
@sqlmem_obj_name,
@sqlmem_ins_name,
@sqlmem_Page_life_expe
end
close cur_sql_mem_info
deallocate cur_sql_mem_info
print'</table><br/>'

print '<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">SQL Server Memory Utilization 
		History:-</span><br class="auto-style1"></strong><br>-- Page Life 
		Expectancy (PLE) value for each NUMA node in current instance<br>-- PLE 
		is a good measurement of memory pressure.<br>-- Higher PLE is better. 
		Watch the trend, not the absolute value.<br>-- This will only return one 
		row for non-NUMA systems.</td>
	</tr>
</table>
<br/>'

/*

SQL Server memory grant pending
*/

print N'<H3>SQL Memory Grant Pending History</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Server Name</strong></th>'+
'<th><strong>Object Name</strong></th>'+
N'<th><strong>Memory Grants Pending</strong></th></tr>'

declare cur_sqlmem_grantinfo cursor for 
SELECT @@SERVERNAME AS [Server Name], [object_name], cntr_value AS [Memory Grants Pending]                                                                                                       
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Memory Manager%' -- Handles named instances
AND counter_name = N'Memory Grants Pending' OPTION (RECOMPILE);

open cur_sqlmem_grantinfo
fetch from cur_sqlmem_grantinfo into 
@sqlmem_svrm_name,
@sqlmem_sql_obj_name,
@sqlmem_sql_mem_grant_pend
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@sqlmem_svrm_name as varchar(500))+'</td><td>'+cast(@sqlmem_sql_obj_name as varchar(500))+'</td><td>'+cast(@sqlmem_sql_mem_grant_pend as varchar(500))+'</td>'+'</tr>'

fetch from cur_sqlmem_grantinfo into 
@sqlmem_svrm_name,
@sqlmem_sql_obj_name,
@sqlmem_sql_mem_grant_pend
end
close cur_sqlmem_grantinfo
deallocate cur_sqlmem_grantinfo
print'</table><br/>'

print '<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">SQL Server Memory Grant Pending 
		History:-</span><br class="auto-style1"><br></strong>-- Memory Grants 
		Pending above zero for a sustained period is a very strong indicator of 
		memory pressure.</td>
	</tr>
</table>
<br/>'

/*
SQL Server memory clerk utilization
*/

print N'<H3>SQL Memory Clerks Memory Utilization</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Memory Clerk Name</strong></th>'+
N'<th><strong>Single Page Memory Allocation in (KB)</strong></th></tr>'

declare cur_sqlmem_clerkinfo cursor for 
SELECT TOP(10) [type] AS [Memory Clerk Type], SUM(single_pages_kb) AS [SPA Mem, Kb] 
FROM sys.dm_os_memory_clerks WITH (NOLOCK)
GROUP BY [type]  
ORDER BY SUM(single_pages_kb) DESC OPTION (RECOMPILE);

open cur_sqlmem_clerkinfo
fetch from cur_sqlmem_clerkinfo into
@sqlmemclerk_obj_name,
@sqlmemclerk_mem_kb
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@sqlmemclerk_obj_name as varchar(500))+'</td><td>'+cast(@sqlmemclerk_mem_kb as varchar(500))+'</td>'+'</tr>'
fetch from cur_sqlmem_clerkinfo into
@sqlmemclerk_obj_name,
@sqlmemclerk_mem_kb
end
close cur_sqlmem_clerkinfo
deallocate cur_sqlmem_clerkinfo
print'</table><br/>'

print'<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">SQL Server Memory Clerk 
		Information:-</span><br><br></strong>-- Look for high value for 
		CACHESTORE_SQLCP (Ad-hoc query plans)<br>-- CACHESTORE_SQLCP SQL Plans
		<br>-- These are cached SQL statements or batches that <br>-- aren't in 
		stored procedures, functions and triggers<br>-- CACHESTORE_OBJCP Object 
		Plans <br>-- These are compiled plans for <br>-- stored procedures, 
		functions and triggers<br>-- CACHESTORE_PHDR Algebrizer Trees <br>-- An 
		algebrizer tree is the parsed SQL text <br>-- that resolves the table 
		and column names</td>
	</tr>
</table>
<br/>'
/*
SQL Server QUery which tells you who is bloating plan cache
*/

print N'<H3>SQL Ad Hoc Query Plan cache  Utilization by Top 10</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>SQL Query Text</strong></th>'+
N'<th><strong>Size in Bytes(B)</strong></th></tr>'


declare cur_plancache_bloatqry cursor for 
SELECT TOP(10) [text] AS [QueryText], cp.size_in_bytes
FROM sys.dm_exec_cached_plans AS cp WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
WHERE cp.cacheobjtype = N'Compiled Plan' 
AND cp.objtype = N'Adhoc' 
AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC OPTION (RECOMPILE);


open cur_plancache_bloatqry
fetch from cur_plancache_bloatqry into
@adhocQue_QueryText,
@adhocQue_Qplan_size_byte

while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@adhocQue_QueryText as varchar(4000))+'</td><td>'+cast(@adhocQue_Qplan_size_byte as varchar(500))+'</td>'+'</tr>'
fetch from cur_plancache_bloatqry into
@adhocQue_QueryText,
@adhocQue_Qplan_size_byte
end
close cur_plancache_bloatqry
deallocate cur_plancache_bloatqry
print'</table><br/>'

print '<table style="width: 100%">
	<tr>
		<td><strong>SQL Ad-Hoc Query Plan cache Utilization by TOP 50:-<br>
		</strong>-- Gives you the text and size of single-use ad-hoc queries 
		that waste space in plan cache<br>-- SQL Server Agent creates lots of 
		ad-hoc, single use query plans in SQL Server 2005<br>-- Enabling forced 
		parameterization for the database can help<br></td>
	</tr>
</table>
<p> </p>'

/*
SQL Server 2005 TokenAndPermUserStore cache information query
*/



print N'<H3>SQL Server 2005 TokenAndPermUserStore cache information</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>SecurityTokenCacheSize(kb)</strong></th></tr>'

declare cur_tkenpermcache_info cursor for 
SELECT SUM(single_pages_kb + multi_pages_kb) AS "SecurityTokenCacheSize(kb)"
FROM sys.dm_os_memory_clerks
WHERE name = 'TokenAndPermUserStore'

open cur_tkenpermcache_info

fetch from cur_tkenpermcache_info into
@tokempermcachesizekb
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@tokempermcachesizekb as varchar(200))+'</td>'+'</tr>'
fetch from cur_tkenpermcache_info into
@tokempermcachesizekb
end
close cur_tkenpermcache_info
deallocate cur_tkenpermcache_info

print'</table><br/>'

print N'<H3>Monitor the number of entries that are removed in the cache store during the clock hand movement</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Name</strong></th>'+
'<th><strong>Type</strong></th>'+
'<th><strong>clock_hand</strong></th>'+
'<th><strong>clock_status</strong></th>'+
'<th><strong>rounds_count</strong></th>'+
'<th><strong>removed_all_rounds_count</strong></th>'+
'<th><strong>removed_last_round_count</strong></th>'+
'<th><strong>updated_last_round_count</strong></th>'+
N'<th><strong>last_round_start_time</strong></th></tr>'
declare cur_clockcount_tkenperm cursor for
select name,type,clock_hand,clock_status,rounds_count,removed_all_rounds_count
,removed_last_round_count,updated_last_round_count,last_round_start_time from sys.dm_os_memory_cache_clock_hands where name='TokenAndPermUserStore'

open cur_clockcount_tkenperm
fetch from cur_clockcount_tkenperm into 
		@clocktokenname ,
		@clocktyoe ,
		@clockhand ,
		@clock_status ,
		@clockroundcounts,
		@clockremovedallroundcount,
		@clockremovedlastroundcount,
		@clockupdatedlastroundcount,
		@clocklastroundstarttime 

while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@clocktokenname as varchar(200))+'</td><td>'+cast(@clocktyoe as varchar(200))+'</td><td>'+cast(@clockhand as varchar(200))+'</td><td>'+cast(@clock_status as varchar(200))+'</td><td>'+cast(@clockroundcounts as varchar(200))+'</td><td>'+cast(@clockremovedallroundcount as varchar(200))+'</td><td>'+cast(@clockremovedlastroundcount as varchar(200))+'</td><td>'+cast(@clockupdatedlastroundcount as varchar(200))+'<td>'+cast(@clocklastroundstarttime as varchar(200))+'</td>'+'</tr>'
fetch from cur_clockcount_tkenperm into 
@clocktokenname ,
		@clocktyoe ,
		@clockhand ,
		@clock_status ,
		@clockroundcounts,
		@clockremovedallroundcount,
		@clockremovedlastroundcount,
		@clockupdatedlastroundcount,
		@clocklastroundstarttime 
end

 close cur_clockcount_tkenperm
 deallocate cur_clockcount_tkenperm
 print'</table><br/>'
print'<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">SQL Server 2005 
		TokenAndPermUserStore cache information:-</span><br class="auto-style1">
		</strong>--TokenAndPermUserStore is one of the many caches present in 
		the SQL Server 2005 memory architecture. As the name implies, this cache 
		stores various security related information used by the SQL Server 
		Engine.<br>--These tokens represent information about cumulative 
		permission checks for queries.<br>--There are several indicators you can 
		monitor to determine if you are running into this class of problems.<br>
		1. The amount of memory used by this security token cache<br>2. The 
		number of entries present in this security token cache<br>3. The extent 
		of contention on this security token cache<br>--There is no specific 
		threshold for this size beyond which the problem starts to happen. The 
		characteristic you need to monitor is the rate at which this cache size 
		is growing.<br>--If you are encountering problems with this cache, then 
		you will notice that as the size of the cache grows, the nature of the 
		problems you experience becomes worse. On a sample server that 
		experienced this problem, the cache grew at a rate approximately 1MB per 
		min to reach close to 1.2 GB. We have seen the problem starting to show 
		up even when the size of this cache reaches several hundred MB.<br>--The 
		symptoms that you want to correlate with the above data points include a 
		combination of the following:<br>1. Queries which normally finish faster 
		take a long time<br>2. CPU usage of SQL Server process is relatively 
		higher. CPU usage could come down after remaining high for a period of 
		time.<br>3. Connections from your applications keep increasing 
		(specifically in connection pool environments)<br>4. You encounter 
		connection or query timeouts<br>--In Microsoft SQL Server 2005, 
		performance issues may occur and CPU usage may increase when the size of 
		the TokenAndPermUserStore cache store increases to several hundred 
		megabytes. To address these issues, SQL Server 2005 Service Pack 3 
		enables you to customize the quota for the TokenAndPermUserStore cache 
		store.<br>--Quota defines the threshold for the number of entries in the 
		cache store. As soon as a new entry is added that exceeds the quota, an 
		internal clock hand movement is made that decrements the cost of each 
		entry in the store, and those entries whose cost reaches zero are 
		released. <br>--You can monitor the number of entries that are removed 
		in the cache store during the clock hand movement. To do this, query the 
		sys.dm_os_memory_cache_clock_hands Dynamic Management View.<br>
		<a href="http://support.microsoft.com/default.aspx?scid=kb;EN-US;959823" target="_blank">
		http://support.microsoft.com/default.aspx?scid=kb;EN-US;959823</a></td>
	</tr>
</table><br/>'


/*
Trace Information about this SQL Server Instance.
*/


print N'<H3>SQL Server enable trace information</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>TraceFlag Name</strong></th>'+
'<th><strong>Status</strong></th>'+
'<th><strong>Global</strong></th>'+
N'<th><strong>Session</strong></th></tr>'
set nocount on
create table #traceinfo(flag varchar(20),Status varchar(10),Global varchar(10),Session varchar(10))
INSERT INTO #traceinfo EXECUTE ('DBCC TRACESTATUS(-1)')

declare cur_trace_info cursor for select flag,Status,Global,Session from #traceinfo
open cur_trace_info
fetch from cur_trace_info
into 
@flagname,
@flagstatus,
@flagglobal,
@flagsesion

while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@flagname as varchar(20))+'</td><td>'+cast(@flagstatus as varchar(20))+'</td><td>'+cast(@flagglobal as varchar(20))+'</td><td>'+cast(@flagsesion as varchar(20))+'</td>'+'</tr>'
fetch from cur_trace_info
into 
@flagname,
@flagstatus,
@flagglobal,
@flagsesion
end
close cur_trace_info
deallocate cur_trace_info
drop table #traceinfo
 print'</table><br/>'
print'<table>
	<tr>
	<td>--For More information about the traceflag please visit following link
	<a href="http://msdn.microsoft.com/en-us/library/ms188396.aspx" target="_blank">
		Trace Flag Information</a></td>
	</tr>
</table><br/>'



/*
Script for getting Top 20 SP ordered bu total worker time to find out most expensive sp by total worker time
indication could be CPU pressure.
The following example returns information about the top five queries ranked by average CPU time. This example aggregates the queries according to their query hash so that logically equivalent queries are grouped by their cumulative resource consumption. 


*/


print N'<H3>SQL Server Top 10 SP ordered by Total Worker time:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>SP Name/Text</strong></th>'+
'<th><strong>Total Worker Time in Microsecond</strong></th>'+
'<th><strong>Average Worker Time in Microsecond</strong></th>'+
'<th><strong>Execution Count</strong></th>'+
'<th><strong>Calls /Second</strong></th>'+
'<th><strong>Average Elapsed Time in Microsecond</strong></th>'+
'<th><strong>Max Logical Reads</strong></th>'+
'<th><strong>Max Logical Writes</strong></th>'+
N'<th><strong>Age in Cache(Min)</strong></th></tr>'

declare cur_topspcpu_info cursor for 
SELECT TOP(10) qt.[text] AS [SP Name],
qs.total_worker_time AS [TotalWorkerTimeinmicroseconds],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTimeinmicroseconds],
qs.execution_count AS [Execution Count],
NULLIF(qs.execution_count/DATEDIFF(Second, qs.creation_time,
GETDATE()), 1) AS [Calls/Second],
ISNULL(qs.total_elapsed_time/qs.execution_count, 0)
AS [AvgElapsedTimemicroseconds],
qs.max_logical_reads, qs.max_logical_writes,
DATEDIFF(Minute, qs.creation_time, GETDATE()) AS [Age in Cache]
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.[sql_handle]) AS qt
--WHERE qt.[dbid] = DB_ID() -- Filter by current database
ORDER BY qs.total_worker_time DESC;

open cur_topspcpu_info
fetch from cur_topspcpu_info into 
		@topspbycpu_spname,
		@topspbycpu_totalworkertimeinmicros ,
		@topspbycpu_Avgworkertimeinmicros ,
		@topspbycpu_Executioncount ,
		@topspbycpu_callsecond ,
		@topspbycpu_averageelapsedtimeinmicros ,
		@topspbycpu_maxlogicalread ,
		@topspbycpu_maxlogicalwrites ,
		@topspbycpu_ageincache 


while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@topspbycpu_spname as varchar(1000))+
	 '</td><td>'+cast(@topspbycpu_totalworkertimeinmicros as varchar(200))+
	 '</td><td>'+cast(@topspbycpu_Avgworkertimeinmicros as varchar(200))+
	 '</td><td>'+cast(@topspbycpu_Executioncount as varchar(20))+
	 '</td><td>'+ISNULL(cast(@topspbycpu_callsecond as varchar(20)),0)+
	 '</td><td>'+cast(@topspbycpu_averageelapsedtimeinmicros as varchar(20))+
	 '</td><td>'+cast(@topspbycpu_maxlogicalread as varchar(20))+
	 '</td><td>'+cast(@topspbycpu_maxlogicalwrites as varchar(20))+
	 '</td><td>'+cast(@topspbycpu_ageincache as varchar(20))+'</td>'+'</tr>'
fetch from cur_topspcpu_info into 
		@topspbycpu_spname,
		@topspbycpu_totalworkertimeinmicros ,
		@topspbycpu_Avgworkertimeinmicros ,
		@topspbycpu_Executioncount ,
		@topspbycpu_callsecond ,
		@topspbycpu_averageelapsedtimeinmicros ,
		@topspbycpu_maxlogicalread ,
		@topspbycpu_maxlogicalwrites ,
		@topspbycpu_ageincache 

end
close cur_topspcpu_info
deallocate cur_topspcpu_info
 print'</table><br/>'
 print N'<table style="width: 100%">
	<tr>
		<td><strong>SQL Server Top 10 SP ordered by Total Worker time:-</strong><br>
		--Above table shows the top 10 stored procedures sorted by total worker 
		time (which equates to CPU pressure). This will tell you the most 
		expensive stored procedures from a CPU perspective</td>
	</tr>
</table>'



 /*
 
SQL Server Scheduler Information and NUMA related Information if parent node has more than one vlaue other than 0 and 32 and 64 
then it indicate that you have NUMA architecture available with your server

 */


 

print N'<H3>SQL Server Scheduler stats and NUMA Stats :-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Parent Node ID/Text</strong></th>'+
'<th><strong>Scheduler ID</strong></th>'+
'<th><strong>CPU ID</strong></th>'+
'<th><strong>Schedler Status</strong></th>'+
'<th><strong>Is Online</strong></th>'+
'<th><strong>Is Idle</strong></th>'+
'<th><strong>Preemptive Switches Count:-</strong></th>'+
'<th><strong>Context Switches Count:-</strong></th>'+
'<th><strong>Idle Switches Count</strong></th>'+
'<th><strong>Current Tasks Count</strong></th>'+
'<th><strong>Runnable Tasks Count</strong></th>'+
'<th><strong>Current Workers Count</strong></th>'+
'<th><strong>Pending Disk IO Count</strong></th>'+
'<th><strong>Failed to Create Workerthread Count</strong></th>'+
N'<th><strong>Active Workers Count</strong></th></tr>'

declare cur_sqlschedule_info cursor for 
select parent_node_id,scheduler_id,cpu_id,status,is_online,is_idle,
preemptive_switches_count,
context_switches_count,
idle_switches_count,
current_tasks_count,
runnable_tasks_count,
current_workers_count,
active_workers_count,
pending_disk_io_count,
failed_to_create_worker

 from sys.dm_os_schedulers

 open cur_sqlschedule_info
 fetch from cur_sqlschedule_info into 
		@sqlschedule_parenenodeid,
		@sqlschedule_schdulerid,
		@sqlschedule_cpuid,
		@sqlschedule_status,
		@sqlschedule_isonline ,
		@sqlschedule_isidle ,
		@sqlschedule_preemptiveswtichescounts ,
		@sqlschedule_contextswtichescounts ,
		@sqlschedule_idleswtichescounts ,
		@sqlschedule_currenttaskcounts ,
		@sqlschedule_runnabletaskcounts ,
		@sqlschedule_currentworkercounts ,
		@sqlschedule_activeworkercounts,
		@sqlschedule_pendingiocounts,
		@sqlschedule_failedtocreate		


while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@sqlschedule_parenenodeid as varchar(20))+'</td><td>'+cast(@sqlschedule_schdulerid as varchar(20))+'</td><td>'+cast(@sqlschedule_cpuid as varchar(20))+'</td><td>'+cast(@sqlschedule_status as varchar(20))+'</td><td>'+cast(@sqlschedule_isonline as varchar(20))+'</td><td>'+cast(@sqlschedule_isidle as varchar(200))+'</td><td>'+cast(@sqlschedule_preemptiveswtichescounts as varchar(20))+'</td><td>'+cast(@sqlschedule_contextswtichescounts as varchar(20))+'</td><td>'+cast(@sqlschedule_idleswtichescounts as varchar(20))+'</td><td>'+cast(@sqlschedule_currenttaskcounts as varchar(20))+'</td><td>'+cast(@sqlschedule_runnabletaskcounts as varchar(20))+'</td><td>'+cast(@sqlschedule_currentworkercounts as varchar(20))+'</td><td>'+cast(@sqlschedule_failedtocreate as varchar(20))+'</td><td>'+cast(@sqlschedule_pendingiocounts as varchar(20))+'</td><td>'+cast(@sqlschedule_activeworkercounts as varchar(20))+'</td>'+'</tr>'

 fetch from cur_sqlschedule_info into 
		@sqlschedule_parenenodeid,
		@sqlschedule_schdulerid,
		@sqlschedule_cpuid,
		@sqlschedule_status,
		@sqlschedule_isonline ,
		@sqlschedule_isidle ,
		@sqlschedule_preemptiveswtichescounts ,
		@sqlschedule_contextswtichescounts ,
		@sqlschedule_idleswtichescounts ,
		@sqlschedule_currenttaskcounts ,
		@sqlschedule_runnabletaskcounts ,
		@sqlschedule_currentworkercounts ,
		@sqlschedule_activeworkercounts,
		@sqlschedule_pendingiocounts,
		@sqlschedule_failedtocreate		

end
close cur_sqlschedule_info
deallocate cur_sqlschedule_info
 print'</table><br/>'
 print '<table style="width: 100%">
	<tr>
		<td><strong>SQL Server Scheduler and NUMA Related Information:-<br>
		</strong>--Non-uniform memory access (NUMA) is enabled on your SQL 
		Server instance.<br>--For more information about NUMA please refer to 
		the following links<br>
		<a href="http://msdn.microsoft.com/en-in/library/ms178144(v=sql.105).aspx">
		http://msdn.microsoft.com/en-in/library/ms178144(v=sql.105).aspx</a><br>
		<a href="http://msdn.microsoft.com/en-us/library/ms345357.aspx">
		http://msdn.microsoft.com/en-us/library/ms345357.aspx</a></td>
	</tr>
</table>'


/*
Looking for Physical IO read Pressure 
Top 20 Executed SP ordered by physical reads.
*/

print N'<H3>SQL Server Top 10 SP Executed by Physical Read:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>SP Name</strong></th>'+
'<th><strong>Total Physical Reads</strong></th>'+
'<th><strong>Avg Physical Reads</strong></th>'+
'<th><strong>Execution Count</strong></th>'+
'<th><strong>Calls/Second</strong></th>'+
'<th><strong>AvgWorker Time(in Microsecond)</strong></th>'+
'<th><strong>TotalWorker Time(in Microsecond)</strong></th>'+
'<th><strong>Avg Elapsed Time(in Microsecond)</strong></th>'+
'<th><strong>Max Logical Reads</strong></th>'+
'<th><strong>Max Logical Writes</strong></th>'+
N'<th><strong>Age In Cache</strong></th></tr>'


declare cur_topspiopre_info cursor for 
SELECT TOP (20) qt.[text] AS [SP Name], qs.total_physical_reads,
qs.total_physical_reads/qs.execution_count AS [Avg Physical Reads],
qs.execution_count AS [Execution Count],
qs.execution_count/DATEDIFF(Second, qs.creation_time, GetDate()) AS [Calls/Second],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],
qs.total_worker_time AS [TotalWorkerTime],
qs.total_elapsed_time/qs.execution_count AS [AvgElapsedTime],
qs.max_logical_reads, qs.max_logical_writes,
DATEDIFF(Minute, qs.creation_time, GetDate()) AS [Age in Cache]
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.[sql_handle]) AS qt
--WHERE qt.[dbid] = db_id() -- Filter by current database
ORDER BY qs.total_physical_reads DESC;

open cur_topspiopre_info
fetch from cur_topspiopre_info into 
@topsp_iopressure_spname,
@topsp_iopressure_physicalread,
@topsp_iopressure_spname_avgphysicalread,
@topsp_iopressure_spname_Executioncount,
@topsp_iopressure_spname_callsecond,
@topsp_iopressure_spname_Avgworkertime,
@topsp_iopressure_spname_Totalworkertime,
@topsp_iopressure_spname_Avgelapsedtime,
@topsp_iopressure_spname_maxlogicalreads,
@topsp_iopressure_spname_maxlogicalwrite,
@topsp_iopressure_spname_ageincache

while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@topsp_iopressure_spname as varchar(1000))+
	  '</td><td>'+cast(@topsp_iopressure_physicalread as varchar(40))+
	  '</td><td>'+cast(@topsp_iopressure_spname_avgphysicalread as varchar(40))+
	  '</td><td>'+cast(@topsp_iopressure_spname_Executioncount as varchar(40))+
	  '</td><td>'+ISNULL(cast(@topsp_iopressure_spname_callsecond as varchar(40)),0)+
	  '</td><td>'+cast(@topsp_iopressure_spname_Avgworkertime as varchar(40))+
	  '</td><td>'+cast(@topsp_iopressure_spname_Totalworkertime as varchar(40))+
	  '</td><td>'+cast(@topsp_iopressure_spname_Avgelapsedtime as varchar(40))+
	  '</td><td>'+cast(@topsp_iopressure_spname_maxlogicalreads as varchar(40))+
	  '</td><td>'+cast(@topsp_iopressure_spname_maxlogicalwrite as varchar(40))+
	  '</td><td>'+cast(@topsp_iopressure_spname_ageincache as varchar(40))+'</td>'+'</tr>'

fetch from cur_topspiopre_info into 
@topsp_iopressure_spname,
@topsp_iopressure_physicalread,
@topsp_iopressure_spname_avgphysicalread,
@topsp_iopressure_spname_Executioncount,
@topsp_iopressure_spname_callsecond,
@topsp_iopressure_spname_Avgworkertime,
@topsp_iopressure_spname_Totalworkertime,
@topsp_iopressure_spname_Avgelapsedtime,
@topsp_iopressure_spname_maxlogicalreads,
@topsp_iopressure_spname_maxlogicalwrite,
@topsp_iopressure_spname_ageincache
end

close cur_topspiopre_info
deallocate cur_topspiopre_info
 print'</table><br/>'
 print'<br>
<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">SQL Server Top 10 SP Executed by 
		Physical Read(IO Pressure):-</span><br class="auto-style1"></strong>--Above table shows the top 10 stored procedures sorted by total 
		physical reads(which equates to read I/O pressure). This will tell you 
		the most expensive stored procedures from a read I/O perspective.<br>-- 
		If it is high Physical Read means SQL has to go to the disk in order to 
		write the data this inturns very expensive operation.</td>
	</tr>
</table>
<br/>'

/*
-- Get Top 25 executed SP's ordered by logical reads (memory pressure)
*/



print N'<H3>SQL Server Top 10 SP Executed by Logical Read(Memory Pressure):-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>SP Name</strong></th>'+
'<th><strong>Total Logical Reads</strong></th>'+
'<th><strong>Execution Count</strong></th>'+
'<th><strong>Average Logical Reads</strong></th>'+
'<th><strong>Calls/Second</strong></th>'+
'<th><strong>AvgWorker Time(in Microsecond)</strong></th>'+
'<th><strong>TotalWorker Time(in Microsecond)</strong></th>'+
'<th><strong>Avg Elapsed Time(in Microsecond)</strong></th>'+
'<th><strong>Total Logical Writes</strong></th>'+
'<th><strong>Max Logical Reads</strong></th>'+
'<th><strong>Max Logical Writes</strong></th>'+
'<th><strong>Total Physical Reads</strong></th>'+
N'<th><strong>Age In Cache</strong></th></tr>'


declare cur_sp_top20logical cursor for 
SELECT TOP(10) qt.[text] AS 'SP Name', total_logical_reads,
qs.execution_count AS 'Execution Count',
total_logical_reads/qs.execution_count AS 'AvgLogicalReads',
qs.execution_count/ISNULL(DATEDIFF(Second, qs.creation_time, GetDate()),1) AS 'Calls/Second',
qs.total_worker_time/qs.execution_count AS 'AvgWorkerTime',
qs.total_worker_time AS 'TotalWorkerTime',
qs.total_elapsed_time/qs.execution_count AS 'AvgElapsedTime',
qs.total_logical_writes,
qs.max_logical_reads, qs.max_logical_writes, qs.total_physical_reads,
DATEDIFF(Minute, qs.creation_time, GetDate()) AS 'Age in Cache'
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.[sql_handle]) AS qt
--WHERE qt.[dbid] = db_id() -- Filter by current database
ORDER BY total_logical_reads DESC;

open cur_sp_top20logical
fetch from cur_sp_top20logical into
@topsp_mempressure_spname ,
@topsp_mempressure_totallogicalread ,
@topsp_mempressure_executioncount,
@topsp_mempressure_Avglogicalreads,
@topsp_mempressure_callspersecond ,
@topsp_mempressure_avgworkertime ,
@topsp_mempressure_totalworkertime ,
@topsp_mempressure_Avgelapsedtime ,
@topsp_mempressure_totallogicalwrite ,
@topsp_mempressure_maxlogicalread ,
@topsp_mempressure_maxlogicalwrite ,
@topsp_mempressure_totalphysicalread ,
@topsp_mempressure_ageincache


while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@topsp_mempressure_spname as varchar(1000))+
	  '</td><td>'+cast(@topsp_mempressure_totallogicalread as varchar(40))+
	  '</td><td>'+cast(@topsp_mempressure_executioncount as varchar(40))+
	  '</td><td>'+cast(@topsp_mempressure_Avglogicalreads as varchar(40))+
	  '</td><td>'+ISNULL(cast(@topsp_mempressure_callspersecond as varchar(40)),0)+
	  '</td><td>'+cast(@topsp_mempressure_avgworkertime as varchar(40))+
	  '</td><td>'+cast(@topsp_mempressure_totalworkertime as varchar(40))+
	  '</td><td>'+cast(@topsp_mempressure_Avgelapsedtime as varchar(40))+
	  '</td><td>'+cast(@topsp_mempressure_totallogicalwrite as varchar(40))+
	  '</td><td>'+cast(@topsp_mempressure_maxlogicalread as varchar(40))+
	  '</td><td>'+cast(@topsp_mempressure_maxlogicalwrite as varchar(40))+
	  '</td><td>'+cast(@topsp_mempressure_totalphysicalread as varchar(40))+
	  '</td><td>'+cast(@topsp_mempressure_ageincache as varchar(40))+'</td>'+'</tr>'

fetch from cur_sp_top20logical into
@topsp_mempressure_spname ,
@topsp_mempressure_totallogicalread ,
@topsp_mempressure_executioncount,
@topsp_mempressure_Avglogicalreads,
@topsp_mempressure_callspersecond ,
@topsp_mempressure_avgworkertime ,
@topsp_mempressure_totalworkertime ,
@topsp_mempressure_Avgelapsedtime ,
@topsp_mempressure_totallogicalwrite ,
@topsp_mempressure_maxlogicalread ,
@topsp_mempressure_maxlogicalwrite ,
@topsp_mempressure_totalphysicalread ,
@topsp_mempressure_ageincache
end


close cur_sp_top20logical
deallocate cur_sp_top20logical
 print'</table><br/>'

 print'<br>
<table style="width: 100%">
	<tr>
		<td><strong>SQL Server Top 10 SP by Logical Reads(Memory Pressure):-</strong><br>
		--Above table shows the top 10 stored procedures sorted by total logical 
		reads(which equates to memory pressure). This will tell you the most 
		expensive stored procedures from a memory perspective, and indirectly 
		from a read I/O perspective.</td>
	</tr>
</table>
<br/>'
 /*
   Looking at Index Advantage to find missing indexes
-- Missing Indexes by Index Advantage (make sure to also look at last user seek time)
 */
 
 print N'<H3>SQL Server Missing Indexes by Index Advantage:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Index Advantage</strong></th>'+
'<th><strong>Last User Seek</strong></th>'+
'<th><strong>Datbase Schema Table</strong></th>'+
'<th><strong>Equality Columns</strong></th>'+
'<th><strong>Inequality Columns</strong></th>'+
'<th><strong>Included Columns</strong></th>'+
'<th><strong>Unique Compiles</strong></th>'+
'<th><strong>User Seeks</strong></th>'+
'<th><strong>Average Total user cost</strong></th>'+
N'<th><strong>Average User Impact</strong></th></tr>'



 declare cur_msng_idx_cost_cur cursor for 
 SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) AS
index_advantage, migs.last_user_seek,
mid.statement AS 'Database.Schema.Table',
mid.equality_columns, mid.inequality_columns, mid.included_columns,
migs.unique_compiles, migs.user_seeks, migs.avg_total_user_cost, migs.avg_user_impact
FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
ON mig.index_handle = mid.index_handle
ORDER BY index_advantage DESC;

open cur_msng_idx_cost_cur
fetch from cur_msng_idx_cost_cur into 
@msngidx_idxadv,
@msngidx_lastuser_seek,
@msngidx_dbschematable,
@msngidx_equalitycols,
@msngidx_inequalitycols,
@msngidx_includedcols,
@msngidx_uniquecompiles,
@msngidx_userseeks,
@msngidx_avgtotalusercost,
@msngidx_avguserimpact


while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@msngidx_idxadv as varchar(100))+
	  '</td><td>'+cast(@msngidx_lastuser_seek as varchar(40))+
	  '</td><td>'+cast(@msngidx_dbschematable as varchar(1000))+
	  '</td><td>'+cast(@msngidx_equalitycols as varchar(1000))+
	  '</td><td>'+cast(@msngidx_inequalitycols as varchar(1000))+
	  '</td><td>'+cast(@msngidx_includedcols as varchar(1000))+
	  '</td><td>'+cast(@msngidx_uniquecompiles as varchar(40))+
	  '</td><td>'+cast(@msngidx_userseeks as varchar(40))+
	  '</td><td>'+cast(@msngidx_avgtotalusercost as varchar(40))+
	  '</td><td>'+cast(@msngidx_avguserimpact as varchar(40))+'</td>'+'</tr>'

fetch from cur_msng_idx_cost_cur into 
@msngidx_idxadv,
@msngidx_lastuser_seek,
@msngidx_dbschematable,
@msngidx_equalitycols,
@msngidx_inequalitycols,
@msngidx_includedcols,
@msngidx_uniquecompiles,
@msngidx_userseeks,
@msngidx_avgtotalusercost,
@msngidx_avguserimpact

end


close cur_msng_idx_cost_cur
deallocate cur_msng_idx_cost_cur
 print'</table><br/>'


 print N'<H3>SQL Server Missing Indexes With Index Creating:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Index Group Handle</strong></th>'+
'<th><strong>Index Handle</strong></th>'+
'<th><strong>Index Improvments Measures</strong></th>'+
'<th><strong>Index Create Statement</strong></th>'+
'<th><strong>Index Group Handle</strong></th>'+
'<th><strong>Index Unique Compiles</strong></th>'+
'<th><strong>Index User Seeks</strong></th>'+
'<th><strong>Index  User Scans</strong></th>'+
'<th><strong>Index Last User Seek</strong></th>'+
'<th><strong>Index Last User Scan</strong></th>'+
'<th><strong>Index Avg Total User Cost</strong></th>'+
'<th><strong>Index Avg User Impact</strong></th>'+
'<th><strong>Index System Seek</strong></th>'+
'<th><strong>Index System Scan</strong></th>'+
'<th><strong>Index Last Sytem Seek</strong></th>'+
'<th><strong>Index Avg total System Cost</strong></th>'+
'<th><strong>Index Avg System Impact</strong></th>'+
'<th><strong>Database ID</strong></th>'+
N'<th><strong>Object ID</strong></th></tr>'

declare cu_msgdet cursor for 
SELECT  
 mig.index_group_handle
 , mid.index_handle
 ,CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) AS improvement_measure
 ,'CREATE INDEX missing_index_' + CONVERT (varchar, mig.index_group_handle) + '_' + CONVERT (varchar, mid.index_handle) 
  + ' ON ' + mid.statement 
  + ' (' + ISNULL (mid.equality_columns,'') 
    + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END + ISNULL (mid.inequality_columns, '')
  + ')' 
  + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement, 
  migs.group_handle,
  migs.unique_compiles,
  migs.user_seeks,
  migs.user_scans,
  migs.last_user_seek,
  ISNULL(migs.last_user_scan,0) as last_user_scan,
  migs.avg_total_user_cost,
  migs.avg_user_impact,
  migs.system_seeks,
  migs.system_scans,
  ISNULL(migs.last_system_seek,0) as last_system_seek,
  migs.avg_total_system_cost,
  migs.avg_system_impact,
   mid.database_id, mid.[object_id]
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) > 10
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC

open cu_msgdet
fetch from cu_msgdet into 
		@msgindx_idxgroup_handle ,
		@msgindx_idx_handle ,
		@msgindx_improvement_measures,
		@msgindx_createidxstat,
		@msgindx_grphandle ,
		@msgindx_uniqcompiles,
		@msgindx_userseeks,
		@msgindx_usescans ,
		@msgindx_lastuserseek ,
		@msgindx_lastuserscan ,
		@msgindx_avgtotalusercost,
		@msgindx_avguserimpact ,
		@msgindx_systemseek ,
		@msgindx_systemscan ,
		@msgindx_lastsysseek ,
		@msgindx_avgtotalsyscost ,
		@msgindx_avgsysimpact ,
		@msgindx_databaseid ,
		@msgindx_objid



while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@msgindx_idxgroup_handle as varchar(100))+
	  '</td><td>'+cast(@msgindx_idx_handle as varchar(100))+
	  '</td><td>'+cast(@msgindx_improvement_measures as varchar(100))+
	  '</td><td>'+cast(@msgindx_createidxstat as varchar(5000))+
	  '</td><td>'+cast(@msgindx_grphandle as varchar(1000))+
	  '</td><td>'+cast(@msgindx_uniqcompiles as varchar(1000))+
	  '</td><td>'+cast(@msgindx_userseeks as varchar(40))+
	  '</td><td>'+cast(@msgindx_usescans as varchar(40))+
	   '</td><td>'+cast(@msgindx_lastuserseek as varchar(40))+
		'</td><td>'+cast(@msgindx_lastuserscan as varchar(40))+
		'</td><td>'+cast(@msgindx_avgtotalusercost as varchar(40))+
		'</td><td>'+cast(@msgindx_avguserimpact as varchar(40))+
		'</td><td>'+cast(@msgindx_systemseek as varchar(40))+
		'</td><td>'+cast(@msgindx_systemscan as varchar(40))+
		'</td><td>'+cast(@msgindx_lastsysseek as varchar(40))+
		'</td><td>'+cast(@msgindx_avgtotalsyscost as varchar(40))+
		'</td><td>'+cast(@msgindx_avgsysimpact as varchar(40))+
	  '</td><td>'+cast(@msgindx_databaseid as varchar(40))+
	  '</td><td>'+cast(@msgindx_objid as varchar(40))+'</td>'+'</tr>'
fetch from cu_msgdet into 
		@msgindx_idxgroup_handle ,
		@msgindx_idx_handle ,
		@msgindx_improvement_measures,
		@msgindx_createidxstat,
		@msgindx_grphandle ,
		@msgindx_uniqcompiles,
		@msgindx_userseeks,
		@msgindx_usescans ,
		@msgindx_lastuserseek ,
		@msgindx_lastuserscan ,
		@msgindx_avgtotalusercost,
		@msgindx_avguserimpact ,
		@msgindx_systemseek ,
		@msgindx_systemscan ,
		@msgindx_lastsysseek ,
		@msgindx_avgtotalsyscost ,
		@msgindx_avgsysimpact ,
		@msgindx_databaseid ,
		@msgindx_objid

end

close cu_msgdet
deallocate cu_msgdet
 print'</table><br/>'



 print'<br>
<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">SQL Server Missing Indexes by 
		Index Advantage:-</span><br class="auto-style1"></strong>--Above table 
		will give you a list of indexes that the query optimizer would have 
		liked to have had, based on the workload.We can see if there are any 
		tables that jump out with multiple missing indexes.<br>--You may also 
		want to look at the last_user_seek column to see when was the last time 
		the optimizer wanted an index. If it is several hours or days ago, it 
		may have been from an ad-hoc query of maintenance job rather than your 
		normal workload.</td>
	</tr>
</table>
<br/>'

 /*
 --Detecting blocking (a more accurate and complete version)
 */

 
 print N'<H3>SQL Server Detected Blocking on Instance:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Lock Type</strong></th>'+
'<th><strong>Database Name</strong></th>'+
'<th><strong>Blocked Object</strong></th>'+
'<th><strong>Lock Requested</strong></th>'+
'<th><strong>Waiter Spid</strong></th>'+
'<th><strong>Wait Time(in Microsecond)</strong></th>'+
'<th><strong>Waiter Batch</strong></th>'+
'<th><strong>Waiter Statement</strong></th>'+
'<th><strong>Blocker Sid</strong></th>'+
N'<th><strong>Blocker Statement</strong></th></tr>'



declare cur_sqlblcoking_detail_cur cursor for 
SELECT t1.resource_type AS 'lock type',db_name(resource_database_id) AS 'database',
t1.resource_associated_entity_id AS 'blk object',t1.request_mode AS 'lock req', --- lock requested
t1.request_session_id AS 'waiter sid', t2.wait_duration_ms AS 'wait time',
(SELECT [text] FROM sys.dm_exec_requests AS r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle)
WHERE r.session_id = t1.request_session_id) AS 'waiter_batch',
(SELECT substring(qt.text,r.statement_start_offset/2,
(CASE WHEN r.statement_end_offset = -1
THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2
ELSE r.statement_end_offset END - r.statement_start_offset)/2)
FROM sys.dm_exec_requests AS r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS qt
WHERE r.session_id = t1.request_session_id) AS 'waiter_stmt',
t2.blocking_session_id AS 'blocker sid',
(SELECT [text] FROM sys.sysprocesses AS p
CROSS APPLY sys.dm_exec_sql_text(p.sql_handle)
WHERE p.spid = t2.blocking_session_id) AS 'blocker_stmt'
FROM sys.dm_tran_locks AS t1
INNER JOIN sys.dm_os_waiting_tasks AS t2
ON t1.lock_owner_address = t2.resource_address;


open cur_sqlblcoking_detail_cur
fetch from cur_sqlblcoking_detail_cur into 
@blocking_lcktype ,
@blocking_dbname ,
@blocking_blockerobj ,
@blocking_lckreque ,
@blocking_waitersid ,
@blocking_waitime ,
@blocking_waitbatch ,
@blocking_waiterstmt ,
@blocking_blockersid ,
@blocking_blocker_stmt



while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@blocking_lcktype as varchar(100))+
	  '</td><td>'+cast(@blocking_dbname as varchar(40))+
	  '</td><td>'+cast(@blocking_blockerobj as varchar(100))+
	  '</td><td>'+cast(@blocking_lckreque as varchar(100))+
	  '</td><td>'+cast(@blocking_waitersid as varchar(10))+
	  '</td><td>'+cast(@blocking_waitime as varchar(100))+
	  '</td><td>'+cast(@blocking_waitbatch as varchar(200))+
	  '</td><td>'+cast(@blocking_waiterstmt as varchar(1000))+
	  '</td><td>'+cast(@blocking_blockersid as varchar(40))+
	  '</td><td>'+cast(@blocking_blocker_stmt as varchar(1000))+'</td>'+'</tr>'
fetch from cur_sqlblcoking_detail_cur into 
@blocking_lcktype ,
@blocking_dbname ,
@blocking_blockerobj ,
@blocking_lckreque ,
@blocking_waitersid ,
@blocking_waitime ,
@blocking_waitbatch ,
@blocking_waiterstmt ,
@blocking_blockersid ,
@blocking_blocker_stmt
end

close cur_sqlblcoking_detail_cur
deallocate cur_sqlblcoking_detail_cur

print'</table><br/>'



/*
Analyse the database size growth using backup history.
*/


 
 print N'<H3>SQL Server Database Growth in Last Six Month:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Database Name</strong></th>'+
'<th><strong>Year-Month</strong></th>'+
'<th><strong>MinSize in MB</strong></th>'+
'<th><strong>MaxSize in MB</strong></th>'+
'<th><strong>Average Size in MB</strong></th>'+
N'<th><strong>Growth in MB</strong></th></tr>'


set nocount on


SET @endDate = GetDate();  -- Include in the statistic all backups from today
SET @months = 6;           -- back to the last 6 months.
WITH HIST AS
   (SELECT BS.database_name AS DatabaseName
          ,YEAR(BS.backup_start_date) * 100
           + MONTH(BS.backup_start_date) AS YearMonth
          ,CONVERT(numeric(10, 1), MIN(BF.file_size / 1048576.0)) AS MinSizeMB
          ,CONVERT(numeric(10, 1), MAX(BF.file_size / 1048576.0)) AS MaxSizeMB
          ,CONVERT(numeric(10, 1), AVG(BF.file_size / 1048576.0)) AS AvgSizeMB
    FROM msdb.dbo.backupset as BS
         INNER JOIN
         msdb.dbo.backupfile AS BF
             ON BS.backup_set_id = BF.backup_set_id
    WHERE NOT BS.database_name IN
              ('master', 'msdb', 'model', 'tempdb')
          AND BF.file_type = 'D'
          AND BS.backup_start_date BETWEEN DATEADD(mm, - @months, @endDate) AND @endDate
    GROUP BY BS.database_name
            ,YEAR(BS.backup_start_date)
            ,MONTH(BS.backup_start_date))
SELECT MAIN.DatabaseName
      ,MAIN.YearMonth
      ,MAIN.MinSizeMB
      ,MAIN.MaxSizeMB
      ,MAIN.AvgSizeMB
      ,MAIN.AvgSizeMB 
       - (SELECT TOP 1 SUB.AvgSizeMB
          FROM HIST AS SUB
          WHERE SUB.DatabaseName = MAIN.DatabaseName
                AND SUB.YearMonth < MAIN.YearMonth
          ORDER BY SUB.YearMonth DESC) AS GrowthMB into #DBgrwothdata
FROM HIST AS MAIN
ORDER BY MAIN.DatabaseName
        ,MAIN.YearMonth 

--select * from #DBgrwothdata

declare cur_dbgrowth_info cursor for 
select
DatabaseName,
YearMonth,
MinSizeMB,
MaxSizeMB,
AvgSizeMB,
GrowthMB from #DBgrwothdata

open cur_dbgrowth_info

fetch from cur_dbgrowth_info into
@DBG_Dbname ,
@DBG_YearMon ,
@DBG_MinSizeMB ,
@DBG_MaxSizeMB ,
@DBG_AVGSizeMB ,
@DBG_GrowthMB 

while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@DBG_Dbname as varchar(100))+
	  '</td><td>'+cast(@DBG_YearMon as varchar(40))+
	  '</td><td>'+cast(@DBG_MinSizeMB as varchar(100))+
	  '</td><td>'+cast(@DBG_MaxSizeMB as varchar(100))+
	  '</td><td>'+cast(@DBG_AVGSizeMB as varchar(10))+
	  '</td><td>'+IsNull(cast(@DBG_GrowthMB as varchar(100)),'')+'</td>'+'</tr>'
fetch from cur_dbgrowth_info into
@DBG_Dbname ,
@DBG_YearMon ,
@DBG_MinSizeMB ,
@DBG_MaxSizeMB ,
@DBG_AVGSizeMB ,
@DBG_GrowthMB 
end
close cur_dbgrowth_info
deallocate cur_dbgrowth_info
set nocount on
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'#DBgrwothdata') AND type in (N'U'))
DROP TABLE #DBgrwothdata
print'</table><br/>'
print'
<br>
<table style="width: 100%">
	<tr>
		<td><span class="auto-style1"><strong>SQL Server Database Growth 
		Matrix:-</strong></span><br class="auto-style1">--Above table shows you 
		your user database growth based on hte backup of the database.<br>--This information is very handy when you planing for 
		capacity management.</td>
	</tr>
</table>

<br/>'



/*
Memory Configuration
*/
SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'
SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

/*
--Physical Memory Details on Server along with VAS.

*/


 print N'<H3>SQL Server Instance Memory Configuration:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Physical Mem in MB</strong></th>'+
'<th><strong>Physical Mem in GB</strong></th>'+
N'<th><strong>Virtual Mem MB</strong></th></tr>'

declare cur_phyvasmem_det cursor for 
SELECT physical_memory_in_bytes/1048576.0 as [Physical Memory_MB], physical_memory_in_bytes/1073741824.0 as [Physical Memory_GB], virtual_memory_in_bytes/1048576.0 as [Virtual Memory MB] FROM sys.dm_os_sys_info
open cur_phyvasmem_det
fetch from cur_phyvasmem_det into
@phymem_onsrvinmb ,
@phymem_onsrvingb ,
@phymem_onsrvVAS 


while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@phymem_onsrvinmb as varchar(100))+
	  '</td><td>'+cast(@phymem_onsrvingb as varchar(40))+
	  '</td><td>'+cast(@phymem_onsrvVAS as varchar(100))+'</td>'+'</tr>'
fetch from cur_phyvasmem_det into
@phymem_onsrvinmb ,
@phymem_onsrvingb ,
@phymem_onsrvVAS 
end
close cur_phyvasmem_det
deallocate cur_phyvasmem_det
print'</table><br/>'

print'<br>
<table style="width: 100%">
	<tr>
		<td><span class="auto-style1"><strong>SQL Server Instance Memory 
		Configuration:-</strong></span><br>--Above table will show you available 
		physical memory in MB on the server and virtual memory available on the 
		server.<br>--It is always good to have overview 
		of how much physical RAM your server have and virtual memory will be 
		always depend upon the 32-bit and 64-bit system.<br>-- For 32-bit system 
		Virtual address space (Virtual Memory) is limited to 2 GB (User Mode 
		Address space and 2 GB( Kernel Mode Address Space).<br>-- While with 
		64-bit system this limitation has been removed. you have almost 8TB 
		virtual address space in 64bit system.</td>
	</tr>
</table>
<br/>'
/*
----Buffer Pool Usage at the Moment

*/

print N'<H3>SQL Server Instance Buffer Pool Usage:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Buffer Pool Commited in MB</strong></th>'+
'<th><strong>Buffer Pool Target Commited GB</strong></th>'+
N'<th><strong>Buffer Pool Visible Memory MB</strong></th></tr>'

declare cur_bpoolmeminfo cursor for 
SELECT (bpool_committed*8)/1024.0 as BPool_Committed_MB, (bpool_commit_target*8)/1024.0 as BPool_Commit_Tgt_MB,(bpool_visible*8)/1024.0 as BPool_Visible_MB  FROM sys.dm_os_sys_info

open cur_bpoolmeminfo
fetch from cur_bpoolmeminfo into
@bpoolusg_commitedinmb,
@bpoolusg_commitedintargetmb ,
@bpoolusg_visibleinMB


while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@bpoolusg_commitedinmb as varchar(100))+
	  '</td><td>'+cast(@bpoolusg_commitedintargetmb as varchar(40))+
	  '</td><td>'+cast(@bpoolusg_visibleinMB as varchar(100))+'</td>'+'</tr>'

fetch from cur_bpoolmeminfo into
@bpoolusg_commitedinmb,
@bpoolusg_commitedintargetmb ,
@bpoolusg_visibleinMB
end
close cur_bpoolmeminfo
deallocate cur_bpoolmeminfo 
print'</table><br/>'
print'<br>
<table style="width: 100%">
	<tr>
		<td><span class="auto-style1"><strong>SQL Server Instace Buffer Pool 
		Usage:-</strong></span><br><strong>1.Bpool Commited Memory:-</strong>Number 
		of 8-KB buffers in the buffer pool. This amount represents committed 
		physical memory in the buffer pool. Does not include reserved memory in 
		the buffer pool<br><strong>2.Bpool Target Commited:-</strong>Number of 
		8-KB buffers needed by the buffer pool. The target amount is calculated 
		using a variety of inputs such as the current state of the system, 
		including its load, the memory requested by current processes, the 
		amount of memory installed on the computer, and configuration 
		parameters. If the bpool_commit_target is larger than the 
		bpool_committed value, the buffer pool will try to obtain additional 
		memory. If the bpool_commit_target is smaller than the bpool_committed 
		value, the buffer pool will shrink.<br><strong>3.Bpool Visible Memory:-</strong>Number 
		of 8-KB buffers in the buffer pool that are directly accessible in the 
		process virtual address space. When not using the Address Windowing 
		Extensions (AWE), when the buffer pool has obtained its memory target 
		(bpool_committed = bpool_commit_target), the value of bpool_visible 
		equals the value of bpool_committed.<br><br>When using AWE on a 32-bit 
		version of SQL Server, bpool_visible represents the size of the AWE 
		mapping window used to access physical memory allocated by the buffer 
		pool. The size of this mapping window is bound by the process address 
		space and, therefore, the visible amount will be smaller than the 
		committed amount, and can be further reduced by internal components 
		consuming memory for purposes other than database pages. If the value of 
		bpool_visible is too low, you might receive out of memory errors.</td>
	</tr>
</table>
<br/>'
/*
Total Memory Consumption by SQL Server from perfmon
*/
print N'<H3>SQL Server Total Memory Consumption:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Memory in KB</strong></th>'+
'<th><strong>Memory in MB</strong></th>'+
N'<th><strong>Memory in GB</strong></th></tr>'

declare cur_sqlmeminfoperf cursor for
SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM sys.dm_os_performance_counters WHERE counter_name = 'Total Server Memory (KB)'
open cur_sqlmeminfoperf
fetch from cur_sqlmeminfoperf into
@totalmemsql_usageinkb,
@totalmemsql_usageinMB,
@totalmemsql_usageinGB

while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@totalmemsql_usageinkb as varchar(100))+
	  '</td><td>'+cast(@totalmemsql_usageinMB as varchar(40))+
	  '</td><td>'+cast(@totalmemsql_usageinGB as varchar(100))+'</td>'+'</tr>'
fetch from cur_sqlmeminfoperf into
@totalmemsql_usageinkb,
@totalmemsql_usageinMB,
@totalmemsql_usageinGB
end
close cur_sqlmeminfoperf
deallocate cur_sqlmeminfoperf
print'</table><br/>'
print '<br>
<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">SQL Server Total Memory 
		Consumption:-</span><br class="auto-style1"></strong>Specifies the 
		amount of memory the server has committed using the memory manage how 
		much memory the cache (buffer cache) is using, which is what you control 
		when you specify max server memory.<br>Note:- This value is only mention 
		for the Buffer cache component of SQL Server memory no other components 
		has been mentioned here so far since this you can control it through Max 
		Server memory setting</td>
	</tr>
</table>
<br/>'
/*
Memory Needed for current workload for SQL Server instance
*/
print N'<H3>Memory Needed by SQL Server Instance:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Memory in KB</strong></th>'+
'<th><strong>Memory in MB</strong></th>'+
N'<th><strong>Memory in GB</strong></th></tr>'

declare cur_memneed_sql cursor for 
SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM sys.dm_os_performance_counters WHERE counter_name = 'Target Server Memory (KB)'

open cur_memneed_sql
fetch from cur_memneed_sql into 
@memneed_curwl_meminkb,
@memneed_curwl_meminmb,
@memneed_curwl_meminGB
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@memneed_curwl_meminkb as varchar(100))+
	  '</td><td>'+cast(@memneed_curwl_meminmb as varchar(40))+
	  '</td><td>'+cast(@memneed_curwl_meminGB as varchar(100))+'</td>'+'</tr>'
fetch from cur_memneed_sql into 
@memneed_curwl_meminkb,
@memneed_curwl_meminmb,
@memneed_curwl_meminGB
end
close cur_memneed_sql
deallocate cur_memneed_sql 
print'</table><br/>'
print '<br>
<table style="width: 100%">
	<tr>
		<td>Memory Needed By SQL Server Instance:-<br>--Above table shows value 
		for Max Server memory Setting we have put for SQL Server and in use.</td>
	</tr>
</table>
<br/>'

/*
Dynamic Memory usage by SQL Server Connections
*/
print N'<H3>Dynamic Memory Usage for SQL Server Connections:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Memory in KB</strong></th>'+
'<th><strong>Memory in MB</strong></th>'+
N'<th><strong>Memory in GB</strong></th></tr>'
SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'
SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

declare cur_sqlconn_memusg cursor for 
	SELECT cntr_value as Mem_KB, 
	cntr_value/1024.0 as Mem_MB,
	 (cntr_value/1048576.0) as Mem_GB 
	 FROM sys.dm_os_performance_counters WHERE counter_name = 'Connection Memory (KB)'
open cur_sqlconn_memusg
fetch from cur_sqlconn_memusg into 
@memcon_usageinkb ,
@memcon_usageinmb ,
@memcon_usageingb 
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@memcon_usageinkb as varchar(100))+
	  '</td><td>'+cast(@memcon_usageinmb as varchar(100))+
	  '</td><td>'+cast(@memcon_usageingb as varchar(100))+'</td>'+'</tr>'
fetch from cur_sqlconn_memusg into 
@memcon_usageinkb ,
@memcon_usageinmb ,
@memcon_usageingb 
end
close cur_sqlconn_memusg
deallocate cur_sqlconn_memusg
print'</table><br/>'
print '<br>
<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">Dynamic Memory Usage for SQL 
		Server Connection:-</span><br class="auto-style1"></strong>--Specifies 
		the total amount of dynamic memory the server is using for maintaining 
		connections.</td>
	</tr>
</table>'
/*
Total Amount of Memory Usage for SQL Server Locks
*/
print N'<H3>Dynamic Memory Usage for SQL Server Locks:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Memory in KB</strong></th>'+
'<th><strong>Memory in MB</strong></th>'+
N'<th><strong>Memory in GB</strong></th></tr>'
SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'
SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

declare cur_locksmem_usg cursor for 
SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM sys.dm_os_performance_counters WHERE counter_name = 'Lock Memory (KB)'

open cur_locksmem_usg
fetch from cur_locksmem_usg into
@memlock_useinkb ,
@memlock_useinMb ,
@memlock_useinGb 
 
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@memlock_useinkb as varchar(100))+
	  '</td><td>'+cast(@memlock_useinMb as varchar(40))+
	  '</td><td>'+cast(@memlock_useinGb as varchar(100))+'</td>'+'</tr>'
fetch from cur_locksmem_usg into
@memlock_useinkb ,
@memlock_useinMb ,
@memlock_useinGb 
 end
 close cur_locksmem_usg
 deallocate cur_locksmem_usg
 print'</table><br/>'
 print '<br>
<table style="width: 100%">
	<tr>
		<td><span class="auto-style1"><strong>Dynamic Memory Usage for SQL 
		Server Locks:-</strong></span><br>--Specifies the total amount of 
		dynamic memory the server is using for locks.</td>
	</tr>
</table>
<br/>'


/*
Total Amount of Memory Usage for Dynamic SQL Server Cache
*/
print N'<H3>Dynamic Memory Usage for SQL Server Cache:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Memory in KB</strong></th>'+
'<th><strong>Memory in MB</strong></th>'+
N'<th><strong>Memory in GB</strong></th></tr>'
SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'
SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

declare cur_sqlmemcache_info cursor for 
SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM sys.dm_os_performance_counters WHERE counter_name = 'SQL Cache Memory (KB)'

open cur_sqlmemcache_info
fetch from cur_sqlmemcache_info into
@dynsqlcache_useinkb ,
@dynsqlcache_useinMb ,
@dynsqlcache_useinGb 

while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@dynsqlcache_useinkb as varchar(100))+
	  '</td><td>'+cast(@dynsqlcache_useinMb as varchar(40))+
	  '</td><td>'+cast(@dynsqlcache_useinGb as varchar(100))+'</td>'+'</tr>'
fetch from cur_sqlmemcache_info into
@dynsqlcache_useinkb ,
@dynsqlcache_useinMb ,
@dynsqlcache_useinGb 
end
close cur_sqlmemcache_info
deallocate cur_sqlmemcache_info
print'</table><br/>'
print '<br>
<table style="width: 100%">
	<tr>
		<td>Dynamic Memory SQL Server Cache:-<br>--Specifies the total amount of 
		dynamic memory the server is using for the dynamic SQL cache.</td>
	</tr>
</table>
<br/>'

/*
Dynamic Memory Utilization by Query Optimization
*/
print N'<H3>Dynamic Memory Usage for SQL Server Query Optimization:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Memory in KB</strong></th>'+
'<th><strong>Memory in MB</strong></th>'+
N'<th><strong>Memory in GB</strong></th></tr>'

SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'
SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

declare cur_quryopti_info cursor for 
SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM sys.dm_os_performance_counters WHERE counter_name = 'Optimizer Memory (KB) '
open cur_quryopti_info
fetch from cur_quryopti_info into 
@qryopt_useinkb,
@qryopt_useinMb ,
@qryopt_useinGb 
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@qryopt_useinkb as varchar(100))+
	  '</td><td>'+cast(@qryopt_useinMb as varchar(40))+
	  '</td><td>'+cast(@qryopt_useinGb as varchar(100))+'</td>'+'</tr>'
fetch from cur_quryopti_info into 
@qryopt_useinkb,
@qryopt_useinMb ,
@qryopt_useinGb 
end
close cur_quryopti_info
deallocate cur_quryopti_info
print'</table><br/>'
print '<br>
<table style="width: 100%">
	<tr>
		<td><strong>Memory Usage for SQL Server Query Optimization:-<br>--Specifies 
		the total amount of dynamic memory the server is using for query 
		optimization.</td>
	</tr>
</table>
<br/>'
/*
Memory Usage by Hash Sort Index Creation Operation
*/
print N'<H3>Dynamic Memory Usage for Hash sort Index Creation:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Memory in KB</strong></th>'+
'<th><strong>Memory in MB</strong></th>'+
N'<th><strong>Memory in GB</strong></th></tr>'

SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'
SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

declare cur_idexsort_memusg cursor for
SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM sys.dm_os_performance_counters WHERE counter_name = 'Granted Workspace Memory (KB) '

open cur_idexsort_memusg
fetch from cur_idexsort_memusg into 
@idexsort_userinkb,
@idexsort_userinMb,
@idexsort_userinGb
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@idexsort_userinkb as varchar(100))+
	  '</td><td>'+cast(@idexsort_userinMb as varchar(40))+
	  '</td><td>'+cast(@idexsort_userinGb as varchar(100))+'</td>'+'</tr>'
fetch from cur_idexsort_memusg into 
@idexsort_userinkb,
@idexsort_userinMb,
@idexsort_userinGb
end
close cur_idexsort_memusg
deallocate cur_idexsort_memusg
print'</table><br/>'
print'<br>
<table style="width: 100%">
	<tr>
		<td><span class="auto-style1"><strong>SQL Server memory usage for Hash 
		Sort and Index Creation:-</strong></span><br>--Specifies the total 
		amount of memory currently granted to executing processes, such as hash, 
		sort, bulk copy, and index creation operations.ons.</td>
	</tr>
</table>
<br/>'
/*
Dynamic memory consumed by Cursor
*/
print N'<H3>Dynamic Memory Usage by SQL Cursors:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Memory in KB</strong></th>'+
'<th><strong>Memory in MB</strong></th>'+
N'<th><strong>Memory in GB</strong></th></tr>'

SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'
SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

declare cur_curmemusginfo cursor for 
SELECT cntr_value as Mem_KB, cntr_value/1024.0 as Mem_MB, (cntr_value/1048576.0) as Mem_GB FROM sys.dm_os_performance_counters WHERE counter_name = 'Cursor memory usage' and instance_name = '_Total'

open cur_curmemusginfo
fetch from cur_curmemusginfo into 
@curmem_useinkb ,
@curmem_useinMb ,
@curmem_useinGb 
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@curmem_useinkb as varchar(100))+
	  '</td><td>'+cast(@curmem_useinMb as varchar(40))+
	  '</td><td>'+cast(@curmem_useinGb as varchar(100))+'</td>'+'</tr>'
fetch from cur_curmemusginfo into 
@curmem_useinkb ,
@curmem_useinMb ,
@curmem_useinGb 
end
close cur_curmemusginfo
deallocate cur_curmemusginfo
print'</table><br/>'
print '<br>
<table style="width: 100%">
	<tr>
		<td>SQL Server Memory Usage by SQL Cursors:-<br>--Memory utilize by SQL 
		Server cursor.</td>
	</tr>
</table>
<br/>'
/*
Number of Pages Consumed in buffer pool includes(free,database,stolen)
*/
print N'<H3>Bufferpool Pages(Includes Free,Datapage,Stolen):-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>No of 8KB Pages</strong></th>'+
'<th><strong>Pages in KB</strong></th>'+
N'<th><strong>Pages in MB</strong></th></tr>'

SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'
SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

declare cur_buffpoolpage_info cursor for 
SELECT cntr_value as [8KB_Pages], (cntr_value*@pg_size)/1024.0 as Pages_in_KB, (cntr_value*@pg_size)/1048576.0 as Pages_in_MB FROM sys.dm_os_performance_counters WHERE object_name= @Instancename+'Buffer Manager' and counter_name = 'Total pages' 

open cur_buffpoolpage_info
fetch from cur_buffpoolpage_info into
@bpool_page_8kbno,
@bpool_pages_inkb,
@bpool_pages_inmb
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@bpool_page_8kbno as varchar(100))+
	  '</td><td>'+cast(@bpool_pages_inkb as varchar(40))+
	  '</td><td>'+cast(@bpool_pages_inmb as varchar(100))+'</td>'+'</tr>'
fetch from cur_buffpoolpage_info into
@bpool_page_8kbno,
@bpool_pages_inkb,
@bpool_pages_inmb
end
close cur_buffpoolpage_info
deallocate cur_buffpoolpage_info
print'</table><br/>'
print '<br>
<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">Buffer Pool Usage:-</span><br class="auto-style1">
		</strong>--Total Number of pages that are included in the buffer pool it 
		includes Data pages Free pages and Stolen pages.</td>
	</tr>
</table>
<br/>'
/*
Total Number of Data Pages in Buffer Pool
*/
print N'<H3>Bufferpool Pages Total Number of DataPages:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>No of 8KB Pages</strong></th>'+
'<th><strong>Pages in KB</strong></th>'+
N'<th><strong>Pages in MB</strong></th></tr>'

SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'
SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

declare cur_bpooldbpage_info cursor for 
SELECT cntr_value as [8KB_Pages], (cntr_value*@pg_size)/1024.0 as Pages_in_KB, (cntr_value*@pg_size)/1048576.0 as Pages_in_MB FROM sys.dm_os_performance_counters WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Database pages' 

open cur_bpooldbpage_info
fetch from cur_bpooldbpage_info into
@dbpagebpool_page_8kbno,
@dbpagebpool_page_inkb ,
@dbpagebpool_page_inmb 
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@dbpagebpool_page_8kbno as varchar(100))+
	  '</td><td>'+cast(@dbpagebpool_page_inkb as varchar(40))+
	  '</td><td>'+cast(@dbpagebpool_page_inmb as varchar(100))+'</td>'+'</tr>'
fetch from cur_bpooldbpage_info into
@dbpagebpool_page_8kbno,
@dbpagebpool_page_inkb ,
@dbpagebpool_page_inmb
end
close cur_bpooldbpage_info
deallocate cur_bpooldbpage_info
print'</table><br/>'
print'<br>
<table style="width: 100%">
	<tr>
		<td><strong>Bpool Number of Data Pages:-<br></strong>--Number of pages 
		in the buffer pool with database content.</td>
	</tr>
</table>
<br/>'

/*
Total Number of Free Pages in Buffer Pool
*/
print N'<H3>Bufferpool Pages Total Number of FreePages:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>No of 8KB Pages</strong></th>'+
'<th><strong>Pages in KB</strong></th>'+
N'<th><strong>Pages in MB</strong></th></tr>'

SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'
SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

declare cur_bpoolfreepage_info cursor for
SELECT cntr_value as [8KB_Pages], (cntr_value*@pg_size)/1024.0 as Pages_in_KB, (cntr_value*@pg_size)/1048576.0 as Pages_in_MB FROM sys.dm_os_performance_counters WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Free pages'

open cur_bpoolfreepage_info 
fetch from cur_bpoolfreepage_info into
@freepagebpool_page_8kbno, 
@freepagebpool_page_inkb,
@freepagebpool_page_inmb
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@freepagebpool_page_8kbno as varchar(100))+
	  '</td><td>'+cast(@freepagebpool_page_inkb as varchar(40))+
	  '</td><td>'+cast(@freepagebpool_page_inmb as varchar(100))+'</td>'+'</tr>'
fetch from cur_bpoolfreepage_info into
@freepagebpool_page_8kbno, 
@freepagebpool_page_inkb,
@freepagebpool_page_inmb
end
close cur_bpoolfreepage_info
deallocate cur_bpoolfreepage_info
print'</table><br/>'
print '<br>
<table style="width: 100%">
	<tr>
		<td><span class="auto-style1"><strong>Bpool Total Number of Free Pages:-</strong></span><br>
		--Number of requests per second that had to wait for a free page.Total 
		number of pages on all free lists.</td>
	</tr>
</table>
<br/>'
/*
--Number of reserved pages in the buffer pool
*/
print N'<H3>Bufferpool Pages Total Number of Reserved Pages:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>No of 8KB Pages</strong></th>'+
'<th><strong>Pages in KB</strong></th>'+
N'<th><strong>Pages in MB</strong></th></tr>'

SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'
SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

declare cur_bpoolresvpage_info cursor for 
SELECT cntr_value as [8KB_Pages], (cntr_value*@pg_size)/1024.0 as Pages_in_KB, (cntr_value*@pg_size)/1048576.0 as Pages_in_MB FROM sys.dm_os_performance_counters WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Reserved pages'
open cur_bpoolresvpage_info
fetch from cur_bpoolresvpage_info into 
@respagebpool_page_8kbno ,
@respagebpool_page_inkb ,
@respagebpool_page_inmb
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@respagebpool_page_8kbno as varchar(100))+
	  '</td><td>'+cast(@respagebpool_page_inkb as varchar(40))+
	  '</td><td>'+cast(@respagebpool_page_inmb as varchar(100))+'</td>'+'</tr>'
fetch from cur_bpoolresvpage_info into 
@respagebpool_page_8kbno ,
@respagebpool_page_inkb ,
@respagebpool_page_inmb
end
close cur_bpoolresvpage_info
deallocate cur_bpoolresvpage_info
print'</table><br/>'
print '<br>
<table style="width: 100%">
	<tr>
		<td>Bpool Total Number of Reserved Pages:-<br>--Number of buffer pool 
		reserved pages.</td>
	</tr>
</table>
<br/>
'
/*
Number of stolen pages in Bpool
*/
print N'<H3>Bufferpool Pages Total Number of Stolen Pages:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>No of 8KB Pages</strong></th>'+
'<th><strong>Pages in KB</strong></th>'+
N'<th><strong>Pages in MB</strong></th></tr>'

SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'
SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

declare cur_bpoolstolenpage_info cursor for 
SELECT cntr_value as [8KB_Pages], (cntr_value*@pg_size)/1024.0 as Pages_in_KB, (cntr_value*@pg_size)/1048576.0 as Pages_in_MB FROM sys.dm_os_performance_counters WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Stolen pages'

open cur_bpoolstolenpage_info
fetch  from cur_bpoolstolenpage_info into
@stolenpbpool_page_8kbno ,
@stolenpbpool_page_inkb ,
@stolenpbpool_page_inmb 
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@stolenpbpool_page_8kbno as varchar(100))+
	  '</td><td>'+cast(@stolenpbpool_page_inkb as varchar(40))+
	  '</td><td>'+cast(@stolenpbpool_page_inmb as varchar(100))+'</td>'+'</tr>'
fetch  from cur_bpoolstolenpage_info into
@stolenpbpool_page_8kbno ,
@stolenpbpool_page_inkb ,
@stolenpbpool_page_inmb 

end
close cur_bpoolstolenpage_info
deallocate cur_bpoolstolenpage_info
print'</table><br/>'
print'<br>
<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">Bpool Total number of Stolen 
		Pages:-</span><br class="auto-style1"></strong>The size of SQL Server 
		database page is 8KB. Buffer Pool is a cache of data pages. Consequently 
		Buffer Pool operates on pages of 8KB in size. It commits and decommits 
		memory blocks of 8KB granularity only. If external components decide to 
		borrow memory out of Buffer Pool they can only get blocks of 8KB in 
		size. These blocks are not continues in memeory. Interesting, right? It 
		means that Buffer Pool can be used as underneath memory manager forSQL 
		Server components as long as they allocate buffers of 8KB. (Sometimes 
		pages allocated from BP are referred as stolen)<br></td>
	</tr>
</table>
<br/>'
/*
Number plan cache pages in Buffer pool
*/
print N'<H3>Bufferpool Pages Total Number of Plan Cache Pages:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>No of 8KB Pages</strong></th>'+
'<th><strong>Pages in KB</strong></th>'+
N'<th><strong>Pages in MB</strong></th></tr>'

SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'
SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'

declare cur_bpoolplancache_info cursor for 
SELECT cntr_value as [8KB_Pages], (cntr_value*@pg_size)/1024.0 as Pages_in_KB, (cntr_value*@pg_size)/1048576.0 as Pages_in_MB FROM sys.dm_os_performance_counters WHERE object_name=@Instancename+'Plan Cache' and counter_name = 'Cache Pages'  and instance_name = '_Total'

open cur_bpoolplancache_info
fetch from cur_bpoolplancache_info into
@plancachebpool_page_8kbno ,
@plancachebpool_page_inkb ,
@plancachebpool_page_inmb 
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@plancachebpool_page_8kbno as varchar(100))+
	  '</td><td>'+cast(@plancachebpool_page_inkb as varchar(40))+
	  '</td><td>'+cast(@plancachebpool_page_inmb as varchar(100))+'</td>'+'</tr>'
fetch from cur_bpoolplancache_info into
@plancachebpool_page_8kbno ,
@plancachebpool_page_inkb ,
@plancachebpool_page_inmb 
end
close cur_bpoolplancache_info
deallocate cur_bpoolplancache_info
print'</table><br/>'
print'<br>
<table style="width: 100%">
	<tr>
		<td><span class="auto-style1"><strong>Bpool plan cache pages:-</strong></span><br>
		--This metric counts the number of 8-kilobyte (KB) pages used by plan 
		cache objects, which indicates the plan cache size of an instance. This 
		counter is very similar to the SQL Server: memory manager: SQL cache 
		memory, but instead of providing the number of 8-kilobyte pages that 
		make up the plan cache, it provides the total amount of memory, in 
		kilobytes, used by the plan cache.</td>
	</tr>
</table>
<br/>'
/*
--SQL Server Binary Module Information 

*/

print N'<H3>SQL Server Binary Module Informatio:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Name and Path of File</strong></th>'+
'<th><strong>File Version</strong></th>'+
'<th><strong>Product Version</strong></th>'+
'<th><strong>Description of Module</strong></th>'+
N'<th><strong>Module Size KB</strong></th></tr>'

declare cur_sqlbinmodule_info cursor for 
SELECT olm.[name], olm.[file_version], olm.[product_version], olm.[description], SUM(ova.[region_size_in_bytes])/1024 [Module Size in KB]
FROM sys.dm_os_virtual_address_dump ova 
INNER JOIN sys.dm_os_loaded_modules olm ON olm.base_address = ova.region_allocation_base_address
GROUP BY olm.[name],olm.[file_version], olm.[product_version], olm.[description],olm.[base_address]
ORDER BY [Module Size in KB] DESC 

open cur_sqlbinmodule_info
fetch from cur_sqlbinmodule_info into 
@DllFilePath,
@FileVer,
@Productver,
@Bin_Descrip,
@Modulesize_inkb
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@DllFilePath as varchar(2000))+
	  '</td><td>'+cast(@FileVer as varchar(400))+
	  '</td><td>'+cast(@Productver as varchar(400))+
	  '</td><td>'+cast(@Bin_Descrip as varchar(5000))+
	  '</td><td>'+cast(@Modulesize_inkb as varchar(100))+'</td>'+'</tr>'
fetch from cur_sqlbinmodule_info into 
@DllFilePath,
@FileVer,
@Productver,
@Bin_Descrip,
@Modulesize_inkb
end
close cur_sqlbinmodule_info
deallocate cur_sqlbinmodule_info
print'</table><br/>'
print'<br>
<table style="width: 100%">
	<tr>
		<td><strong><span class="auto-style1">SQL Server Binary Information:-</span><br class="auto-style1">
		--</strong>The above table contains information about SQL Server binary 
		information loaded inside in SQL Server OS.</td>
	</tr>
</table>
<br/>'

/*
Version Store Information
*/

print N'<H3>SQL Server Version Store Informatio:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Version Store Pages Used</strong></th>'+
N'<th><strong>Version stored space in MB</strong></th></tr>'

declare cur_versionstoreinfo cursor for 
SELECT SUM(version_store_reserved_page_count) AS [version store pages used],
(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]FROM sys.dm_db_file_space_usage

open  cur_versionstoreinfo
fetch from cur_versionstoreinfo into
@verstorepage_used,
@verstorepage_spaceinMB
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@verstorepage_used as varchar(200))+
	  '</td><td>'+cast(@verstorepage_spaceinMB as varchar(100))+'</td>'+'</tr>'
fetch from cur_versionstoreinfo into
@verstorepage_used,
@verstorepage_spaceinMB
end
close cur_versionstoreinfo
deallocate cur_versionstoreinfo
print'</table><br/>'
print'<br>
<table style="width: 100%">
	<tr>
		<td>SQL Server Version Store Information:-<br>-- Version store is 
		feature available in SQL Server with Snap shot isolation level.But it 
		has contention on the TEMPDB.<br>-- We have to check if any database is 
		having snapshot isolation level on.</td>
	</tr>
</table>
<br/>'
/*
TempDB pages information for the storaage 
*/

print N'<H3>SQL Server Version Store Informatio:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>User Object Pages MB</strong></th>'+
N'<th><strong>Internal Object Pages MB</strong></th>'+
N'<th><strong>Version Store Pages MB</strong></th>'+
N'<th><strong>Total in Use Pages MB</strong></th>'+
N'<th><strong>Total Free Pages MB</strong></th></tr>'

Declare cur_tempdbfileusg_info cursor for 
SELECT (SUM(user_object_reserved_page_count)*8)/1024 AS user_object_pages_mb,
(SUM(internal_object_reserved_page_count)*8)/1024 AS internal_object_pages_mb,
(SUM(version_store_reserved_page_count)*8)/1024 AS version_store_pages_mb,
total_in_use_pages_mb = (SUM(user_object_reserved_page_count)+ SUM(internal_object_reserved_page_count)+ SUM(version_store_reserved_page_count)*8)/1024,
(SUM(unallocated_extent_page_count)*8)/1024 AS total_free_pages_mb
FROM sys.dm_db_file_space_usage ;

open cur_tempdbfileusg_info 
fetch from cur_tempdbfileusg_info into
@tempdb_user_obj_pages_inMB,
@tempdb_internal_obj_pages_inMB,
@tempdb_versionstore_obj_pages_inMB,
@tempdb_total_pages_use_inMB ,
@tempdb_total_pages_free_inMB
while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@tempdb_user_obj_pages_inMB as varchar(20))+
	  '</td><td>'+cast(@tempdb_internal_obj_pages_inMB as varchar(20))+
	  '</td><td>'+cast(@tempdb_versionstore_obj_pages_inMB as varchar(50))+
	 '</td><td>'+cast(@tempdb_total_pages_use_inMB as varchar(50))+
	  '</td><td>'+cast(@tempdb_total_pages_free_inMB as varchar(50))+'</td>'+'</tr>'
fetch from cur_tempdbfileusg_info into
@tempdb_user_obj_pages_inMB,
@tempdb_internal_obj_pages_inMB,
@tempdb_versionstore_obj_pages_inMB,
@tempdb_total_pages_use_inMB ,
@tempdb_total_pages_free_inMB 
end

close cur_tempdbfileusg_info
deallocate cur_tempdbfileusg_info
print'</table><br/>'


/*
TempDb usage by session
*/
print N'<H3>SQL Server Tempdb Usaage by Session:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Session ID</strong></th>'+
N'<th><strong>Request ID</strong></th>'+
N'<th><strong>Execution Context ID</strong></th>'+
N'<th><strong>Database ID</strong></th>'+
N'<th><strong>User Object Page Allocation Count</strong></th>'+
N'<th><strong>User Object Page Deallocation Count</strong></th>'+
N'<th><strong>Internal Object Page Allocation Count</strong></th>'+
N'<th><strong>Internal Object Page Deallocation Count</strong></th></tr>'

declare cur_tempdbsessinfo_usg cursor for 
SELECT TOP 10
*
FROM sys.dm_db_task_space_usage
WHERE session_id > 50
ORDER BY user_objects_alloc_page_count + internal_objects_alloc_page_count DESC ;

open cur_tempdbsessinfo_usg
fetch from cur_tempdbsessinfo_usg into
@tempdbsession_sid,
@tempdbsession_requ_sid,
@tempdbsession_execontext_sid,
@tempdbsession_dbid ,
@tempdbsession_usrobjallocpage_count,
@tempdbsession_usrobjdeallocpage_count,
@tempdbsession_internalallocpage_count,
@tempdbsession_internaldeallocpage_count

while @@FETCH_STATUS>=0
 begin
print '<tr><td>'+cast(@tempdbsession_sid as varchar(20))+
	  '</td><td>'+cast(@tempdbsession_requ_sid as varchar(20))+
	  '</td><td>'+cast(@tempdbsession_execontext_sid as varchar(20))+
	'</td><td>'+cast(@tempdbsession_dbid as varchar(20))+
	'</td><td>'+cast(@tempdbsession_usrobjallocpage_count as varchar(20))+
	 '</td><td>'+cast(@tempdbsession_usrobjdeallocpage_count as varchar(50))+
	 '</td><td>'+cast(@tempdbsession_internalallocpage_count as varchar(50))+
	  '</td><td>'+cast(@tempdbsession_internaldeallocpage_count as varchar(50))+'</td>'+'</tr>'
fetch from cur_tempdbsessinfo_usg into
@tempdbsession_sid,
@tempdbsession_requ_sid,
@tempdbsession_execontext_sid,
@tempdbsession_dbid ,
@tempdbsession_usrobjallocpage_count,
@tempdbsession_usrobjdeallocpage_count,
@tempdbsession_internalallocpage_count,
@tempdbsession_internaldeallocpage_count
end

close cur_tempdbsessinfo_usg
deallocate cur_tempdbsessinfo_usg
print'</table><br/>'

/*
Top 10 Session in SQL by what they are doing

*/

print N'<H3>SQL Server Top Sessions:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Session ID</strong></th>'+
N'<th><strong>Login Time</strong></th>'+
N'<th><strong>Host Name</strong></th>'+
N'<th><strong>Program Name</strong></th>'+
N'<th><strong>CPU Time</strong></th>'+
N'<th><strong>Memory Usage in KB</strong></th>'+
N'<th><strong>Total Scheduled Time in MS</strong></th>'+
N'<th><strong>Total Elapsed Time in MS</strong></th>'+
N'<th><strong>Last Request End Time</strong></th>'+
N'<th><strong>Number of Reads</strong></th>'+
N'<th><strong>Number of Writes</strong></th>'+
N'<th><strong>Number of Connection Count</strong></th></tr>'

declare cur_topsess_activity cursor for 

select top 10 s.session_id
, s.login_time
, s.host_name
, s.program_name
, s.cpu_time as cpu_time
, s.memory_usage * 8 as memory_usage_in_KB
, s.total_scheduled_time as total_scheduled_time
, s.total_elapsed_time as total_elapsed_time
, s.last_request_end_time
, s.reads
, s.writes
, count(c.connection_id) as conn_count
from sys.dm_exec_sessions s
left outer join sys.dm_exec_connections c on ( s.session_id = c.session_id )
left outer join sys.dm_exec_requests r on ( r.session_id = c.session_id )
where (s.is_user_process= 1)
group by s.session_id, s.login_time, s.host_name, s.cpu_time, s.memory_usage,
s.total_scheduled_time, s.total_elapsed_time, s.last_request_end_time, s.reads,
s.writes, s.program_name
order by s.memory_usage desc

open cur_topsess_activity
fetch from cur_topsess_activity into 
@sessionact_sid ,
@sessionact_logintime ,
@sessionact_hostname,
@sessionact_programname,
@sessionact_cputime ,
@sessionact_memusginkb ,
@sessionact_totalschetime ,
@sessionact_totalelsapsedtime ,
@sessionact_lastrequestendtime ,
@sessionact_reads,
@sessionact_write ,
@sessionact_conncount

while @@FETCH_STATUS>=0
 begin
print	    '<tr><td>'+cast(@sessionact_sid as varchar(20))+
		    '</td><td>'+cast(@sessionact_logintime as varchar(1000))+
		    '</td><td>'+cast(@sessionact_hostname as varchar(50))+
			'</td><td>'+cast(@sessionact_programname as varchar(520))+
			'</td><td>'+cast(@sessionact_cputime as varchar(20))+
			 '</td><td>'+cast(@sessionact_memusginkb as varchar(50))+
			 '</td><td>'+cast(@sessionact_totalschetime as varchar(50))+
 			 '</td><td>'+cast(@sessionact_totalelsapsedtime as varchar(50))+
			 '</td><td>'+cast(@sessionact_lastrequestendtime as varchar(50))+
			 '</td><td>'+cast(@sessionact_reads as varchar(50))+
			 '</td><td>'+cast(@sessionact_write as varchar(50))+
			 '</td><td>'+cast(@sessionact_conncount as varchar(50))+'</td>'+'</tr>'


fetch from cur_topsess_activity into 
@sessionact_sid ,
@sessionact_logintime ,
@sessionact_hostname,
@sessionact_programname,
@sessionact_cputime ,
@sessionact_memusginkb ,
@sessionact_totalschetime ,
@sessionact_totalelsapsedtime ,
@sessionact_lastrequestendtime ,
@sessionact_reads,
@sessionact_write ,
@sessionact_conncount
end

close cur_topsess_activity
deallocate cur_topsess_activity
print'</table><br/>'

print N'<H3>SQL Server Top Activity:-</H3>'
print N'<table cellspacing="1" cellpadding="1" border="1">'+
N'<tr><th><strong>Session ID</strong></th>'+
N'<th><strong>Last Worker Time</strong></th>'+
N'<th><strong>Last Physical Read</strong></th>'+
N'<th><strong>Total Physical Read</strong></th>'+
N'<th><strong>Total Logical Read</strong></th>'+
N'<th><strong>Last Logical Read</strong></th>'+
N'<th><strong>Current Wait Type</strong></th>'+
N'<th><strong>Last Wait Type</strong></th>'+
N'<th><strong>Wait Resource Type</strong></th>'+
N'<th><strong>Wait Time</strong></th>'+
N'<th><strong>Open Transaction Count</strong></th>'+
N'<th><strong>Row Count</strong></th>'+
N'<th><strong>Grant Memory in kB</strong></th>'+
N'<th><strong>SQL Text</strong></th>'+'</tr>'

declare cur_sqlact_info cursor 
for
SELECT
Rqst.session_id as SPID,
Qstat.last_worker_time,
Qstat.last_physical_reads,
Qstat.total_physical_reads,
Qstat.total_logical_writes,
Qstat.last_logical_reads,
Rqst.wait_type as CurrentWait,
Rqst.last_wait_type,
Rqst.wait_resource,
Rqst.wait_time,
Rqst.open_transaction_count,
Rqst.row_count,
Rqst.granted_query_memory,
tSQLCall.text as SqlText
FROM sys.dm_exec_query_stats Qstat
JOIN sys.dm_exec_requests Rqst ON
Qstat.plan_handle = Rqst.plan_handle AND Qstat.sql_handle = Rqst.sql_handle
CROSS APPLY sys.dm_exec_sql_text (Rqst.sql_handle) tSQLCall

open cur_sqlact_info
fetch from cur_sqlact_info into 
@otran_spid,
@otran_lasworkertime ,
@otran_lastphysicalread ,
@otran_totalphysicalread ,
@otran_totallogicalwrites,
@otran_lastlogicalreads ,
@otran_currentwait ,
@otran_lastwaittype,
@otran_watiresource,
@otran_waittime ,
@otran_opentrancount ,
@otran_rowcount ,
@otran_granterqmem ,
@otran_sqltect

while @@FETCH_STATUS>=0
 begin
print	    '<tr><td>'+cast(@otran_spid as varchar(50))+
		    '</td><td>'+cast(@otran_lasworkertime as varchar(200))+
		    '</td><td>'+cast(@otran_lastphysicalread as varchar(50))+
			'</td><td>'+cast(@otran_totalphysicalread as varchar(100))+
			'</td><td>'+cast(@otran_totallogicalwrites as varchar(50))+
			 '</td><td>'+cast(@otran_lastlogicalreads as varchar(50))+
			 '</td><td>'+cast(@otran_currentwait as varchar(200))+
 			 '</td><td>'+cast(@otran_lastwaittype as varchar(200))+
			 '</td><td>'+cast(@otran_watiresource as varchar(100))+
			 '</td><td>'+cast(@otran_waittime as varchar(50))+
			 '</td><td>'+cast(@otran_opentrancount as varchar(50))+
			 '</td><td>'+cast(@otran_waittime as varchar(50))+
			 '</td><td>'+cast(@otran_rowcount as varchar(50))+
			 '</td><td>'+cast(@otran_sqltect as varchar(1000))+'</td>'+'</tr>'


fetch from cur_sqlact_info into 
@otran_spid,
@otran_lasworkertime ,
@otran_lastphysicalread ,
@otran_totalphysicalread ,
@otran_totallogicalwrites,
@otran_lastlogicalreads ,
@otran_currentwait ,
@otran_lastwaittype,
@otran_watiresource,
@otran_waittime ,
@otran_opentrancount ,
@otran_rowcount ,
@otran_granterqmem ,
@otran_sqltect

end

close cur_sqlact_info
deallocate cur_sqlact_info
print'</table><br/>'


/*
Message From Nirav Joshi
*/
print'<table style="width: 100%">
	<tr>
		<td><strong>Thanks for using this reporting solution for SQL Server Base 
		Line Performance Report.<br>This tool is developed by Nirav Joshi we 
		have taken queries from Glenn Berry's SQL Server Performance.<br>Thanks 
		Glenn for sharing those queries.<br>Looking forward to use this queries 
		in your day to day SQL Server performance trouble shooting.<br>We will 
		be keep updating this script with new Queries and more automation 
		detail.<br>We always look forward for your feedback and your suggestion.<br>
		You can download this script from <br></strong>
		<a href="Download%20Scripts%20for%20SQL%20Server%20Performance%20BaseLine%20Report">
		<strong>
		http://niravjoshi05.wordpress.com/2012/12/31/sql-server-200520082008r22012-instance-performance-data-capture-scripts</strong></a><strong><br>
		</strong><a href="http://www.SkyNicIndia.com"><strong>SkyNicIndia.com</strong></a><br>
		</td>
	</tr>
</table>'
print '</HTML>'



GO



USE [master]
GO
if exists(select 1 from sys.sysobjects where name=N'SP_InstanceBaselinePerfReport' and type=N'P')
begin
Drop procedure [dbo].[SP_InstanceBaselinePerfReport]
end

/****** Object:  StoredProcedure [dbo].[SP_InstanceBaselinePerfReport] 
Script Date: 1/17/2013 10:28:51 PM 
Created By Nirav Joshi
Subject:This script will create folder under the master database location as PerformanceBaseline and then it will also create HTML file in this folder
using the server name and created datetime stamp.

Please let me know your feedback about the script any suggestion comment are most welcome 
Please drop me line at nirav.j05@gmail.com


******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[SP_InstanceBaselinePerfReport]

as
declare @sql varchar(8000)
declare @sql2 varchar(8000)
declare @path varchar(4000)
declare @foldername varchar(200)
declare @command varchar(4000)
declare @datefile varchar(200)
declare @srvname varchar(200)
declare @ftype varchar(10)
declare @finalfile varchar(2000)
declare @fret int
declare @repret int
declare @value int
DECLARE @fileEx int

declare cur_spvalue cursor for 
SELECT cast(value_in_use as int)
FROM sys.configurations WITH (NOLOCK) where name='xp_cmdshell'
ORDER BY name OPTION (RECOMPILE);

open cur_spvalue
fetch from cur_spvalue into 
@value
while @@fetch_status>=0
begin 
if @value<>1
begin
exec sp_configure 'xp_cmdshell',1
reconfigure with override
end
fetch from cur_spvalue into 
@value
end

close cur_spvalue
deallocate cur_spvalue

set @foldername ='PerformanceBaseLine'
set @path=(SELECT SUBSTRING(physical_name, 1, CHARINDEX(N'\master.mdf', LOWER(physical_name)) - 1)
                  FROM master.sys.master_files
                  WHERE database_id = 1 AND file_id = 1)
set @path=@path+@foldername
--select @path

create table #tempdir
(
File_Exists int,
File_is_a_Directory int,
Parent_Directory_Exists int
)
insert into #tempdir(File_Exists,File_is_a_Directory,Parent_Directory_Exists)
EXEC master..xp_fileexist @path
select @fileEx = (select File_is_a_Directory from #tempdir)


Drop table #tempdir

if @fileEx = 0 
begin
set @command='mkdir "'+@path+'"'
--select @command
set nocount on

exec @fret= master.dbo.xp_cmdshell @command,no_output
print @fret
if @fret <> 0
	begin
		print'#############################################################################################################################'
		print @path
		print'#############################################################################################################################'
		print'#############################################################################################################################'
		print 'Folder is not able to create on the ' +@path+ ' please validate security settings for this folder for SQL Server service account or folder is already exisit.'
		print'#############################################################################################################################'
		return 1
	end
	
else
	begin
		print'#############################################################################################################################'
		print 'Folder is created now generating report'
		print'#############################################################################################################################'
		
	end
end

set @datefile = GETDATE()
set @datefile=(select convert(datetime,@datefile,126))
set @datefile=Replace(@datefile, ' ', '')
set @datefile=REPLACE(@datefile,':','')
--print @datefile

set @srvname=(select @@SERVERNAME)
set @srvname=REPLACE(@srvname,'\','')
set @path=@path+'\'
set @ftype='.html'
set @finalfile=(@path+@srvname+@datefile+@ftype)
--print @finalfile

select @sql='sqlcmd -E -Q "exec master.[dbo].[InstanceAnalysis_PerformanceBaseLine]" -o "'+@path+@srvname+@datefile+@ftype+'" -S'+ @@SERVERNAME
--print @sql
exec @repret=master..xp_cmdshell @sql,no_output
if @repret <>0
	begin
		print'#############################################################################################################################'
		print 'Report creating has failed there is something wrong with report.'
		print'#############################################################################################################################'
		return 1
	end
else
	begin
		print'#############################################################################################################################'
		print 'Report is Created fine please check report at this location ' +@finalfile+ '  please validate it'
		print'#############################################################################################################################'
	    return 0
	end

GO


USE [msdb]
GO

if exists(select 1 from sysjobs where name='DBA_PerfBaseline_Report_Job')
begin
declare @jid uniqueidentifier
select @jid=(select job_id from sysjobs where name='DBA_PerfBaseline_Report_Job')
EXEC msdb.dbo.sp_delete_job @job_id=@jid,@delete_unused_schedule=1
end

/****** Object:  Job [DBA_PerfBaseline_Report_Job]    Script Date: 1/17/2013 10:38:09 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 1/17/2013 10:38:09 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA_PerfBaseline_Report_Job', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job is creating performance baseline report.For this instance report is locating under the location where master data files are reside.--This job is owned by Physical DBA.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Execute SP For Creating HTML Report]    Script Date: 1/17/2013 10:38:09 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Execute SP For Creating HTML Report', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
declare @retval int

exec @retval=SP_InstanceBaselinePerfReport

select  @retval
if @retval <> 0 
begin
RAISERROR (50005, -- Message id.
           10, -- Severity,
           1, -- State,
           N''PerformanceBaseline Job is failing Please check folder  and FIles or anything wrong with script'')
end', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
