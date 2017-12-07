
-- Extended events default session
if exists(select * from sys.server_event_sessions where name='system_health')
	drop event session system_health on server
go
-- The predicates in this session have been carefully crafted to minimize impact of event collection
-- Changing the predicate definition may impact system performance
--
create event session system_health on server
add event sqlserver.error_reported
(
	action (package0.callstack, sqlserver.session_id, sqlserver.sql_text, sqlserver.tsql_stack, package0.collect_system_time)
	-- Get callstack, SPID, and query for all high severity errors ( above sev 20 )
	where severity >= 20
	-- Get callstack, SPID, and query for OOM errors ( 17803 , 701 , 802 , 8645 , 8651 , 8657 , 8902 )
	or (error = 17803 or error = 701 or error = 802 or error = 8645 or error = 8651 or error = 8657 or error = 8902)
),
add event sqlos.scheduler_monitor_non_yielding_ring_buffer_recorded,
add event sqlserver.xml_deadlock_report,
add event sqlos.wait_info
(
	action (package0.callstack, sqlserver.session_id, sqlserver.sql_text, package0.collect_system_time)
	where 
	(duration > 15000 and 
		(	
			(wait_type > 31	-- Waits for latches and important wait resources (not locks ) that have exceeded 15 seconds. 
				and
				(
					(wait_type > 47 and wait_type < 54)
					or wait_type < 38
					or (wait_type > 63 and wait_type < 70)
					or (wait_type > 96 and wait_type < 100)
					or (wait_type = 107)
					or (wait_type = 113)
					or (wait_type > 174 and wait_type < 179)
					or (wait_type = 186)
					or (wait_type = 207)
					or (wait_type = 269)
					or (wait_type = 283)
					or (wait_type = 284)
				)
			)
			or 
			(duration > 20000		-- Waits for locks that have exceeded 30 secs.
				and wait_type < 22
			) 
		)
	)
),
add event sqlos.wait_info_external
(
	action (package0.callstack, sqlserver.session_id, sqlserver.sql_text, package0.collect_system_time)
	where 
	(duration > 5000 and
		(   
			(	-- Login related preemptive waits that have exceeded 5 seconds.
				(wait_type > 365 and wait_type < 372)
				or	(wait_type > 372 and wait_type < 377)
				or	(wait_type > 377 and wait_type < 383)
				or	(wait_type > 420 and wait_type < 424)
				or	(wait_type > 426 and wait_type < 432)
				or	(wait_type > 432 and wait_type < 435)
			)
			or 
			(duration > 25000 	-- Preemptive OS waits that have exceeded 45 seconds. 
				and 
				(	
					(wait_type > 382 and wait_type < 386)
					or	(wait_type > 423 and wait_type < 427)
					or	(wait_type > 434 and wait_type < 437)
					or	(wait_type > 442 and wait_type < 451)
					or	(wait_type > 451 and wait_type < 473)
					or	(wait_type > 484 and wait_type < 499)
					or wait_type = 365
					or wait_type = 372
					or wait_type = 377
					or wait_type = 387
					or wait_type = 432
					or wait_type = 502
				)
			)
		)
	)
)
add target package0.asynchronous_file_target      -- Store events on disk (in the LOG folder of the instance)
(
set filename           = N'system_health2.xel',
        max_file_size      = 5, /* MB */
        max_rollover_files = 4
),
add target package0.ring_buffer		-- Store events in the ring buffer target
	(set max_memory = 4096)
with (startup_state = on)
go

    if not exists (select * from sys.dm_xe_sessions where name = 'system_health')
        alter event session system_health on server state=start
    go