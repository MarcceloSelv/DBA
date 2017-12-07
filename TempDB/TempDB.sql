USE [master]
GO
DECLARE @cpu_count      int,
        @file_count     int,
        @logical_name   sysname,
        @file_name      nvarchar(520),
        @physical_name  nvarchar(520),
        @size           int,
        @max_size       int,
        @growth         int,
        @alter_command  nvarchar(max)

SELECT  @physical_name = physical_name,
        @size = size / 128, 
        @max_size = max_size / 128,
        @growth = growth / 128
FROM    tempdb.sys.database_files
WHERE   name = 'tempdev'

SELECT  physical_name,
        size , 
        max_size ,
        growth
FROM    tempdb.sys.database_files
WHERE   name = 'tempdev'

SELECT  @file_count = COUNT(*)
FROM    tempdb.sys.database_files
WHERE   type_desc = 'ROWS'

select @file_count

SELECT  @cpu_count = cpu_count
FROM    sys.dm_os_sys_info

select @cpu_count

WHILE @file_count < @cpu_count And @file_count < 8 -- Add * 0.25 here to add 1 file for every 4 cpus, * .5 for every 2 etc.
 BEGIN
    SELECT  @logical_name = 'tempdev' + CAST(@file_count AS nvarchar)
    SELECT  @file_name = REPLACE(@physical_name, 'tempdb.mdf', @logical_name + '.ndf')
    SELECT  @alter_command = 'ALTER DATABASE [tempdb] ADD FILE ( NAME =N''' + @logical_name + ''', FILENAME =N''' +  @file_name + ''', SIZE = ' + CAST(@size AS nvarchar) + 'MB, MAXSIZE = ' + CAST(@max_size AS nvarchar) + 'MB, FILEGROWTH = ' + CAST(@growth AS nvarchar) + 'MB )'
    PRINT   @alter_command
--    EXEC    sp_executesql @alter_command
    SELECT  @file_count = @file_count + 1
 END


--ALTER DATABASE [tempdb] ADD FILE ( NAME =N'tempdev1', FILENAME =N'C:\Program Files\Microsoft SQL Server\MSSQL.2\MSSQL\DATA\tempdev1.ndf', SIZE = 8192KB,  FILEGROWTH = 10%)
--ALTER DATABASE [tempdb] ADD FILE ( NAME =N'tempdev2', FILENAME =N'C:\Program Files\Microsoft SQL Server\MSSQL.2\MSSQL\DATA\tempdev2.ndf', SIZE = 8192KB,  FILEGROWTH = 10% )
--ALTER DATABASE [tempdb] ADD FILE ( NAME =N'tempdev3', FILENAME =N'C:\Program Files\Microsoft SQL Server\MSSQL.2\MSSQL\DATA\tempdev3.ndf', SIZE = 8192KB,  FILEGROWTH = 10% )
--ALTER DATABASE [tempdb] ADD FILE ( NAME =N'tempdev4', FILENAME =N'C:\Program Files\Microsoft SQL Server\MSSQL.2\MSSQL\DATA\tempdev4.ndf', SIZE = 8192KB,  FILEGROWTH = 10% )
--ALTER DATABASE [tempdb] ADD FILE ( NAME =N'tempdev5', FILENAME =N'C:\Program Files\Microsoft SQL Server\MSSQL.2\MSSQL\DATA\tempdev5.ndf', SIZE = 8192KB,  FILEGROWTH = 10% )
--ALTER DATABASE [tempdb] ADD FILE ( NAME =N'tempdev6', FILENAME =N'C:\Program Files\Microsoft SQL Server\MSSQL.2\MSSQL\DATA\tempdev6.ndf', SIZE = 8192KB,  FILEGROWTH = 10% )
