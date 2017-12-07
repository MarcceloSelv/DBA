/*we add the extended property to provide a description to the  dbo.Customer.InsertionDate column */
EXECUTE sys.sp_addextendedproperty 'MS_Description',
  'the date at which the row was created', 'schema', 'dbo', 'table',
  'Customer', 'column', 'InsertionDate';
-- alternative syntax for SQL 2005
EXECUTE sys.sp_addextendedproperty 'MS_Description',
  'the date at which the row was created', 'schema', 'sales', 'table',
  'Customer', 'column', 'ModifiedDate';
/* and then update the description of the  dbo.Customer.InsertionDate column  */
EXECUTE sys.sp_updateextendedproperty 'MS_Description',
  'the full date at which the row was created', 'schema', 'dbo', 'table',
  'Customer', 'column', 'InsertionDate';
/* we can list this column */
SELECT *
  FROM::fn_listextendedproperty('MS_Description', 'schema', 'dbo', 'table', 'Customer', 'column', 'InsertionDate');
/* or all the properties for the table column of dbo.Customer*/
SELECT *
  FROM::fn_listextendedproperty(DEFAULT, 'schema', 'dbo', 'table', 'Customer', 'column', DEFAULT);
/* And now we drop the MS_Description property of   dbo.Customer.InsertionDate column */
EXECUTE sys.sp_dropextendedproperty 'MS_Description', 'schema', 'dbo',
  'table', 'Customer', 'column', 'InsertionDate';

    SELECT value
  FROM::fn_listextendedproperty
   (@PropertyForAmendment, @Level0, @Name0, @Level1, @Name1, @Level2, @Name2);

Declare @Data_Execucao Datetime = CAST('' as datetime)

EXEC sys.sp_addextendedproperty 
        @name = N'UserId',
        @value = 28,
        @level0type = N'SCHEMA',
		@level0name = 'dbo',
        @level1type = N'PROCEDURE',
		@level1name = 'SP_061_Int_Cli_ERP_SIG';
go
Declare @Data_Execucao Datetime = getdate()-15

EXEC sys.sp_updateextendedproperty 
        @name = N'LastRun',
        @value = @Data_Execucao,
        @level0type = N'SCHEMA',
		@level0name = 'dbo',
        @level1type = N'PROCEDURE',
		@level1name = 'SP_061_Int_Cli_ERP_SIG';

Select OBJECTPROPERTY(OBJECT_ID('SP_061_Int_Cli_ERP_SIG'), 'LastRun')
Select 

SELECT ObjType, objname, name, value  
 FROM fn_listextendedproperty (NULL, 'schema', 'dbo', 'PROCEDURE', 'SP_061_Int_Cli_ERP_SIG', NULL, NULL);    
--get just the "Version" that i created:

SELECT *
FROM fn_listextendedproperty ('LastRun', 'schema', 'dbo', 'PROCEDURE', 'SP_061_Int_Cli_ERP_SIG', NULL, NULL);

SELECT	Data_Execucao			= Case Name When 'LastRun' Then CAST(value as DateTime) End,
		Usuario_Integracao_Id	= Case Name When 'UserId' Then CAST(value as Int) End
FROM	Fn_ListExtendedProperty (Null, 'schema', 'dbo', 'PROCEDURE', 'SP_061_Int_Cli_ERP_SIG', NULL, NULL);


Select *
From (
	SELECT	Nome = Name, Conteudo = Value
	FROM	Fn_ListExtendedProperty (Null, 'schema', 'dbo', 'PROCEDURE', 'SP_061_Int_Cli_ERP_SIG', NULL, NULL)
	) T
		Pivot (Max(Conteudo) For Nome IN ([LastRun], [UserId])
	) P