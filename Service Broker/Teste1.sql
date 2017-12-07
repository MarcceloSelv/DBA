ALTER DATABASE DESENVOLVIMENTO SET ENABLE_BROKER

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'marccelo'

CREATE MESSAGE TYPE Texto VALIDATION = NONE;
 
CREATE CONTRACT Contrato ( Texto SENT BY INITIATOR );
 
CREATE QUEUE Fila WITH STATUS = ON;
 
CREATE SERVICE Servico ON QUEUE Fila(Contrato);
 
GO











ALTER DATABASE DESENVOLVIMENTO SET ENABLE_BROKER

CREATE DATABASE SERV_BROKER 

ALTER DATABASE SERV_BROKER SET ENABLE_BROKER

--DROP TABLE Resultados

CREATE TABLE Resultados (Id UNIQUEIDENTIFIER, Texto VARCHAR(100));
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'marccelo';
 
GO
CREATE MESSAGE TYPE Texto VALIDATION = NONE;
 
CREATE CONTRACT Contrato ( Texto SENT BY INITIATOR );
 
CREATE QUEUE Fila WITH STATUS = ON;
 
CREATE SERVICE Servico ON QUEUE Fila(Contrato);
GO

alter PROC USP_Ativacao AS
BEGIN
    DECLARE @Mensagem VARCHAR(100)
    , @MensagemId UNIQUEIDENTIFIER
    , @MensagemTipo NVARCHAR(256);
 
    WAITFOR (
        RECEIVE TOP(1)
            @Mensagem = [message_body],
            @MensagemId = [conversation_handle],
            @MensagemTipo = [message_type_name]
        FROM Fila
    ), TIMEOUT 2000 -- 2000ms ou 2s
 
    IF @MensagemId IS NOT NULL
        AND @MensagemTipo = 'Texto'
    BEGIN
        --WAITFOR DELAY '00:00:01';
 
        INSERT INTO Resultados
        SELECT @MensagemId, 'Ativação: ' + @Mensagem;
 
        END CONVERSATION @MensagemId;
    END;
END;

GO
 
ALTER QUEUE Fila
WITH ACTIVATION (
    STATUS = ON,
    PROCEDURE_NAME = USP_Ativacao,
    MAX_QUEUE_READERS = 5,
    EXECUTE AS OWNER
)
 
GO

DECLARE	@Mensagem VARCHAR(100)
	, @MensagemId UNIQUEIDENTIFIER;

SET @Mensagem = 'Teste 2';
 
BEGIN DIALOG CONVERSATION @MensagemId
    FROM SERVICE Servico
    TO SERVICE 'Servico'
    ON CONTRACT Contrato;
 
SEND ON CONVERSATION @MensagemId
    MESSAGE TYPE Texto (@Mensagem);
 
SELECT * FROM FILA
 
-- RECEIVE TOP(1)
--     *
--FROM Fila

-- Primeira verificação: Vazia
SELECT * FROM Resultados;
 
--WAITFOR DELAY '00:00:05';

-- Segunda verificação: Dados inseridos
DECLARE @XML XML = (SELECT (SELECT * FROM Resultados FOR XML PATH('Resultado'), ELEMENTS, TYPE) FOR XML PATH ('Resultados'))

--SELECT @XML
select	ref.value('Id[1]', 'Varchar(100)') Id,
	ref.value('Texto[1]', 'Varchar(100)') Texto
from	@XML.nodes('//Resultados/Resultado') T(ref)

DECLARE @XML XML = (SELECT * FROM Resultados FOR XML AUTO)

--SELECT @XML
select	ref.value('@Id[1]', 'Varchar(100)') Id,
	ref.value('@Texto[1]', 'Varchar(100)') Texto
from	@XML.nodes('//Resultados') T(ref)