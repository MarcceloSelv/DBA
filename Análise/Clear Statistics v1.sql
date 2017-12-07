USE [Master];

GO

 

SET NOCOUNT ON;

 

-- Table to hold all auto stats and their DROP statements
DROP TABLE #commands
GO
CREATE TABLE #commands

       (
       Database_Name        SYSNAME,
       Table_Name              SYSNAME,
       Stats_Name               SYSNAME,
       cmd                            NVARCHAR(4000),

       CONSTRAINT    PK_#commands
              PRIMARY KEY CLUSTERED      (
			Database_Name,
			Table_Name,
			Stats_Name
		)

       );

 

-- A cursor to browse all user databases

DECLARE Databases CURSOR

FOR

SELECT [name]

FROM   sys.databases

WHERE  database_id = 7;

 DECLARE       @Database_Name SYSNAME,

                        @cmd NVARCHAR(4000);


OPEN Databases;

FETCH NEXT FROM Databases INTO @Database_Name;

 

WHILE @@FETCH_STATUS = 0
BEGIN

-- Create all DROP statements for the database
	SET @cmd =    'SELECT       N''' + @Database_Name + ''',
                       so.name,
                       ss.name,
                       N''DROP STATISTICS [''
                       + ssc.name
                        +'']''
                       +''.[''
                       + so.name
                       +'']''
                       + ''.[''
                       + ss.name
			+ ''];''
			FROM ['     + @Database_Name + '].sys.stats AS ss
			INNER JOIN ['
			       + @Database_Name + '].sys.objects AS so
			       ON ss.[object_id] = so.[object_id]
			       INNER JOIN ['
			      + @Database_Name + '].sys.schemas AS ssc
			      ON so.schema_id = ssc.schema_id
                     WHERE         ss.auto_created = 1
                                           AND
                                           so.is_ms_shipped = 0';
--SELECT @cmd -- DEBUG

-- Execute and store in temp table

       INSERT INTO #commands

              EXECUTE       (@cmd);

-- Next Database

       FETCH NEXT FROM Databases

              INTO   @Database_Name;


CLOSE Databases
DEALLOCATE Databases
END;

GO

SELECT* FROM #commands