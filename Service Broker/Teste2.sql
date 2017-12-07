USE DB01;
 
CREATE MESSAGE TYPE Requisicao
    VALIDATION = WELL_FORMED_XML;
 
CREATE MESSAGE TYPE Resposta
    VALIDATION = WELL_FORMED_XML;
 
CREATE CONTRACT Contrato (
    Requisicao SENT BY INITIATOR,
    Resposta SENT BY TARGET
);
 
USE DB02;
 
CREATE MESSAGE TYPE Requisicao
    VALIDATION = WELL_FORMED_XML;
 
CREATE MESSAGE TYPE Resposta
    VALIDATION = WELL_FORMED_XML;
 
CREATE CONTRACT Contrato (
    Requisicao SENT BY INITIATOR,
    Resposta SENT BY TARGET
);

USE DB02;
 
CREATE QUEUE FilaRequisicao
    WITH STATUS = ON;
 
CREATE SERVICE ServicoRequisicao
    ON QUEUE FilaRequisicao (Contrato);
 
USE DB01;
 
CREATE QUEUE FilaResposta
    WITH STATUS = ON;
 
CREATE SERVICE ServicoResposta
    ON QUEUE FilaResposta (Contrato);
 
GO

USE DB01;
 
DECLARE @Mensagem XML = 'Requisição'
, @MensagemId UNIQUEIDENTIFIER;
 
BEGIN DIALOG CONVERSATION @MensagemId
    FROM SERVICE ServicoResposta
    TO SERVICE 'ServicoRequisicao'
    ON CONTRACT Contrato;
 
SEND ON CONVERSATION @MensagemId
    MESSAGE TYPE Requisicao(@Mensagem);

USE DB02;
 
DECLARE @Mensagem XML
, @MensagemId UNIQUEIDENTIFIER;
 
RECEIVE TOP(1)
    @Mensagem = [message_body],
    @MensagemId = [conversation_handle]
FROM FilaRequisicao;
 
SELECT @MensagemId, @Mensagem;
 
IF @MensagemId IS NOT NULL
BEGIN
    SET @Mensagem = 'Resposta';
 
    SEND ON CONVERSATION @MensagemId
        MESSAGE TYPE Resposta(@Mensagem);
END

USE DB01;
 
DECLARE @Mensagem XML
, @MensagemId UNIQUEIDENTIFIER;
 
RECEIVE TOP(1)
    @Mensagem = [message_body],
    @MensagemId = [conversation_handle]
FROM FilaResposta;
 
SELECT @MensagemId, @Mensagem;
 
IF @MensagemId IS NOT NULL
    END CONVERSATION @MensagemId;