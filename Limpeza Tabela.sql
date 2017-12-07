
BEGIN TRAN

BEGIN TRY

	/*Retira os índices para liberar espaço para a nova tabela*/

	DROP INDEX [IDX_TS_RG_INCLUDE_LS_TTA_US_DTL_RL_FN] ON [dbo].[LOG_SISTEMA]

	ALTER TABLE [dbo].[LOG_SISTEMA] DROP CONSTRAINT [PK__LOG_SISTEMA__53CE4C56]

	/***********************************************************/

	SELECT 
		Log_Sistema_Id
		,Tabela_Sistema_Id
		,Tab_Tipo_Acao_Id
		,Usuario_Id
		,Data_Log
		,Registro_Id
		,Registro_Log
		,Funcao_Id
		,Log_Sistema_Ident
	INTO	LOG_SISTEMA2
	FROM	LOG_SISTEMA LS WITH (TABLOCKX)
	WHERE	NOT Tabela_Sistema_Id = 137
	AND	NOT Tabela_Sistema_Id = 490

	DROP TABLE LOG_SISTEMA

	EXEC SP_RENAME @objname = 'LOG_SISTEMA2', @newname = 'LOG_SISTEMA'

	/****** Object:  Index [PK__LOG_SISTEMA__53CE4C56]    Script Date: 11/6/2015 4:45:53 PM ******/
	ALTER TABLE [dbo].[LOG_SISTEMA] ADD PRIMARY KEY CLUSTERED 
	(
		[Log_Sistema_Ident] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]

	/****** Object:  Index [IDX_TS_RG_INCLUDE_LS_TTA_US_DTL_RL_FN]    Script Date: 11/6/2015 4:45:27 PM ******/
	CREATE NONCLUSTERED INDEX [IDX_TS_RG_INCLUDE_LS_TTA_US_DTL_RL_FN] ON [dbo].[LOG_SISTEMA]
	(
		[Tabela_Sistema_Id] ASC,
		[Registro_Id] ASC
	)
	INCLUDE ( 	[Log_Sistema_Id],
		[Tab_Tipo_Acao_Id],
		[Usuario_Id],
		[Data_Log],
		[Registro_Log],
		[Funcao_Id]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

	CREATE NONCLUSTERED INDEX [IDX_LSID] ON [dbo].[LOG_SISTEMA] (LOG_SISTEMA_ID)
	WITH (ONLINE = OFF)

END TRY
BEGIN CATCH
	ROLLBACK TRAN
	RETURN
END CATCH

COMMIT
