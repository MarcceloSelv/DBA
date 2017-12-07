exec SP_BUSCA_SP_INSERT 'Veiculo_Fornecedor'
GO
ALTER PROC SP_BUSCA_SP_INSERT
	@Nome_Tabela Varchar(150)
as

Select	[Procedure] = Upper(Nome), [Versão] = Cast(IsNull(Versao.Match, 0) as int), M.Match
From	(SELECT	O.NAME, SM.definition
		FROM	sys.sql_expression_dependencies ED
				INNER JOIN sys.objects O ON O.object_id = ED.referencing_id
				INNER JOIN sys.sql_modules sm ON SM.object_id = O.object_id
		WHERE	ED.referenced_entity_name = @Nome_Tabela
		) T
		--Cross Apply master.dbo.RegExMatches('INSERT[ \t\s]+[\bINTO\b]*[ \t\s]+'+@Nome_Tabela, t.definition, 3) M
		Cross Apply master.dbo.RegExMatches('INSERT[ \t\s(\n|\r|\r\n)+(\bINTO\b)? \t\s(\n|\r|\r\n)]+'+@Nome_Tabela, t.definition, 3) M
		Outer Apply master.dbo.RegExMatches('\d+$', T.NAME, 3) Versao
		Cross Apply (Select Nome = Substring(T.Name, 1, IsNull(Versao.MatchIndex, Len(T.Name) ) )) Name
Order By 1, 2 desc


--SELECT	Separador = 'Separador', OBJECT_NAME(T.object_id), M.*, Versao.*
--FROM	sys.sql_modules T
--		Outer Apply master.dbo.RegExMatches('INSERT[ \t\s(\n|\r|\r\n)+(\bINTO\b)? \t\s(\n|\r|\r\n)]+veiculo_fornecedor', t.definition, 3) M
--		Outer Apply master.dbo.RegExMatches('\d+$', OBJECT_NAME(T.object_id), 3) Versao
--Where	t.object_id = object_id('SP_035_INC_VEICULO_FORNECEDOR19') OR object_id = object_id('SP_027_FIL_IN_VEICULO_FOR20') or object_id = object_id('TR_CGS_GRA_POSICAO_VEICULO')

SP_HELP_SIGNA