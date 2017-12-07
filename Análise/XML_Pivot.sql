WITH XMLNAMESPACES (default 'http://www.portalfiscal.inf.br/cte')
SELECT  
	NodePai = Nod.value('local-name(..)', 'varchar(300)'),
	NodeChild = Nod.value('local-name(.)', 'varchar(300)'),
	NodeValue = Nod.value('.', 'varchar(300)'),
	NodeValue = Nod.query('./*[1]'),
	NodeValue = infNod.query('.')
	--NodeValue = Nod.value('..', 'varchar(50)')
	--NodChild	= NodChild.value('local-name(.)', 'varchar(50)'),
	--XML_AUTORIZACAO.value('(/cteProc/CTe/infCte/rem/ICMS/ICMS00/CST)[1] ', 'varchar(200)'),
	--XML_AUTORIZACAO
FROM
	ECARGO..CTE CTE
	CROSS APPLY (
		SELECT	QTDE = COUNT(1)
		FROM	ECARGO..NOTA_FISCAL NF
		WHERE	CTE.DOCTO_TRANSPORTE_ID = NF.DOCTO_TRANSPORTE_ID
	) NOTA_FISCAL
	CROSS APPLY XML_AUTORIZACAO.nodes('//*') AS TBL(Nod)
	CROSS APPLY XML_AUTORIZACAO.nodes('(/cteProc/CTe/infCte/rem/infNFe)[1]') AS nf(infNod)
WHERE   XML_AUTORIZACAO IS NOT NULL
--AND	QTDE > 1
and CHAVE_CTE = '35120786501400000287570010000000141000000141'


DECLARE @ColunasPivot VARCHAR(8000)
DECLARE @GrupoPivot NVARCHAR(MAX)

WITH XMLNAMESPACES (default 'http://www.portalfiscal.inf.br/cte')
SELECT  @ColunasPivot = COALESCE(@ColunasPivot + ',[' + NodeName + ']', '[' + NodeName + ']')
FROM (	
	SELECT  
		NodeName = Nod.value('concat(local-name(..), ''/'', local-name(.))', 'varchar(50)'),
		NodeValue = Nod.value('.', 'varchar(50)')
		--XML_AUTORIZACAO.value('(/cteProc/CTe/infCte/imp/ICMS/ICMS00/CST)[1] ', 'varchar(200)'),
		--XML_AUTORIZACAO,
		--CHAVE_CTE
	FROM    ECARGO..CTE
		CROSS APPLY XML_AUTORIZACAO.nodes('//*') AS TBL(Nod)
	WHERE   XML_AUTORIZACAO IS NOT NULL
	and chave_cte = '35120786501400000287570010000000141000000141'

) AS P
Group By NodeName

--select @ColunasPivot
 
SET @GrupoPivot = N'
WITH XMLNAMESPACES (default ''http://www.portalfiscal.inf.br/cte'')
SELECT *
FROM (	
	SELECT  
		NodeName = Nod.value(''concat(local-name(..), ''''/'''', local-name(.))'', ''varchar(50)''),
		NodeValue = Nod.value(''.'', ''varchar(50)'')
		--XML_AUTORIZACAO.value(''(/cteProc/CTe/infCte/imp/ICMS/ICMS00/CST)[1]'', ''varchar(200)''),
		--XML_AUTORIZACAO,
		--CHAVE_CTE
	FROM    ECARGO..CTE
		CROSS APPLY XML_AUTORIZACAO.nodes(''//*'') AS TBL(Nod)
	WHERE   XML_AUTORIZACAO IS NOT NULL
	and chave_cte = ''35120786501400000287570010000000141000000141''
) AS P PIVOT (MAX(NodeValue) FOR NodeName IN (' + @ColunasPivot + ')) AS Pvt
'
 
EXECUTE(@GrupoPivot)