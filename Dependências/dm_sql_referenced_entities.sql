DECLARE 
	@TableName VARCHAR(100) = 'Tab_Parametro_Sistema_Audit',
	@DB_Id int = DB_ID('penske'),
	@Proc_Name Varchar(100) = 'TR_ECR_AUDIT_TAB_PARAMETRO_SISTEMA'

SELECT
	SourceSchema            = OBJECT_SCHEMA_NAME(sed.referencing_id, @DB_Id)
	,SourceObject           = OBJECT_NAME(sed.referencing_id, @DB_Id)
	,ReferencedDB           = ISNULL(sre.referenced_database_name, DB_NAME(@DB_Id))
	,ReferencedSchema       = ISNULL(sre.referenced_schema_name, OBJECT_SCHEMA_NAME(sed.referencing_id, @DB_Id))
	,ReferencedObject       = sre.referenced_entity_name
	,ReferencedColumnID		= sre.referenced_minor_id
	,ReferencedColumn       = sre.referenced_minor_name
FROM
	PENSKE.sys.sql_expression_dependencies sed
	OUTER APPLY PENSKE.sys.dm_sql_referenced_entities('dbo.' + OBJECT_NAME(sed.referencing_id, @DB_Id), 'OBJECT') sre
WHERE
	sed.referenced_id = object_id(db_name(@db_id) + '.dbo.' + @Proc_Name)
And	(sre.referenced_entity_name = @Proc_Name OR @Proc_Name IS NULL)
--	sed.referenced_entity_name = @TableName
--AND sre.referenced_entity_name = @TableName

--SELECT DB_ID('ecargo')

--SP_048_XML_NFE_CONSISTE_ABS8

--FN_048_PESSOA_CNPJ_CPF_IE

--FN_ECR_PESSOA_EX01

SELECT TOP 50 * FROM PENSKE.sys.sql_expression_dependencies sed WHERE sed.referenced_entity_name = 'Tab_Parametro_Sistema_Audit'
SELECT TOP 50 sed.referencing_id, * FROM PENSKE.sys.sql_expression_dependencies sed WHERE sed.referenced_id  = OBJECT_ID('PENSKE..Tab_Parametro_Sistema_Audit')

SELECT OBJECT_ID('PENSKE..Tab_Parametro_Sistema_Audit')

select OBJECT_NAME(object_id, db_id('penske')), * from sys.sql_dependencies where referenced_major_id = OBJECT_ID('Tab_Parametro_Sistema_Audit')

Select	OBJECT_NAME(parent_Id), *
From	sys.triggers t
		Inner Join sys.sql_dependencies sd On t.object_Id = sd.object_id
Where	sd.referenced_major_id = Object_Id('Tab_Parametro_Sistema_Audit')
And		t.is_disabled = 0

Select	*
From	sys.triggers t
		Inner Join sys.sql_dependencies sd On t.object_Id = sd.object_id
		Inner Join sys.sql_modules sm On sm.object_id = t.object_id
Where	t.parent_id = Object_Id('Tab_Parametro_Sistema')
And		sd.referenced_major_id = Object_Id('Tab_Parametro_Sistema_Audit')
And		t.is_disabled = 0
And		sm.definition Like '%' + 'TAB_STATUS_BLOQUEIO_ID' + '%'

select * from PENSKE.sys.sql_dependencies where object_id = OBJECT_ID('PENSKE..Tab_Parametro_Sistema_Audit')
select * from PENSKE.sys.sql_dependencies where referenced_minor_id = OBJECT_ID('PENSKE..Tab_Parametro_Sistema_Audit')

select * from sys.dm_sql_referenced_entities('dbo.TR_ECR_AUDIT_TAB_PARAMETRO_SISTEMA', 'object')
select * from sys.dm_sql_referencing_entities ('dbo.Tab_Parametro_Sistema_Audit', 'object')

select * from sys.sql_dependencies sd where Exists (select 1 from sys.columns c where sd.column_id = c.column_id and c.name = 'log_gerador_id')

select	Rotina = Object_Name(sd.object_id), Tabela = object_name(sd.referenced_major_id)
From	sys.sql_dependencies sd 
Where	Exists	(
		Select	1
		From	sys.columns c 
		Where	sd.referenced_minor_id = c.column_id
		And		sd.referenced_major_id = c.object_id
		And		c.name = 'Log_Gerador_Id')
Order By 1

--select * from sys.columns c where c.name = 'log_gerador_id'
select o.* from sys.objects o inner join sys.sql_modules sm on sm.object_id = o.object_id where o.name like '%sig%' and definition like '%columns%'
select o.* from sys.objects o inner join sys.sql_modules sm on sm.object_id = o.object_id where definition like '%columns%'
select o.* from sys.objects o inner join sys.sql_modules sm on sm.object_id = o.object_id where definition like '%sys.sql_dependencies%'


SP_HELPTEXT_SIG_VAL
sp_helptext_sig2
SP_Rename_Sig
sp_signa_grant_all
SPSIGCarregaTabelas
SP_040_BAIXA_PARC_FAT_ERP_SIG
SP_SIG_COMPARA_LISTA_TABELAS
SP_HELPTEXT_SIG
SP_HELPTEXT_SIG_LOTE_DROP
sp_helptext_sig_LOTE
SP_SIG_INC_LOG_SISTEMA2
sp_helptext_sig_LOTE_VAL
SP_SIG_INC_LOG_SISTEMA_LOTE02
sp_signa_cria_tabela

