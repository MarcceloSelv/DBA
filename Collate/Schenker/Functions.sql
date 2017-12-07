USE [SCHENKER]
GO

/****** Object:  UserDefinedFunction [dbo].[FN_036_QUEBRA_STRING]    Script Date: 21/07/2015 16:25:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[FN_036_QUEBRA_STRING]
(
    @TAMANHO INT,
    @STRING  VARCHAR(8000)
)
RETURNS @RESULTS TABLE
                (
                temp_id INT IDENTITY(1,1),
                items VARCHAR(8000) NULL
                )
AS

BEGIN

DECLARE
    @POSICAO                INT , 
    @STR_AUX                VARCHAR(8000),
    @LINHA                  VARCHAR(200),
    @POSICAO_RETROCESSO     INT , 
    @CONTEUDO_POSICAO_ATUAL CHAR(1), 
    @CONTEUDO_PROX_POSICAO  CHAR(1),
    @TAM_TOTAL              INT


/*============================================================================================================*/
    
    SET @STR_AUX = RTRIM(LTRIM(@STRING)) + ' '
    SET @TAM_TOTAL = LEN(@STR_AUX)
    SET @POSICAO = 1

    WHILE (@POSICAO <= @TAM_TOTAL)
        BEGIN
            /* INI QUEBRA A STRING ATÉ O ÚLTIMO CAMPO EM BRANCO OU A ÚLTIMA VIRGULA EXISTENTE NA STRING */
            SET @CONTEUDO_POSICAO_ATUAL = SUBSTRING(@STR_AUX, @POSICAO + @TAMANHO - 1, 1)
            SET @CONTEUDO_PROX_POSICAO = SUBSTRING(@STR_AUX, @POSICAO + @TAMANHO, 1)
            SET @POSICAO_RETROCESSO = @POSICAO + @TAMANHO

            /* ESTÁ CORTANDO UMA PALAVRA NO MEIO, RETROCEDO ATÉ BRANCO */
            IF @CONTEUDO_POSICAO_ATUAL IS NOT NULL AND @CONTEUDO_PROX_POSICAO IS NOT NULL 
                AND @CONTEUDO_POSICAO_ATUAL NOT IN(' ', ',') 
                AND @CONTEUDO_PROX_POSICAO != ' '
                AND @CONTEUDO_PROX_POSICAO != '/'
                BEGIN
                    WHILE (@CONTEUDO_POSICAO_ATUAL != '' AND @CONTEUDO_POSICAO_ATUAL != ',' AND @CONTEUDO_POSICAO_ATUAL != '/' AND @CONTEUDO_POSICAO_ATUAL IS NOT NULL)
                        BEGIN
                            SET @POSICAO_RETROCESSO = @POSICAO_RETROCESSO - 1
                            SET @CONTEUDO_POSICAO_ATUAL = SUBSTRING(@STR_AUX, @POSICAO_RETROCESSO, 1)
                        END
                END  
            /* FIM QUEBRA A STRING ATÉ O ÚLTIMO CAMPO EM BRANCO OU A ÚLTIMA VIRGULA EXISTENTE NA STRING */

            IF @CONTEUDO_POSICAO_ATUAL = ',' OR @CONTEUDO_POSICAO_ATUAL = '/'
                SET @POSICAO_RETROCESSO = @POSICAO_RETROCESSO + 1
                
            /* SE O RETROCESSO FOR MENOR QUE A STRING, PARA NÃO DAR ERRO QUEBRA A STRING PELO TAMANHO DO PARAMETRO */
            IF @POSICAO_RETROCESSO < @POSICAO
                SET @POSICAO_RETROCESSO = @POSICAO + @TAMANHO 

            SET @LINHA = SUBSTRING(@STR_AUX,@POSICAO, @POSICAO_RETROCESSO - @POSICAO)
            SET @LINHA = LTRIM(RTRIM(@LINHA))

            INSERT INTO @RESULTS
            VALUES(@LINHA)

            SET @POSICAO = @POSICAO_RETROCESSO
        END

    RETURN

END
 

GO

/****** Object:  UserDefinedFunction [dbo].[FN_036_QUEBRA_STRING1]    Script Date: 21/07/2015 16:25:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[FN_036_QUEBRA_STRING1] 
(
    @P_I_TAMANHO        AS INT,
    @P_V_STRING         AS VARCHAR(8000),
    @P_V_SEPARADORES    AS VARCHAR(255)
)
RETURNS 
    @RESULTS TABLE
    (
        temp_id     INT IDENTITY(1,1),
        items       VARCHAR(8000) NULL
    )
AS 

BEGIN

    DECLARE 
        @V_LINHA                    AS VARCHAR(8000)

    DECLARE 
        @I_INPUTLEN                 AS INT,
        @I_CURPOS                   AS INT,
        @I_CURLINESTART             AS INT,
        @I_POSOFLASTSEPARATOR       AS INT

/*===========================================================================================================================*/

    -- SAVE THE LENGTH OF THE INPUT
    SET @I_INPUTLEN = LEN(@P_V_STRING)

    -- START BOTH CHARACTER POINTERS AT THE BEGINNING
    SET @I_CURPOS = 1
    SET @I_CURLINESTART = 1
    SET @I_POSOFLASTSEPARATOR = 0  

    SET @V_LINHA = '' -- EMPTY STRING, NOT NULL

    SET @P_V_SEPARADORES = ISNULL(@P_V_SEPARADORES, SPACE(0))
/*
    IF LEN(@P_V_SEPARADORES) = 0
        SET @P_V_SEPARADORES = SPACE(1)
*/
    -- LOOP THROUGH ALL CHARACTERS OF THE INPUT
    WHILE (@I_CURPOS < @I_INPUTLEN)
        BEGIN
            -- MAKE NOTE OF THE LAST SEPARATOR FOR USE LATER.
            IF CHARINDEX(SUBSTRING(@P_V_STRING, @I_CURPOS, 1), @P_V_SEPARADORES, 1) > 0
                 SET @I_POSOFLASTSEPARATOR = @I_CURPOS

            -- ONCE WE HAVE ENOUGH FOR A LINE, GO BACK TO
            -- THE LAST SEPARATOR WE SAW AND END THE LINE THERE.
            IF @I_CURPOS >= (@I_CURLINESTART + @P_I_TAMANHO - 1 )
                BEGIN
                    IF @I_POSOFLASTSEPARATOR = 0 
                        BEGIN
                            -- CASES WHERE A WORD IS LONGER THAN THE LINE LENGTH
                            SET @V_LINHA = SUBSTRING(@P_V_STRING, @I_CURLINESTART, @P_I_TAMANHO)
                            SET @V_LINHA = LTRIM(RTRIM(@V_LINHA))
                            
                            -- APPEND THE NEW TO THE RESULT
                            INSERT INTO @RESULTS
                            VALUES(@V_LINHA)
                            
                            SET @I_CURLINESTART = @I_CURLINESTART + @P_I_TAMANHO                    
                        END
                    ELSE 
                        BEGIN
                            SET @V_LINHA = SUBSTRING(@P_V_STRING, @I_CURLINESTART, @I_POSOFLASTSEPARATOR - @I_CURLINESTART + 1) --)) + @LINETERMINATOR
                            SET @V_LINHA = LTRIM(RTRIM(@V_LINHA))
                            
                            -- APPEND THIS NEW LINE TO THE RESULT
                            INSERT INTO @RESULTS
                            VALUES(@V_LINHA)
                            
                            -- RESET THE NEXT LINE'S STARTING POINT TO THE
                            -- POINT USED FOR THE LAST ONE'S END + 1.
                            SET @I_CURLINESTART = @I_POSOFLASTSEPARATOR + 1
                            
                            -- DON'T HAVE ONE NOW.
                            SET @I_POSOFLASTSEPARATOR = 0
                        END 
                    
                    -- REMOVE ANY LEADING SEPARATORS FROM THE NEW LINE.
                    WHILE CHARINDEX(SUBSTRING(@P_V_STRING, @I_CURLINESTART, 1), @P_V_SEPARADORES, 1) > 0 
                        BEGIN 
                            SET @I_CURLINESTART = @I_CURLINESTART + 1
                            SET @I_CURPOS = @I_CURLINESTART + 1 
                        END
                END

            -- INCREMENT OUR CURRENT POSITION.
            SET @I_CURPOS = @I_CURPOS + 1
        END

    -- IF THE LOOP ENDS BEFORE WE ADD ALL THE TEXT, ADD IT NOW.
    SET @V_LINHA = SUBSTRING(@P_V_STRING, @I_CURLINESTART, @I_INPUTLEN - @I_CURLINESTART + 1)
    SET @V_LINHA = LTRIM(RTRIM(@V_LINHA))
    
    INSERT INTO @RESULTS
    VALUES(@V_LINHA)
    
    RETURN
END
 
 

GO

/****** Object:  UserDefinedFunction [dbo].[FN_040_QUEBRA_STRING]    Script Date: 21/07/2015 16:25:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[FN_040_QUEBRA_STRING]
(
    @TAMANHO INT,
    @STRING  VARCHAR(8000)
)
RETURNS @RESULTS TABLE
                (
                temp_id INT IDENTITY(1,1),
                items VARCHAR(8000) NULL
                )
AS

BEGIN

DECLARE
    @POSICAO                INT , 
    @STR_AUX                VARCHAR(8000),
    @LINHA                  VARCHAR(200),
    @POSICAO_RETROCESSO     INT , 
    @CONTEUDO_POSICAO_ATUAL CHAR(1), 
    @CONTEUDO_PROX_POSICAO  CHAR(1),
    @TAM_TOTAL              INT


/*============================================================================================================*/
    
    SET @STR_AUX = RTRIM(LTRIM(@STRING)) + ' '
    SET @TAM_TOTAL = LEN(@STR_AUX)
    SET @POSICAO = 1

    WHILE (@POSICAO <= @TAM_TOTAL)
        BEGIN
            /* INI QUEBRA A STRING ATÉ O ÚLTIMO CAMPO EM BRANCO OU A ÚLTIMA VIRGULA EXISTENTE NA STRING */
            SET @CONTEUDO_POSICAO_ATUAL = SUBSTRING(@STR_AUX, @POSICAO + @TAMANHO - 1, 1)
            SET @CONTEUDO_PROX_POSICAO = SUBSTRING(@STR_AUX, @POSICAO + @TAMANHO, 1)
            SET @POSICAO_RETROCESSO = @POSICAO + @TAMANHO

            /* ESTÁ CORTANDO UMA PALAVRA NO MEIO, RETROCEDO ATÉ BRANCO */
            IF @CONTEUDO_POSICAO_ATUAL IS NOT NULL AND @CONTEUDO_PROX_POSICAO IS NOT NULL 
                AND @CONTEUDO_POSICAO_ATUAL NOT IN(' ', ',') 
                AND @CONTEUDO_PROX_POSICAO != ' '
                AND @CONTEUDO_PROX_POSICAO != '/'
                BEGIN
                    WHILE (@CONTEUDO_POSICAO_ATUAL != '' AND @CONTEUDO_POSICAO_ATUAL != ',' AND @CONTEUDO_POSICAO_ATUAL != '/' AND @CONTEUDO_POSICAO_ATUAL IS NOT NULL)
                        BEGIN
                            SET @POSICAO_RETROCESSO = @POSICAO_RETROCESSO - 1
                            SET @CONTEUDO_POSICAO_ATUAL = SUBSTRING(@STR_AUX, @POSICAO_RETROCESSO, 1)
                        END
                END  
            /* FIM QUEBRA A STRING ATÉ O ÚLTIMO CAMPO EM BRANCO OU A ÚLTIMA VIRGULA EXISTENTE NA STRING */

            IF @CONTEUDO_POSICAO_ATUAL = ',' OR @CONTEUDO_POSICAO_ATUAL = '/'
                SET @POSICAO_RETROCESSO = @POSICAO_RETROCESSO + 1
                
            /* SE O RETROCESSO FOR MENOR QUE A STRING, PARA NÃO DAR ERRO QUEBRA A STRING PELO TAMANHO DO PARAMETRO */
            IF @POSICAO_RETROCESSO < @POSICAO
                SET @POSICAO_RETROCESSO = @POSICAO + @TAMANHO 

            SET @LINHA = SUBSTRING(@STR_AUX,@POSICAO, @POSICAO_RETROCESSO - @POSICAO)
            SET @LINHA = LTRIM(RTRIM(@LINHA))

            INSERT INTO @RESULTS
            VALUES(@LINHA)

            SET @POSICAO = @POSICAO_RETROCESSO
        END

    RETURN

END
 
 

GO

/****** Object:  UserDefinedFunction [dbo].[FN_SPLIT]    Script Date: 21/07/2015 16:25:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[FN_SPLIT](@String nvarchar(4000), @Delimiter char(1))
RETURNS @Results TABLE (Items nvarchar(4000) NULL)
AS

BEGIN
    DECLARE @INDEX INT
    DECLARE @SLICE nvarchar(4000)

	SELECT @STRING = LTRIM(RTRIM(@STRING))

    -- HAVE TO SET TO 1 SO IT DOESNT EQUAL Z
    --     ERO FIRST TIME IN LOOP
    SELECT @INDEX = 1
    WHILE @INDEX !=0


        BEGIN	
        	-- GET THE INDEX OF THE FIRST OCCURENCE OF THE FN_SPLIT CHARACTER
        	SELECT @INDEX = CHARINDEX(@Delimiter,@STRING)
        	-- NOW PUSH EVERYTHING TO THE LEFT OF IT INTO THE SLICE VARIABLE
        	IF @INDEX !=0
        		SELECT @SLICE = LEFT(@STRING,@INDEX - 1)
        	ELSE
        		SELECT @SLICE = @STRING
			SELECT @SLICE = RTRIM(LTRIM(@SLICE))

        	-- PUT THE ITEM INTO THE RESULTS SET
        	INSERT INTO @Results(Items) VALUES(@SLICE)
        	-- CHOP THE ITEM REMOVED OFF THE MAIN STRING
        	SELECT @STRING = RIGHT(@STRING,LEN(@STRING) - @INDEX)
        	SELECT @STRING = RTRIM(LTRIM(@STRING))
        	-- BREAK OUT IF WE ARE DONE
        	IF LEN(@STRING) = 0 BREAK
    END
    RETURN
END

 
 
 

GO

/****** Object:  UserDefinedFunction [dbo].[FN_SPLIT_MS]    Script Date: 21/07/2015 16:25:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[FN_SPLIT_MS]
(
    @STRING         AS VARCHAR(MAX), 
    @DELIMITER      AS CHAR(1)
)
RETURNS 
    @RESULTS TABLE
    (
        temp_id     INT IDENTITY(1,1),
        items       VARCHAR(MAX) NULL
    )
AS

BEGIN

    DECLARE 
        @INDEX      AS INT
        
    DECLARE 
        @SLICE      AS VARCHAR(MAX)

/*============================================================================================================*/

    IF @STRING IS NOT NULL
        BEGIN
            /* TRATAMENTO PARA CONSIDERAR O ULTIMO ITEM DA STRING, MESMO QUE SEJA '' */
	        SET @STRING = LTRIM(RTRIM(@STRING)) + @DELIMITER

            -- HAVE TO SET TO 1 SO IT DOESNT EQUAL ZERO FIRST TIME IN LOOP
            SET @INDEX = 1

            WHILE @INDEX !=0
                BEGIN	
        	        -- GET THE INDEX OF THE FIRST OCCURENCE OF THE FN_SPLIT_MS CHARACTER
        	        SET @INDEX = CHARINDEX(@DELIMITER, @STRING)

        	        -- NOW PUSH EVERYTHING TO THE LEFT OF IT INTO THE SLICE VARIABLE
        	        IF @INDEX !=0
        		        SET @SLICE = LEFT(@STRING, @INDEX - 1)
        	        ELSE
        		        SET @SLICE = @STRING

			        SET @SLICE = RTRIM(LTRIM(@SLICE))

        	        -- PUT THE ITEM INTO THE RESULTS SET
        	        INSERT INTO @RESULTS
                    (
                        items
                    ) 
                    VALUES
                    (
                        @SLICE
                    )

        	        -- CHOP THE ITEM REMOVED OFF THE MAIN STRING
        	        SET @STRING = RIGHT(@STRING, LEN(@STRING) - @INDEX)
        	        SET @STRING = RTRIM(LTRIM(@STRING))

        	        -- BREAK OUT IF WE ARE DONE
        	        IF LEN(@STRING) = 0 OR @STRING IS NULL
                        BREAK
                END
        END
    RETURN
END
 
 

GO

/****** Object:  UserDefinedFunction [dbo].[FN_SPLIT_TXT_QUERY]    Script Date: 21/07/2015 16:25:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[FN_SPLIT_TXT_QUERY]
(
    @STRING         AS VARCHAR(MAX) 
)
RETURNS 
    @RESULTS TABLE
    (
        temp_id     INT IDENTITY(1,1),
        items       VARCHAR(MAX) NULL
    )
AS

BEGIN

    DECLARE 
        @INDEX      AS INT,
        @DELIMITER      AS CHAR(2)
        
    DECLARE 
        @SLICE      AS VARCHAR(MAX)

/*============================================================================================================*/

	SET @DELIMITER = '__'

    IF @STRING IS NOT NULL
        BEGIN
            /* TRATAMENTO PARA CONSIDERAR O ULTIMO ITEM DA STRING, MESMO QUE SEJA '' */
	        SET @STRING = LTRIM(RTRIM(@STRING)) + @DELIMITER

            -- HAVE TO SET TO 1 SO IT DOESNT EQUAL ZERO FIRST TIME IN LOOP
            SET @INDEX = 1

            WHILE @INDEX !=0
                BEGIN	
        	        -- GET THE INDEX OF THE FIRST OCCURENCE OF THE FN_SPLIT_MS CHARACTER
        	        SET @INDEX = CHARINDEX(@DELIMITER, @STRING)

        	        -- NOW PUSH EVERYTHING TO THE LEFT OF IT INTO THE SLICE VARIABLE
        	        IF @INDEX !=0
        		        SET @SLICE = LEFT(@STRING, @INDEX - 1)
        	        ELSE
        		        SET @SLICE = @STRING

			        SET @SLICE = RTRIM(LTRIM(@SLICE))

        	        -- PUT THE ITEM INTO THE RESULTS SET
        	        INSERT INTO @RESULTS
                    (
                        items
                    ) 
                    VALUES
                    (
                        @SLICE
                    )

        	        -- CHOP THE ITEM REMOVED OFF THE MAIN STRING
        	        SET @STRING = RIGHT(@STRING, LEN(@STRING) - (@INDEX + 1))
        	        SET @STRING = RTRIM(LTRIM(@STRING))

        	        -- BREAK OUT IF WE ARE DONE
        	        IF LEN(@STRING) = 0 OR @STRING IS NULL
                        BREAK
                END
        END
    RETURN
END
 
 
 

GO

/****** Object:  UserDefinedFunction [dbo].[FN_SPLIT2]    Script Date: 21/07/2015 16:25:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[FN_SPLIT2]
(
    @STRING VARCHAR(8000), 
    @DELIMITER CHAR(1)
)
RETURNS @RESULTS TABLE
                (
                ITEMS VARCHAR(8000) NULL
                )
AS

BEGIN

    DECLARE @INDEX INT
    DECLARE @SLICE VARCHAR(8000)

/*============================================================================================================*/

    IF @STRING IS NOT NULL
        BEGIN
            /* TRATAMENTO PARA CONSIDERAR O ULTIMO ITEM DA STRING, MESMO QUE SEJA '' */
	        SET @STRING = LTRIM(RTRIM(@STRING)) + @DELIMITER

            -- HAVE TO SET TO 1 SO IT DOESNT EQUAL ZERO FIRST TIME IN LOOP
            SET @INDEX = 1

            WHILE @INDEX !=0
                BEGIN	
        	        -- GET THE INDEX OF THE FIRST OCCURENCE OF THE FN_SPLIT2 CHARACTER
        	        SET @INDEX = CHARINDEX(@DELIMITER, @STRING)

        	        -- NOW PUSH EVERYTHING TO THE LEFT OF IT INTO THE SLICE VARIABLE
        	        IF @INDEX !=0
        		        SET @SLICE = LEFT(@STRING, @INDEX - 1)
        	        ELSE
        		        SET @SLICE = @STRING

			        SET @SLICE = RTRIM(LTRIM(@SLICE))

        	        -- PUT THE ITEM INTO THE RESULTS SET
        	        INSERT INTO @RESULTS
                    (
                        items
                    ) 
                    VALUES
                    (
                        @SLICE
                    )

        	        -- CHOP THE ITEM REMOVED OFF THE MAIN STRING
        	        SET @STRING = RIGHT(@STRING, LEN(@STRING) - @INDEX)
        	        SET @STRING = RTRIM(LTRIM(@STRING))

        	        -- BREAK OUT IF WE ARE DONE
        	        IF LEN(@STRING) = 0 
                        BREAK
                END
        END
    RETURN
END
 
 
 

GO

/****** Object:  UserDefinedFunction [dbo].[FN_SPLIT3]    Script Date: 21/07/2015 16:25:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 CREATE FUNCTION [dbo].[FN_SPLIT3]
(
    @STRING VARCHAR(MAX), 
    @DELIMITER CHAR(1)
)
RETURNS @RESULTS TABLE
                (
                    items VARCHAR(MAX) NULL
                )
AS

BEGIN

    DECLARE @INDEX INT
    DECLARE @SLICE VARCHAR(MAX)

/*============================================================================================================*/

    IF @STRING IS NOT NULL
        BEGIN
            /* TRATAMENTO PARA CONSIDERAR O ULTIMO ITEM DA STRING, MESMO QUE SEJA '' */
	        SET @STRING = LTRIM(RTRIM(@STRING)) + @DELIMITER

            -- HAVE TO SET TO 1 SO IT DOESNT EQUAL ZERO FIRST TIME IN LOOP
            SET @INDEX = 1

            WHILE @INDEX !=0
                BEGIN	
        	        -- GET THE INDEX OF THE FIRST OCCURENCE OF THE FN_SPLIT3 CHARACTER
        	        SET @INDEX = CHARINDEX(@DELIMITER, @STRING)

        	        -- NOW PUSH EVERYTHING TO THE LEFT OF IT INTO THE SLICE VARIABLE
        	        IF @INDEX !=0
        		        SET @SLICE = LEFT(@STRING, @INDEX - 1)
        	        ELSE
        		        SET @SLICE = @STRING

			        SET @SLICE = RTRIM(LTRIM(@SLICE))

        	        -- PUT THE ITEM INTO THE RESULTS SET
        	        INSERT INTO @RESULTS
                    (
                        items
                    ) 
                    VALUES
                    (
                        @SLICE
                    )

        	        -- CHOP THE ITEM REMOVED OFF THE MAIN STRING
        	        SET @STRING = RIGHT(@STRING, LEN(@STRING) - @INDEX)
        	        SET @STRING = RTRIM(LTRIM(@STRING))

        	        -- BREAK OUT IF WE ARE DONE
        	        IF LEN(@STRING) = 0 OR @STRING IS NULL
                        BREAK
                END
        END
    RETURN
END
 

 
 
 

GO

/****** Object:  UserDefinedFunction [dbo].[FN_SPLIT4]    Script Date: 21/07/2015 16:25:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[FN_SPLIT4]
(
    @STRING         AS VARCHAR(MAX), 
    @DELIMITER      AS CHAR(1)
)
RETURNS 
    @RESULTS TABLE
    (
        temp_id     INT IDENTITY(1,1),
        items       VARCHAR(MAX) NULL
    )
AS

BEGIN

    DECLARE 
        @INDEX      AS INT
        
    DECLARE 
        @SLICE      AS VARCHAR(MAX)

/*============================================================================================================*/

    IF @STRING IS NOT NULL
        BEGIN
            /* TRATAMENTO PARA CONSIDERAR O ULTIMO ITEM DA STRING, MESMO QUE SEJA '' */
	        SET @STRING = LTRIM(RTRIM(@STRING)) + @DELIMITER

            -- HAVE TO SET TO 1 SO IT DOESNT EQUAL ZERO FIRST TIME IN LOOP
            SET @INDEX = 1

            WHILE @INDEX !=0
                BEGIN	
        	        -- GET THE INDEX OF THE FIRST OCCURENCE OF THE FN_SPLIT_MS CHARACTER
        	        SET @INDEX = CHARINDEX(@DELIMITER, @STRING)

        	        -- NOW PUSH EVERYTHING TO THE LEFT OF IT INTO THE SLICE VARIABLE
        	        IF @INDEX !=0
        		        SET @SLICE = LEFT(@STRING, @INDEX - 1)
        	        ELSE
        		        SET @SLICE = @STRING

			        SET @SLICE = RTRIM(LTRIM(@SLICE))

        	        -- PUT THE ITEM INTO THE RESULTS SET
        	        INSERT INTO @RESULTS
                    (
                        items
                    ) 
                    VALUES
                    (
                        @SLICE
                    )

        	        -- CHOP THE ITEM REMOVED OFF THE MAIN STRING
        	        SET @STRING = RIGHT(@STRING, LEN(@STRING) - @INDEX)
        	        SET @STRING = RTRIM(LTRIM(@STRING))

        	        -- BREAK OUT IF WE ARE DONE
        	        IF LEN(@STRING) = 0 OR @STRING IS NULL
                        BREAK
                END
        END
    RETURN
END
 
 
 

GO

/****** Object:  UserDefinedFunction [SSRS].[SplitValues]    Script Date: 21/07/2015 16:25:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [SSRS].[SplitValues] 
	( @Codes VARCHAR(MAX) )
RETURNS 
	@T1 TABLE (Code VARCHAR(100))
AS
BEGIN
	DECLARE @STR VARCHAR(100)
	SET @STR = @Codes

	;WITH codeValues AS
	(
	SELECT 0 A, 1 B
	UNION ALL
	SELECT B, CHARINDEX(',', @STR, B) + LEN(',')
	FROM codeValues
	WHERE B > A
	)
	INSERT INTO @T1 (Code)
	SELECT CONVERT(INT,SUBSTRING(@STR,A,
	CASE WHEN B > LEN(',') THEN B-A-LEN(',') ELSE LEN(@STR) - A + 1 END)) VALUE   
	FROM codeValues WHERE A >0
	
	RETURN 
END

GO

/****** Object:  UserDefinedFunction [dbo].[SplitString_Xml]    Script Date: 21/07/2015 16:25:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[SplitString_Xml]
(
   @List       NVARCHAR(4000),
   @Delimiter  NVARCHAR(255)
)
RETURNS TABLE
WITH SCHEMABINDING
AS
   RETURN 
   (  
      SELECT Id = Row_Number() OVER (ORDER BY (SELECT 1)), Item = y.i.value('(./text())[1]', 'nvarchar(4000)')
      FROM 
      ( 
        SELECT x = CONVERT(XML, '<i>'
          + REPLACE(@List, @Delimiter, '</i><i>') 
          + '</i>').query('.')
      ) AS a CROSS APPLY x.nodes('i') AS y(i)
   );
 
 
 

GO

