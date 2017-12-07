SELECT	*
FROM	sys.server_event_sessions es
	Inner join sys.server_event_session_actions esa on esa.event_session_id = es.event_session_id
	Inner join sys.server_event_session_events ese on ese.event_session_id = es.event_session_id
	Inner join sys.server_event_session_fields esf on esf.event_session_id = es.event_session_id
	Inner join sys.server_event_session_targets est on est.event_session_id = es.event_session_id

select * from sys.server_event_session_events

--sys.server_event_sessions sys.server_event_session_actions sys.server_event_session_events sys.server_event_session_fields sys.server_event_session_targets

-- dm_xe_sessions st 
--	JOIN sys.dm_xe_sessions s
--            ON s.address = st.event_session_address
--WHERE	name = 'TrackResourceWaits' 
--	AND target_name = 'ring_buffer'

Select * from sys.dm_xe_sessions s


SELECT sessions.name AS SessionName, sevents.package as PackageName, 
sevents.name AS EventName, 
sevents.predicate, sactions.name AS ActionName, stargets.name AS TargetName 
FROM sys.server_event_sessions sessions 
INNER JOIN sys.server_event_session_events sevents 
ON sessions.event_session_id = sevents.event_session_id 
INNER JOIN sys.server_event_session_actions sactions
ON sessions.event_session_id = sactions.event_session_id 
INNER JOIN sys.server_event_session_targets stargets 
ON sessions.event_session_id = stargets.event_session_id 
WHERE sessions.name = 'MonitorExpensiveQuery' 

