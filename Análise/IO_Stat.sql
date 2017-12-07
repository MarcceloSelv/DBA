-- IO stats by file
Select DBName = DB_NAME(FS.database_id),
    IsSnapshotOf = DB_NAME(D.source_database_id),
    LogicalName = MF.name,
    FilePathName = MF.physical_name,
    Filetype = MF.type_desc,
    FileState = MF.state_desc,
    NumberOfReads = FS.num_of_reads,
    ReadStall_ms = FS.io_stall_read_ms,
    NumberOfWrites = FS.num_of_writes,
    WriteStall_ms = FS.io_stall_write_ms,
    TotalStall = FS.io_stall,
    AvgReadTransfer_ms = Case When FS.num_of_reads = 0 Then 0
                        Else FS.io_stall_read_ms/FS.num_of_reads
                        End,
    AvgWriteTransfer_ms = Case When FS.num_of_writes = 0 Then 0
                        Else FS.io_stall_write_ms/FS.num_of_writes
                        End,
    AvgStall_ms = Case When FS.num_of_reads +  FS.num_of_writes = 0 Then 0
                        Else FS.io_stall/(FS.num_of_reads + FS.num_of_writes)
                        End,
    BytesPerRead = Case When FS.num_of_reads = 0 Then 0
                        Else FS.num_of_bytes_read/FS.num_of_reads
                        End,
    BytesPerWrite = Case When FS.num_of_writes = 0 Then 0
                        Else FS.num_of_bytes_written/FS.num_of_writes
                        End
From sys.dm_io_virtual_file_stats(null, null) FS
Inner Join sys.master_files MF On MF.database_id = FS.database_id
    And MF.file_id = FS.file_id
Left Join sys.databases D On D.database_id = FS.database_id;
Go

-- I/O stats per drive letter
Select DriveLetter = Left(MF.physical_name, 1),
    NumberOfReads = SUM(FS.num_of_reads),
    ReadStall_ms = SUM(FS.io_stall_read_ms),
    NumberOfWrites = SUM(FS.num_of_writes),
    WriteStall_ms = SUM(FS.io_stall_write_ms),
    TotalStall = SUM(FS.io_stall),
    AvgReadTransfer_ms = Case When SUM(FS.num_of_reads) = 0 Then 0
                        Else SUM(FS.io_stall_read_ms)/SUM(FS.num_of_reads)
                        End,
    AvgWriteTransfer_ms = Case When SUM(FS.num_of_writes) = 0 Then 0
                        Else SUM(FS.io_stall_write_ms)/SUM(FS.num_of_writes)
                        End,
    AvgStall_ms = Case When SUM(FS.num_of_reads + FS.num_of_writes) = 0 Then 0
                        Else SUM(FS.io_stall)/SUM(FS.num_of_reads + FS.num_of_writes)
                        End,
    BytesPerRead = Case When SUM(FS.num_of_reads) = 0 Then 0
                        Else SUM(FS.num_of_bytes_read)/SUM(FS.num_of_reads)
                        End,
    BytesPerWrite = Case When SUM(FS.num_of_writes) = 0 Then 0
                        Else SUM(FS.num_of_bytes_written)/SUM(FS.num_of_writes)
                        End
From sys.dm_io_virtual_file_stats(null, null) FS
Inner Join sys.master_files MF On MF.database_id = FS.database_id
    And MF.file_id = FS.file_id
Group By Left(MF.physical_name, 1);
Go

-- I/O stats per database
Select DBName = DB_NAME(FS.database_id),
    IsSnapshotOf = MIN(DB_NAME(D.source_database_id)),
    NumberOfReads = SUM(FS.num_of_reads),
    ReadStall_ms = SUM(FS.io_stall_read_ms),
    NumberOfWrites = SUM(FS.num_of_writes),
    WriteStall_ms = SUM(FS.io_stall_write_ms),
    TotalStall = SUM(FS.io_stall),
    AvgReadTransfer_ms = Case When SUM(FS.num_of_reads) = 0 Then 0
                        Else SUM(FS.io_stall_read_ms)/SUM(FS.num_of_reads)
                        End,
    AvgWriteTransfer_ms = Case When SUM(FS.num_of_writes) = 0 Then 0
                        Else SUM(FS.io_stall_write_ms)/SUM(FS.num_of_writes)
                        End,
    AvgStall_ms = Case When SUM(FS.num_of_reads + FS.num_of_writes) = 0 Then 0
                        Else SUM(FS.io_stall)/SUM(FS.num_of_reads + FS.num_of_writes)
                        End,
    BytesPerRead = Case When SUM(FS.num_of_reads) = 0 Then 0
                        Else SUM(FS.num_of_bytes_read)/SUM(FS.num_of_reads)
                        End,
    BytesPerWrite = Case When SUM(FS.num_of_writes) = 0 Then 0
                        Else SUM(FS.num_of_bytes_written)/SUM(FS.num_of_writes)
                        End
From sys.dm_io_virtual_file_stats(null, null) FS
Inner Join sys.master_files MF On MF.database_id = FS.database_id
    And MF.file_id = FS.file_id
Left Join sys.databases D On D.database_id = FS.database_id
Group By FS.database_id
Order By DBName;
Go