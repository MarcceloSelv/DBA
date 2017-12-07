SELECT Cast( Cast('<t>' + OBJECT_DEFINITION(OBJECT_ID('SP_040_CON_VAL_TABELA105'))+ '</t>' as varchar(max) )  as xml)

DECLARE @Enter Char(2); Set @Enter = Char(13) + Char(10)

SELECT	'SET ANSI_NULLS OFF' + @Enter + 
	'SET ANSI_DEFAULTS OFF' + @Enter + 
	'go' + @Enter +
	Replace(definition, 'CREATE PROCEDURE', 'ALTER PROCEDURE') + @Enter +
	'go' + @Enter +
	'Grant Execute On dbo.SP_040_CON_VAL_TABELA96 To Public' + @Enter +
	'go' + @Enter +
	'Grant Execute On dbo.SP_040_CON_VAL_TABELA96 To Sistema' + @Enter +
	'go' + @Enter
FROM
	sys.sql_modules
WHERE
	object_id=object_id('SP_040_CON_VAL_TABELA96')  FOR XML PATH(''), type, elements



SELECT	*
FROM	ECARGO.sys.sql_modules sm
	CROSS APPLY (
	SELECT	DISTINCT objectid
	FROM	SYS.dm_exec_query_stats qs
		Cross Apply Sys.dm_exec_sql_text(qs.sql_handle) txt
	WHERE
		txt.dbid = db_id('ECARGO')
	AND	txt.objectid = sm.object_id
	) T
WHERE	sm.definition LIKE '%INDEX=%'