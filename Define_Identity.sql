Declare @SQ					Varchar(300) = '',
		@Object_Name		Varchar(300) = (Select master.dbo.udf_TitleCase('ESTATISTICA_USUARIO')),
		@Column_PK_Name		Varchar(100),
		@Column_Ident_Id	Int,
		@IsIdentity			bit,
		@Enter				Char(2) = Char(13) + Char(10)

Select @Column_Ident_Id = column_id From SYS.columns Where object_id = Object_Id(@Object_Name) And Is_Identity = 1

Select  @Sq = 'ALTER TABLE ' + QuoteName(@Object_Name) + ' DROP CONSTRAINT ' + QuoteName(i.name),
		@Column_PK_Name = Case c.Is_Identity When 0 Then QuoteName(c.name) + ' ' + Type_Name(c.user_type_id) End,
		@IsIdentity = Case When @Column_Ident_Id = c.column_id Then 1 Else 0 End
From	sys.indexes AS i
		Inner Join sys.index_columns AS ic ON  i.object_id = ic.object_id
                                AND i.index_id = ic.index_id
		Inner Join sys.columns c on c.column_id = ic.column_id and c.object_id = ic.object_id
Where   i.is_primary_key = 1
And		ic.object_id = Object_Id(@Object_Name)

If @IsIdentity = 1
    Begin
		Print 'Coluna Identity já definida nesta tabela.'
		Return;
	End

Print @Sq 
Print 'Go'
Print 'ALTER TABLE ' + QuoteName(@Object_Name) + ' ADD ' + QUOTENAME(@Object_Name + '_Ident') + ' Int Not Null Identity Primary Key'
Print 'Go'
Print 'ALTER TABLE ' + QuoteName(@Object_Name) + ' Alter Column ' + @Column_PK_Name + ' Not Null'