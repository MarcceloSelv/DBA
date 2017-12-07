DECLARE @TableName nvarchar(255)
DECLARE MyTableCursor Cursor
FOR 
SELECT name FROM sys.tables WHERE [type] = 'U' and name <> 'sysdiagrams' ORDER BY name 
OPEN MyTableCursor

FETCH NEXT FROM MyTableCursor INTO @TableName
WHILE @@FETCH_STATUS = 0
    BEGIN
    EXEC ScriptCreateTableKeys @TableName
    print 'go'

    FETCH NEXT FROM MyTableCursor INTO @TableName
END
CLOSE MyTableCursor
DEALLOCATE MyTableCursor