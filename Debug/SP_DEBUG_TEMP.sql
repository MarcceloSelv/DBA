SET ANSI_NULLS ON 
SET QUOTED_IDENTIFIER  ON 
/*
If Object_ID('SP_DEBUG_TEMP', 'P') Is Not Null
        Drop Procedure SP_DEBUG_TEMP
*/
go
 

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


 
go
 
Grant Execute On dbo.SP_DEBUG_TEMP To Public
go
Grant Execute On dbo.SP_DEBUG_TEMP To Sistema
go
