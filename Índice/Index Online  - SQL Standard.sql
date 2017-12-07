http://aboutsqlserver.com/2014/09/23/reducing-offline-index-rebuild-and-table-locking-time-in-sql-server/

@T1 bigint, @T2 bigint

select 
	@T1 = avg(RecId) -- Making sure that IN_ROW pages are read
	,@T2 = avg(len(LOB_Column)) -- Making sure that LOB pages are read
from dbo.MyTable with (nolock, index=IDX_CI) 
option (maxdop 1)


--

select i.name, au.type_desc, count(*) as [Cached Pages]
from 
	sys.dm_os_buffer_descriptors bd with (nolock) 
        join sys.allocation_units au with (nolock) on 
		    bd.allocation_unit_id = au.allocation_unit_id
	join sys.partitions p with (nolock) on
		(au.type in (1,3) and au.container_id = p.hobt_id) or
		(au.type = 2 and au.container_id = p.partition_id)
	join sys.indexes i with (nolock) on
		p.object_id = i.object_id and 
		p.index_id = i.index_id
where
	bd.database_id = db_id() and
	p.object_id = object_id (N'dbo.MyTable') and 
	p.index_id = 1 -- ID of the index
group by
	i.name, au.type_desc