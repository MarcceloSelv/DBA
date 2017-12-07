;with temp as  (
	Select	[Constraint Origem] = fk.name, [Tabela Origem] = op.name, [Coluna Origem] = cfk.name, [Tabela destino] = oref.name, [Coluna destino] = cpfk.name--, --, fkref.name, fk.*
	From	sys.foreign_keys fk
		inner join sys.objects op on op.object_id = fk.parent_object_id
		inner join sys.objects oref on oref.object_id = fk.referenced_object_id
		Inner join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
		Inner join sys.columns cfk on cfk.column_id = fkc.parent_column_id and cfk.object_id = fkc.parent_object_id
		Inner join sys.columns cpfk on cpfk.column_id = fkc.referenced_column_id and cpfk.object_id = fkc.referenced_object_id
	--order by op.name, cfk.name, oref.name, cpfk.name
	--Where	
	--	op.name = 'ABASTECIMENTO'
	Except
	Select	[Constraint Origem] = Max(fk.name), [Tabela Origem] = op.name, [Coluna Origem] = cfk.name, [Tabela destino] = oref.name, [Coluna destino] = cpfk.name--, --, fkref.name, fk.*
	From	sys.foreign_keys fk
		inner join sys.objects op on op.object_id = fk.parent_object_id
		inner join sys.objects oref on oref.object_id = fk.referenced_object_id
		Inner join sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
		Inner join sys.columns cfk on cfk.column_id = fkc.parent_column_id and cfk.object_id = fkc.parent_object_id
		Inner join sys.columns cpfk on cpfk.column_id = fkc.referenced_column_id and cpfk.object_id = fkc.referenced_object_id
	--Where	
	--	op.name = 'ABASTECIMENTO'
	Group By op.name, cfk.name, oref.name, cpfk.name
	--Order By op.name,cfk.name, oref.name, cpfk.name
)
Select 'Alter table ' + QuoteName([Tabela Origem]) + ' Drop Constraint ' + QuoteName([Constraint Origem])
--Into	#temp
From	temp

;WITH TEMP AS (

Select	[Tabela Origem] = op.name collate Latin1_General_CI_AS, [Coluna Origem] = cfk.name collate Latin1_General_CI_AS, [Tabela destino] = oref.name collate Latin1_General_CI_AS, [Coluna destino] = cpfk.name collate Latin1_General_CI_AS--, --, fkref.name, fk.*
From	duasaliancas2.sys.foreign_keys fk
	inner join duasaliancas2.sys.objects op on op.object_id = fk.parent_object_id
	Inner join duasaliancas2.sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
	Inner join duasaliancas2.sys.columns cfk on cfk.column_id = fkc.parent_column_id and cfk.object_id = fkc.parent_object_id
	Inner join duasaliancas2.sys.columns cpfk on cpfk.column_id = fkc.referenced_column_id and cpfk.object_id = fkc.referenced_object_id
	inner join duasaliancas2.sys.objects oref on oref.object_id = fk.referenced_object_id
Except
Select	[Tabela Origem] = op.name collate Latin1_General_CI_AS, [Coluna Origem] = cfk.name collate Latin1_General_CI_AS, [Tabela destino] = oref.name collate Latin1_General_CI_AS, [Coluna destino] = cpfk.name collate Latin1_General_CI_AS--, --, fkref.name, fk.*
From	duasaliancas.sys.foreign_keys fk
	inner join duasaliancas.sys.objects op on op.object_id = fk.parent_object_id
	Inner join duasaliancas.sys.foreign_key_columns fkc on fk.object_id = fkc.constraint_object_id
	Inner join duasaliancas.sys.columns cfk on cfk.column_id = fkc.parent_column_id and cfk.object_id = fkc.parent_object_id
	Inner join duasaliancas.sys.columns cpfk on cpfk.column_id = fkc.referenced_column_id and cpfk.object_id = fkc.referenced_object_id
	inner join duasaliancas.sys.objects oref on oref.object_id = fk.referenced_object_id
)

SELECT 'ALTER TABLE ' + [Tabela Origem] + ' WITH CHECK ADD FOREIGN KEY (' + QUOTENAME([Coluna Origem]) + ') REFERENCES ' + [Tabela destino] + ' ( ' + [Coluna destino] + ' ) '
FROM TEMP