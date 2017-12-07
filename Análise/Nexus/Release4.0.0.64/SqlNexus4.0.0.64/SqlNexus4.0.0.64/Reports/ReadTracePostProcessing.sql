/*****************************************************
  This is the script to setup the proper objects
  used by the Reporter for RML reporting

  OWNER:  RDORR and KEITHELM

	  This requires SQL 2005 or later to execute
*****************************************************/

----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_TraceFiles'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_TraceFiles
go

create procedure ReadTrace.spReporter_TraceFiles
as
begin

	set nocount on

	select FileProcessed, FirstSeqNumber, LastSeqNumber, isnull(convert(nvarchar, FirstEventTime, 121), 'Unknown') as [FirstEventTime], isnull(convert(nvarchar, LastEventTime, 121), 'Unknown') as [LastEventTime], EventsRead, TraceFileName from ReadTrace.tblTraceFiles 
	order by FileProcessed asc
	
end
go

----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_CurrentDB'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_CurrentDB
go

create procedure ReadTrace.spReporter_CurrentDB
as
begin

	set nocount on
	--waitfor delay '23:00:00'		--		Easy way to test query timeout
	select db_name() as [Database]
end
go



----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_MiscInfo'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_MiscInfo
go

create procedure ReadTrace.spReporter_MiscInfo
as
begin

	select Attribute, Value from ReadTrace.tblMiscInfo

		union all

	select 'Active SQL Version', @@VERSION

		union all

	select 'Current Date', cast(GetDate() as nvarchar)

		union all

	select 'Database', DB_NAME()

		union all

	select 'Database Sort Order', cast(databasepropertyex(db_name(), 'SQLSortOrder') as nvarchar)

		union all
		
	select 'Timing Base',
		case 
			WHEN Value < 9 THEN N'Milliseconds (ms)'
			ELSE N'Microseconds (' + NCHAR(181) + N's)'
		end 
	from ReadTrace.tblMiscInfo
	where Attribute = 'EventVersion'

	order by Attribute

end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_TimeIntervals'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_TimeIntervals
go

--	Cast as proper format for parameter display 
create procedure ReadTrace.spReporter_TimeIntervals
as
begin
	--
	-- Relies on NULLs sorting first so that Auto Select is the first row in the result set (and thus
	-- picked as the default value for the parameter in the reports)
	--
	select convert(int, NULL) as TimeInterval,
			convert(varchar, '<Auto Select>') as StartTime,
			convert(varchar, '<Auto Select>') as EndTime

	union all
	
	select TimeInterval, 
			convert(varchar, StartTime, 121) as [StartTime],
			convert(varchar, EndTime, 121) as [EndTime]
	from ReadTrace.tblTimeIntervals
	
	order by TimeInterval
end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_TracedEvents'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_TracedEvents
go

create procedure ReadTrace.spReporter_TracedEvents
as
begin

	set nocount on

	--	SQL Azure does not have trace events
	if object_id('sys.trace_events','V') IS NOT NULL
	begin
		select e.EventID, se.name from ReadTrace.tblTracedEvents e
			inner join sys.trace_events se on se.trace_event_id = e.EventID
	end
	else
	begin		
		create table #tmp
		(
			trace_event_id	int	NOT NULL PRIMARY KEY,
			name			nvarchar(128)
		)

		insert into #tmp (trace_event_id, name) 
		values --select '(' + cast(trace_event_id as varchar) +  ', ''' + name + '''), ' from sys.trace_events
		(10, 'RPC:Completed'), 
		(11, 'RPC:Starting'), 
		(12, 'SQL:BatchCompleted'), 
		(13, 'SQL:BatchStarting'), 
		(14, 'Audit Login'), 
		(15, 'Audit Logout'), 
		(16, 'Attention'), 
		(17, 'ExistingConnection'), 
		(18, 'Audit Server Starts And Stops'), 
		(19, 'DTCTransaction'), 
		(20, 'Audit Login Failed'), 
		(21, 'EventLog'), 
		(22, 'ErrorLog'), 
		(23, 'Lock:Released'), 
		(24, 'Lock:Acquired'), 
		(25, 'Lock:Deadlock'), 
		(26, 'Lock:Cancel'), 
		(27, 'Lock:Timeout'), 
		(28, 'Degree of Parallelism'), 
		(33, 'Exception'), 
		(34, 'SP:CacheMiss'), 
		(35, 'SP:CacheInsert'), 
		(36, 'SP:CacheRemove'), 
		(37, 'SP:Recompile'), 
		(38, 'SP:CacheHit'), 
		(40, 'SQL:StmtStarting'), 
		(41, 'SQL:StmtCompleted'), 
		(42, 'SP:Starting'), 
		(43, 'SP:Completed'), 
		(44, 'SP:StmtStarting'), 
		(45, 'SP:StmtCompleted'), 
		(46, 'Object:Created'), 
		(47, 'Object:Deleted'), 
		(50, 'SQLTransaction'), 
		(51, 'Scan:Started'), 
		(52, 'Scan:Stopped'), 
		(53, 'CursorOpen'), 
		(54, 'TransactionLog'), 
		(55, 'Hash Warning'), 
		(58, 'Auto Stats'), 
		(59, 'Lock:Deadlock Chain'), 
		(60, 'Lock:Escalation'), 
		(61, 'OLEDB Errors'), 
		(67, 'Execution Warnings'), 
		(68, 'Showplan Text (Unencoded)'), 
		(69, 'Sort Warnings'), 
		(70, 'CursorPrepare'), 
		(71, 'Prepare SQL'), 
		(72, 'Exec Prepared SQL'), 
		(73, 'Unprepare SQL'), 
		(74, 'CursorExecute'), 
		(75, 'CursorRecompile'), 
		(76, 'CursorImplicitConversion'), 
		(77, 'CursorUnprepare'), 
		(78, 'CursorClose'), 
		(79, 'Missing Column Statistics'), 
		(80, 'Missing Join Predicate'), 
		(81, 'Server Memory Change'), 
		(82, 'UserConfigurable:0'), 
		(83, 'UserConfigurable:1'), 
		(84, 'UserConfigurable:2'), 
		(85, 'UserConfigurable:3'), 
		(86, 'UserConfigurable:4'), 
		(87, 'UserConfigurable:5'), 
		(88, 'UserConfigurable:6'), 
		(89, 'UserConfigurable:7'), 
		(90, 'UserConfigurable:8'), 
		(91, 'UserConfigurable:9'), 
		(92, 'Data File Auto Grow'), 
		(93, 'Log File Auto Grow'), 
		(94, 'Data File Auto Shrink'), 
		(95, 'Log File Auto Shrink'), 
		(96, 'Showplan Text'), 
		(97, 'Showplan All'), 
		(98, 'Showplan Statistics Profile'), 
		(100, 'RPC Output Parameter'), 
		(102, 'Audit Database Scope GDR Event'), 
		(103, 'Audit Schema Object GDR Event'), 
		(104, 'Audit Addlogin Event'), 
		(105, 'Audit Login GDR Event'), 
		(106, 'Audit Login Change Property Event'), 
		(107, 'Audit Login Change Password Event'), 
		(108, 'Audit Add Login to Server Role Event'), 
		(109, 'Audit Add DB User Event'), 
		(110, 'Audit Add Member to DB Role Event'), 
		(111, 'Audit Add Role Event'), 
		(112, 'Audit App Role Change Password Event'), 
		(113, 'Audit Statement Permission Event'), 
		(114, 'Audit Schema Object Access Event'), 
		(115, 'Audit Backup/Restore Event'), 
		(116, 'Audit DBCC Event'), 
		(117, 'Audit Change Audit Event'), 
		(118, 'Audit Object Derived Permission Event'), 
		(119, 'OLEDB Call Event'), 
		(120, 'OLEDB QueryInterface Event'), 
		(121, 'OLEDB DataRead Event'), 
		(122, 'Showplan XML'), 
		(123, 'SQL:FullTextQuery'), 
		(124, 'Broker:Conversation'), 
		(125, 'Deprecation Announcement'), 
		(126, 'Deprecation Final Support'), 
		(127, 'Exchange Spill Event'), 
		(128, 'Audit Database Management Event'), 
		(129, 'Audit Database Object Management Event'), 
		(130, 'Audit Database Principal Management Event'), 
		(131, 'Audit Schema Object Management Event'), 
		(132, 'Audit Server Principal Impersonation Event'), 
		(133, 'Audit Database Principal Impersonation Event'), 
		(134, 'Audit Server Object Take Ownership Event'), 
		(135, 'Audit Database Object Take Ownership Event'), 
		(136, 'Broker:Conversation Group'), 
		(137, 'Blocked process report'), 
		(138, 'Broker:Connection'), 
		(139, 'Broker:Forwarded Message Sent'), 
		(140, 'Broker:Forwarded Message Dropped'), 
		(141, 'Broker:Message Classify'), 
		(142, 'Broker:Transmission'), 
		(143, 'Broker:Queue Disabled'), 
		(144, 'Broker:Mirrored Route State Changed'), 
		(146, 'Showplan XML Statistics Profile'), 
		(148, 'Deadlock graph'), 
		(149, 'Broker:Remote Message Acknowledgement'), 
		(150, 'Trace File Close'), 
		(151, 'Database Mirroring Connection'), 
		(152, 'Audit Change Database Owner'), 
		(153, 'Audit Schema Object Take Ownership Event'), 
		(154, 'Audit Database Mirroring Login'), 
		(155, 'FT:Crawl Started'), 
		(156, 'FT:Crawl Stopped'), 
		(157, 'FT:Crawl Aborted'), 
		(158, 'Audit Broker Conversation'), 
		(159, 'Audit Broker Login'), 
		(160, 'Broker:Message Undeliverable'), 
		(161, 'Broker:Corrupted Message'), 
		(162, 'User Error Message'), 
		(163, 'Broker:Activation'), 
		(164, 'Object:Altered'), 
		(165, 'Performance statistics'), 
		(166, 'SQL:StmtRecompile'), 
		(167, 'Database Mirroring State Change'), 
		(168, 'Showplan XML For Query Compile'), 
		(169, 'Showplan All For Query Compile'), 
		(170, 'Audit Server Scope GDR Event'), 
		(171, 'Audit Server Object GDR Event'), 
		(172, 'Audit Database Object GDR Event'), 
		(173, 'Audit Server Operation Event'), 
		(175, 'Audit Server Alter Trace Event'), 
		(176, 'Audit Server Object Management Event'), 
		(177, 'Audit Server Principal Management Event'), 
		(178, 'Audit Database Operation Event'), 
		(180, 'Audit Database Object Access Event'), 
		(181, 'TM: Begin Tran starting'), 
		(182, 'TM: Begin Tran completed'), 
		(183, 'TM: Promote Tran starting'), 
		(184, 'TM: Promote Tran completed'), 
		(185, 'TM: Commit Tran starting'), 
		(186, 'TM: Commit Tran completed'), 
		(187, 'TM: Rollback Tran starting'), 
		(188, 'TM: Rollback Tran completed'), 
		(189, 'Lock:Timeout (timeout > 0)'), 
		(190, 'Progress Report: Online Index Operation'), 
		(191, 'TM: Save Tran starting'), 
		(192, 'TM: Save Tran completed'), 
		(193, 'Background Job Error'), 
		(194, 'OLEDB Provider Information'), 
		(195, 'Mount Tape'), 
		(196, 'Assembly Load'), 
		(198, 'XQuery Static Type'), 
		(199, 'QN: Subscription'), 
		(200, 'QN: Parameter table'), 
		(201, 'QN: Template'), 
		(202, 'QN: Dynamics'), 
		(212, 'Bitmap Warning'), 
		(213, 'Database Suspect Data Page'), 
		(214, 'CPU threshold exceeded'), 
		(215, 'PreConnect:Starting'), 
		(216, 'PreConnect:Completed'), 
		(217, 'Plan Guide Successful'), 
		(218, 'Plan Guide Unsuccessful'), 
		(235, 'Audit Fulltext');

		select e.EventID, se.name from ReadTrace.tblTracedEvents e
			inner join #tmp se on se.trace_event_id = e.EventID
	end
			
	
end
go


/*
16          Attention
33          Exception
37          SP:Recompile
55          Hash Warning
58          Auto Stats
60          Lock:Escalation
67          Execution Warnings
69          Sort Warnings
80          Missing Join Predicate

select * from ReadTrace.tblInterestingEvents e
select * from ReadTrace.tblTimeIntervals

exec ReadTrace.spReporter_InterestingEvents
*/
----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_InterestingEventsGrouped'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_InterestingEventsGrouped
go

create procedure ReadTrace.spReporter_InterestingEventsGrouped
	@StartTimeInterval int = null,
	@EndTimeInterval int = null,
	@EventID int = null
as
begin
	set nocount on

	declare @StartTime datetime, @EndTime datetime

	if(@StartTimeInterval is null)
		select @StartTimeInterval = min(TimeInterval) from ReadTrace.tblTimeIntervals

	if(@EndTimeInterval is null)
		select @EndTimeInterval = max(TimeInterval) from ReadTrace.tblTimeIntervals

	select @StartTime = StartTime from ReadTrace.tblTimeIntervals where TimeInterval = @StartTimeInterval
	select @EndTime = EndTime from ReadTrace.tblTimeIntervals where TimeInterval = @EndTimeInterval

	--
	--	For any interesting events that we observed somewhere in the time window of interest, build the complete 
	--	list of all time intervals in the window, event id, event name combinations.  In the following query which
	--	does a LEFT JOIN using this set we'll return each time interval with a count of events (zero if NULL).  If we don't
	--	return the time interval or return a value of NULL the report control will continue charting the same
	--	value up until the next data point (rather than charting a count of zero).  For example, if you had 1 attention
	-- 	in TimeInterval 1 and 1 attention in TimeInterval 3, the chart would show 1 across interval 2 as well which
	--	is very misleading
	--
	create table #TimeAndEvents
	(
		TimeInterval			BigInt,
		IntervalStartTime		DateTime,
		IntervalEndTime			Datetime,
		trace_event_id			int,
		name					nvarchar(128)
	)
	
	insert into #TimeAndEvents
	select i.TimeInterval, 
		i.StartTime as IntervalStartTime, 
		i.EndTime as IntervalEndTime, 
		e.trace_event_id,
		e.name 
	from ReadTrace.tblTimeIntervals i 
		cross join (select distinct EventID from ReadTrace.tblInterestingEvents 
						where EventID = isnull(@EventID, EventID)
							and coalesce(EndTime, StartTime) between @StartTime and @EndTime) as x
		join ReadTrace.trace_events e on x.EventID = e.trace_event_id
	where i.TimeInterval between @StartTimeInterval and @EndTimeInterval
	option (recompile)


	select 
		z.TimeInterval,
		z.IntervalStartTime,
		z.IntervalEndTime,
		z.trace_event_id as EventID,
		z.name,
		isnull(Count, 0) as [Count]
	from #TimeAndEvents as z
		left join (select TimeInterval,
					EventID,
					count(*) as [Count]
				from (select e.EventID,
						-- project the time interval for the event
						case when e.EndTime is not null then (select top 1 TimeInterval from ReadTrace.tblTimeIntervals ti where e.EndTime <= ti.EndTime order by ti.EndTime asc)
							else (select top 1 TimeInterval from ReadTrace.tblTimeIntervals ti where e.StartTime >= ti.StartTime order by ti.StartTime desc)
						end as TimeInterval
					from ReadTrace.tblInterestingEvents e
					where EventID = isnull(@EventID, EventID)
							and coalesce(EndTime, StartTime) between @StartTime and @EndTime) as x
				group by TimeInterval, EventID) as g on z.TimeInterval = g.TimeInterval and z.trace_event_id = g.EventID
	order by EventID, TimeInterval
	option (recompile)
end
go


if objectproperty(object_id('ReadTrace.spReporter_InterestingEventDetails'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_InterestingEventDetails
go

create procedure ReadTrace.spReporter_InterestingEventDetails
	@EventID int,
	@StartTimeInterval int = null,
	@EndTimeInterval int = null
as
begin
	set nocount on

	if(@StartTimeInterval is null)
		select @StartTimeInterval = min(TimeInterval) from ReadTrace.tblTimeIntervals

	if(@EndTimeInterval is null)
		select @EndTimeInterval = max(TimeInterval) from ReadTrace.tblTimeIntervals

	declare @dtStart datetime, @dtEnd datetime
	select @dtStart = StartTime from ReadTrace.tblTimeIntervals where TimeInterval = @StartTimeInterval
	select @dtEnd = EndTime from ReadTrace.tblTimeIntervals where TimeInterval = @EndTimeInterval

	--	SQL Trace is not part of SQL Azure
	if object_id('sys.trace_subclass_values','V') IS NOT NULL
	begin
			select top 5000
				e.Seq,
				e.ConnId,
				e.Session,
				e.Request,
				e.StartTime,
				e.EndTime,
				e.Duration,
				e.DBID,
				e.IntegerData,
				e.EventSubclass,
				sv.subclass_name as SubclassDescription,
				e.TextData,
				e.ObjectID,
				e.Error
			from ReadTrace.tblInterestingEvents e
				left join sys.trace_subclass_values sv on e.EventID = sv.trace_event_id
						and e.EventSubclass = sv.subclass_value
						and sv.trace_column_id = 21		-- event subclass
			where e.EventID = @EventID 
				and isnull(e.EndTime, e.StartTime) between @dtStart and @dtEnd
			order by e.StartTime
	end
	else
	begin
			create table #tmp
			(
				trace_event_id	int	NOT NULL,
				subclass_value  int NOT NULL,
				subclass_name  nvarchar(128)
			)

			insert into #tmp (trace_event_id, subclass_value, subclass_name) 
			values --select '(' + cast(trace_event_id as varchar) + ', ' + cast(subclass_value as varchar) + ', ''' + subclass_name + '''), ' from sys.trace_subclass_values where trace_column_id = 21
				(46, 0, 'Begin'), 
				(164, 0, 'Begin'), 
				(47, 0, 'Begin'), 
				(46, 1, 'Commit'), 
				(164, 1, 'Commit'), 
				(47, 1, 'Commit'), 
				(46, 2, 'Rollback'), 
				(164, 2, 'Rollback'), 
				(47, 2, 'Rollback'), 
				(59, 101, 'Resource type Lock'), 
				(59, 102, 'Resource type Exchange'), 
				(55, 0, 'Recursion'), 
				(55, 1, 'Bailout'), 
				(212, 0, 'Disabled'), 
				(81, 1, 'Increase'), 
				(81, 2, 'Decrease'), 
				(119, 0, 'Starting'), 
				(119, 1, 'Completed'), 
				(120, 0, 'Starting'), 
				(120, 1, 'Completed'), 
				(121, 0, 'Starting'), 
				(121, 1, 'Completed'), 
				(67, 1, 'Query wait'), 
				(67, 2, 'Query timeout'), 
				(28, 1, 'Select'), 
				(28, 2, 'Insert'), 
				(28, 3, 'Update'), 
				(28, 4, 'Delete'), 
				(28, 5, 'Merge'), 
				(69, 1, 'Single pass'), 
				(69, 2, 'Multiple pass'), 
				(115, 1, 'Backup'), 
				(115, 2, 'Restore'), 
				(115, 3, 'BackupLog'), 
				(118, 1, 'Create'), 
				(176, 1, 'Create'), 
				(128, 1, 'Create'), 
				(129, 1, 'Create'), 
				(131, 1, 'Create'), 
				(177, 1, 'Create'), 
				(130, 1, 'Create'), 
				(118, 2, 'Alter'), 
				(176, 2, 'Alter'), 
				(128, 2, 'Alter'), 
				(129, 2, 'Alter'), 
				(131, 2, 'Alter'), 
				(177, 2, 'Alter'), 
				(130, 2, 'Alter'), 
				(118, 3, 'Drop'), 
				(176, 3, 'Drop'), 
				(128, 3, 'Drop'), 
				(129, 3, 'Drop'), 
				(131, 3, 'Drop'), 
				(177, 3, 'Drop'), 
				(130, 3, 'Drop'), 
				(118, 4, 'Backup'), 
				(176, 4, 'Backup'), 
				(128, 4, 'Backup'), 
				(129, 4, 'Backup'), 
				(131, 4, 'Backup'), 
				(177, 4, 'Backup'), 
				(130, 4, 'Backup'), 
				(177, 5, 'Disable'), 
				(177, 6, 'Enable'), 
				(176, 7, 'Credential mapped to login'), 
				(131, 8, 'Transfer'), 
				(176, 9, 'Credential Map Dropped'), 
				(129, 10, 'Open'), 
				(118, 11, 'Restore'), 
				(176, 11, 'Restore'), 
				(128, 11, 'Restore'), 
				(129, 11, 'Restore'), 
				(131, 11, 'Restore'), 
				(177, 11, 'Restore'), 
				(130, 11, 'Restore'), 
				(129, 12, 'Access'), 
				(130, 13, 'Change User Login - Update One'), 
				(130, 14, 'Change User Login - Auto Fix'), 
				(176, 15, 'Shutdown on Audit Failure'), 
				(111, 1, 'Add'), 
				(109, 1, 'Add'), 
				(104, 1, 'Add'), 
				(108, 1, 'Add'), 
				(110, 1, 'Add'), 
				(111, 2, 'Drop'), 
				(109, 2, 'Drop'), 
				(104, 2, 'Drop'), 
				(108, 2, 'Drop'), 
				(110, 2, 'Drop'), 
				(110, 3, 'Change group'), 
				(109, 3, 'Grant database access'), 
				(109, 4, 'Revoke database access'), 
				(18, 1, 'Shutdown'), 
				(18, 2, 'Started'), 
				(18, 3, 'Paused'), 
				(18, 4, 'Continue'), 
				(103, 1, 'Grant'), 
				(102, 1, 'Grant'), 
				(105, 1, 'Grant'), 
				(170, 1, 'Grant'), 
				(171, 1, 'Grant'), 
				(172, 1, 'Grant'), 
				(103, 2, 'Revoke'), 
				(102, 2, 'Revoke'), 
				(105, 2, 'Revoke'), 
				(170, 2, 'Revoke'), 
				(171, 2, 'Revoke'), 
				(172, 2, 'Revoke'), 
				(103, 3, 'Deny'), 
				(102, 3, 'Deny'), 
				(105, 3, 'Deny'), 
				(170, 3, 'Deny'), 
				(171, 3, 'Deny'), 
				(172, 3, 'Deny'), 
				(158, 1, 'No Security Header'), 
				(158, 2, 'No Certificate'), 
				(158, 3, 'Invalid Signature'), 
				(158, 4, 'Run As Target Failure'), 
				(158, 5, 'Bad Data'), 
				(159, 1, 'Login Success'), 
				(159, 2, 'Login Protocol Error'), 
				(159, 3, 'Message Format Error'), 
				(159, 4, 'Negotiate Failure'), 
				(159, 5, 'Authentication Failure'), 
				(159, 6, 'Authorization Failure'), 
				(154, 1, 'Login Success'), 
				(154, 2, 'Login Protocol Error'), 
				(154, 3, 'Message Format Error'), 
				(154, 4, 'Negotiate Failure'), 
				(154, 5, 'Authentication Failure'), 
				(154, 6, 'Authorization Failure'), 
				(142, 1, 'Transmission Exception'), 
				(117, 1, 'Audit started'), 
				(117, 2, 'Audit stopped'), 
				(117, 3, 'C2 mode ON'), 
				(117, 4, 'C2 mode OFF'), 
				(19, 3, 'Close connection'), 
				(19, 23, 'Unknown'), 
				(19, 0, 'Get address'), 
				(19, 1, 'Propagate Transaction'), 
				(19, 14, 'Preparing Transaction'), 
				(19, 15, 'Transaction is prepared'), 
				(19, 16, 'Transaction is aborting'), 
				(19, 17, 'Transaction is committing'), 
				(19, 22, 'TM failed while in prepared state'), 
				(19, 9, 'Internal commit'), 
				(19, 10, 'Internal abort'), 
				(19, 6, 'Creating a new DTC transaction'), 
				(19, 7, 'Enlisting in a DTC transaction'), 
				(50, 0, 'Begin'), 
				(50, 1, 'Commit'), 
				(50, 2, 'Rollback'), 
				(50, 3, 'Savepoint'), 
				(37, 1, 'Schema changed'), 
				(37, 2, 'Statistics changed'), 
				(37, 3, 'Deferred compile'), 
				(37, 4, 'Set option change'), 
				(37, 5, 'Temp table changed'), 
				(37, 6, 'Remote rowset changed'), 
				(37, 7, 'For browse permissions changed'), 
				(37, 8, 'Query notification environment changed'), 
				(37, 9, 'PartitionView changed'), 
				(37, 10, 'Cursor options changed'), 
				(37, 11, 'Option (recompile) requested'), 
				(37, 12, 'Parameterized plan flushed'), 
				(37, 13, 'Test plan linearization'), 
				(37, 14, 'Plan affecting database version changed'), 
				(166, 1, 'Schema changed'), 
				(166, 2, 'Statistics changed'), 
				(166, 3, 'Deferred compile'), 
				(166, 4, 'Set option change'), 
				(166, 5, 'Temp table changed'), 
				(166, 6, 'Remote rowset changed'), 
				(166, 7, 'For browse permissions changed'), 
				(166, 8, 'Query notification environment changed'), 
				(166, 9, 'PartitionView changed'), 
				(166, 10, 'Cursor options changed'), 
				(166, 11, 'Option (recompile) requested'), 
				(166, 12, 'Parameterized plan flushed'), 
				(166, 13, 'Test plan linearization'), 
				(166, 14, 'Plan affecting database version changed'), 
				(106, 1, 'Default database changed'), 
				(106, 2, 'Default language changed'), 
				(106, 3, 'Name changed'), 
				(106, 5, 'Policy changed'), 
				(106, 6, 'Expiration changed'), 
				(106, 4, 'Credential changed'), 
				(107, 1, 'Password self changed'), 
				(107, 2, 'Password changed'), 
				(107, 3, 'Password self reset'), 
				(107, 4, 'Password reset'), 
				(107, 5, 'Password unlocked'), 
				(107, 6, 'Password must change'), 
				(124, 1, 'SEND Message'), 
				(124, 2, 'END CONVERSATION'), 
				(124, 3, 'END CONVERSATION WITH ERROR'), 
				(124, 4, 'Broker Initiated Error'), 
				(124, 5, 'Terminate Dialog'), 
				(124, 6, 'Received Sequenced Message'), 
				(124, 7, 'Received END CONVERSATION'), 
				(124, 8, 'Received END CONVERSATION WITH ERROR'), 
				(124, 9, 'Received Broker Error Message'), 
				(124, 10, 'Received END CONVERSATION Ack'), 
				(124, 11, 'BEGIN DIALOG'), 
				(124, 12, 'Dialog Created'), 
				(124, 13, 'END CONVERSATION WITH CLEANUP'), 
				(136, 1, 'Create'), 
				(136, 2, 'Drop'), 
				(149, 1, 'Message with Acknowledgement Sent'), 
				(149, 2, 'Acknowledgement Sent'), 
				(149, 3, 'Message with Acknowledgement Received'), 
				(149, 4, 'Acknowledgement Received'), 
				(160, 1, 'Sequenced Message'), 
				(160, 2, 'Unsequenced Message'), 
				(163, 1, 'Started'), 
				(163, 2, 'Ended'), 
				(163, 3, 'Aborted'), 
				(163, 4, 'Notified'), 
				(163, 5, 'Task Output'), 
				(163, 6, 'Failed to start'), 
				(138, 1, 'Connecting'), 
				(138, 2, 'Connected'), 
				(138, 3, 'Connect Failed'), 
				(138, 4, 'Closing'), 
				(138, 5, 'Closed'), 
				(138, 6, 'Accept'), 
				(138, 7, 'Send IO Error'), 
				(138, 8, 'Receive IO Error'), 
				(144, 1, 'Operational'), 
				(144, 2, 'Operational with principal only'), 
				(144, 3, 'Not operational'), 
				(151, 1, 'Connecting'), 
				(151, 2, 'Connected'), 
				(151, 3, 'Connect Failed'), 
				(151, 4, 'Closing'), 
				(151, 5, 'Closed'), 
				(151, 6, 'Accept'), 
				(151, 7, 'Send IO Error'), 
				(151, 8, 'Receive IO Error'), 
				(127, 1, 'Spill begin'), 
				(127, 2, 'Spill end'), 
				(185, 1, 'Commit'), 
				(186, 1, 'Commit'), 
				(185, 2, 'Commit and Begin'), 
				(186, 2, 'Commit and Begin'), 
				(187, 1, 'Rollback'), 
				(188, 1, 'Rollback'), 
				(187, 2, 'Rollback and Begin'), 
				(188, 2, 'Rollback and Begin'), 
				(190, 1, 'Start'), 
				(190, 2, 'Stage 1 execution begin'), 
				(190, 3, 'Stage 1 execution end'), 
				(190, 4, 'Stage 2 execution begin'), 
				(190, 5, 'Stage 2 execution end'), 
				(190, 6, 'Inserted row count'), 
				(190, 7, 'Done'), 
				(141, 1, 'Local'), 
				(141, 2, 'Remote'), 
				(141, 3, 'Delayed'), 
				(195, 1, 'Tape mount request'), 
				(195, 2, 'Tape mount complete'), 
				(195, 3, 'Tape mount cancelled'), 
				(36, 1, 'Compplan Remove'), 
				(36, 2, 'Proc Cache Flush'), 
				(165, 0, 'SQL'), 
				(165, 1, 'SP:Plan'), 
				(165, 2, 'Batch:Plan'), 
				(165, 3, 'QueryStats'), 
				(165, 4, 'ProcedureStats'), 
				(165, 5, 'TriggerStats'), 
				(173, 175, 'Alter Server State'), 
				(178, 1, 'Checkpoint'), 
				(178, 2, 'Subscribe to Query Notification'), 
				(178, 3, 'Authenticate'), 
				(178, 4, 'Showplan'), 
				(178, 5, 'Connect'), 
				(178, 6, 'View Database State'), 
				(173, 1, 'Administer Bulk Operations'), 
				(173, 2, 'Alter Settings'), 
				(173, 3, 'Alter Resources'), 
				(173, 4, 'Authenticate'), 
				(173, 5, 'External Access Assembly'), 
				(173, 7, 'Unsafe Assembly'), 
				(173, 8, 'Alter Connection'), 
				(173, 9, 'Alter Resource Governor'), 
				(173, 10, 'Use Any Workload Group'), 
				(173, 11, 'View Server State'), 
				(199, 1, 'Subscription registered'), 
				(199, 2, 'Subscription rewound'), 
				(199, 3, 'Subscription fired'), 
				(199, 4, 'Firing failed with broker error'), 
				(199, 5, 'Firing failed without broker error'), 
				(199, 6, 'Broker error intercepted'), 
				(199, 7, 'Subscription deletion attempt'), 
				(199, 8, 'Subscription deletion failed'), 
				(199, 9, 'Subscription destroyed'), 
				(200, 1, 'Table created'), 
				(200, 2, 'Table drop attempt'), 
				(200, 3, 'Table drop attempt failed'), 
				(200, 4, 'Table dropped'), 
				(200, 5, 'Table pinned'), 
				(200, 6, 'Table unpinned'), 
				(200, 7, 'Number of users incremented'), 
				(200, 8, 'Number of users decremented'), 
				(200, 9, 'LRU counter reset'), 
				(200, 10, 'Cleanup task started'), 
				(200, 11, 'Cleanup task finished'), 
				(201, 1, 'Template created'), 
				(201, 2, 'Template matched'), 
				(201, 3, 'Template dropped'), 
				(202, 1, 'Clock run started'), 
				(202, 2, 'Clock run finished'), 
				(202, 3, 'Master cleanup task started'), 
				(202, 4, 'Master cleanup task finished'), 
				(202, 5, 'Master cleanup task skipped'), 
				(215, 1, 'RG Classifier UDF'), 
				(216, 1, 'RG Classifier UDF'), 
				(215, 2, 'Logon Trigger'), 
				(216, 2, 'Logon Trigger'), 
				(14, 1, 'Nonpooled'), 
				(14, 2, 'Pooled'), 
				(15, 1, 'Nonpooled'), 
				(15, 2, 'Pooled'), 
				(20, 1, 'Nonpooled'), 
				(20, 2, 'Pooled'), 
				(60, 0, 'LOCK_THRESHOLD'), 
				(60, 1, 'MEMORY_THRESHOLD'), 
				(235, 1, 'Fulltext Filter Daemon Connect Success'), 
				(235, 2, 'Fulltext Filter Daemon Connect Error'), 
				(235, 3, 'Fulltext Launcher Connect Success'), 
				(235, 4, 'Fulltext Launcher Connect Error'), 
				(235, 5, 'Fulltext Inbound Shared Memory Corrupt'), 
				(235, 6, 'Fulltext Inbound Pipe Message Corrupt');
	
			select top 5000
			e.Seq,
			e.ConnId,
			e.Session,
			e.Request,
			e.StartTime,
			e.EndTime,
			e.Duration,
			e.DBID,
			e.IntegerData,
			e.EventSubclass,
			sv.subclass_name as SubclassDescription,
			e.TextData,
			e.ObjectID,
			e.Error
		from ReadTrace.tblInterestingEvents e
			left join #tmp sv on e.EventID = sv.trace_event_id
					and e.EventSubclass = sv.subclass_value
					--and sv.trace_column_id = 21		-- event subclass
		where e.EventID = @EventID 
			and isnull(e.EndTime, e.StartTime) between @dtStart and @dtEnd
		order by e.StartTime

	end
	
end
go

----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_BatchAggregatesTimeIntervalGrouping'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_BatchAggregatesTimeIntervalGrouping
go

create procedure ReadTrace.spReporter_BatchAggregatesTimeIntervalGrouping
	@StartTimeInterval int = null,
	@EndTimeInterval int = null
as
begin
	set nocount on

	if(@StartTimeInterval is null)
		select @StartTimeInterval = min(TimeInterval) from ReadTrace.tblTimeIntervals

	if(@EndTimeInterval is null)
		select @EndTimeInterval = max(TimeInterval) from ReadTrace.tblTimeIntervals

	select  * from ReadTrace.vwBatchPartialAggsByGroupTimeInterval a
		where a.TimeInterval between @StartTimeInterval and @EndTimeInterval
		order by a.TimeInterval asc
	option (recompile)

end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.fn_ReporterCalculateScaleFactor'), 'IsScalarFunction') = 1
	drop function ReadTrace.fn_ReporterCalculateScaleFactor
go

/*
 *	Function: fn_ReporterCalculateScaleFactor
 *
 *	This function calculates a scale factor that the given input value must be multiplied by so that it is in the range of 0 to 100.
 *	This resultant value is used as a multiplier for each of the various series that will be charted in Reporter to ensure that they
 *	all plot within the same range.  Otherwise a value that is unusually large will skew the chart range so that reasonable/small 
 *	values can't be visually differentiated.  Currently, all values are scaled via a factor of 10, similar to Performance Monitor.  It
 *	is assumed that the input value will always be greater than or equal to zero (so that we don't have to multiply by values > 1)
 *
 *	When converting a float value to varchar using format specification 1 (below) the output is always formatted as 8 digits with 
 *	an exponent (i.e., 1.2345678e+nnn).  Use substring to extract the exponent.  Because we want all values to be scaled between 0 and 100, 
 *	subtract 2 from the exponent and build a fraction (0.nnnn1) that can be used to multiply so that the value will be in this range
 */
create function ReadTrace.fn_ReporterCalculateScaleFactor ( @Input float )
returns numeric(38, 20)
as
begin
	declare @ScaleFactor numeric(38, 20)
	select @ScaleFactor = 
		case 
			when @Input < 1 then 100
			when @Input < 10 then 10
			when @Input < 100 then 1
			when @Input is null then 1
			else convert(numeric(38, 20), '0.' + replicate('0', convert(int, substring(convert(varchar(60), @Input, 1), 11, 10)) - 2) + '1')
		end

	return @ScaleFactor
end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_BatchAggScaleFactor'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_BatchAggScaleFactor
go

create procedure ReadTrace.spReporter_BatchAggScaleFactor
	@StartTimeInterval int = null,
	@EndTimeInterval int = null
as
begin
	--	In order to keep a single chart with reads, writes, CPU and such
	--	we have to adjust the values (as if scaled in perfmon) to be like the
	--	max setting so they can all live together with some sort of graph
	--	definition
	set nocount on

	declare @MaxEventCount int

	if(@StartTimeInterval is null)
		select @StartTimeInterval = min(TimeInterval) from ReadTrace.tblTimeIntervals

	if(@EndTimeInterval is null)
		select @EndTimeInterval = max(TimeInterval) from ReadTrace.tblTimeIntervals

	create table #BatchAggs (StartTime datetime, EndTime datetime, TimeInterval int, StartingEvents int, 
				CompletedEvents int, Attentions int, Duration bigint, Reads bigint, Writes bigint, 
				CPU bigint)

	-- Insert the aggregated batch information for the specified time window into a local temp table
	insert into #BatchAggs exec ReadTrace.spReporter_BatchAggregatesTimeIntervalGrouping @StartTimeInterval, @EndTimeInterval
	
	-- I want to make sure that I always chart starting & completed events on the same scale, so that if
	-- their is some divergence in the number (due to longer running queries, blocking, etc) that the two
	-- lines diverge and make this very obvious.  Therefore I get the max of either of these two and use it
	-- as input for scaling in the final query below
	select @MaxEventCount = max(NumberOfEvents) from (
		select max(StartingEvents) as NumberOfEvents from #BatchAggs
		union all
		select max(CompletedEvents) as NumberOfEvents from #BatchAggs) as t


	select 
		case when @MaxEventCount <= 100 then 1.0 else ReadTrace.fn_ReporterCalculateScaleFactor(@MaxEventCount) end as StartingEventsScale,
		case when @MaxEventCount <= 100 then 1.0 else ReadTrace.fn_ReporterCalculateScaleFactor(@MaxEventCount) end as CompletedEventsScale,
		case when max(Attentions) <= 100 then 1.0 else ReadTrace.fn_ReporterCalculateScaleFactor(max(Attentions)) end as AttentionEventsScale,
		ReadTrace.fn_ReporterCalculateScaleFactor(max(a.Duration)) as DurationScale,
		ReadTrace.fn_ReporterCalculateScaleFactor(max(a.Reads)) as ReadsScale,
		ReadTrace.fn_ReporterCalculateScaleFactor(max(a.Writes)) as WritesScale,
		ReadTrace.fn_ReporterCalculateScaleFactor(max(a.CPU)) as CPUScale
	from #BatchAggs as a
	
end
go


----------------------------------------------------------------------------------------------
/*
declare @xmlVar  xml

set @xmlVar = N'<FILTERVALUES><GROUP Number=''1'' Name=''EndTime'' Value=''11/21/2000 3:23:56 PM''/><GROUP Number=''2'' Name=''StartTime'' Value=''12/21/2000 3:23:56 PM''/></FILTERVALUES>' 

select group_name.value('(./@Number)[1]', 'int'),
group_name.value('(./@Name)[1]', 'nvarchar(50)'),
group_name.value('(./@Value)[1]', 'nvarchar(max)'),
group_name.query('.')
from ((select 1 as dummyRow) as p				--	Single row to force the cross apply of all nodes from the actual XML
	cross apply @xmlVar.nodes('./FILTERVALUES/GROUP') as filter(group_name))

*/
----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_DetermineFilterValues'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_DetermineFilterValues
go

--	It is possible that the user from a report can set the filter multiple
--	times.  Insert into table and select TOP 1 row back to get the actual values
create procedure ReadTrace.spReporter_DetermineFilterValues
	@StartTimeInterval	int output,
	@EndTimeInterval	int output,
	@iDBID		int output,
	@iAppNameID	int output,
	@iLoginNameID	int output,
	@Filter1	nvarchar(256),
	@Filter2	nvarchar(256),
	@Filter3	nvarchar(256),
	@Filter4	nvarchar(256),
	@Filter1Name	nvarchar(64),
	@Filter2Name	nvarchar(64),
	@Filter3Name	nvarchar(64),
	@Filter4Name	nvarchar(64)
as
begin
	set nocount on

	declare @iTimeInterval 	int

	set @iTimeInterval = null

	create table #tblFilter
	(
		strFilterName		nvarchar(64)  collate database_default null,
		strFilterValue		nvarchar(256) collate database_default null  
	)

	insert into #tblFilter values
		(@Filter1Name, @Filter1),
		(@Filter2Name, @Filter2),
		(@Filter3Name, @Filter3),
		(@Filter4Name, @Filter4)
	
	----------------------------------------------------------------------------------------------
	--	Keep in sync with spReporter_PartialAggs_GroupBy
	----------------------------------------------------------------------------------------------
	select TOP 1 @iTimeInterval = cast(strFilterValue as int) from
		#tblFilter f 		
		where strFilterName = N'EndTime'

	select TOP 1 @iDBID = cast(strFilterValue as int) from
		#tblFilter where strFilterName = N'DBID'

	select TOP 1 @iAppNameID = n.iID from
		#tblFilter f 
		inner join ReadTrace.tblUniqueAppNames n on n.AppName = f.strFilterValue
		where strFilterName = N'AppName'

	select TOP 1 @iLoginNameID = n.iID from
		#tblFilter f 
		inner join ReadTrace.tblUniqueLoginNames n on n.LoginName = f.strFilterValue
		where strFilterName = N'LoginName'

	--	Has user set any of the time interval range to override the direct EndTime filter
	if(	    @StartTimeInterval is null 
		and @EndTimeInterval is null
		and @iTimeInterval is not null)
	begin
		select @StartTimeInterval = @iTimeInterval
		select @EndTimeInterval = @iTimeInterval
	end
	else
	begin
		if(@StartTimeInterval is null)
			select @StartTimeInterval = min(TimeInterval) from ReadTrace.tblTimeIntervals
	
		if(@EndTimeInterval is null)
			select @EndTimeInterval = max(TimeInterval) from ReadTrace.tblTimeIntervals
	end


end
go

--------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_GetFilterAsString'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_GetFilterAsString
go

create procedure ReadTrace.spReporter_GetFilterAsString
		@Filter1	nvarchar(256) = null,
		@Filter2	nvarchar(256) = null,
		@Filter3	nvarchar(256) = null,
		@Filter4	nvarchar(256) = null,
		@Filter1Name	nvarchar(64) = null,
		@Filter2Name	nvarchar(64) = null,
		@Filter3Name	nvarchar(64) = null,
		@Filter4Name	nvarchar(64) = null
as
begin
	set nocount on

	declare	@strFilterString		nvarchar(1024)
	
	select @strFilterString = ''

	if('AppName' = @Filter1Name or 'LoginName' = @Filter1Name or 'DBID' = @Filter1Name)
	begin
		select @strFilterString = @strFilterString + @Filter1Name + ' = ' + @Filter1 + char(10)
	end	
			
	if('AppName' = @Filter2Name or 'LoginName' = @Filter2Name or 'DBID' = @Filter2Name)
	begin
		select @strFilterString = @strFilterString + @Filter2Name + ' = ' + @Filter2 + char(10)
	end	

	if('AppName' = @Filter3Name or 'LoginName' = @Filter3Name or 'DBID' = @Filter3Name)
	begin
		select @strFilterString = @strFilterString + @Filter3Name + ' = ' + @Filter3 + char(10)
	end	

	if('AppName' = @Filter4Name or 'LoginName' = @Filter4Name or 'DBID' = @Filter4Name)
	begin
		select @strFilterString = @strFilterString + @Filter4Name + ' = ' + @Filter4 + char(10)
	end		

	select  case 
		when @strFilterString = '' then NULL 
		else @strFilterString 
	end as 'FilterString'

end
go


/*
exec sp_executesql @CmdText=N'exec spReporter_GetActualTimeRange 
	@StartTimeInterval, @EndTimeInterval',@VarDefs=N'@StartTimeInterval nvarchar, 
	@EndTimeInterval nvarchar',@StartTimeInterval=NULL,@EndTimeInterval=NULL
*/
----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_GetActualTimeRange'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_GetActualTimeRange
go

create procedure ReadTrace.spReporter_GetActualTimeRange
		@StartTimeInterval int = null,
		@EndTimeInterval int = null,
		@Filter1	nvarchar(256) = null,
		@Filter2	nvarchar(256) = null,
		@Filter3	nvarchar(256) = null,
		@Filter4	nvarchar(256) = null,
		@Filter1Name	nvarchar(64) = null,
		@Filter2Name	nvarchar(64) = null,
		@Filter3Name	nvarchar(64) = null,
		@Filter4Name	nvarchar(64) = null
as
begin

	set nocount on

	-- Possible filters to be applied
	declare	@iAppNameID		int
	declare @iLoginNameID		int
	declare @iDBID			int

	exec ReadTrace.spReporter_DetermineFilterValues 
			@StartTimeInterval output,
			@EndTimeInterval output,
			@iDBID output,
			@iAppNameID output,
			@iLoginNameID output,
			@Filter1,
			@Filter2,
			@Filter3,
			@Filter4,
			@Filter1Name,
			@Filter2Name,
			@Filter3Name,
			@Filter4Name

	select  
	(select StartTime from ReadTrace.tblTimeIntervals where TimeInterval = @StartTimeInterval) as [StartTime],
	(select EndTime from ReadTrace.tblTimeIntervals where TimeInterval = @EndTimeInterval) as [EndTime]
	

end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_BatchTopN'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_BatchTopN
go

--	ReadTrace.spReporter_BatchTopN  null, null, 9, null, null
--	select * from tblUniqueLoginNames
--	select * from tblUniqueAppNames
--	select distinct(LoginNameID) from tblBatchPartialAggs
--	ReadTrace.spReporter_BatchTopN  null, null, 9, 'Connected Before Trace', null, null, null, 'LoginName'
--	ReadTrace.spReporter_BatchTopN  null, null, 9, 'Unspecified', null, null, null, 'LoginName'
--	ReadTrace.spReporter_BatchTopN  null, null, 9, 'Unspecified', 'PRIMUS:d589844e-ca63-4be1-a126-02d6e1e62770', null, null, 'LoginName', 'AppName'
create procedure ReadTrace.spReporter_BatchTopN
	@StartTimeInterval int = null,
	@EndTimeInterval int = null,
	@TopN int = null,
	@Filter1	nvarchar(256) = null,
	@Filter2	nvarchar(256) = null,
	@Filter3	nvarchar(256) = null,
	@Filter4	nvarchar(256) = null,
	@Filter1Name	nvarchar(64) = null,
	@Filter2Name	nvarchar(64) = null,
	@Filter3Name	nvarchar(64) = null,
	@Filter4Name	nvarchar(64) = null
as
begin
	set nocount on

	-- Possible filters to be applied
	declare	@iAppNameID		int
	declare @iLoginNameID		int
	declare @iDBID			int

	if @TopN is null set @TopN = 10

	exec ReadTrace.spReporter_DetermineFilterValues 
			@StartTimeInterval output,
			@EndTimeInterval output,
			@iDBID output,
			@iAppNameID output,
			@iLoginNameID output,
			@Filter1,
			@Filter2,
			@Filter3,
			@Filter4,
			@Filter1Name,
			@Filter2Name,
			@Filter3Name,
			@Filter4Name

	--	Use the row_number and order by's to get list the # of entries that match
	--	Since unique row only returned 1 time this works like a large set of unions
	select *,
		row_number() over(order by CPU desc) as QueryNumber
	from (
		select 	a.HashID,
			sum(CompletedEvents) as Executes,
		    sum(TotalCPU) as CPU,
			sum(TotalDuration) as Duration,
			sum(TotalReads) as Reads,
			sum(TotalWrites) as Writes,
			sum(AttentionEvents) as Attentions, 
			(select StartTime from ReadTrace.tblTimeIntervals i where TimeInterval = @StartTimeInterval) as [StartTime],
			(select EndTime from ReadTrace.tblTimeIntervals i where TimeInterval = @EndTimeInterval) as [EndTime],
			(select cast(NormText as nvarchar(4000)) from ReadTrace.tblUniqueBatches b where b.HashID = a.HashID) as [NormText],
		       	row_number() over(order by sum(TotalCPU) desc) as CPUDesc,
		       	row_number() over(order by sum(TotalCPU) asc) as CPUAsc,
		       	row_number() over(order by sum(TotalDuration) desc) as DurationDesc,
		       	row_number() over(order by sum(TotalDuration) asc) as DurationAsc,
		       	row_number() over(order by sum(TotalReads) desc) as ReadsDesc,
		       	row_number() over(order by sum(TotalReads) asc) as ReadsAsc,
				row_number() over(order by sum(TotalWrites) desc) as WritesDesc,
		       	row_number() over(order by sum(TotalWrites) asc) as WritesAsc
			from ReadTrace.tblBatchPartialAggs a
				where TimeInterval between @StartTimeInterval and @EndTimeInterval
					and a.AppNameID = isnull(@iAppNameID, a.AppNameID)
					and a.LoginNameID = isnull(@iLoginNameID, a.LoginNameID)
					and a.DBID = isnull(@iDBID, a.DBID)
			group by a.HashID
		       ) as Outcome
		where 	(CPUDesc <= @TopN 
			or CPUAsc <= @TopN
			or DurationDesc <= @TopN 
			or DurationAsc <= @TopN
			or ReadsDesc <= @TopN 
			or ReadsAsc <= @TopN
			or WritesDesc <= @TopN 
			or WritesAsc <= @TopN)
		order by CPU desc
		option (recompile)

end
go



----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_TopN'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_TopN
go

create procedure ReadTrace.spReporter_TopN
as
begin
	set nocount on

	select 3 as [TopN]
		union all
	select 5 as [TopN]
		union all
	select 10 as [TopN]
		union all
	select 25 as [TopN]
		union all
	select 50 as [TopN]
		union all
	select 100 as [TopN]

	order by TopN asc
end
go



----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_OrderByColumns'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_OrderByColumns
go

create procedure ReadTrace.spReporter_OrderByColumns
as
begin
	set nocount on

	select cast('CPU' as varchar(30)) as [OrderByColumn]
		union all
	select 'Duration'
		union all
	select 'Reads'
		union all
	select 'Writes'
		union all
	select 'Executes'
end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_ResourceUsageDuringInterval'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_ResourceUsageDuringInterval
go

create procedure ReadTrace.spReporter_ResourceUsageDuringInterval
	@StartTimeInterval int = null,
	@EndTimeInterval int = null,
	@Filter1	nvarchar(256) = null,
	@Filter2	nvarchar(256) = null,
	@Filter3	nvarchar(256) = null,
	@Filter4	nvarchar(256) = null,
	@Filter1Name	nvarchar(64) = null,
	@Filter2Name	nvarchar(64) = null,
	@Filter3Name	nvarchar(64) = null,
	@Filter4Name	nvarchar(64) = null
as
begin
	set nocount on

	declare	@iAppNameID		int
	declare @iLoginNameID		int
	declare @iDBID			int

	exec ReadTrace.spReporter_DetermineFilterValues 
			@StartTimeInterval output,
			@EndTimeInterval output,
			@iDBID output,
			@iAppNameID output,
			@iLoginNameID output,
			@Filter1,
			@Filter2,
			@Filter3,
			@Filter4,
			@Filter1Name,
			@Filter2Name,
			@Filter3Name,
			@Filter4Name

	declare @ms bigint
	declare @dtStart datetime, @dtEnd datetime
	select @dtStart = StartTime from ReadTrace.tblTimeIntervals where TimeInterval = @StartTimeInterval
	select @dtEnd = EndTime from ReadTrace.tblTimeIntervals where TimeInterval = @EndTimeInterval
	select @ms = datediff(dd, @dtStart, @dtEnd) * cast(86400000 as bigint) + datediff(ms, dateadd(dd, datediff(dd, @dtStart, @dtEnd), @dtStart), @dtEnd)
	
	-- Calculate total consumption during the intervals based on batch partial aggs (if we have it) or
	-- stmt aggs if batch-level events weren't captured
	if exists (select * from ReadTrace.tblBatchPartialAggs)
	begin
		select
			@ms as ElapsedMilliseconds,
			sum(TotalCPU) as IntervalCPU,
			sum(TotalDuration) as IntervalDuration,
			sum(TotalReads) as IntervalReads,
			sum(TotalWrites) as IntervalWrites
		from ReadTrace.tblBatchPartialAggs a
		where TimeInterval between @StartTimeInterval and @EndTimeInterval
			and a.AppNameID = isnull(@iAppNameID, a.AppNameID)
			and a.LoginNameID = isnull(@iLoginNameID, a.LoginNameID)
			and a.DBID = isnull(@iDBID, a.DBID)
		option (recompile)
	end
	else
	begin
		select
			@ms as ElapsedMilliseconds,
			sum(TotalCPU) as IntervalCPU,
			sum(TotalDuration) as IntervalDuration,
			sum(TotalReads) as IntervalReads,
			sum(TotalWrites) as IntervalWrites
		from ReadTrace.tblStmtPartialAggs a
		where TimeInterval between @StartTimeInterval and @EndTimeInterval
			and a.AppNameID = isnull(@iAppNameID, a.AppNameID)
			and a.LoginNameID = isnull(@iLoginNameID, a.LoginNameID)
			and a.DBID = isnull(@iDBID, a.DBID)
		option (recompile)
	end
end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_ExampleBatchDetails'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_ExampleBatchDetails
go


CREATE procedure ReadTrace.spReporter_ExampleBatchDetails
	@HashID bigint
as
begin
	set nocount on

	SELECT TOP 1
		ub.NormText,
		ub.OrigText,
		p.[Name] as SpecialProcName, 
		b.ConnId,
		b.Session,
		b.Request,
		convert(varchar(30), b.StartTime, 121) as StartTime,
		convert(varchar(30), b.EndTime, 121) as EndTime,
		b.Reads,
		b.Writes,
		b.CPU,
		b.Duration,
		(select TOP 1 TraceFileName from ReadTrace.tblTraceFiles where FirstSeqNumber <= [b].[BatchSeq] order by FirstSeqNumber desc) as [File]
	from ReadTrace.tblUniqueBatches ub
		join ReadTrace.tblBatches b on ub.Seq = b.BatchSeq
		left join ReadTrace.tblProcedureNames p on ub.SpecialProcID = p.SpecialProcID
	where ub.HashID = @HashID
end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_BatchDetails'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_BatchDetails
go


CREATE procedure ReadTrace.spReporter_BatchDetails 
	@HashID bigint, 
	@StartTimeInterval int = null, 
	@EndTimeInterval int = null,
	@Filter1	nvarchar(256) = null,
	@Filter2	nvarchar(256) = null,
	@Filter3	nvarchar(256) = null,
	@Filter4	nvarchar(256) = null,
	@Filter1Name	nvarchar(64) = null,
	@Filter2Name	nvarchar(64) = null,
	@Filter3Name	nvarchar(64) = null,
	@Filter4Name	nvarchar(64) = null
as
begin
	-- Possible filters to be applied
	declare	@iAppNameID		int
	declare @iLoginNameID		int
	declare @iDBID			int

	exec ReadTrace.spReporter_DetermineFilterValues 
			@StartTimeInterval output,
			@EndTimeInterval output,
			@iDBID output,
			@iAppNameID output,
			@iLoginNameID output,
			@Filter1,
			@Filter2,
			@Filter3,
			@Filter4,
			@Filter1Name,
			@Filter2Name,
			@Filter3Name,
			@Filter4Name


	select min(t.StartTime) as StartTime,
		min(t.EndTime) as EndTime,
		t.TimeInterval,
		sum(isnull(pa.StartingEvents, 0)) as StartingEvents,
		sum(isnull(pa.CompletedEvents, 0)) as CompletedEvents,
		sum(isnull(pa.AttentionEvents, 0)) as Attentions,
		sum(isnull(pa.TotalDuration, 0)) as Duration,
		--min(isnull(pa.MinDuration, 0)) as MinDuration,
		--max(isnull(pa.MaxDuration, 0)) as MaxDuration,
		sum(isnull(pa.TotalCPU, 0)) as CPU,
		--min(isnull(pa.MinCPU, 0)) as MinCPU,
		--max(isnull(pa.MaxCPU, 0)) as MaxCPU,
		sum(isnull(pa.TotalReads, 0)) as Reads,
		--min(isnull(pa.MinReads, 0)) as MinReads,
		--max(isnull(pa.MaxReads, 0)) as MaxReads,
		sum(isnull(pa.TotalWrites, 0)) as Writes
		--min(isnull(pa.MinWrites, 0)) as MinWrites,
		--max(isnull(pa.MaxWrites, 0)) as MaxWrites
	from ReadTrace.tblTimeIntervals t
		left join (select * from ReadTrace.tblBatchPartialAggs 
				where HashID = @HashID
					and DBID = isnull(@iDBID, DBID)
					and AppNameID = isnull(@iAppNameID, AppNameID)
					and LoginNameID = isnull(@iLoginNameID, LoginNameID)
				) as pa  
			on pa.TimeInterval = t.TimeInterval
	where 	    t.TimeInterval >= @StartTimeInterval
		and t.TimeInterval <= @EndTimeInterval
	group by t.TimeInterval
	order by t.TimeInterval
	option(recompile)

end
go



----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_BatchDistinctPlans'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_BatchDistinctPlans
go


CREATE procedure ReadTrace.spReporter_BatchDistinctPlans 
	@HashID bigint, 
	@StartTimeInterval int = null, 
	@EndTimeInterval int = null,
	@Filter1	nvarchar(256) = null,
	@Filter2	nvarchar(256) = null,
	@Filter3	nvarchar(256) = null,
	@Filter4	nvarchar(256) = null,
	@Filter1Name	nvarchar(64) = null,
	@Filter2Name	nvarchar(64) = null,
	@Filter3Name	nvarchar(64) = null,
	@Filter4Name	nvarchar(64) = null
as
begin
	set nocount on

	-- Possible filters to be applied
	declare	@iAppNameID		int
	declare @iLoginNameID		int
	declare @iDBID			int
	declare @plans_collected bit
	declare @multiple_plans_per_batch bit
	declare @query_has_no_plan bit
	declare @dtStart datetime, @dtEnd datetime

	select @plans_collected = 0x1, @multiple_plans_per_batch = 0x0, @query_has_no_plan = 0x0

	-- Exit immediately if they didn't capture showplan/statistics profile
	if not exists (select * from ReadTrace.tblTracedEvents where EventID in (97, 98))
	begin
		PRINT 'No plans collected'
		select @plans_collected = 0x0
		goto exit_now
	end

	exec ReadTrace.spReporter_DetermineFilterValues 
			@StartTimeInterval output,
			@EndTimeInterval output,
			@iDBID output,
			@iAppNameID output,
			@iLoginNameID output,
			@Filter1,
			@Filter2,
			@Filter3,
			@Filter4,
			@Filter1Name,
			@Filter2Name,
			@Filter3Name,
			@Filter4Name

	select @dtStart = StartTime from ReadTrace.tblTimeIntervals where TimeInterval = @StartTimeInterval
	select @dtEnd = EndTime from ReadTrace.tblTimeIntervals where TimeInterval = @EndTimeInterval

	-- If this is a batch which always had a single statement (i.e., one query plan event per batch)
	if exists (select b.BatchSeq, count(*) from ReadTrace.tblBatches as b with (index(tblBatches_HashID))
		join ReadTrace.tblPlans p on p.BatchSeq = b.BatchSeq
			where b.HashID = @HashID
				and b.StartTime >= @dtStart
				and b.EndTime <= @dtEnd
		group by b.BatchSeq
		having count(*) > 1)
	begin
		PRINT 'Multiple plans'
		select @multiple_plans_per_batch = 0x1
		goto exit_now
	end
	else
	begin
		--		Azure does not support select into
		create table #temp
		(
			PlanHashID			bigint,
			Rows				bigint,
			Executes			bigint,
			StmtText			nvarchar(max),
			StmtID				int,
			NodeID				smallint,
			Parent				smallint,
			PhysicalOp			varchar(30),
			LogicalOp			varchar(30),
			Argument			nvarchar(256),
			DefinedValues		nvarchar(256),
			EstimateRows		float,
			EstimateIO			float,
			EstimateCPU			float,
			AvgRowSize			int,
			TotalSubtreeCost	float,
			OutputList			nvarchar(256),
			Warnings			varchar(100),
			Type				varchar(30),
			Parallel			tinyint,
			EstimateExecutions	float,
			RowOrder			smallint,

			--		Aggregates 
			PlanExecutes		bigint, 
			PlanFirstUsed		DateTime, 
			PlanLastUsed		DateTime,
			PlanMinReads		bigint,
			PlanMaxReads		bigint,
			PlanAvgReads		bigint,
			PlanTotalReads		bigint,
			PlanMinWrites		bigint,
			PlanMaxWrites		bigint,
			PlanAvgWrites		bigint,
			PlanTotalWrites		bigint,
			PlanMinCPU			bigint,
			PlanMaxCPU			bigint,
			PlanAvgCPU			bigint,
			PlanTotalCPU		bigint,
			PlanMinDuration		bigint,
			PlanMaxDuration		bigint,
			PlanAvgDuration		bigint,
			PlanTotalDuration	bigint,
			PlanAttnCount	bigint
		)

		-- Then return the plan text, rows, executes information for each plan that was used, as well as 
		-- statistics about the number of times that plan was used, when it was first/last used, IO, CPU 
		-- and usage statistics, etc
		insert into #temp
		select upr.*,
					p.PlanExecutes, 
					p.PlanFirstUsed, 
					p.PlanLastUsed,
					p.PlanMinReads,
					p.PlanMaxReads,
					p.PlanAvgReads,
					p.PlanTotalReads,
					p.PlanMinWrites,
					p.PlanMaxWrites,
					p.PlanAvgWrites,
					p.PlanTotalWrites,
					p.PlanMinCPU,
					p.PlanMaxCPU,
					p.PlanAvgCPU,
					p.PlanTotalCPU,
					p.PlanMinDuration,
					p.PlanMaxDuration,
					p.PlanAvgDuration,
					p.PlanTotalDuration,
					p.PlanAttnCount
		from ReadTrace.tblUniquePlanRows upr
			join (select p.PlanHashID, 
					count_big(b.BatchSeq) as PlanExecutes, 
					min(b.StartTime) as PlanFirstUsed, 
					max(b.StartTime) as PlanLastUsed,
					min(b.Reads) as PlanMinReads,
					max(b.Reads) as PlanMaxReads,
					avg(b.Reads) as PlanAvgReads,
					sum(b.Reads) as PlanTotalReads,
					min(b.Writes) as PlanMinWrites,
					max(b.Writes) as PlanMaxWrites,
					avg(b.Writes) as PlanAvgWrites,
					sum(b.Writes) as PlanTotalWrites,
					min(b.CPU) as PlanMinCPU,
					max(b.CPU) as PlanMaxCPU,
					avg(b.CPU) as PlanAvgCPU,
					sum(b.CPU) as PlanTotalCPU,
					min(b.Duration) as PlanMinDuration,
					max(b.Duration) as PlanMaxDuration,
					avg(b.Duration) as PlanAvgDuration,
					sum(b.Duration) as PlanTotalDuration,
					sum(case when b.AttnSeq is not null then 1 else 0 end) as PlanAttnCount
				from ReadTrace.tblBatches b
					left join ReadTrace.tblPlans p on p.BatchSeq = b.BatchSeq
				where b.HashID = @HashID
					and b.StartTime >= @dtStart
					and b.EndTime <= @dtEnd
				group by p.PlanHashID) as p on p.PlanHashID = upr.PlanHashID
		option (recompile);

		-- Many types of statements may not generate a showplan (e.g., DECLARE, IF (scalar), SET, RETURN, ...)
		-- Still need to ensure that we return a row indicating there is no plan
		if @@rowcount = 0
		begin
			PRINT 'No plan for this query'
			set @query_has_no_plan = 0x1
			goto exit_now
		end

	end

	;with plan_hierarchy as
	(
		select *, 0 as tree_level from #temp t where Parent is null
		union all
		select t.*, tree_level + 1 from #temp t 
			join plan_hierarchy p on t.PlanHashID = p.PlanHashID and t.Parent = p.NodeID
	)
	select 
		@plans_collected as fPlansCollected,
		@multiple_plans_per_batch as fMultiplePlansPerBatch,
		@query_has_no_plan as fQueryHasNoPlan,
		p.PlanHashID, 
		p.PlanExecutes,
		p.PlanFirstUsed, 
		p.PlanLastUsed,
		p.PlanMinReads,
		p.PlanMaxReads,
		p.PlanAvgReads,
		p.PlanTotalReads,
		p.PlanMinWrites,
		p.PlanMaxWrites,
		p.PlanAvgWrites,
		p.PlanTotalWrites,
		p.PlanMinCPU,
		p.PlanMaxCPU,
		p.PlanAvgCPU,
		p.PlanTotalCPU,
		p.PlanMinDuration,
		p.PlanMaxDuration,
		p.PlanAvgDuration,
		p.PlanTotalDuration,
		p.PlanAttnCount,
		p.Warnings,
		p.EstimateRows,
		p.EstimateExecutions,
		p.RowOrder,
		p.tree_level,
		case when patindex(N'%|--%', StmtText) > 0
			then substring(StmtText, patindex(N'%|--%', StmtText) + 3, datalength(StmtText) - patindex(N'%|--%', StmtText) - 3)
			else ltrim(StmtText)
		end as StmtText
	from plan_hierarchy p
	order by p.PlanExecutes desc, p.PlanHashID, p.RowOrder
	return;

exit_now:
	select 
		@plans_collected as fPlansCollected,
		@multiple_plans_per_batch as fMultiplePlansPerBatch,
		@query_has_no_plan as fQueryHasNoPlan,
		cast(NULL as bigint) as PlanHashID, 
		cast(NULL as bigint) as PlanExecutes,
		cast(NULL as datetime) as PlanFirstUsed, 
		cast(NULL as datetime) as PlanLastUsed,
		cast(NULL as bigint) as PlanMinReads,
		cast(NULL as bigint) as PlanMaxReads,
		cast(NULL as bigint) as PlanAvgReads,
		cast(NULL as bigint) as PlanTotalReads,
		cast(NULL as bigint) as PlanMinWrites,
		cast(NULL as bigint) as PlanMaxWrites,
		cast(NULL as bigint) as PlanAvgWrites,
		cast(NULL as bigint) as PlanTotalWrites,
		cast(NULL as bigint) as PlanMinCPU,
		cast(NULL as bigint) as PlanMaxCPU,
		cast(NULL as bigint) as PlanAvgCPU,
		cast(NULL as bigint) as PlanTotalCPU,
		cast(NULL as bigint) as PlanMinDuration,
		cast(NULL as bigint) as PlanMaxDuration,
		cast(NULL as bigint) as PlanAvgDuration,
		cast(NULL as bigint) as PlanTotalDuration,
		cast(NULL as bigint) as PlanAttnCount,
		cast(NULL as varchar(100)) as Warnings,
		cast(NULL as float) as EstimateRows,
		cast(NULL as float) as EstimateExecutions,
		cast(NULL as int) as RowOrder,
		cast(NULL as int) as tree_level,
		cast(NULL as nvarchar(max)) as StmtText
end
go



----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_BatchDetailsScaleFactor'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_BatchDetailsScaleFactor
go


CREATE procedure ReadTrace.spReporter_BatchDetailsScaleFactor 
	@HashID bigint, 
	@StartTimeInterval int = null, 
	@EndTimeInterval int = null,
	@Filter1	nvarchar(256) = null,
	@Filter2	nvarchar(256) = null,
	@Filter3	nvarchar(256) = null,
	@Filter4	nvarchar(256) = null,
	@Filter1Name	nvarchar(64) = null,
	@Filter2Name	nvarchar(64) = null,
	@Filter3Name	nvarchar(64) = null,
	@Filter4Name	nvarchar(64) = null
as
begin
	
	declare @MaxEventCount int

	create table #BatchDetails (
		StartTime datetime, 
		EndTime datetime, 
		TimeInterval int, 
		StartingEvents int, 
		CompletedEvents int, 
		Attentions int, 
		Duration bigint,
		--MinDuration bigint,
		--MaxDuration bigint,
		CPU bigint,
		--MinCPU bigint,
		--MaxCPU bigint,
		Reads bigint, 
		--MinReads bigint,
		--MaxReads bigint,
		Writes bigint
		--MinWrites bigint,
		--MaxWrites bigint
		)

	-- Insert the aggregated batch information for the specified time window into a local temp table
	insert into #BatchDetails exec ReadTrace.spReporter_BatchDetails @HashID, @StartTimeInterval, @EndTimeInterval,
			@Filter1, @Filter2, @Filter3, @Filter4, @Filter1Name, @Filter2Name, @Filter3Name, @Filter4Name
	
	-- I want to make sure that I always chart starting & completed events on the same scale, so that if
	-- their is some divergence in the number (due to longer running queries, blocking, etc) that the two
	-- lines diverge and make this very obvious.  Therefore I get the max of either of these two and use it
	-- as input for scaling in the final query below
	select @MaxEventCount = max(NumberOfEvents) from (
		select max(StartingEvents) as NumberOfEvents from #BatchDetails
		union all
		select max(CompletedEvents) as NumberOfEvents from #BatchDetails) as t


	select
		case when @MaxEventCount <= 100 then 1.0 else ReadTrace.fn_ReporterCalculateScaleFactor(@MaxEventCount) end as StartingEventsScale,
		case when @MaxEventCount <= 100 then 1.0 else ReadTrace.fn_ReporterCalculateScaleFactor(@MaxEventCount) end as CompletedEventsScale,
		case when max(Attentions) <= 100 then 1.0 else ReadTrace.fn_ReporterCalculateScaleFactor(max(Attentions)) end as AttentionEventsScale,
		ReadTrace.fn_ReporterCalculateScaleFactor(max(a.AvgDuration)) as DurationScale,
		ReadTrace.fn_ReporterCalculateScaleFactor(max(a.AvgReads)) as ReadsScale,
		ReadTrace.fn_ReporterCalculateScaleFactor(max(a.AvgWrites)) as WritesScale,
		ReadTrace.fn_ReporterCalculateScaleFactor(max(a.AvgCPU)) as CPUScale,
		max(a.StartingEvents) as MaxStartingEvents,
		max(a.CompletedEvents) as MaxCompletedEvents,
		max(a.Attentions) as MaxAttentionEvents,
		max(a.Duration) as MaxDuration,
		max(a.Reads) as MaxReads,
		max(a.Writes) as MaxWrites,
		max(a.CPU) as MaxCPU
	from (select 
			StartingEvents,
			CompletedEvents,
			Attentions,
			Duration,
			Reads,
			Writes,
			CPU,
			case when CompletedEvents > 0 then CPU / CompletedEvents else null end as AvgCPU,
			case when CompletedEvents > 0 then Duration / CompletedEvents else null end as AvgDuration,
			case when CompletedEvents > 0 then Reads / CompletedEvents else null end as AvgReads,
			case when CompletedEvents > 0 then Writes / CompletedEvents else null end as AvgWrites
		 from #BatchDetails) as a	
end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_BatchDetailsMinMaxAvg'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_BatchDetailsMinMaxAvg
go


CREATE procedure ReadTrace.spReporter_BatchDetailsMinMaxAvg
	@HashID bigint,
	@StartTimeInterval int = null, 
	@EndTimeInterval int = null,
	@Filter1	nvarchar(256) = null,
	@Filter2	nvarchar(256) = null,
	@Filter3	nvarchar(256) = null,
	@Filter4	nvarchar(256) = null,
	@Filter1Name	nvarchar(64) = null,
	@Filter2Name	nvarchar(64) = null,
	@Filter3Name	nvarchar(64) = null,
	@Filter4Name	nvarchar(64) = null
as
begin
	set nocount on

	-- Possible filters to be applied
	declare	@iAppNameID		int
	declare @iLoginNameID	int
	declare @iDBID			int

	exec ReadTrace.spReporter_DetermineFilterValues 
			@StartTimeInterval output,
			@EndTimeInterval output,
			@iDBID output,
			@iAppNameID output,
			@iLoginNameID output,
			@Filter1,
			@Filter2,
			@Filter3,
			@Filter4,
			@Filter1Name,
			@Filter2Name,
			@Filter3Name,
			@Filter4Name

	select 
		min(b.MinReads) as BatchMinReads,
		max(b.MaxReads) as BatchMaxReads,
		sum(b.TotalReads) / sum(b.CompletedEvents) as BatchAvgReads,
		sum(b.TotalReads) as BatchTotalReads,
		min(b.MinWrites) as BatchMinWrites,
		max(b.MaxWrites) as BatchMaxWrites,
		sum(b.TotalWrites) / sum(b.CompletedEvents) as BatchAvgWrites,
		sum(b.TotalWrites) as BatchTotalWrites,
		min(b.MinCPU) as BatchMinCPU,
		max(b.MaxCPU) as BatchMaxCPU,
		sum(b.TotalCPU) / sum(b.CompletedEvents) as BatchAvgCPU,
		sum(b.TotalCPU) as BatchTotalCPU,
		min(b.MinDuration) as BatchMinDuration,
		max(b.MaxDuration) as BatchMaxDuration,
		sum(b.TotalDuration) / sum(b.CompletedEvents) as BatchAvgDuration,
		sum(b.TotalDuration) as BatchTotalDuration
	from ReadTrace.tblBatchPartialAggs b
	where b.HashID = @HashID 
		and b.TimeInterval between @StartTimeInterval and @EndTimeInterval
		and b.DBID = isnull(@iDBID, b.DBID)
		and b.AppNameID = isnull(@iAppNameID, b.AppNameID)
		and b.LoginNameID = isnull(@iLoginNameID, b.LoginNameID)
end
go



----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_Warnings'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_Warnings
go


CREATE procedure ReadTrace.spReporter_Warnings
as
begin
	set nocount on
	
	select WarningMessage, NumberOfTimes, FirstGlobalSeq,       
			fMayAffectCPU, fMayAffectIO, fMayAffectDuration, fAffectsEventAssociation
	  from ReadTrace.tblWarnings
end
go



----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_PartialAggs_GroupBy'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_PartialAggs_GroupBy
go

create procedure ReadTrace.spReporter_PartialAggs_GroupBy
as
begin
	set nocount on

	select 'Application Name' as 'GroupBy', 'AppName' as 'Value'
		union
	select 'Login Name', 'LoginName'
		union
	select 'Database Id', 'DBID'
	order by 1
	
end
go



----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_PartialAggs_OrderBy'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_PartialAggs_OrderBy
go

create procedure ReadTrace.spReporter_PartialAggs_OrderBy
as
begin
	set nocount on

	create table #tbl
	(
		OrderBy	varchar(30) collate database_default NOT NULL,
		Value	varchar(30) collate database_default NOT NULL
	)

	insert into #tbl
		exec ReadTrace.spReporter_PartialAggs_GroupBy


	select * from #tbl
		union
	select 'Reads' as 'OrderBy', 'Reads' as 'Value'
		union
	select 'Reads Desc' , 'Reads Desc'
		union
	select 'Writes', 'Writes'
		union
	select 'Writes Desc', 'Writes Desc'
		union
	select 'CPU', 'CPU'
		union
	select 'CPU Desc', 'CPU Desc'
		union
	select 'Duration', 'Duration'
		union 
	select 'Duration Desc', 'Duration Desc'
		union 
	select 'Batches Started', 'StartingEvents'
		union
	select 'Batches Started Desc', 'StartingEvents Desc'
		union
	select 'Batches Completed', 'CompletedEvents'
		union
	select 'Batches Completed Desc', 'CompletedEvents Desc'
		union
	select 'Attentions', 'Attentions'
		union
	select 'Attentions Desc', 'Attentions Desc'
	order by 1
	
end
go



----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_GetUnitsForDuration'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_GetUnitsForDuration
go

create procedure ReadTrace.spReporter_GetUnitsForDuration
as
begin

	set nocount on

	select case 
			WHEN Value < 9 THEN N'ms'
			ELSE NCHAR(181) + N's'
		end as DurationUnits
	from ReadTrace.tblMiscInfo
	where Attribute = 'EventVersion'	
	
end
go



----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_BatchAggregatesGrouped'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_BatchAggregatesGrouped
go


create procedure ReadTrace.spReporter_BatchAggregatesGrouped
	@StartTimeInterval int,
	@EndTimeInterval int,
	@Group1Field varchar(30),
	@Group1Value nvarchar(256) = null,
	@Group2Field varchar(30) = null,
	@Group2Value nvarchar(256) = null,
	@Group3Field varchar(30) = null
as
begin
	set nocount on

	if(@StartTimeInterval is null)
		select @StartTimeInterval = min(TimeInterval) from ReadTrace.tblTimeIntervals

	if(@EndTimeInterval is null)
		select @EndTimeInterval = max(TimeInterval) from ReadTrace.tblTimeIntervals

	if exists (select * from (select @Group1Field as param_value
								union all 
								select @Group2Field
								union all
								select @Group3Field) as p
		where p.param_value is not null and p.param_value not in ('DBID', 'AppName', 'LoginName'))
	begin
		RAISERROR('ERROR: An invalid grouping parameter was specified', 16, 1)
		return
	end

	declare @column varchar(128)
	declare @select_columns varchar(1000)
	declare @grouping_columns varchar(1000)
	declare @remaining_columns varchar(100)
	declare @query_body varchar(8000)
	declare @param_definition nvarchar(4000)
	declare @filter varchar(8000)

	select @filter = char(13) + char(10)
	select @grouping_columns = char(13) + char(10) + 'GROUP BY '
	select @param_definition = N'@StartTimeInterval int, @EndTimeInterval int, @Group1Value nvarchar(256), @Group2Value nvarchar(256)'
	select @query_body = ',
			sum(StartingEvents) as [StartingEvents],
			sum(CompletedEvents) as [CompletedEvents],
			sum(AttentionEvents) as [Attentions],
			sum(TotalDuration) as [Duration],
			sum(TotalReads) as [Reads],
			sum(TotalWrites) as [Writes],
			sum(TotalCPU) as [CPU]
		from ReadTrace.tblBatchPartialAggs b
			inner join ReadTrace.tblUniqueAppNames a on a.iID = b.AppNameID
			inner join ReadTrace.tblUniqueLoginNames l on l.iID = b.LoginNameID
		where b.TimeInterval between @StartTimeInterval and @EndTimeInterval'

	if @Group1Value is not null
	begin
		select @select_columns = '@Group1Value as [Group1]'

		select @column = case @Group1Field 
				when 'DBID' then 'b.DBID'
				when 'AppName' then 'a.AppName'
				when 'LoginName' then 'l.LoginName'
			end
		select @filter = @filter + 'AND ' + @column + ' = @Group1Value'
	end
	else if @Group1Field is not null
	begin
		select @column = case @Group1Field 
				when 'DBID' then 'b.DBID'
				when 'AppName' then 'a.AppName'
				when 'LoginName' then 'l.LoginName'
			end

		select @select_columns = @column + ' as [Group1]'
		select @grouping_columns = @grouping_columns + @column
		select @remaining_columns = ', NULL as [Group2], NULL as [Group3]'
	end

	if @Group2Value is not null
	begin
		select @select_columns = @select_columns + ', @Group2Value as [Group2]'

		select @column = case @Group2Field 
				when 'DBID' then 'b.DBID'
				when 'AppName' then 'a.AppName'
				when 'LoginName' then 'l.LoginName'
			end
		select @filter = @filter + ' AND ' + @column + ' = @Group2Value'
	end
	else if @Group2Field is not null
	begin
		select @column = case @Group2Field 
				when 'DBID' then 'b.DBID'
				when 'AppName' then 'a.AppName'
				when 'LoginName' then 'l.LoginName'
			end

		select @select_columns = @select_columns + ', ' + @column + ' as [Group2]'
		select @grouping_columns = @grouping_columns + @column
		select @remaining_columns = ', NULL as [Group3]'
	end

	if @Group3Field is not null
	begin
		select @column = case @Group3Field 
				when 'DBID' then 'b.DBID'
				when 'AppName' then 'a.AppName'
				when 'LoginName' then 'l.LoginName'
			end

		select @select_columns = @select_columns + ', ' + @column + ' as [Group3]'
		select @grouping_columns = @grouping_columns + @column
		select @remaining_columns = ''
	end


	declare @final_query nvarchar(max)
	select @final_query = 'SELECT ' + @select_columns + @remaining_columns + @query_body + @filter + @grouping_columns + ' OPTION (RECOMPILE)'
	--select @final_query

	exec sp_executesql @final_query, @param_definition, @StartTimeInterval, @EndTimeInterval, @Group1Value, @Group2Value
end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_GetQueriesAssociatedWithEvent'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_GetQueriesAssociatedWithEvent
go


create procedure ReadTrace.spReporter_GetQueriesAssociatedWithEvent
	@EventID int,							-- the trace_event_id of interest/what queries caused this event
	@StartTimeInterval int,					-- the starting time range of when the EVENT occurred (not when the batch/stmt started)
	@EndTimeInterval int,					-- the ending time range of when the EVENT occurred (not when the batch/stmt completed)
	@TopN int								-- limit result set to this number of queries
as
begin
	declare @dtEventStart datetime, @dtEventEnd datetime
	declare @TotalEvents float
	declare @localEventID int

	if (@StartTimeInterval is null)
	begin
		select @StartTimeInterval = min(TimeInterval) from ReadTrace.tblTimeIntervals
	end
	select @dtEventStart = StartTime from ReadTrace.tblTimeIntervals where TimeInterval = @StartTimeInterval

	if (@EndTimeInterval is null)
	begin
		select @EndTimeInterval = max(TimeInterval) from ReadTrace.tblTimeIntervals
	end
	select @dtEventEnd = EndTime from ReadTrace.tblTimeIntervals where TimeInterval = @EndTimeInterval

	select @TopN = ISNULL(@TopN, 25), @localEventID = @EventID

	select @TotalEvents = count(*) 
	from ReadTrace.tblInterestingEvents 
	where EventID = @EventID
			and ISNULL(EndTime, StartTime) between @dtEventStart and @dtEventEnd

	--
	-- Not all events can be associated with a query (e.g., server memory change) so NULLable HashIDs are necessary
	--
	declare @AffectedQueries table (BatchHashID bigint null, StmtHashID bigint null, NumberOfEvents bigint not null, StmtText nvarchar(max) null)

	--
	--	Attentions are important enough that I have precomputed this info.  Also normal matching rules
	--	wouldn't work anyway because attention event shows up AFTER the completed event
	--
	if @EventID = 16
	begin
		insert into @AffectedQueries (BatchHashID, StmtHashID, NumberOfEvents) 
			select top (@TopN)
				b.HashID as BatchHashID,
				s.HashID as StmtHashID,
				count(*)
			from ReadTrace.tblBatches b
				join ReadTrace.tblInterestingEvents i on b.AttnSeq = i.Seq
				left join ReadTrace.tblStatements s on s.AttnSeq = b.AttnSeq
			where b.AttnSeq is not null
				and i.StartTime between @dtEventStart and @dtEventEnd
			group by b.HashID, s.HashID
			order by count(*) desc
	end
	else if @EventID in (
			37, /* SP:Recompile */
			58, /* Autostats */ 
			166 /* SQL:StmtRecompile */)
	begin
		--
		-- In general these events fire before the associated *Starting event and there isn't a very reliable
		-- way via query to associate to stmt-level event due to nestlevel and various other quirks, especially
		-- if SP:StmtStarting wasn't captured
		--
		insert into @AffectedQueries (BatchHashID, StmtHashID, NumberOfEvents) 
			select top (@TopN)
				b.HashID as BatchHashID, 
				NULL as StmtHashID, 
				count(*)
--				case when @EventID = 166 then i.TextData			-- SQL:StmtRecompile has the text of the query in the event itself
--					else NULL
--				end as StmtText
			from ReadTrace.tblInterestingEvents i
				left join ReadTrace.tblBatches b on b.BatchSeq = i.BatchSeq
			where i.EventID = @EventID
				and ISNULL(i.EndTime, i.StartTime) between @dtEventStart and @dtEventEnd
			group by b.HashID
			order by count(*) desc	
	end
	else
	begin
		-- All other events.  Assumption is that they happen on the same Session and the event's sequence number is
		-- between the startseq and endseq for the associated statement
		insert into @AffectedQueries (BatchHashID, StmtHashID, NumberOfEvents) 
			select top (@TopN)
				y.HashID as BatchHashID, 
				z.HashID as StmtHashID, 
				count(*)
			from 
				(select
					i.BatchSeq,
					(select top 1 StmtSeq from ReadTrace.tblStatements where BatchSeq = i.BatchSeq
							and i.Seq between isnull(StartSeq, 0) and isnull(EndSeq, 9223372036854775807) order by isnull(StartSeq, 0) desc, isnull(EndSeq, 9223372036854775807) asc) as StmtSeq 
				from ReadTrace.tblInterestingEvents i
				where i.EventID = @EventID 
					and ISNULL(i.EndTime, i.StartTime) between @dtEventStart and @dtEventEnd) as x
			left join ReadTrace.tblBatches y on y.BatchSeq = x.BatchSeq
			left join ReadTrace.tblStatements z on z.StmtSeq = x.StmtSeq
			group by y.HashID, z.HashID
			order by count(*) desc	
	end

	select t.NumberOfEvents,
		case when @TotalEvents > 0 then t.NumberOfEvents / @TotalEvents else 0.0 end as PctOfEvents,
		t.BatchHashID,
		ub.NormText as BatchTemplate,
		t.StmtHashID,
		coalesce(t.StmtText, us.NormText) as StmtTemplate
	from @AffectedQueries as t
		left join ReadTrace.tblUniqueBatches ub on ub.HashID = t.BatchHashID
		left join ReadTrace.tblUniqueStatements us on us.HashID = t.StmtHashID
end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_TopStatementsInBatch'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_TopStatementsInBatch
go


create procedure ReadTrace.spReporter_TopStatementsInBatch
	@StartTimeInterval int,					-- the starting time range of when the associated batch completed
	@EndTimeInterval int,					-- the ending time range of when the associated batch completed
	@HashID bigint,							-- show resource usage for batches with this hashid
	@TopN int,								-- limit result set to this number of queries per tree-level in the hierarchy
	@OrderBy varchar(20)					-- what to order by (CPU | Duration | Reads | Writes)
as
begin
	declare @dtEventStart datetime, @dtEventEnd datetime

	if (@StartTimeInterval is null)
	begin
		select @StartTimeInterval = min(TimeInterval) from ReadTrace.tblTimeIntervals
	end
	select @dtEventStart = StartTime from ReadTrace.tblTimeIntervals where TimeInterval = @StartTimeInterval

	if (@EndTimeInterval is null)
	begin
		select @EndTimeInterval = max(TimeInterval) from ReadTrace.tblTimeIntervals
	end
	select @dtEventEnd = EndTime from ReadTrace.tblTimeIntervals where TimeInterval = @EndTimeInterval

	select @TopN = ISNULL(@TopN, 3)

	--
	-- This select is a relatively quick and efficient way to get the TopN statements from all nestlevels 
	-- associated with this batch.  But just because it was TopN at its own nestlevel doesn't mean that it is 
	-- part of the tree of most expensive statements though.  Consider this example:
	--		PROCA
	--			SELECT 1
	--			SELECT 2
	--			SELECT 3
	--			EXEC PROCB
	--				SELECT 4
	--				EXEC PROCC
	--					SELECT 5
	-- Let's assume that TopN = 3.  This initial query will return the TopN statements from all three procs (a, b, c).
	-- If TopN=3, and SELECT 1, SELECT 2 and SELECT 3 have higher usage than the cumulative usage of PROCB then it is 
	-- irrelevant what usage was for statements in PROCB and nested PROCC since it isn't in the TopN at the highest 
	-- level. All of these nested statements which don't have a parent statement in the TopN at the higher level will 
	-- be filtered out in the final CTE below
	--
	-- NOTE: If a statement with the same HashID has different ParentHashIDs (same query shows up in multiple procs, or the
	-- same proc is called from multiple places) the report viewer control's recursive hierarchy detection first seems to
	-- group on the specified column and looses any that have other parent grouping column value.  To avoid having rows
	-- disappear I create a unique row_id to use for the hierarchy grouping
	--
	--	drop table #u
	create table #u
	(
		ParentHashID		bigint,
		HashID				bigint,
		NestLevel			int,
		Executes			bigint,
		CPU					bigint,
		Duration			bigint,
		Reads				bigint,
		Writes				bigint,
		ordering_column		nvarchar(128),
		rank_at_nestlevel	bigint,
		row_id				bigint
	)
	
	insert into #u
		select *, row_number() over (order by HashID) as row_id 
	from (select t.*,
				row_number() over (partition by ParentHashID, NestLevel order by ordering_column desc) as rank_at_nestlevel
			from
			(select
				s2.HashID as ParentHashID,
				s.HashID,
				s.NestLevel,
				count_big(*) as Executes,
				sum(s.CPU) as CPU,
				sum(s.Duration) as Duration,
				sum(s.Reads) as Reads,
				sum(s.Writes) as Writes,
				case when @OrderBy = 'CPU' then sum(s.CPU)
					when @OrderBy = 'Duration' then sum(s.Duration)
					when @OrderBy = 'Reads' then sum(s.Reads)
					when @OrderBy = 'Writes' then sum(s.Writes)
					when @OrderBy = 'Executes' then count(*)
					else NULL
				end as ordering_column
			from ReadTrace.tblStatements s
				join ReadTrace.tblBatches b on s.BatchSeq = b.BatchSeq
				left join ReadTrace.tblStatements s2 on s.ParentStmtSeq = s2.StmtSeq
			where b.HashID = @HashID
				and s.EndSeq is not null									-- recompile and XStmtFlush may cause SP:StmtStarting, SP:StmtStarting, SP:StmtCompleted and we only want to count as one execute
				and b.EndTime between @dtEventStart and @dtEventEnd			-- batch had to complete to show up on batch details report
			group by s2.HashID, s.HashID, s.NestLevel) as t
		where isnull(ordering_column, 1) > 0) as u
	where rank_at_nestlevel <= @TopN

--	select * from #u
/*	if not exists (select * from #u where ParentHashID is not null)
	begin
		-- create a fake row to use as "parent" for each nestlevel, then link them up
		insert into #u (NestLevel) select distinct NestLevel from #u
	end
*/

	-- Define CTE to walk the hierarchy so as to only show statements who have a parent in the TopN at a higher level
	;with stmt_hierarchy as
	(
		select cast(NULL as bigint) as parent_id, 
			row_id, 
			ParentHashID, 
			HashID, 
			Executes, 
			CPU, 
			Duration, 
			Reads, 
			Writes, 
			rank_at_nestlevel,
			NestLevel,
			ordering_column
		from #u 
		where ParentHashID is NULL

		union all 

		select
			h.row_id as parent_id, 
			u.row_id, 
			u.ParentHashID, 
			u.HashID, 
			u.Executes, 
			u.CPU, 
			u.Duration, 
			u.Reads, 
			u.Writes, 
			u.rank_at_nestlevel, 
			u.NestLevel,
			u.ordering_column
		from #u as u
			join stmt_hierarchy h on u.ParentHashID = h.HashID 
		where u.NestLevel > h.NestLevel		-- nestlevel may skip, but child must have higher nestlevel or you can have infinite recursion
	)

	-- Final results, including the normalized text for the statements
	select 
		h.row_id,
		h.parent_id,
		h.ParentHashID,
		h.HashID, 
		h.Executes,
		h.CPU,
		h.Duration,
		h.Reads,
		h.Writes,
		h.rank_at_nestlevel,
		h.NestLevel,
--		h.ordering_column,
		us1.NormText as ParentNormText,
		us2.NormText as NormText
	from stmt_hierarchy h
		left join ReadTrace.tblUniqueStatements us1 on h.ParentHashID = us1.HashID
		left join ReadTrace.tblUniqueStatements us2 on h.HashID = us2.HashID
	order by ordering_column desc

end
go



----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_ExampleStmtDetails'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_ExampleStmtDetails
go


CREATE procedure ReadTrace.spReporter_ExampleStmtDetails
	@HashID bigint
as
begin
	set nocount on

	SELECT TOP 1
		us.NormText,
		us.OrigText, 
		s.ConnId,
		s.Session,
		s.Request,
		convert(varchar(30), s.StartTime, 121) as StartTime,
		convert(varchar(30), s.EndTime, 121) as EndTime,
		s.Reads,
		s.Writes,
		s.CPU,
		s.Duration,
		(select TOP 1 TraceFileName from ReadTrace.tblTraceFiles where FirstSeqNumber <= [s].[StmtSeq] order by FirstSeqNumber desc) as [File]
	from ReadTrace.tblUniqueStatements us
		join ReadTrace.tblStatements s on us.Seq = s.StmtSeq
	where us.HashID = @HashID
end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_StmtDetails'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_StmtDetails
go


CREATE procedure ReadTrace.spReporter_StmtDetails 
	@HashID bigint, 
	@StartTimeInterval int = null, 
	@EndTimeInterval int = null,
	@Filter1	nvarchar(256) = null,
	@Filter2	nvarchar(256) = null,
	@Filter3	nvarchar(256) = null,
	@Filter4	nvarchar(256) = null,
	@Filter1Name	nvarchar(64) = null,
	@Filter2Name	nvarchar(64) = null,
	@Filter3Name	nvarchar(64) = null,
	@Filter4Name	nvarchar(64) = null
as
begin
	-- Possible filters to be applied
	declare	@iAppNameID		int
	declare @iLoginNameID		int
	declare @iDBID			int

	exec ReadTrace.spReporter_DetermineFilterValues 
			@StartTimeInterval output,
			@EndTimeInterval output,
			@iDBID output,
			@iAppNameID output,
			@iLoginNameID output,
			@Filter1,
			@Filter2,
			@Filter3,
			@Filter4,
			@Filter1Name,
			@Filter2Name,
			@Filter3Name,
			@Filter4Name


	select min(t.StartTime) as StartTime,
		min(t.EndTime) as EndTime,
		t.TimeInterval,
		sum(isnull(pa.StartingEvents, 0)) as StartingEvents,
		sum(isnull(pa.CompletedEvents, 0)) as CompletedEvents,
/*		sum(isnull(pa.AttentionEvents, 0)) */ 0 as Attentions,
		sum(isnull(pa.TotalDuration, 0)) as Duration,
		sum(isnull(pa.TotalCPU, 0)) as CPU,
		sum(isnull(pa.TotalReads, 0)) as Reads,
		sum(isnull(pa.TotalWrites, 0)) as Writes
	from ReadTrace.tblTimeIntervals t
		left join (select * from ReadTrace.tblStmtPartialAggs 
				where HashID = @HashID
--					and DBID = isnull(@iDBID, DBID)
--					and AppNameID = isnull(@iAppNameID, AppNameID)
--					and LoginNameID = isnull(@iLoginNameID, LoginNameID)
				) as pa  
			on pa.TimeInterval = t.TimeInterval
	where 	    t.TimeInterval >= @StartTimeInterval
		and t.TimeInterval <= @EndTimeInterval
	group by t.TimeInterval
	order by t.TimeInterval
	option(recompile)

end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_StmtDetailsScaleFactor'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_StmtDetailsScaleFactor
go


CREATE procedure ReadTrace.spReporter_StmtDetailsScaleFactor 
	@HashID bigint, 
	@StartTimeInterval int = null, 
	@EndTimeInterval int = null,
	@Filter1	nvarchar(256) = null,
	@Filter2	nvarchar(256) = null,
	@Filter3	nvarchar(256) = null,
	@Filter4	nvarchar(256) = null,
	@Filter1Name	nvarchar(64) = null,
	@Filter2Name	nvarchar(64) = null,
	@Filter3Name	nvarchar(64) = null,
	@Filter4Name	nvarchar(64) = null
as
begin
	declare @MaxEventCount int

	create table #StmtDetails (
		StartTime datetime, 
		EndTime datetime, 
		TimeInterval int, 
		StartingEvents int, 
		CompletedEvents int, 
		Attentions int, 
		Duration bigint, 
		CPU bigint,
		Reads bigint, 
		Writes bigint)

	-- Insert the aggregated batch information for the specified time window into a local temp table
	insert into #StmtDetails exec ReadTrace.spReporter_StmtDetails @HashID, @StartTimeInterval, @EndTimeInterval,
			@Filter1, @Filter2, @Filter3, @Filter4, @Filter1Name, @Filter2Name, @Filter3Name, @Filter4Name
	
	-- I want to make sure that I always chart starting & completed events on the same scale, so that if
	-- their is some divergence in the number (due to longer running queries, blocking, etc) that the two
	-- lines diverge and make this very obvious.  Therefore I get the max of either of these two and use it
	-- as input for scaling in the final query below
	select @MaxEventCount = max(NumberOfEvents) from (
		select max(StartingEvents) as NumberOfEvents from #StmtDetails
		union all
		select max(CompletedEvents) as NumberOfEvents from #StmtDetails) as t


	select 
		case when @MaxEventCount <= 100 then 1 else ReadTrace.fn_ReporterCalculateScaleFactor(@MaxEventCount) end as StartingEventsScale,
		case when @MaxEventCount <= 100 then 1 else ReadTrace.fn_ReporterCalculateScaleFactor(@MaxEventCount) end as CompletedEventsScale,
		case when max(Attentions) <= 100 then 1 else ReadTrace.fn_ReporterCalculateScaleFactor(max(Attentions)) end as AttentionEventsScale,
		ReadTrace.fn_ReporterCalculateScaleFactor(max(a.AvgDuration)) as DurationScale,
		ReadTrace.fn_ReporterCalculateScaleFactor(max(a.AvgReads)) as ReadsScale,
		ReadTrace.fn_ReporterCalculateScaleFactor(max(a.AvgWrites)) as WritesScale,
		ReadTrace.fn_ReporterCalculateScaleFactor(max(a.AvgCPU)) as CPUScale,
		max(a.StartingEvents) as MaxStartingEvents,
		max(a.CompletedEvents) as MaxCompletedEvents,
/*		max(a.Attentions) */ NULL as MaxAttentionEvents,
		max(a.Duration) as MaxDuration,
		max(a.Reads) as MaxReads,
		max(a.Writes) as MaxWrites,
		max(a.CPU) as MaxCPU
	from (select 
			StartingEvents,
			CompletedEvents,
			Attentions,
			Duration,
			Reads,
			Writes,
			CPU,
			case when CompletedEvents > 0 then CPU / CompletedEvents else null end as AvgCPU,
			case when CompletedEvents > 0 then Duration / CompletedEvents else null end as AvgDuration,
			case when CompletedEvents > 0 then Reads / CompletedEvents else null end as AvgReads,
			case when CompletedEvents > 0 then Writes / CompletedEvents else null end as AvgWrites
		 from #StmtDetails) as a
		 
end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_StmtDetailsMinMaxAvg'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_StmtDetailsMinMaxAvg
go


CREATE procedure ReadTrace.spReporter_StmtDetailsMinMaxAvg
	@HashID bigint,
	@StartTimeInterval int = null, 
	@EndTimeInterval int = null,
	@Filter1	nvarchar(256) = null,
	@Filter2	nvarchar(256) = null,
	@Filter3	nvarchar(256) = null,
	@Filter4	nvarchar(256) = null,
	@Filter1Name	nvarchar(64) = null,
	@Filter2Name	nvarchar(64) = null,
	@Filter3Name	nvarchar(64) = null,
	@Filter4Name	nvarchar(64) = null
as
begin
	set nocount on

	-- Possible filters to be applied
	declare	@iAppNameID		int
	declare @iLoginNameID	int
	declare @iDBID			int

	exec ReadTrace.spReporter_DetermineFilterValues 
			@StartTimeInterval output,
			@EndTimeInterval output,
			@iDBID output,
			@iAppNameID output,
			@iLoginNameID output,
			@Filter1,
			@Filter2,
			@Filter3,
			@Filter4,
			@Filter1Name,
			@Filter2Name,
			@Filter3Name,
			@Filter4Name

	select 
		min(s.MinReads) as StmtMinReads,
		max(s.MaxReads) as StmtMaxReads,
		sum(s.TotalReads) / sum(s.CompletedEvents) as StmtAvgReads,
		sum(s.TotalReads) as StmtTotalReads,
		min(s.MinWrites) as StmtMinWrites,
		max(s.MaxWrites) as StmtMaxWrites,
		sum(s.TotalWrites) / sum(s.CompletedEvents) as StmtAvgWrites,
		sum(s.TotalWrites) as StmtTotalWrites,
		min(s.MinCPU) as StmtMinCPU,
		max(s.MaxCPU) as StmtMaxCPU,
		sum(s.TotalCPU) / sum(s.CompletedEvents) as StmtAvgCPU,
		sum(s.TotalCPU) as StmtTotalCPU,
		min(s.MinDuration) as StmtMinDuration,
		max(s.MaxDuration) as StmtMaxDuration,
		sum(s.TotalDuration) / sum(s.CompletedEvents) as StmtAvgDuration,
		sum(s.TotalDuration) as StmtTotalDuration
	from ReadTrace.tblStmtPartialAggs s
	where s.HashID = @HashID 
		and s.TimeInterval between @StartTimeInterval and @EndTimeInterval
		and s.DBID = isnull(@iDBID, s.DBID)
		and s.AppNameID = isnull(@iAppNameID, s.AppNameID)
		and s.LoginNameID = isnull(@iLoginNameID, s.LoginNameID)
	option (recompile)
end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_StmtDistinctPlans'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_StmtDistinctPlans
go


CREATE procedure ReadTrace.spReporter_StmtDistinctPlans 
	@HashID bigint, 
	@StartTimeInterval int = null, 
	@EndTimeInterval int = null,
	@Filter1	nvarchar(256) = null,
	@Filter2	nvarchar(256) = null,
	@Filter3	nvarchar(256) = null,
	@Filter4	nvarchar(256) = null,
	@Filter1Name	nvarchar(64) = null,
	@Filter2Name	nvarchar(64) = null,
	@Filter3Name	nvarchar(64) = null,
	@Filter4Name	nvarchar(64) = null
as
begin
	set nocount on

	-- Possible filters to be applied
	declare	@iAppNameID		int
	declare @iLoginNameID		int
	declare @iDBID			int
	declare @plans_collected bit
	declare @query_has_no_plan bit
	declare @dtStart datetime, @dtEnd datetime

	select @plans_collected = 0x1, @query_has_no_plan = 0x0

	-- Exit immediately if they didn't capture showplan/statistics profile
	if not exists (select * from ReadTrace.tblTracedEvents where EventID in (97, 98))
	begin
		PRINT 'No plans collected'
		set @plans_collected = 0x0
		goto exit_now
	end

	exec ReadTrace.spReporter_DetermineFilterValues 
			@StartTimeInterval output,
			@EndTimeInterval output,
			@iDBID output,
			@iAppNameID output,
			@iLoginNameID output,
			@Filter1,
			@Filter2,
			@Filter3,
			@Filter4,
			@Filter1Name,
			@Filter2Name,
			@Filter3Name,
			@Filter4Name

	select @dtStart = StartTime from ReadTrace.tblTimeIntervals where TimeInterval = @StartTimeInterval
	select @dtEnd = EndTime from ReadTrace.tblTimeIntervals where TimeInterval = @EndTimeInterval

	-- Then return the plan text, rows, executes information for each plan that was used, as well as 
	-- statistics about the number of times that plan was used, when it was first/last used, IO, CPU 
	-- and usage statistics, etc
		--		Azure does not support select into
		create table #temp
		(
			PlanHashID			bigint,
			Rows				bigint,
			Executes			bigint,
			StmtText			nvarchar(max),
			StmtID				int,
			NodeID				smallint,
			Parent				smallint,
			PhysicalOp			varchar(30),
			LogicalOp			varchar(30),
			Argument			nvarchar(256),
			DefinedValues		nvarchar(256),
			EstimateRows		float,
			EstimateIO			float,
			EstimateCPU			float,
			AvgRowSize			int,
			TotalSubtreeCost	float,
			OutputList			nvarchar(256),
			Warnings			varchar(100),
			Type				varchar(30),
			Parallel			tinyint,
			EstimateExecutions	float,
			RowOrder			smallint,

			--		Aggregates 
			PlanExecutes		bigint, 
			PlanFirstUsed		DateTime, 
			PlanLastUsed		DateTime,
			PlanMinReads		bigint,
			PlanMaxReads		bigint,
			PlanAvgReads		bigint,
			PlanTotalReads		bigint,
			PlanMinWrites		bigint,
			PlanMaxWrites		bigint,
			PlanAvgWrites		bigint,
			PlanTotalWrites		bigint,
			PlanMinCPU			bigint,
			PlanMaxCPU			bigint,
			PlanAvgCPU			bigint,
			PlanTotalCPU		bigint,
			PlanMinDuration		bigint,
			PlanMaxDuration		bigint,
			PlanAvgDuration		bigint,
			PlanTotalDuration	bigint,
			PlanAttnCount	bigint
		)

	insert into #temp
	select upr.*,
				p.PlanExecutes, 
				p.PlanFirstUsed, 
				p.PlanLastUsed,
				p.PlanMinReads,
				p.PlanMaxReads,
				p.PlanAvgReads,
				p.PlanTotalReads,
				p.PlanMinWrites,
				p.PlanMaxWrites,
				p.PlanAvgWrites,
				p.PlanTotalWrites,
				p.PlanMinCPU,
				p.PlanMaxCPU,
				p.PlanAvgCPU,
				p.PlanTotalCPU,
				p.PlanMinDuration,
				p.PlanMaxDuration,
				p.PlanAvgDuration,
				p.PlanTotalDuration,
				p.PlanAttnCount
	from ReadTrace.tblUniquePlanRows upr
		join (select p.PlanHashID,
				count_big(b.BatchSeq) as PlanExecutes, 
				min(b.StartTime) as PlanFirstUsed, 
				max(b.StartTime) as PlanLastUsed,
				min(b.Reads) as PlanMinReads,
				max(b.Reads) as PlanMaxReads,
				avg(b.Reads) as PlanAvgReads,
				sum(b.Reads) as PlanTotalReads,
				min(b.Writes) as PlanMinWrites,
				max(b.Writes) as PlanMaxWrites,
				avg(b.Writes) as PlanAvgWrites,
				sum(b.Writes) as PlanTotalWrites,
				min(b.CPU) as PlanMinCPU,
				max(b.CPU) as PlanMaxCPU,
				avg(b.CPU) as PlanAvgCPU,
				sum(b.CPU) as PlanTotalCPU,
				min(b.Duration) as PlanMinDuration,
				max(b.Duration) as PlanMaxDuration,
				avg(b.Duration) as PlanAvgDuration,
				sum(b.Duration) as PlanTotalDuration,
				sum(case when b.AttnSeq is not null then 1 else 0 end) as PlanAttnCount
			from ReadTrace.tblStatements b
				left join ReadTrace.tblPlans p on p.StmtSeq = b.StmtSeq
			where b.HashID = @HashID
				and b.StartTime >= @dtStart
				and b.EndTime <= @dtEnd
			group by p.PlanHashID) as p on p.PlanHashID = upr.PlanHashID
	option (recompile);

	-- Many types of statements may not generate a showplan (e.g., DECLARE, IF (scalar), SET, RETURN, ...)
	-- Still need to ensure that we return a row indicating there is no plan
	if @@rowcount = 0
	begin
		PRINT 'Query has no plan'
		set @query_has_no_plan = 0x1
		goto exit_now
	end

	;with plan_hierarchy as
	(
		select *, 0 as tree_level from #temp t where Parent is null
		union all
		select t.*, tree_level + 1 from #temp t 
			join plan_hierarchy p on t.PlanHashID = p.PlanHashID and t.Parent = p.NodeID
	)
	select 
		@plans_collected as fPlansCollected,
		@query_has_no_plan as fQueryHasNoPlan,
		p.PlanHashID, 
		p.PlanExecutes,
		p.PlanFirstUsed, 
		p.PlanLastUsed,
		p.PlanMinReads,
		p.PlanMaxReads,
		p.PlanAvgReads,
		p.PlanTotalReads,
		p.PlanMinWrites,
		p.PlanMaxWrites,
		p.PlanAvgWrites,
		p.PlanTotalWrites,
		p.PlanMinCPU,
		p.PlanMaxCPU,
		p.PlanAvgCPU,
		p.PlanTotalCPU,
		p.PlanMinDuration,
		p.PlanMaxDuration,
		p.PlanAvgDuration,
		p.PlanTotalDuration,
		p.PlanAttnCount,
		p.Warnings,
		p.EstimateRows,
		p.EstimateExecutions,
		p.RowOrder,
		p.tree_level,
		case when patindex(N'%|--%', StmtText) > 0
			then substring(StmtText, patindex(N'%|--%', StmtText) + 3, datalength(StmtText) - patindex(N'%|--%', StmtText) - 3)
			else ltrim(StmtText)
		end as StmtText
	from plan_hierarchy p
	order by p.PlanExecutes desc, p.PlanHashID, p.RowOrder
	return;

exit_now:
	select 
		@plans_collected as fPlansCollected,
		@query_has_no_plan as fQueryHasNoPlan,
		cast(NULL as bigint) as PlanHashID, 
		cast(NULL as bigint) as PlanExecutes,
		cast(NULL as datetime) as PlanFirstUsed, 
		cast(NULL as datetime) as PlanLastUsed,
		cast(NULL as bigint) as PlanMinReads,
		cast(NULL as bigint) as PlanMaxReads,
		cast(NULL as bigint) as PlanAvgReads,
		cast(NULL as bigint) as PlanTotalReads,
		cast(NULL as bigint) as PlanMinWrites,
		cast(NULL as bigint) as PlanMaxWrites,
		cast(NULL as bigint) as PlanAvgWrites,
		cast(NULL as bigint) as PlanTotalWrites,
		cast(NULL as bigint) as PlanMinCPU,
		cast(NULL as bigint) as PlanMaxCPU,
		cast(NULL as bigint) as PlanAvgCPU,
		cast(NULL as bigint) as PlanTotalCPU,
		cast(NULL as bigint) as PlanMinDuration,
		cast(NULL as bigint) as PlanMaxDuration,
		cast(NULL as bigint) as PlanAvgDuration,
		cast(NULL as bigint) as PlanTotalDuration,
		cast(NULL as bigint) as PlanAttnCount,
		cast(NULL as varchar(100)) as Warnings,
		cast(NULL as float) as EstimateRows,
		cast(NULL as float) as EstimateExecutions,
		cast(NULL as int) as RowOrder,
		cast(NULL as int) as tree_level,
		cast(NULL as nvarchar(max)) as StmtText
end
go



----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_StmtTopN'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_StmtTopN
go

create procedure ReadTrace.spReporter_StmtTopN
	@StartTimeInterval int = null,
	@EndTimeInterval int = null,
	@TopN int = null,
	@Filter1	nvarchar(256) = null,
	@Filter2	nvarchar(256) = null,
	@Filter3	nvarchar(256) = null,
	@Filter4	nvarchar(256) = null,
	@Filter1Name	nvarchar(64) = null,
	@Filter2Name	nvarchar(64) = null,
	@Filter3Name	nvarchar(64) = null,
	@Filter4Name	nvarchar(64) = null
as
begin
	set nocount on

	-- Possible filters to be applied
	declare	@iAppNameID		int
	declare @iLoginNameID		int
	declare @iDBID			int

	if @TopN is null set @TopN = 10

	exec ReadTrace.spReporter_DetermineFilterValues 
			@StartTimeInterval output,
			@EndTimeInterval output,
			@iDBID output,
			@iAppNameID output,
			@iLoginNameID output,
			@Filter1,
			@Filter2,
			@Filter3,
			@Filter4,
			@Filter1Name,
			@Filter2Name,
			@Filter3Name,
			@Filter4Name

	--	Use the row_number and order by's to get list the # of entries that match
	--	Since unique row only returned 1 time this works like a large set of unions
	select *,
		row_number() over(order by CPU desc) as QueryNumber
	from (
		select 	a.HashID,
			sum(CompletedEvents) as Executes,
		    sum(TotalCPU) as CPU,
			sum(TotalDuration) as Duration,
			sum(TotalReads) as Reads,
			sum(TotalWrites) as Writes,
			sum(AttentionEvents) as Attentions, 
			(select StartTime from ReadTrace.tblTimeIntervals i where TimeInterval = @StartTimeInterval) as [StartTime],
			(select EndTime from ReadTrace.tblTimeIntervals i where TimeInterval = @EndTimeInterval) as [EndTime],
			(select cast(NormText as nvarchar(4000)) from ReadTrace.tblUniqueStatements s where s.HashID = a.HashID) as [NormText],
		       	row_number() over(order by sum(TotalCPU) desc) as CPUDesc,
		       	row_number() over(order by sum(TotalCPU) asc) as CPUAsc,
		       	row_number() over(order by sum(TotalDuration) desc) as DurationDesc,
		       	row_number() over(order by sum(TotalDuration) asc) as DurationAsc,
		       	row_number() over(order by sum(TotalReads) desc) as ReadsDesc,
		       	row_number() over(order by sum(TotalReads) asc) as ReadsAsc,
				row_number() over(order by sum(TotalWrites) desc) as WritesDesc,
		       	row_number() over(order by sum(TotalWrites) asc) as WritesAsc
			from ReadTrace.tblStmtPartialAggs a
				where TimeInterval between @StartTimeInterval and @EndTimeInterval
--					and a.AppNameID = isnull(@iAppNameID, a.AppNameID)
--					and a.LoginNameID = isnull(@iLoginNameID, a.LoginNameID)
					and a.DBID = isnull(@iDBID, a.DBID)
			group by a.HashID
		       ) as Outcome
		where 	(CPUDesc <= @TopN 
			or CPUAsc <= @TopN
			or DurationDesc <= @TopN 
			or DurationAsc <= @TopN
			or ReadsDesc <= @TopN 
			or ReadsAsc <= @TopN
			or WritesDesc <= @TopN 
			or WritesAsc <= @TopN)
		order by CPU desc
		option (recompile)
end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_GetModulesContainingStatement'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_GetModulesContainingStatement
go

create procedure ReadTrace.spReporter_GetModulesContainingStatement
	@HashID bigint,
	@StartTimeInterval int = null,
	@EndTimeInterval int = null,
	@Filter1	nvarchar(256) = null,
	@Filter2	nvarchar(256) = null,
	@Filter3	nvarchar(256) = null,
	@Filter4	nvarchar(256) = null,
	@Filter1Name	nvarchar(64) = null,
	@Filter2Name	nvarchar(64) = null,
	@Filter3Name	nvarchar(64) = null,
	@Filter4Name	nvarchar(64) = null
as
begin
	set nocount on

	declare @iDBID			int
	declare	@iAppNameID		int
	declare @iLoginNameID	int
	declare @dtEventStart datetime, @dtEventEnd datetime
	declare @crlf nvarchar(2)
	declare @cmd nvarchar(max)

	select @crlf = char(13) + char(10)

	if (@StartTimeInterval is null)
	begin
		select @StartTimeInterval = min(TimeInterval) from ReadTrace.tblTimeIntervals
	end
	select @dtEventStart = StartTime from ReadTrace.tblTimeIntervals where TimeInterval = @StartTimeInterval

	if (@EndTimeInterval is null)
	begin
		select @EndTimeInterval = max(TimeInterval) from ReadTrace.tblTimeIntervals
	end
	select @dtEventEnd = EndTime from ReadTrace.tblTimeIntervals where TimeInterval = @EndTimeInterval

	exec ReadTrace.spReporter_DetermineFilterValues 
			NULL,
			NULL,
			@iDBID output,
			@iAppNameID output,
			@iLoginNameID output,
			@Filter1,
			@Filter2,
			@Filter3,
			@Filter4,
			@Filter1Name,
			@Filter2Name,
			@Filter3Name,
			@Filter4Name

	select @cmd = N'select 
	distinct upper(p.Name) as ModuleName
from ReadTrace.tblProcedureNames p
	join ReadTrace.tblStatements s on p.DBID = s.DBID and p.ObjectID = s.ObjectID'

	if @iAppNameID is not null or @iLoginNameID is not null
	begin
		select @cmd = @cmd + @crlf + N'	join ReadTrace.tblConnections c on s.ConnSeq = c.ConnSeq and s.Session = c.Session'

		if @iAppNameID is not null
			select @cmd = @cmd + @crlf + N'	join ReadTrace.tblUniqueAppNames ua on ua.AppName = c.ApplicationName'

		if @iLoginNameID is not null
			select @cmd = @cmd + @crlf + N'	join ReadTrace.tblUniqueLoginNames ul on ul.LoginName = c.LoginName'
	end

	select @cmd = @cmd + @crlf + N'where s.HashID = @HashID
		and coalesce(s.EndTime, s.StartTime) between @dtEventStart and @dtEventEnd'

	if @iDBID is not null
		select @cmd = @cmd + @crlf + N'		and s.DBID = @iDBID'

	if @iAppNameID is not null
		select @cmd = @cmd + @crlf + N'		and ua.iID = @iAppNameID'

	if @iLoginNameID is not null
		select @cmd = @cmd + @crlf + N'		and ul.iID = @iLoginNameID'

/*	select @cmd, @HashID,
		@dtEventStart,
		@dtEventEnd,
		@iDBID,
		@iAppNameID,
		@iLoginNameID
*/
		
	exec sp_executesql @cmd, 
		N'@HashID bigint, @dtEventStart datetime, @dtEventEnd datetime, @iDBID int, @iAppNameID int, @iLoginNameID int',
		@HashID,
		@dtEventStart,
		@dtEventEnd,
		@iDBID,
		@iAppNameID,
		@iLoginNameID

end
go



----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_DTASample'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_DTASample
go

--	ReadTrace.spReporter_DTASample 3492714307520456998
create procedure ReadTrace.spReporter_DTASample
	@HashID bigint
as
begin
	--	select * from ReadTrace.tblBatches
	--		TODO: May need to wind this together with connection options
	select TextData
	from
		(select TextData ,
				Duration,
				row_number() over(order by [Duration] desc) as DurationMaxRank,
				row_number() over(order by [Duration] asc) as DurationMinRank,
				row_number() over(order by [CPU] desc) as CPUMaxRank,
				row_number() over(order by [CPU] asc) as CPUMinRank,
				row_number() over(order by [Reads] desc) as ReadsMaxRank,
				row_number() over(order by [Reads] asc) as ReadsMinRank,
				row_number() over(order by [Writes] desc) as WritesMaxRank,
				row_number() over(order by [Writes] asc) as WritesMinRank
			from ReadTrace.tblBatches
			where HashID = @HashID and TextData is not null) as Outcome
		where (		    DurationMaxRank <= 5
					 or DurationMinRank <= 5
					 or	CPUMaxRank <= 5
					 or CPUMinRank <= 5
					 or	ReadsMaxRank <= 5
					 or ReadsMinRank <= 5
					 or	WritesMaxRank <= 5
					 or WritesMinRank <= 5
				 )

	union all

		select TextData 
			from ReadTrace.tblBatches
				TABLESAMPLE (2 PERCENT)
				REPEATABLE (205)		
			where HashID = @HashID and TextData is not null
		

end
go


----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_BatchISQL'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_BatchISQL
go

create procedure ReadTrace.spReporter_BatchISQL
	@HashID bigint
as
begin
	select OrigText from ReadTrace.tblUniqueBatches
		where HashID = @HashID
end
go

----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_StatementISQL'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_StatementISQL
go

create procedure ReadTrace.spReporter_StatementISQL
	@HashID bigint
as
begin
	select OrigText from ReadTrace.tblUniqueStatements
		where HashID = @HashID
end
go



--**********************************************************************
--		Comparison Report Objects
--
--		APR 2008 - RDORR - VERSION 1
--				I decided to use small peices to build the report
--				so as we went through a beta we can take feedback and
--				change dynamically without large re-works and eventually
--				combine these into more sophisticated queries
--**********************************************************************

----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_Compare_Overview_BatchUniqueHashInfo'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_Compare_Overview_BatchUniqueHashInfo
go

create procedure ReadTrace.spReporter_Compare_Overview_BatchUniqueHashInfo
as
begin
	set nocount on

	select 'Matching' as [Desc],
			count_big(*) as [Count]
			from ReadTrace.tblUniqueBatches b
			inner join ReadTraceCompare.tblUniqueBatches c
				on b.HashID = c.HashID
	
	union all
		select 'BO' as [Desc],
				count_big(*) 
				from ReadTrace.tblUniqueBatches b
				left outer join ReadTraceCompare.tblUniqueBatches c
					on b.HashID = c.HashID
				where c.HashID is NULL

	union all
		select 'CO' as [Desc],
				count_big(*) 
				from ReadTrace.tblUniqueBatches b
				right outer join ReadTraceCompare.tblUniqueBatches c
					on b.HashID = c.HashID
				where b.HashID is NULL
	order by [Desc]
end 
go

----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_Overview_Counts'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_Overview_Counts
go

-- ReadTrace.spReporter_Overview_Counts 'TotalReads'
create procedure ReadTrace.spReporter_Overview_Counts
		@strColumn	sysname
as
begin
	set nocount on

	declare @strCmd		nvarchar(max)

	set @strCmd = 
	'select	''B'' as [Type],
			sum([b.@strColumn]) as [Value]
		from ReadTrace.tblComparisonBatchPartialAggs
			where [b.HashID] is NOT NULL and [c.HashID] is NOT NULL

	union all
	select	''C'',
			sum([c.@strColumn])
		from ReadTrace.tblComparisonBatchPartialAggs
		where [b.HashID] is NOT NULL and [c.HashID] is NOT NULL

	union all
	select	 ''BO'',
			sum([b.@strColumn]) 
		from ReadTrace.tblComparisonBatchPartialAggs
		where [c.HashID] is NULL 

	union all 
	select	''CO'',
			sum([c.@strColumn]) 
		from ReadTrace.tblComparisonBatchPartialAggs
		where [b.HashID] is NULL '

	set @strCmd = replace(@strCmd, '@strColumn', @strColumn);
	exec sp_executesql @strCmd

end
go

----------------------------------------------------------------------------------------------
if objectproperty(object_id('ReadTrace.spReporter_Compare_TopN'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_Compare_TopN
go

/*
 *	PROCEDURE: ReadTrace.spReporter_Compare_TopN
 *
 *	PURPOSE:
 *	When running Reporter in comparison mode, this procedure is called to find the queries
 *	that ran ONLY in the baseline database or ONLY in the comparison database, then do a TOP N
 *	over those to see which were the most expensive queries unique to a given workload
 *
 *	PARAMETERS:
 *		@strDBSchema		the schema where we want to find the queries that only exist there and not the other workload
 *								Ex: If strDBSchema is 'ReadTrace' (baseline) then return queries which only ran in the baseline DB
 *								Ex: If strDBSchema is 'ReadTraceCompare' (comparison) then return queries which only ran in the comparison DB
 *		@TopN				Limit to top N queries of each category (reads/writes/cpu/duration)
 *
 *	NOTES:
 *	This is expected to be called from the context of the baseline database (that is the DB we are connected
 *	to when running the ReadTrace_CompareMain report).
 *
 */ 
create procedure ReadTrace.spReporter_Compare_TopN
	@strDBSchema sysname,
	@TopN int = NULL								-- limit result set to this number of queries per tree-level in the hierarchy
as
begin
	set nocount on

	declare @strCmd		nvarchar(max)
	declare @strSchemaWhereNotRun sysname;

	if @strDBSchema not in ('ReadTrace', 'ReadTraceCompare')
	begin
		raiserror('Schema name must either be ''ReadTrace'' (baseline) or ''ReadTraceCompare'' (comparison)', 16, 1);
		return 0;
	end
	
	if @TopN is null set @TopN = 10

	select @strSchemaWhereNotRun = case 
		when @strDBSchema = 'ReadTrace' then 'ReadTraceCompare' 
		else 'ReadTrace'
	end;

	
	set @strCmd = 

	'select 
		row_number() over(order by [CPU] desc, HashID asc) as QueryNumber,
		Executes, HashID, Text, CPU, Duration, Reads, Writes 
	from 
	(
		select * from
		(
			select 
				*,
				row_number() over(order by CPU desc) as CPURank,
				row_number() over(order by Reads desc) as ReadsRank,
				row_number() over(order by Writes desc) as WritesRank,
				row_number() over(order by Duration desc) as DurationRank
			from
				(
					-- Aggregate detail data all those queries that appeared in one workload/schema
					-- but don''t appear in tblUniqueBatches of the other schema (i.e. they didn''t run over there)
					select pa.[HashID] as [HashID],
						(select NormText from @strDBSchema.tblUniqueBatches s where s.HashID = pa.[HashID]) as [Text],
						sum(pa.CompletedEvents) as [Executes],
						sum(pa.TotalCPU) as [CPU],
						sum(pa.TotalDuration) as [Duration],
						sum(pa.TotalReads) as [Reads],
						sum(pa.TotalWrites) as [Writes]
						from @strDBSchema.tblBatchPartialAggs pa
							left join @strSchemaWhereNotRun.tblUniqueBatches ub on pa.HashID = ub.HashID
						where ub.HashID is NULL
						group by pa.HashID
				) as Outcome
		) as t
		where
			CPURank <= @TopN
		or  ReadsRank <= @TopN
		or  WritesRank <= @TopN
		or  DurationRank <= @TopN

	) as Final
	order by [CPU] desc, HashID'

	set @strCmd = replace(@strCmd, '@strDBSchema', @strDBSchema);
	set @strCmd = replace(@strCmd, '@strSchemaWhereNotRun', @strSchemaWhereNotRun);
	
	--print @strCmd
	exec sp_executesql @strCmd, N'@TopN int', @TopN

end
go


----------------------------------------------------------------------------------------------
--	The Diff is calculated as TotalActual - (projected total)
--	so the ones we want are when the value is positive where
--	the projected from the baseline is less than actual used
if objectproperty(object_id('ReadTrace.spReporter_Overview_TopN'), 'IsProcedure') = 1
	drop procedure ReadTrace.spReporter_Overview_TopN
go

-- ReadTrace.spReporter_Overview_TopN  
create procedure ReadTrace.spReporter_Overview_TopN
		@TopN int = NULL								-- limit result set to this number of queries per tree-level in the hierarchy
as
begin
	set nocount on

	if @TopN is null set @TopN = 10

	select Outcome.HashID,
			Outcome.[b.CompletedEvents],
			Outcome.[c.CompletedEvents],
			Outcome.[b.TotalCPU],
			Outcome.[c.TotalCPU],
			Outcome.[b.TotalReads],
			Outcome.[c.TotalReads],
			Outcome.[b.TotalWrites],
			Outcome.[c.TotalWrites],
			Outcome.[b.TotalDuration],
			Outcome.[c.TotalDuration],
			ProjectedCPUDiff,
			ProjectedReadsDiff,
			ProjectedWritesDiff,
			ProjectedDurationDiff,
			ActualEventDiff,
			row_number() over(order by ProjectedCPUDiff desc) as QueryNumber,
			u.NormText
	from (	select 
				[b.HashID] as HashID,
				[b.CompletedEvents],
				[c.CompletedEvents],
				[b.TotalCPU],
				[c.TotalCPU],
				[b.TotalReads],
				[c.TotalReads],
				[b.TotalWrites],
				[c.TotalWrites],
				[b.TotalDuration],
				[c.TotalDuration],
				([c.CompletedEvents] - [b.CompletedEvents]) as [ActualEventDiff],
				ProjectedCPUDiff,
				ProjectedReadsDiff,
				ProjectedWritesDiff,
				ProjectedDurationDiff,
				row_number() over(order by ProjectedCPUDiff desc) as CPUDesc,
				row_number() over(order by ProjectedReadsDiff desc) as ReadsDesc,
				row_number() over(order by ProjectedWritesDiff desc) as WritesDesc,
				row_number() over(order by ProjectedDurationDiff desc) as DurationDesc,
				row_number() over(order by abs(([c.CompletedEvents] - [b.CompletedEvents])) desc) as EventDesc
			from ReadTrace.tblComparisonBatchPartialAggs
				where [b.HashID] is not null 
					and [c.HashID] is not null
		) as Outcome 
			inner join ReadTrace.tblUniqueBatches u on u.HashID = Outcome.HashID
		where
			CPUDesc <= @TopN
		or	ReadsDesc <= @TopN
		or	WritesDesc <= @TopN
		or	DurationDesc <= @TopN
		or	EventDesc <= @TopN
		
		order by QueryNumber	--	Default ordering

end
go


