EXEC SP_050_GERA_EDI_OCOREN55 N, 20, null, 5, null, null, null , null 

sp_ddlevents SP_050_GERA_EDI_OCOREN55

SELECT OBJECT_NAME(OBJECT_ID), * FROM SYS.sql_modules WHERE definition LIKE '%@FLAG_INTEGRACAO%'

SELECT * FROM sys.sql_expression_dependencies WHERE referenced_entity_name = 'Sp_050_gra_sol_cont_os_fecha03'
SELECT * FROM sys.sql_expression_dependencies WHERE referencing_id = object_id('Sp_050_gra_sol_cont_os_fecha03')
SELECT * FROM sys.sql_expression_dependencies WHERE referencing_id = object_id('SP_050_INTEGRA_TRACKING_OCOREN')

--SP_050_GERA_EDI_OCOREN55
--SP_050_INTEGRA_TRACKING_OCOREN
GO
--+ Row_Number() Over(Partition By cte.referencing_id Order By (Select 1))
CREATE PROC SP_DEPENDS_SIG
	@Object_Name Varchar(150)
as
;With CTE AS (
	Select	NestLevel = 0, Linha = Row_Number() Over(Order By (Select 1)) * 1000, sed.referencing_id, sed.referenced_entity_name, o.*--, o.object_id
	From	sys.sql_expression_dependencies sed
			Inner Join sys.objects o On o.[name] = sed.referenced_entity_name
	Where	sed.referencing_id = object_id('SP_050_GRA_FEC_OS_LOTE_TIP02')
	And		o.type NOT IN ('U', 'V')
	Union All
	Select	NestLevel + 1, Linha + NestLevel + (Row_Number() Over(Order By (Select 1))  * 100), sed.referencing_id, sed.referenced_entity_name, o.*
	From	sys.sql_expression_dependencies sed
			Inner Join CTE On sed.referencing_id = object_id(cte.referenced_entity_name)
			Inner Join sys.objects o On o.[name] = sed.referenced_entity_name
	Where	o.type NOT IN ('U', 'V')
)

SELECT	Linha - (Row_Number() Over(Partition By referencing_id Order By (Select 1)) * 100), * 
FROM	CTE
ORDER BY 1

select * from sys.sql_dependencies

SP_050_GRA_FEC_OS_LOTE_TIP02
Sp_050_alt_container_osac02
SP_ECR_CALC_OS24
SP_SIG_INC_LOG_SISTEMA3
SP_ECR_INC_LOG_SISTEMA_TEXTO
SP_036_VAL_ICMS_ISS_OS5
SP_036_VAL_TARIFA_CHEIA_PROV11
SP_036_VAL_TARIFA_CHEIA_PROV9
SP_036_VAL_TARIFA_ESCOLTA2
SP_036_VAL_TARIFA_ESCOLTA4
SP_036_VAL_TARIFA_OVA_DESOVA1
SP_036_VAL_TARIFA_OVA_DESOVA3
SP_036_CON_DADOS_ICMS_OS3
SP_CGS_BUSCA_DADOS_ICMS2
SP_CGS_BUSCA_UFS_ICMS

select top 50 * from cte order by CTE_ID desc
select top 50 * from arquivo_cte order by arquivo_cte_id desc



WITH DepTree 
 AS 
(
	Select  o.name, o.[object_id] AS referenced_id , 
			o.name AS referenced_name, 
			o.[object_id] AS referencing_id, 
			o.name AS referencing_name,  
			0 AS NestLevel
	From	sys.objects o 
	Where	o.is_ms_shipped = 0
	And		o.object_id = object_id('SP_050_GRA_FEC_OS_LOTE_TIP02')
	--AND o.type = 'V'
    UNION ALL
    Select r.name, d1.referenced_id,  
		   OBJECT_NAME( d1.referenced_id) , 
		   d1.referencing_id, 
		   OBJECT_NAME( d1.referencing_id) , 
		   NestLevel + 1
     From  sys.sql_expression_dependencies d1 
				JOIN DepTree r  ON d1.referenced_id =  r.referencing_id
)
 SELECT DISTINCT name as ViewName, MAX(NestLevel) AS MaxNestLevel
  FROM DepTree
 GROUP BY name
 --HAVING MAX(NestLevel) > 4
 ORDER BY MAX(NestLevel) DESC; 