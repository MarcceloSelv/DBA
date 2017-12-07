--http://blog.extreme-advice.com/2013/02/18/find-service-broker-queue-count-in-sql-server/
SELECT
	'Transmission Queue' AS QueueName,
	Parti.Rows, *
FROM
	sys.objects AS Obj
	INNER JOIN sys.partitions AS Parti ON Parti.object_id = Obj.object_id
WHERE
	Obj.name = 'sysxmitqueue'

SELECT
	queues.Name
	, parti.Rows
FROM
	sys.objects AS SysObj
	INNER JOIN sys.partitions AS parti ON parti.object_id = SysObj.object_id
	INNER JOIN sys.objects AS queues ON SysObj.parent_object_id = queues.object_id
WHERE	parti.index_id = 1