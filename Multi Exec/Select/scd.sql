
SELECT 'FOR %%A IN (*.SQL) DO ( sqlcmd -S ' + '177.185.9.173' + ' -d ' + name + '  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB' + Cast(ROW_NUMBER() OVER(ORDER BY database_id) + 54 as varchar(30)) + '.txt" -I )' + char(13) + char(10)+ char(13) + char(10)
FROM	sys.databases
WHERE	database_id > 4