SET ANSI_NULLS OFF
SET ANSI_DEFAULTS OFF
/*
If Object_ID('sp_sig_tamanho_tabelas', 'P') Is Not Null
        Drop Procedure sp_sig_tamanho_tabelas
*/
go
 
 
 
-- sp_sig_tamanho_tabelas 'data'
create procedure sp_sig_tamanho_tabelas
                @Ordem Varchar(30) = 'data'
as
 
declare @id    int            -- The object id that takes up space
    ,@type    character(2) -- The object type.
    ,@pages    bigint            -- Working variable for size calc.
    ,@dbsize bigint
    ,@logsize bigint
    ,@reservedpages  bigint
    ,@usedpages  bigint
    ,@rowCount bigint
        ,@objname nvarchar(776)
        ,@sql        varchar(4000)
 
        Set @Ordem = ltrim(rtrim(@Ordem))
        if @Ordem not in ('name','rows','reserved','data','index_size','unused')
           begin 
                RAISERROR('Valor do parametro invalido. deve ser ''name'',''rows'',''reserved'',''data'',''index_size'' ou ''unused''', 16, 1)
                return (0)
           end
 
        set nocount on
 
        Create Table #Temp_Tables
        (
                vname        varchar(130) Null,
                vrows        bigint Null,
                vreserved    bigint Null,
                vdata        bigint Null,
                vindex_size  bigint Null,
                vunused      bigint Null
        )
        
        Declare Temp_tables_cursor Insensitive Cursor For
            Select         
                    name 
            From sysobjects 
            where type='U'
        
        Open Temp_tables_cursor
                
        Fetch Next From Temp_tables_cursor Into @objname
        
        While (@@Fetch_Status = 0)
           Begin
                        Set @pages = 0
                        Set @dbsize = 0
                        Set @logsize = 0
                        Set @reservedpages = 0
                        Set @usedpages = 0
                        Set @rowCount = 0
                                
                    /*
                    **  Try to find the object.
                    */
                    SELECT @id = object_id, @type = type FROM sys.objects WHERE object_id = object_id(@objname)
                
                    -- Translate @id to internal-table for queue
                    IF @type = 'SQ'
                        SELECT @id = object_id FROM sys.internal_tables WHERE parent_id = @id and internal_type = 201 --ITT_ServiceQueue
                
                
                    /*
                    ** Now calculate the summary data. 
                    *  Note that LOB Data and Row-overflow Data are counted as Data Pages.
                    */
                    SELECT 
                        @reservedpages = SUM (reserved_page_count),
                        @usedpages = SUM (used_page_count),
                        @pages = SUM (
                            CASE
                                WHEN (index_id < 2) THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count)
                                ELSE lob_used_page_count + row_overflow_used_page_count
                            END
                            ),
                        @rowCount = SUM (
                            CASE
                                WHEN (index_id < 2) THEN row_count
                                ELSE 0
                            END
                            )
                    FROM sys.dm_db_partition_stats
                    WHERE object_id = @id;
                
                    /*
                    ** Check if table has XML Indexes or Fulltext Indexes which use internal tables tied to this table
                    */
                    IF (SELECT count(*) FROM sys.internal_tables WHERE parent_id = @id AND internal_type IN (202,204)) > 0 
                    BEGIN
                        /*
                        **  Now calculate the summary data. Row counts in these internal tables don't 
                        **  contribute towards row count of original table.  
                        */
                     SELECT 
                            @reservedpages = @reservedpages + sum(reserved_page_count),
                            @usedpages = @usedpages + sum(used_page_count)
                        FROM sys.dm_db_partition_stats p, sys.internal_tables it
                        WHERE it.parent_id = @id AND it.internal_type IN (202,204) AND p.object_id = it.object_id;
                    END
                
                    
 
                Insert Into #Temp_Tables
                (
                        vname        ,
                        vrows        ,
                        vreserved    ,
                        vdata        ,
                        vindex_size  ,
                        vunused      
                )
                Values
                (
                        OBJECT_NAME (@id),
                        @rowCount,
                        @reservedpages * 8,
                        @pages * 8,
                        (CASE WHEN @usedpages > @pages THEN (@usedpages - @pages) ELSE 0 END) * 8,
                        (CASE WHEN @reservedpages > @usedpages THEN (@reservedpages - @usedpages) ELSE 0 END) * 8
                )
 
 
 
/*                name = OBJECT_NAME (@id),
                        rows = convert (char(11), @rowCount),
                        reserved = LTRIM (STR (@reservedpages * 8, 15, 0) + ' KB'),
                        data = LTRIM (STR (@pages * 8, 15, 0) + ' KB'),
                        index_size = LTRIM (STR ((CASE WHEN @usedpages > @pages THEN (@usedpages - @pages) ELSE 0 END) * 8, 15, 0) + ' KB'),
                        unused = LTRIM (STR ((CASE WHEN @reservedpages > @usedpages THEN (@reservedpages - @usedpages) ELSE 0 END) * 8, 15, 0) + ' KB')
 
*/
 
                --Exec sp_spaceused log_sistema
        
                Fetch Next From Temp_tables_cursor Into @objname
        
           End /*loop*/
        
        Close Temp_tables_cursor
        
        Deallocate Temp_tables_cursor
 
        print '++++++++++++++++++++++++++++++++++++++++++++++++++++++ SUMARIO ++++++++++++++++++++++++++++++++++++++++++++++++++++++'
        print '+-------------------------------------------------------------------------------------------------------------------+'
        print '|name       | Nome da tabela                                                                                        |'
        print '|-----------|-------------------------------------------------------------------------------------------------------|'
        print '|rows       | Número de linhas existentes na tabela.                                                                |'
        print '|-----------|-------------------------------------------------------------------------------------------------------|'
        print '|reserved   | Total de espaço reservado para a tabela.                                                              |'
        print '|-----------|-------------------------------------------------------------------------------------------------------|'
        print '|data       | Total de espaço usado por dados na tabela.                                                            |'
        print '|-----------|-------------------------------------------------------------------------------------------------------|'
        print '|index_size | Total de espaço usado por índices na tabela.                                                          |'
        print '|-----------|-------------------------------------------------------------------------------------------------------|'
        print '|unused     | Total de espaço reservado para tabela, mas ainda não usado.                                           |'
        print '+-------------------------------------------------------------------------------------------------------------------+'
        print ''
        print 'Resultado ordenado por ' + @Ordem + '. Para alterar a ordenação use ''exec sp_sig_tamanho_tabelas index_size'''
        print ''
 
        set @sql = ''
        set @sql = @sql + ' select '
        set @sql = @sql + '         vname As name,'
        set @sql = @sql + '         convert (char(11), vrows)                  As rows,'
        set @sql = @sql + '         LTRIM (STR (vreserved, 15, 0) + '' KB'')   As reserved,'
        set @sql = @sql + '         LTRIM (STR (vdata, 15, 0) + '' KB'')       As data,'
        set @sql = @sql + '         LTRIM (STR (vindex_size, 15, 0) + '' KB'') As index_size,'
        set @sql = @sql + '         LTRIM (STR (vunused, 15, 0) + '' KB'')     As unused'
        set @sql = @sql + '  from #Temp_Tables'
        set @sql = @sql + '         Order By v' + @Ordem + ' Desc'
 
        --print '@sql = ' + @sql
        exec (@sql)
 
        drop table #Temp_Tables
        
        set nocount off
        
               
        
        return (0) -- sp_sig_tamanho_tabelas
 
 
 
go
 
Grant Execute On dbo.sp_sig_tamanho_tabelas To Public
go
Grant Execute On dbo.sp_sig_tamanho_tabelas To Sistema
go
