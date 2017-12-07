
create PROCEDURE dbo.st_SelectPAGEs(@Object_ID Int,  @Qtde_Pages Int = 100, @Table_Name Varchar(30) = Null)
AS
BEGIN
/*
Original Version: John Huang's

Revised by: Fabiano Neves Amorim
http://fabianosqlserver.spaces.live.com/

Use:

DECLARE @i Int
SET @i = Object_ID('<TABELA>')

EXEC dbo.st_SelectPAGEs @Object_ID = @i, @Qtde_Pages = 10000
*/

  BEGIN TRY
    SET NOCOUNT ON
      
    IF NOT EXISTS(SELECT 1 FROM sysobjects where id = @Object_ID)
    BEGIN
      RAISERROR 30002 'Specified object do not exists';
    END

    if @Table_Name is null
        Begin
		set @Table_Name = '##Temp_Debug_' + Cast(@@Spid as varchar)
	End

	BEGIN TRY
		DECLARE @SQ VARCHAR(500)

		SET @SQ = 'DROP TABLE ' + @Table_Name

		EXEC (@SQ)
	END TRY
	BEGIN CATCH
	END CATCH
   
    DECLARE @SQL VarChar(Max),
            @PageFID SmallInt, 
            @PagePID Integer
      
    CREATE TABLE #DBCC_IND_SQL2005_2008(ROWID           Integer IDENTITY(1,1) PRIMARY KEY, 
                                        PageFID         SmallInt, 
                                        PagePID         Integer, 
                                        IAMFID          Integer, 
                                        IAMPID          Integer, 
                                        ObjectID        Integer,
                                        IndexID         Integer,
                                        PartitionNumber BigInt,
                                        PartitionID     BigInt, 
                                        Iam_Chain_Type  VarChar(80), 
                                        PageType        Integer,
                                        IndexLevel      Integer,
                                        NexPageFID      Integer,
                                        NextPagePID     Integer,
                                        PrevPageFID     Integer,
                                        PrevPagePID     Integer)
                           
    CREATE TABLE #DBCC_IND_SQL2000(ROWID           Integer IDENTITY(1,1) PRIMARY KEY, 
                                   PageFID         SmallInt, 
                                   PagePID         Integer, 
                                   IAMFID          Integer, 
                                   IAMPID          Integer, 
                                   ObjectID        Integer,
                                   IndexID         Integer,
                                   PageType        Integer,
                                   IndexLevel      Integer,
                                   NexPageFID      Integer,
                                   NextPagePID     Integer,
                                   PrevPageFID     Integer,
                                   PrevPagePID     Integer)    
    
    CREATE TABLE #DBCC_Page(ROWID        Integer IDENTITY(1,1) PRIMARY KEY, 
                            ParentObject VarChar(500),
                            Object       VarChar(500), 
                            Field        VarChar(500), 
                            Value        VarChar(Max))

    CREATE TABLE #Results(ROWID     Integer PRIMARY KEY, 
                            Page      VarChar(100), 
                            Slot      VarChar(300), 
                            Object    VarChar(300), 
                            FieldName VarChar(300), 
                            Value     VarChar(6000))

    CREATE TABLE #Columns(ColumnID Integer PRIMARY KEY, 
                          Name     VarChar(800))

    INSERT INTO #Columns
    SELECT ColID, 
           Name
      FROM syscolumns
     WHERE id = @Object_ID

    SELECT @SQL = 'DBCC IND(' + QUOTENAME(DB_NAME()) + 
                   ', ' + 
                   CONVERT(VarChar(20), @Object_ID) +
                   ', 1) WITH NO_INFOMSGS'

--    PRINT @SQL

    DBCC TRACEON(3604) WITH NO_INFOMSGS
    
    IF @@Version LIKE 'SQL Server 2000%'
    BEGIN
      INSERT INTO #DBCC_IND_SQL2000
      EXEC(@SQL)

      INSERT INTO #DBCC_IND_SQL2005_2008
      SELECT ROWID,
             PageFID,
             PagePID,
             IAMFID,
             IAMPID,
             ObjectID,
             IndexID,
             0,
             0,
             '',
             PageType,
             IndexLevel,
             NexPageFID,
             NextPagePID,
             PrevPageFID,
             PrevPagePID
        FROM #DBCC_IND_SQL2000
    END
    ELSE
    BEGIN
      INSERT INTO #DBCC_IND_SQL2005_2008
      EXEC (@SQL)
    END
    
    DECLARE cCursor CURSOR FOR
    SELECT TOP (@Qtde_Pages)
           PageFID, 
           PagePID 
      FROM #DBCC_IND_SQL2005_2008 
     WHERE PageType = 1

    OPEN cCursor

    FETCH NEXT FROM cCursor INTO @PageFID, @PagePID 

    WHILE @@FETCH_STATUS = 0
    BEGIN
      DELETE #DBCC_Page
      
      SELECT @SQL = 'DBCC PAGE ('  + 
                     QUOTENAME(DB_NAME()) + ',' + 
                     CONVERT(VarChar(20), @PageFID) + 
                     ',' + 
                     CONVERT(VarChar(20), @PagePID) + 
                     ', 3) WITH TABLERESULTS, NO_INFOMSGS '
--      PRINT @SQL
      
      INSERT INTO #DBCC_Page
      EXEC (@SQL)
      
      DELETE FROM #DBCC_Page 
       WHERE Object NOT LIKE 'Slot %' 
          OR Field = '' 
          OR Field IN ('Record Type', 'Record Attributes') 
          OR ParentObject in ('PAGE HEADER:')
      
      INSERT INTO #Results
      SELECT ROWID, cast(@PageFID as VarChar(20)) + ':' + CAST(@PagePID as VarChar(20)), ParentObject, Object, Field, Value FROM #DBCC_Page

      FETCH NEXT FROM cCursor INTO @PageFID, @PagePID 
    END
    
    CLOSE cCursor
    DEALLOCATE cCursor

	UPDATE #RESULTS
	SET value = null
	WHERE value = '[NULL]'
    
--    SELECT * FROM #Results

    SELECT @SQL = '
    SELECT ' + 
    STUFF(CAST((SELECT ',' + QuoteName(Name)
                  FROM #Columns 
                 Order By ColumnID For Xml Path('')) AS VarChar(MAX)), 1,1,'')+'
	INTO	' +  @Table_Name + '
    FROM (SELECT CONVERT(VarChar(20), Page) + CONVERT(VarChar(500),Slot) p, FieldName x_FieldName_x, Value x_Value_x FROM #Results) Tab
    PIVOT(MAX(Tab.x_Value_x) FOR Tab.x_FieldName_x IN( ' 
          + STUFF((SELECT ',' + QuoteName(Name) FROM #Columns Order By ColumnID For Xml Path('')), 1,1,'') + ' )
    ) AS pvt
    
    SELECT * FROM ' +  @Table_Name

    --PRINT @SQL
    EXEC (@SQL)

    SELECT 'SELECT * FROM ' +  @Table_Name

  END TRY
  BEGIN CATCH
    -- Execute error retrieval routine.
    SELECT ERROR_NUMBER()    AS ErrorNumber,
           ERROR_SEVERITY()  AS ErrorSeverity,
           ERROR_STATE()     AS ErrorState,
           ERROR_PROCEDURE() AS ErrorProcedure,
           ERROR_LINE()      AS ErrorLine,
           ERROR_MESSAGE()   AS ErrorMessage;
  END CATCH;
END
GO