select request_session_id, * from sys.dm_tran_locks where resource_associated_entity_id = OBJECT_ID('Resultados') and resource_database_id = DB_ID()
select * from sys.dm_exec_sessions


dbcc inputbuffer (52)

exec sp_who2 52 -- will give you some info

exec sp_who2  52 -- will give you some info
exec sp_who2  55

--SELECT * FROM sys.dm_exec_requests

INSERT INTO LOG_RESULTADOS
VALUES(GETDATE(), @COMANDO)

SELECT @ID = SCOPE_IDENTITY()

INSERT ...


UPDATE LOG_RESULTADOS SET DATA_FIM = GETDATE() WHERE ID = @ID