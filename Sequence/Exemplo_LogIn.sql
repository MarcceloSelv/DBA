Update	Docto_Transporte
Set		Flag_Integrado = Case Flag_Integrado
							When 'P' Then Null
							When 'X' Then 'A'
						 End
Where	Flag_Integrado Like '[XP]'

Update	Docto_Pagto
Set		Flag_Integrado = Case Flag_Integrado
							When 'P' Then Null
							When 'X' Then 'A'
						 End
Where	Flag_Integrado Like '[XP]'

Delete T From (
	Select	Id_Max = Row_Number() Over(Partition By Tabela_Sistema_Id, Origem_Id, Mensagem, Message_Id Order By Data_Log Desc), 
			Id_Min = Row_Number() Over(Partition By Tabela_Sistema_Id, Origem_Id, Mensagem, Message_Id Order By Data_Log Asc), *
	From	Temp_Log_Integra
	Where	Data_Log <= Getdate()-45
	) T
Where	Id_Min > 1--Mantém o primeiro registro
And		Id_Max > 1--Mantém o último registro

/*Primeiro domingo do mês*/
If DatePart(WeekDay, GetDate()) = 1 And (((DatePart(Day, GetDate())-1) / 7) + 1) = 1
	Begin
		Alter Sequence Seq.Temp_Log_Integra_Id RESTART
	End
go
--Declare @Table As table(Flag_Integrado_Del Char(1), Flag_Integrado_Ins Char(1))

--Update	Docto_Transporte
--Set		Flag_Integrado = 'X'
--Where	Docto_Transporte_id = 12608

--Begin Tran

--Create Schema Seq
--go
--CREATE SEQUENCE Seq.Temp_Log_Integra_Id
--    START WITH 1  
--    INCREMENT BY 1 ;  
--GO

--Select
--		Temp_Log_Integra_Id = Next Value For Seq.Temp_Log_Integra_Id
--		,Tabela_Sistema_Id
--		,Origem_Id
--		,Destino_Id
--		,Tab_Status_Id
--		,Data_Log
--		,Flag_Reintegra
--		,Sentido
--		,Mensagem
--		,Tipo_Msg_Id
--		,Message_Id
--Into
--		Temp_Log_Integra2
--From
--		Temp_Log_Integra

--Alter Table Temp_Log_Integra2 Alter Column Temp_Log_Integra_Id Int Not Null
--Alter Table Temp_Log_Integra2 Add Default Next Value For Seq.Temp_Log_Integra_Id For Temp_Log_Integra_Id
--Alter Table Temp_Log_Integra2 Add Constraint PK_Temp_Log_Id Primary Key (Temp_Log_Integra_Id)
--Alter Table Temp_Log_Integra2 Add Constraint DF_Temp_Log_Data Default GetDate() For Data_Log

--Drop Table Temp_Log_Integra
		
--Exec SP_Rename 'dbo.Temp_Log_Integra2', 'Temp_Log_Integra'

--Update	Temp_Log_Integra2
--Set		Temp_Log_Integra_Id = Next Value For Seq.Temp_Log_Integra_Id

--Select * From Temp_Log_Integra2 Order By Data_Log

--DROP TABLE TEMP_LOG_INTEGRA2

--Select	Flag_Integrado,
--		Tab_Tipo_Docto_Transp_Id,
--		Docto_Transporte_Id
--From	Docto_Transporte
--Where	Flag_Integrado Like '[XP]'

--Select	Flag_Integrado,
--		Tab_Tipo_Docto_Transp_Id
--From	Docto_Transporte
--Where	Flag_Integrado Like 'X'


--Declare @Sql Varchar (70) = 'Alter Sequence Seq.Temp_Log_Integra_Id RESTART WITH '

--Select @Sql += Cast((Select Count(1) From Temp_Log_Integra) + 1 as varchar)

--Exec (@Sql)

--Alter Sequence Seq.Temp_Log_Integra_Id RESTART




