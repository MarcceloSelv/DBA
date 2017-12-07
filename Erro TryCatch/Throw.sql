begin tran teste1

Begin Try

	Update	Tab_Status
	Set		Desc_Status += '1'
	Where	Tab_Status_id = 1

	;Throw 50001, 'erro', 1

End Try
Begin Catch

	Select top 1 * From Tab_Status
	Print Error_Message()
	Rollback

	;Throw --50001, 'erro 2', 1

End Catch

--Rollback