SELECT fk.name AS ForeignKey,
IsNotForReplication = case when fk.is_not_for_replication = 0 then 'No' else 'yes'
end,
OBJECT_NAME(fk.parent_object_id) AS TableName,
COL_NAME(fkc.parent_object_id,
fkc.parent_column_id) AS ColumnName,
OBJECT_NAME (fk.referenced_object_id) AS ReferenceTableName,
COL_NAME(fkc.referenced_object_id,
fkc.referenced_column_id) AS ReferenceColumnName
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc
ON fk.OBJECT_ID = fkc.constraint_object_id
order by TableName, IsNotForReplication