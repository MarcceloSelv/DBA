SELECT	p.*, t.*
FROM	
	sys.objects o
	Inner Join sys.parameters p On o.object_id = p.object_id
	Inner Join sys.types t on t.user_type_id = p.user_type_id
WHERE
	o.type <> 'P'
And	t.collation_name is not null
And     p.is_output = 0
And
	o.NAME IN (
	'FN_SPLIT'
	,'FN_SPLIT_MS'
	,'SplitString_Xml'
	,'FN_036_QUEBRA_STRING'
	,'FN_036_QUEBRA_STRING1'
	,'FN_SPLIT_TXT_QUERY'
	,'FN_SPLIT2'
	,'FN_ECR_BUSCA_ENDERECO_ID'
	,'FN_SPLIT4'
	,'SplitValues'
	,'FN_040_QUEBRA_STRING'
	,'FN_SPLIT3'
)


--SELECT * FROM SYS.parameters

--SELECT	*
--FROM	
--	sys.objects o
--WHERE
--	Exists(Select 1 From sys.parameters p Inner Join sys.types t On t.user_type_id = p.user_type_id Where o.object_id = p.object_id And t.collation_name is not null)
--And	o.type = 'TF'



DECLARE @SQLTEXT VARCHAR(MAX); SET @SQLTEXT = ''

/* Functions */
SELECT	O.OBJECT_ID
INTO 	#FUNCTION_IDS
FROM	SYS.OBJECTS O
WHERE	NAME IN ( 'FN_SPLIT' 
,'FN_SPLIT_MS' 
,'SplitString_Xml' 
,'FN_036_QUEBRA_STRING' 
,'FN_036_QUEBRA_STRING1' 
,'FN_SPLIT_TXT_QUERY' 
,'FN_SPLIT2' 
,'FN_ECR_BUSCA_ENDERECO_ID' 
,'FN_SPLIT4' 
,'SplitValues' 
,'FN_040_QUEBRA_STRING' 
,'FN_SPLIT3' )



SELECT	@SQLTEXT = @SQLTEXT + ' EXEC SP_HELPTEXT_SIG ''' + QUOTENAME(Schema_Name(schema_id)) + '.' + QUOTENAME(NAME) + ''' ' + CHAR(13) + CHAR(10) --+ 'GO' + CHAR(13) + CHAR(10)
FROM	SYS.OBJECTS O
WHERE	EXISTS(SELECT 1 FROM #FUNCTION_IDS F WHERE F.OBJECT_ID = O.OBJECT_ID)

EXEC (@SQLTEXT)

DROP TABLE #FUNCTION_IDS