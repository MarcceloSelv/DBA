
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

DECLARE @DESC_STATUS VARCHAR(50)
DECLARE @CONTADOR INT = 0
DECLARE @PESSOA_ID VARCHAR(30) = 'PESSOA_ID = ' + CAST((SELECT PESSOA_ID FROM INFRA_IDS) AS VARCHAR)

BEGIN TRAN

RAISERROR(@PESSOA_ID, 1 , 1) WITH NOWAIT

DECLARE CUR_TESTE CURSOR LOCAL FAST_FORWARD FORWARD_ONLY FOR
SELECT	DESC_STATUS
FROM	TAB_STATUS

OPEN CUR_TESTE
FETCH NEXT FROM CUR_TESTE INTO @DESC_STATUS
WHILE (@@FETCH_STATUS = 0 AND @CONTADOR < 100)
    BEGIN
	UPDATE INFRA_IDS SET PESSOA_ID += 1
	
	SET @CONTADOR += 1
	
	WAITFOR DELAY '00:00:10'
	FETCH NEXT FROM CUR_TESTE INTO @DESC_STATUS
    END
CLOSE CUR_TESTE
DEALLOCATE CUR_TESTE

ROLLBACK
UPDATE INFRA_IDS SET PESSOA_ID = @PESSOA_ID