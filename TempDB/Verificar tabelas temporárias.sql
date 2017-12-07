

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--GOTO INICIO

if (select OBJECT_ID ('tempdb..#RESULT')) > 0
	DROP TABLE #RESULT

if (select OBJECT_ID ('tempdb..#ind')) > 0
	DROP TABLE #ind

CREATE TABLE #RESULT (ParentObject Varchar(100), [Object] Varchar(100), Field Varchar(300), value varchar (1000) null)
CREATE TABLE #ind (PageFID BigInt, PagePID BigInt, IAMFID BigInt, IAMPID BigInt, ObjectID BigInt, IndexID BigInt, PartitionNumber BigInt, PartitionID BigInt, iam_chain_type varchar(100), PageType BigInt, IndexLevel BigInt, NextPageFID BigInt, NextPagePID BigInt, PrevPageFID BigInt, PrevPagePID BigInt)

DECLARE @OBJECT_ID INT,
	@sq	Varchar(max),
	@PageFID BigInt,
	@PagePID BigInt

SELECT  top 1 @OBJECT_ID = object_id
FROM    tempdb.sys.tables T
WHERE   T.name LIKE N'#Temp_Ship[_][_]%'
order by OBJECT_ID desc;

--select @OBJECT_ID 

select  @sq = 'dbcc ind(''tempdb'', ' + Cast(@OBJECT_ID as varchar) + ', -1)'

insert #ind
exec (@sq)

--SELECT * FROM #ind

Declare CURSOR_PAGE CURSOR LOCAL FOR
SELECT	PageFID, PagePID
FROM	#ind
Where	IAMFID Is Not Null

OPEN CURSOR_PAGE
FETCH NEXT FROM CURSOR_PAGE INTO @PageFID, @PagePID
WHILE @@FETCH_STATUS = 0
    BEGIN
	SET @SQ = 'dbcc page(tempdb, ' + CAST(@PageFID AS VARCHAR) + ',' + CAST(@PagePID AS VARCHAR) + ', 3) with tableresults'

	PRINT ISNULL(@SQ, 'BRANCO')

	Insert #RESULT
	Exec (@SQ)

	FETCH NEXT FROM CURSOR_PAGE INTO @PageFID, @PagePID
    END
CLOSE CURSOR_PAGE
DEALLOCATE CURSOR_PAGE

update #RESULT
set value = null
where value = '[NULL]'

delete from #RESULT
where [object] not like 'Slot % Column % Offset%'

ALTER TABLE #RESULT ADD ID INT IDENTITY

IF EXISTS(SELECT 1 FROM master.sys.objects WHERE NAME = 'RESULT')
	DROP TABLE master.dbo.RESULT

SELECT	*
INTO	master.dbo.RESULT
FROM	#RESULT

DECLARE @COLUNAS VARCHAR(MAX)
SET @COLUNAS = '' 

SELECT @COLUNAS = COALESCE(@COLUNAS + '[' + Field + '],','')
FROM (select distinct Field from #RESULT) AS DADOS_HORIZONTAIS 

SET @COLUNAS = LEFT (@COLUNAS, LEN(@COLUNAS)-1)

DECLARE @SQLSTRING NVARCHAR(max); 

SET @SQLSTRING = N'
USE master 

IF EXISTS(SELECT 1 FROM SYS.OBJECTS WHERE NAME = ''Temp_Result'')
	DROP TABLE Temp_Result

SELECT * 
INTO	Temp_Result
FROM	(select linha = Row_number() Over(partition by Field order by (select 1)), Field, value from RESULT) AS DADOS_HORIZONTAIS PIVOT( MAX(value) FOR Field IN('+@COLUNAS+')) AS PivotTable;

Alter Table Temp_Result Drop Column Linha
' 
EXECUTE SP_EXECUTESQL @SQLSTRING

BEGIN TRY
	DROP TABLE #Temp_Result
END TRY
BEGIN CATCH
END CATCH

SELECT	*
INTO	#Temp_Result
FROM	master..Temp_Result

DROP TABLE master..Temp_Result

SELECT	*--FLAG_AGRUPA_OK, nota_Fiscal_ctrc, nota_Fiscal_ship, qtde_ship, qtde_ctrc, docto_ctrc_id, DOCTO_ship_ID, * 
FROM	#Temp_Result

select 	tmp.num_shipment_int, ds.SHIPMENT_ID, dct_ship.docto_transporte_id, dct_ship.tab_tipo_docto_transp_Id, dct_ship.fornecedor_id,
	[Num Ct-e] = dct_cte.NUM_DOCTO_TRANSPORTE,
	[Num Ship] = dct_ship.NUM_DOCTO_TRANSPORTE,
	docto_transp_ship_id = dct_ship.docto_transporte_id,
	fornecedor_Id = dct_ship.fornecedor_id,
	tmp.*
From
	#Temp_Result  as tmp 
	left Join DOCTO_TRANSPORTE as dct_cte (Nolock) on dct_cte.DOCTO_TRANSPORTE_ID = tmp.num_shipment_int
	left Join dct_shipment ds (Nolock) on dct_cte.docto_transporte_id = ds.docto_transporte_id 
		And ds.tab_status_id = 1
	left Join DOCTO_TRANSPORTE as dct_ship (Nolock) on ds.shipment_id = dct_ship.docto_transporte_id
		And dct_ship.TAB_STATUS_ID = 1
		--And dct_ship.tab_tipo_docto_transp_Id = 401
		--And dct_ship.fornecedor_id = 3523
	left Join TAB_TIPO_DOCUMENTO (Nolock) ON dct_ship.TAB_TIPO_DOCUMENTO_ID = TAB_TIPO_DOCUMENTO.TAB_TIPO_DOCUMENTO_ID
	left Join VPONTO_OPERACAO (Nolock) ON dct_ship.PONTO_OPERACAO_ID = VPONTO_OPERACAO.PONTO_OPERACAO_ID
order by data_emissao_plan2, tmp.num_shipment_int



--SELECT	dct.DOCTO_TRANSPORTE_ID, PARAMETRO_FORNEC_id
--FROM	DOCTO_TRANSPORTE AS DCT (NOLOCK)
--	INNER JOIN #Temp_Result ON DCT.DOCTO_TRANSPORTE_ID = #Temp_Result.DOCTO_SHIP_ID
--	INNER JOIN DCT_SHIPMENT DS ON #Temp_Result.DOCTO_SHIP_ID = ds.SHIPMENT_ID and ds.TAB_STATUS_ID <> 2
--	INNER JOIN DOCTO_TRANSPORTE CTE ON ds.DOCTO_TRANSPORTE_ID = cte.DOCTO_TRANSPORTE_ID
--	LEFT JOIN PARAMETRO_FORNEC (NoLock) ON DCT.FORNECEDOR_ID = PARAMETRO_FORNEC.FORNECEDOR_ID 
--		AND PARAMETRO_FORNEC.TAB_STATUS_ID = 1
--WHERE
--	(	ISNULL(PARAMETRO_FORNEC.FLAG_EXIGE_ENTREGA_CTRC_FAT, '' ) <> 'S' 
--		OR
--		(ISNULL(PARAMETRO_FORNEC.FLAG_EXIGE_ENTREGA_CTRC_FAT, '') = 'S'
--			AND DCT.DOCTO_TRANSPORTE_ID IN ( 
--				SELECT TRACKING.DOCTO_TRANSPORTE_ID 
--				FROM	TRACKING 
--					INNER JOIN TAB_TIPO_TRACKING ON TRACKING.TAB_TIPO_TRACKING_ID = TAB_TIPO_TRACKING.TAB_TIPO_TRACKING_ID 
--				WHERE	TRACKING.TAB_STATUS_ID = 1 
--				AND	TRACKING.DOCTO_TRANSPORTE_ID = DCT.DOCTO_TRANSPORTE_ID
--				AND	TAB_TIPO_TRACKING.TAB_STATUS_TRACKING_ID IN (113 ) 
--				)
--		) 
--	)
--	AND	(	ISNULL('N', '' ) <> 'S' 
--			OR (
--			ISNULL(	'N', '') = 'S' AND	CTE.PROTOCOLO_ENTREGA_ID IS NOT NULL )
--		)
--	AND	(
--			ISNULL ( 'S' , '' ) <> 'S'
--			OR 
--			(
--				ISNULL('S','') = 'S' 
--				AND DCT.DOCTO_TRANSPORTE_ID IN ( 
--					SELECT	DCT_SHIPMENT.SHIPMENT_ID 
--					FROM	DCT_SHIPMENT 
--						INNER JOIN DOCTO_TRANSP_MANIFESTO_ROD ON DCT_SHIPMENT.DOCTO_TRANSPORTE_ID = DOCTO_TRANSP_MANIFESTO_ROD.DOCTO_TRANSPORTE_ID 
--						INNER JOIN MANIFESTO_ROD ON DOCTO_TRANSP_MANIFESTO_ROD.MANIFESTO_ROD_ID = MANIFESTO_ROD.MANIFESTO_ROD_ID 
--					WHERE	DCT_SHIPMENT.TAB_STATUS_ID = 1 
--					AND	DOCTO_TRANSP_MANIFESTO_ROD.TAB_STATUS_ID = 1 
--					AND	MANIFESTO_ROD.TAB_STATUS_ID = 1 
--					AND	DCT_SHIPMENT.SHIPMENT_ID = DCT.DOCTO_TRANSPORTE_ID ) ) 
--		)

	--SELECT	NF.NOTA_FISCAL_iD , DCT.DOCTO_TRANSPORTE_iD, NF.nota_fiscal_int, dct.val_total, dct.val_custo_total, dct.num_docto_transporte, DCt.TAB_SITUACAO_NF_ID, nf.tab_status_tracking_id, 'S'
	--FROM	DOCTO_TRANSPORTE AS DCT (NOLOCK)
	--	INNER JOIN NOTA_FISCAL AS NF (NOLOCK) ON DCT.DOCTO_TRANSPORTE_iD = NF.DOCTO_TRANSPORTE_iD
	--	INNER JOIN #Temp_Result AS A (NOLOCK) ON NF.NOTA_FISCAL_iD = A.NOTA_FISCAL_SHIP_iD
	--	LEFT JOIN PARAMETRO_FORNEC (NoLock) ON DCT.FORNECEDOR_ID = PARAMETRO_FORNEC.FORNECEDOR_ID AND PARAMETRO_FORNEC.TAB_STATUS_ID = 1
	--WHERE	DCT.TAB_TIPO_DOCTO_TRANSP_iD = ISNULL(401,1)
	--AND	DCT.TAB_STATUS_ID = 1
	--AND	NF.TAB_STATUS_ID = 1

--SELECT data_emissao_plan2, CAST(data_emissao_plan2 AS DATETIME), peso_total_plan, *
--FROM	#Temp_Result
--WHERE ISDATE(data_emissao_plan2) = 1
--ORDER BY REG_num_shipment
--ORDER BY DOCTO_TRANSP_CTE_ID

--SET DATEFORMAT dmy
--SELECT ISDATE('31/01/2014 15:33:13')

--SET DATEFORMAT ymd
--SELECT ISDATE('2014/01/31 15:33:13')

RETURN

/*
declare @contador			INT,
	@REG_CNPJ_PREST			VARCHAR(14),
	@REG_INDIC_PF_PJ_PREST		CHAR(2),
	@REG_NUM_FATURA			VARCHAR(10),
	@Fornecedor_Id			INT ,
	@NOME_FORNEC			VARCHAR(40) ,
	@EMAIL				VARCHAR(100) ,
	@RETORNO			INT ,
	@MSG_RET			VARCHAR(255) ,
	@FLAG_SHIPMENT			CHAR(1),		
	@flag_resp_agrup		CHAR(1),
	@flag_remetente			CHAR(1),
	@Flag_Tipo_Shipment		CHAR(1),
	@REG_DATA_VENCTO		VARCHAR(10),
	@Data_vencto_aux		VARCHAR(10),
	@data_vencto			DATETIME,
	@REG_VAL_FATURA			VARCHAR(15),
	@VAL_FATURA			NUMERIC(15,2),
	@qtde_nf			INT,
	@Reg_Num_Shipment		INT
	
/*fatura*/
declare @PARAM_I_ARQUIVO_RECEBIDO_EDI_ID	INT,
	@V_DATA_EMISSAO				DATETIME,
	@PARAM_I_CLIENTE_ID_DCTO		INT,
	@Empresa_id				INT

	/*insere o conemb*/
declare
	@DOCTO_TRANSP_SHIP_ID		INT ,
	@NOTA_FISCAL_ID_LISTA		VARCHAR(4000),
	@DOCTO_PAGTO_ID			INT ,
        @END_REMETENTE_ID               INT ,
        @CLIENTE_ID                     INT ,
        @DESTINO_ID                     INT ,
        @END_DESTINATARIO_ID            INT ,
        @ORIGEM_ID                      INT ,
        @END_CLIENTE_ID                 INT ,
        @DATA_EMISSAO                   DATETIME,
        @PONTO_OPERACAO_ID		INT ,
        @ZUSUARIO_ID		        INT ,
        @ARQUIVO_RECEBIDO_EDI_ID    	INT ,
        @TAB_TIPO_ARQ_RECEBIDO_ID	INT ,
        @FILIAL				VARCHAR(10),
        @SERIE				VARCHAR(3),
        @NUM_CONTROLE_CTAC		VARCHAR(20),
	@ID_SISTEMA_EXTERNO_CT		VARCHAR(20),
        @TAB_TIPO_COBRANCA_ID		INT,
        @RESP_PAGTO			VARCHAR(1),
        @PESO_TAXADO			NUMERIC(20,6),
        @VAL_TOTAL			NUMERIC(15,2),
        @VAL_BASE_ICMS			NUMERIC(15,2),
        @ALIQUOTA_ICMS			NUMERIC(4,2),
        @VAL_ICMS			NUMERIC(15,2),
        @VAL_FRETE_PESO			NUMERIC(15,2),
        @VAL_FRETE_VALOR    	        NUMERIC(15,2),
        @VAL_OUTROS			NUMERIC(15,2),
        @VAL_CAT			NUMERIC(15,2),
        @VAL_DESPACHO			NUMERIC(15,2),
        @VAL_TOTAL_PEDAGIO		NUMERIC(15,2),
        @VAL_ADEME			NUMERIC(15,2),
        @TAB_TIPO_ICMS_ID		INT,
        @TIPO_ICMS			VARCHAR(1),
        @ACAO_DOCUMENTO			VARCHAR(1),
        @CFOP				VARCHAR(5),
        @CFOP_NOVO			VARCHAR(5),
        @CGC_CONHEC_DEVOLUCAO		VARCHAR(14),
        @INDICATIVO_CONTINUIDADE 	VARCHAR(1),
        @PJ_CGC_EMBARC			VARCHAR(14),
        @PJ_CGC_EMISS			VARCHAR(14),
        @TAB_TIPO_DOCUMENTO_ID		INT,
        @PESO_REAL  			NUMERIC(10,4),
        @VOLUME 			INT,
        @VAL_DECLARADO                  NUMERIC(15,2),
        @TAB_TIPO_PRODUTO_ID            INT,
        @TXT_EMBALAGEM                  VARCHAR(50),
	@CHAVE_CTE_PARCEIRO		VARCHAR(44)	,
        @TAB_TIPO_TRANSPORTE_ID         INT           ,
        @NUM_DOCTO_TRANSPORTE           INT           , 
        @DATA_CHEGADA_CLIENTE_PREVISTA  DATETIME      ,
        @TAB_SIT_ENTREGA_ID             INT           ,
        @ID_SISTEMA_EXTERNO             VARCHAR(50)   ,
	@FLAG_INDICA_TIPO_DOCTO		CHAR(1),
	@FLAG_TAB_TIPO_DOCTO_TRANSP_ID	VARCHAR(50),
	@FLAG_INSERE_FATURA_COM_CONSIST CHAR(1)

DECLARE Plan_Tra_Cursor CURSOR LOCAL FAST_FORWARD FORWARD_ONLY FOR
Select Distinct 
	tmp.docto_transp_ship_id, dct_ship.end_remetente_Id, dct_ship.cliente_Id,
	dct_ship.destino_Id, dct_ship.end_destinatario_Id,dct_ship.origem_id, dct_ship.end_cliente_Id,
	NULL, dct_ship.ponto_operacao_id, tmp.reg_num_ctrc, tmp.reg_num_ctrc, dct_ship.tab_tipo_cobranca_id,
	tmp.peso_total_plan, NULL, NULL, NULL, NULL,
	NULL, dct_ship.cfop, dct_ship.cfop, dct_ship.tab_tipo_documento_id, 
	NULL, NULL, NULL	, tmp.fornecedor_Id, tmp.Reg_Num_Shipment
From
	#Temp_Result as tmp
	Inner Join docto_transporte as dct_ship on tmp.docto_transp_ship_id = dct_ship.docto_transporte_id
Where
	IsNull(CONSISTIU,'N') <> 'S'

OPEN Plan_Tra_Cursor

FETCH NEXT From plan_tra_cursor INTO @DOCTO_TRANSP_SHIP_ID, @End_Remetente_Id, @CLIENTE_ID,
	@DESTINO_ID, @END_DESTINATARIO_ID, @ORIGEM_ID, @End_Cliente_Id, 
	@data_emissao, @ponto_Operacao_Id, @NUM_CONTROLE_CTAC, @ID_SISTEMA_EXTERNO_CT, @TAB_TIPO_COBRANCA_ID,
	@PESO_TAXADO,	@VAL_TOTAL, @VAL_BASE_ICMS, @VAL_ICMS, @ALIQUOTA_ICMS,  @VAL_FRETE_PESO	, @cfop, @CFOP_NOVO, @TAB_TIPO_DOCUMENTO_ID, 
	@PESO_REAL, @VOLUME, @VAL_DECLARADO, @Fornecedor_Id, @Reg_Num_Shipment

WHILE (@@fetch_status <> -1)
	Begin				/* if0030 */
	If (@@fetch_status <> -2)
		Begin			/* if0040 */

		PRINT @Reg_Num_Shipment
		End				/* if0040 */

	FETCH NEXT From plan_tra_cursor INTO @DOCTO_TRANSP_SHIP_ID, @end_remetente_Id,@CLIENTE_ID,
		@DESTINO_ID, @END_DESTINATARIO_ID, @ORIGEM_ID, @end_cliente_Id, 
		@data_emissao, @ponto_Operacao_Id, @NUM_CONTROLE_CTAC, @ID_SISTEMA_EXTERNO_CT, @TAB_TIPO_COBRANCA_ID,
		@PESO_TAXADO,	@VAL_TOTAL, @VAL_BASE_ICMS, @VAL_ICMS, @ALIQUOTA_ICMS, @VAL_FRETE_PESO, @cfop, @CFOP_NOVO, @TAB_TIPO_DOCUMENTO_ID, 
		@PESO_REAL, @VOLUME, @VAL_DECLARADO, @Fornecedor_Id, @Reg_Num_Shipment
	End					/* if0030 */	

CLOSE Plan_Tra_Cursor
DEALLOCATE Plan_Tra_Cursor

*/