SELECT * FROM NOTA_FISCAL WHERE NOTA_FISCAL = '393557'

SELECT NUM_DOCTO_TRANSPORTE, TAB_TIPO_DOCTO_TRANSP_ID, FORNECEDOR_ID FROM DOCTO_tRANSPORTE WHERE DOCTO_TRANSPORTE_ID = 5418215

SELECT	* 
FROM	DCT_SHIPMENT 
WHERE	SHIPMENT_ID = 5418215


SELECT NUM_DOCTO_TRANSPORTE, TAB_TIPO_DOCTO_TRANSP_ID, FORNECEDOR_ID FROM DOCTO_tRANSPORTE WHERE DOCTO_TRANSPORTE_ID = 5407746 
SELECT NOTA_FISCAL, SERIE FROM NOTA_FISCAL WHERE DOCTO_TRANSPORTE_ID = 5407746 

SELECT NUM_DOCTO_TRANSPORTE, TAB_TIPO_DOCTO_TRANSP_ID, FORNECEDOR_ID FROM DOCTO_tRANSPORTE WHERE DOCTO_TRANSPORTE_ID = 5224359
SELECT NOTA_FISCAL, SERIE FROM NOTA_FISCAL WHERE DOCTO_TRANSPORTE_ID = 5224359





--exec SP_040_EXC_FAT_TRANSP02 8157,1
--exec SP_040_CON_FATURA_TRANSP04 8166

SELECT * FROM DOCTO_PAGTO WHERE DOCTO_PAGTO_ID = 8166

SELECT * FROM ANOMALIA_EDI WHERE ARQUIVO_RECEBIDO_EDI_ID = 87315
return
DELETE FROM ANOMALIA_EDI WHERE ARQUIVO_RECEBIDO_EDI_ID = 87315


sp_who3 1

EXEC SP_DEBUG_TEMP 'temp_trk_nf_ship'

SELECT * FROM ##temp_pedido_nf_aux
SELECT * FROM ##temp_track_ship
SELECT * FROM ##temp_trk_nf_ship

SELECT DOCTO_TRANSPORTE_ID, Data_Entrega, * FROM NOTA_FISCAL WHERE NOTA_FISCAL_ID = 18966537
SELECT TAB_SITUACAO_NF_iD, * FROM DOCTO_TRANSPORTE WHERE DOCTO_TRANSPORTE_ID = 12689307


DROP TABLE ##Temp_Pedido

SELECT * FROM ##Temp_Consiste_NF WHERE NOTA_FISCAL = '354329'
SELECT * FROM ##Temp_Consiste_NF WHERE NOTA_FISCAL = '359565'
/*
SELECT * FROM ##Temp_Nota WHERE REG_NUM_shipment = 5301867
SELECT * FROM ##Temp_Ship WHERE REG_NUM_shipment = 5301867

Select COUNT(REG_NOTA_FISCAL) From ##Temp_Nota Where REG_NOTA_FISCAL IS NOT NULL And REG_SERIE IS NOT NULL

Select REG_NOTA_FISCAL, REG_SERIE From ##Temp_Nota Where REG_NOTA_FISCAL IS NOT NULL And REG_SERIE IS NOT NULL
except
Select nota_fiscal, serie From ##Temp_Consiste_NF
*/

Select	DISTINCT tmp.REG_NUM_shipment, tmp.docto_transp_ship_Id, ##Temp_Nota.*
From
	##Temp_Ship tmp
	Inner Join ##Temp_Nota on ##Temp_Nota.REG_NUM_shipment = tmp.REG_NUM_shipment
Where
	REG_NOTA_FISCAL IS NOT NULL And REG_SERIE IS NOT NULL	
	And tmp.docto_transp_ship_Id not in (Select docto_transporte_id From ##Temp_Consiste_NF)
AND  tmp.REG_NUM_shipment = 5301867

SELECT * FROM ##Temp_Nota WHERE REG_NUM_SHIPMENT = 5241781
ORDER BY CAST(TEMP_ID AS INT) 

Select  
	A.NOTA_FISCAL_ID,
	A.DOCTO_TRANSPORTE_iD,
	A.NOTA_FISCAL,
	A.SERIE
From    
	NOTA_FISCAL A (Nolock) 
Where 
	A.TAB_STATUS_ID		= 1
And Exists(
	Select	1 
	From	DOCTO_TRANSPORTE B (Nolock) 
		Inner Join dct_shipment ds on B.DOCTO_TRANSPORTE_ID = ds.SHIPMENT_ID And ds.TAB_STATUS_ID = 1
	Where	B.DOCTO_TRANSPORTE_ID = A.DOCTO_TRANSPORTE_ID 
	And B.TAB_STATUS_ID <> 2
	And B.TAB_TIPO_DOCTO_TRANSP_ID	= 401
	And B.fornecedor_id = 765
)
And Exists (	Select 1
		From	##Temp_Nota C 
		WHERE	A.NOTA_FISCAL = C.REG_NOTA_FISCAL
			And A.SERIE = C.REG_SERIE
			And C.REG_NOTA_FISCAL IS NOT NULL And C.REG_SERIE IS NOT NULL
	)

And	A.NOTA_FISCAL = '354329'
And	A.SERIE = '94'

SELECT TAB_TIPO_DOCTO_TRANSP_ID, Fornecedor_id, TAB_STATUS_ID FROM DOCTO_TRANSPORTE WHERE DOCTO_TRANSPORTE_ID = 5551138
SELECT * FROM DCT_SHIPMENT WHERE SHIPMENT_ID = 5551138
SELECT * FROM NOTA_FISCAL WHERE DOCTO_TRANSPORTE_ID = 5551138
SELECT * FROM NOTA_FISCAL WHERE DOCTO_TRANSPORTE_ID = 5301867


SELECT * FROM ##Temp_Ship 
WHERE CONSISTIU = 'S'
ORDER BY CAST(TEMP_ID AS INT)

SELECT	
	tmp.num_shipment_int,
	[cte na dct_shipment] = ds.docto_transporte_id,
	[shipment cte] = ds.shipment_id,
	docto_transp_ship_id = dct_ship.docto_transporte_id,
	fornecedor_Id = dct_ship.fornecedor_id
From	##Temp_Ship  as tmp 
	Left Join DOCTO_TRANSPORTE as dct_cte (Nolock) on dct_cte.DOCTO_TRANSPORTE_ID = tmp.num_shipment_int
	Left Join dct_shipment ds (Nolock) on dct_cte.docto_transporte_id = ds.docto_transporte_id 
		And ds.tab_status_id = 1
	Left Join DOCTO_TRANSPORTE as dct_ship (Nolock) on ds.shipment_id = dct_ship.docto_transporte_id
		And dct_ship.TAB_STATUS_ID = 1
		And dct_ship.tab_tipo_docto_transp_Id = 401
		--And dct_ship.fornecedor_id = 765
Where
	CONSISTIU = 'S'
ORDER BY CAST(TEMP_ID AS INT)


GO

/*
CREATE PROC SP_DEBUG_TEMP 
	@Nome_Tabela Varchar(100) = 'Temp_ship'
AS
DECLARE @OBJECT_ID INT,
	@Qtde_Temporarias Int

SELECT  @Qtde_Temporarias = COUNT(1)
FROM    tempdb.sys.tables T
WHERE   T.name LIKE N'#' + @Nome_Tabela + '[_][_]%'

If @Qtde_Temporarias = 0
	Select Mensagem = 'Não foi encontrada nenhuma temporária com esse nome.'

Select [Qtde Tabelas temporarias encontradas] = @Qtde_Temporarias

IF @Qtde_Temporarias > 1
    BEGIN
	SELECT  *
	FROM    tempdb.sys.tables T
	WHERE   T.name LIKE N'#' + @Nome_Tabela + '[_][_]%'
    END

SELECT  top 1 @OBJECT_ID = object_id
FROM    tempdb.sys.tables T
WHERE   T.name LIKE N'#' + @Nome_Tabela + '[_][_]%'
order by OBJECT_ID desc;

Set @Nome_Tabela = '##' + @Nome_Tabela

--select @Nome_Tabela

--Select @OBJECT_ID

EXEC tempdb..st_SelectPAGEs @OBJECT_ID, @Table_Name = @Nome_Tabela


*/