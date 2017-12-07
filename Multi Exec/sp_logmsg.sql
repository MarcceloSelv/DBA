SET ANSI_NULLS ON 
SET QUOTED_IDENTIFIER ON
/*
If Object_ID('sp_logmsg', 'P') Is Not Null
        Drop Procedure sp_logmsg
*/
go
 
 
 
 
alter Procedure SP_LogMsg  /*sp_logMsg.sql*/
	@Data_Log_Ini		DateTime = Null,
	@Data_Log_Fim		DateTime = Null,
	@Tab_Tipo_Msg_ID	Int = Null,
	@Texto			Varchar(300) = Null
As
	If @Data_Log_Ini Is Null 
	    Begin
		Set @Data_Log_Ini = Convert(DateTime, Convert(Varchar(10), GetDate(), 111))
		If @Data_Log_Fim Is Null
			Set @Data_Log_Fim = @Data_Log_Ini
	    End

	If @Data_Log_Fim Is Null 
	    Begin
		Set @Data_Log_Fim = Convert(DateTime, Convert(Varchar(10), GetDate(), 111))
		If @Data_Log_Ini Is Null
			Set @Data_Log_Ini = @Data_Log_Fim
	    End

	If Convert(Varchar, @Data_Log_Fim, 108) = '00:00:00'
		Set @Data_Log_Fim = DateAdd(Day, 1, @Data_Log_Fim)

	Select	TTM.descr_tipo_msg	As 'Tipo Msg'	,
		Usu.Nome_Usuario	As 'Usuário'	,
		LM.Data_Log		As 'Data'	,
		LM.msg01				,
		LM.msg02				,
		LM.msg03				,
		LM.msg04				,
		LM.msg05								
	From	Log_Msg			As LM	(NOLOCK)
		Left Join Usuario	As Usu	(NOLOCK)On LM.Usuario_Internet_ID = Usu.Usuario_ID
		Left Join Tab_Tipo_Msg	As TTM	(NOLOCK) On LM.Tab_Tipo_Msg_ID = TTM.Tab_Tipo_Msg_ID
	Where	LM.Data_Log >= @Data_Log_Ini
		And LM.Data_Log < @Data_Log_Fim
		And (LM.TAB_TIPO_MSG_ID = @Tab_Tipo_Msg_ID OR @Tab_Tipo_Msg_ID Is Null)
		And (LM.msg01 Like '%' + @Texto + '%' OR @Texto Is Null)
	Order By
		LM.Data_Log Desc
 
 
 
 
 
 
 
 
 
 
 
go
 
Grant Execute On dbo.sp_logmsg To Public
go
Grant Execute On dbo.sp_logmsg To Sistema
go
