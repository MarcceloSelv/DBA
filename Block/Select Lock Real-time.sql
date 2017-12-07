WITH blocking_info AS
(
    SELECT
        [blocker] = wait.blocking_session_id,
        [waiter] = lock.request_session_id,
        b_handle = br.[sql_handle],
        w_handle = wr.[sql_handle],
        [dbid] = lock.resource_database_id,
        duration = wait.wait_duration_ms / 1000,
        lock_type = lock.resource_type,
        lock_mode = block.request_mode
    FROM
        sys.dm_tran_locks AS lock
    INNER JOIN 
        sys.dm_os_waiting_tasks AS wait
        ON lock.lock_owner_address = wait.resource_address
    INNER JOIN
        sys.dm_exec_requests AS br
        ON wait.blocking_session_id = br.session_id
    INNER JOIN
        sys.dm_exec_requests AS wr
        ON lock.request_session_id = wr.session_id
    INNER JOIN 
        sys.dm_tran_locks AS block
        ON block.request_session_id = br.session_id
    WHERE
        block.request_owner_type = 'TRANSACTION'
)
SELECT
    [database] = DB_NAME(bi.[dbid]),
    bi.blocker,
    blocker_command = bt.[text],
    bi.waiter,
    waiter_command  = wt.[text],
    [duration MM:SS] = RTRIM(bi.duration / 60) + ':' 
        + RIGHT('0' + RTRIM(bi.duration % 60), 2),
    bi.lock_type,
    bi.lock_mode
FROM
    blocking_info AS bi
CROSS APPLY
    sys.dm_exec_sql_text(bi.b_handle) AS bt
CROSS APPLY
    sys.dm_exec_sql_text(bi.w_handle) AS wt;