CREATE EVENT SESSION [Timeouts] ON SERVER
ADD EVENT sqlserver.sql_batch_completed (
    ACTION (sqlserver.session_id)
    WHERE ([result] <> (2))),
ADD EVENT sqlserver.sql_batch_starting (
    ACTION (sqlserver.session_id))
ADD TARGET package0.pair_matching (SET begin_event = N'sqlserver.sql_batch_starting',
                                   begin_matching_actions = N'sqlserver.session_id',
                                   begin_matching_columns = N'batch_text',
                                   end_event = N'sqlserver.sql_batch_completed',
                                   end_matching_actions = N'sqlserver.session_id',
                                   end_matching_columns = N'batch_text')
WITH (MAX_MEMORY = 4096 KB,
      EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
      MAX_DISPATCH_LATENCY = 30 SECONDS,
      MAX_EVENT_SIZE = 0 KB,
      MEMORY_PARTITION_MODE = NONE,
      TRACK_CAUSALITY = ON,
      STARTUP_STATE = OFF)
GO