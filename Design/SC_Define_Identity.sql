DECLARE @SQ VARCHAR(300) = '',
		@Object_Name VARCHAR(300) = 'ESTATISTICA_USUARIO',
		@Column_Ident_Id Int,
		@IsIdentity bit

SELECT @Column_Ident_Id = column_id FROM SYS.columns WHERE object_id = Object_Id(@Object_Name) And Is_Identity = 1

SELECT  @SQ = 'ALTER TABLE ' + QUOTENAME(@Object_Name) + ' DROP CONSTRAINT ' + QUOTENAME(i.name),
		@IsIdentity = Case When @Column_Ident_Id = c.column_id Then 1 Else 0 End
FROM    sys.indexes AS i	INNER JOIN 
        sys.index_columns AS ic ON  i.OBJECT_ID = ic.OBJECT_ID
                                AND i.index_id = ic.index_id
							INNER JOIN 
		sys.columns c on c.column_id = ic.column_id and c.object_id = ic.object_id
WHERE   i.is_primary_key = 1
AND		ic.object_id = OBJECT_ID(@Object_Name)

IF @IsIdentity = 1
    BEGIN
		SELECT Mensagem = 'Coluna Identity já definida nesta tabela.'
		RETURN
	END

SELECT @SQ += CHAR(13) + CHAR(10) + 'ALTER TABLE ' + QUOTENAME(@Object_Name) + ' ADD ' + QUOTENAME(@Object_Name + '_Ident') + ' Int Not Null Identity Primary Key'

SELECT @SQ
