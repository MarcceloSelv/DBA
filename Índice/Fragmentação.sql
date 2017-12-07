SELECT  TOP 50
 DB_NAME(dps.database_id) AS [DatabaseName],
 QUOTENAME(DB_NAME(dps.database_id)) + '.' + QUOTENAME(SCHEMA_NAME(O.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(dps.object_id, dps.database_id)) AS TableName,
 'ALTER INDEX ' + QUOTENAME(I.name) + ' ON ' + QUOTENAME(DB_NAME(dps.DATABASE_ID)) + '.' + QUOTENAME(SCHEMA_NAME(O.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(dps.object_id, dps.database_id)) + CASE WHEN dps.avg_fragmentation_in_percent < 80  THEN ' REBUILD ' ELSE ' REBUILD' END,
 I.NAME AS IndexName,
 INDEX_TYPE_DESC AS IndexType,
 avg_fragmentation_in_percent AS AvgPageFragmentation,
 PAGE_COUNT AS PageCounts
FROM	sys.dm_db_index_physical_stats (DB_ID('ECARGO'), NULL, NULL , NULL, 'LIMITED') DPS
	INNER JOIN ECARGO.sys.indexes I
		ON DPS.object_id = I.object_id AND DPS.INDEX_ID = I.index_id
	INNER JOIN ECARGO.sys.objects O ON O.object_id = dps.object_id
--AND DPS.OBJECT_ID = OBJECT_ID('ecargo..docto_transporte')--docto_transporte
Where
	dps.page_count > 1000
Order By AVG_FRAGMENTATION_IN_PERCENT desc

sp_who2
GO
ALTER INDEX [IDX_TTipoEndereco_TS_PessoaId] ON [ECARGO].[dbo].[ENDERECO_PESSOA] REBUILD
ALTER INDEX [INDEX_REGISTRO_ID] ON [ECARGO].[dbo].[LOG_SISTEMA] REBUILD
ALTER INDEX [IDX_DAMDFE] ON [ECARGO].[dbo].[MANIFESTO_ROD] REBUILD 

--SP_UPDATESTATS LOG_GERADOR
SELECT	TOP 50 *
FROM	sys.dm_db_index_physical_stats(DB_ID('ECARGO'), NULL, NULL, NULL, 'LIMITED') 
WHERE	alloc_unit_type_desc = 'IN_ROW_DATA'
AND		index_level = 0
AND		page_count > 100
Order By AVG_FRAGMENTATION_IN_PERCENT desc


ALTER INDEX [IDX_DOCTO_TRANSP_NUM] ON [ECARGO].[dbo].[DOCTO_TRANSPORTE] REBUILD 
ALTER INDEX [IDX_DOCTO_ARQ_CONT2] ON [ECARGO].[dbo].[DOCTO_TRANSPORTE] REBUILD 
ALTER INDEX [INDEX_ID_SISTEMA_EXTERNO_DCT] ON [ECARGO].[dbo].[DOCTO_TRANSPORTE] REBUILD 
ALTER INDEX [_dta_index_DOCTO_TRANSPORTE_7_244820580__K2_K12_K91] ON [ECARGO].[dbo].[DOCTO_TRANSPORTE] REBUILD 
ALTER INDEX [IDX_DCT_PAI_TIPO_PO_EMIS_EDI] ON [ECARGO].[dbo].[DOCTO_TRANSPORTE] REBUILD 
ALTER INDEX [IDX_CLI_DTEMISSAO] ON [ECARGO].[dbo].[DOCTO_TRANSPORTE] REBUILD 
ALTER INDEX [IDX_DOCTO_TRANSP_VEIC_STAT] ON [ECARGO].[dbo].[DOCTO_TRANSPORTE] REBUILD 
ALTER INDEX [idx_dct_TAB_TIPO_DOCTO_TRANSP_ID] ON [ECARGO].[dbo].[DOCTO_TRANSPORTE] REBUILD 

SELECT
    object_id AS objectid,
    index_id AS indexid,
    partition_number AS partitionnum,
    avg_fragmentation_in_percent AS frag
INTO #work_to_do
FROM sys.dm_db_index_physical_stats (DB_ID('ecargo'), NULL, NULL , NULL, 'LIMITED')
WHERE avg_fragmentation_in_percent > 10.0 AND index_id > 0
and page_count > 1000


ALTER INDEX [idx_docto_transporte_id] ON [ECARGO].[dbo].[NOTA_FISCAL] REORGANIZE
ALTER INDEX [_dta_index_NOTA_FISCAL_7_1861998110__K83_K3_K6_1_2_7_8_9_10_11_12_15_20_21_22_28_30_48_63_65_68_72_74_84_85_88_90_121_122_123_] ON [ECARGO].[dbo].[NOTA_FISCAL] REORGANIZE 