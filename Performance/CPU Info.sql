SELECT 
  cpu_count AS NumberOfLogicalCPUs
, hyperthread_ratio
, ( cpu_count / hyperthread_ratio ) AS NumberOfPhysicalCPUs
, CASE
      WHEN hyperthread_ratio = cpu_count THEN cpu_count
      ELSE ( ( cpu_count - hyperthread_ratio ) / 
             ( cpu_count / hyperthread_ratio ) )
 END AS NumberOfCoresInEachCPU
, CASE
    WHEN hyperthread_ratio = cpu_count THEN cpu_count
    ELSE ( cpu_count / hyperthread_ratio ) 
    * ( ( cpu_count - hyperthread_ratio ) / 
            ( cpu_count / hyperthread_ratio ) )
  END AS TotalNumberOfCores
FROM sys.dm_os_sys_info