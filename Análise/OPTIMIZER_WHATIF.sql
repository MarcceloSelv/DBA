SET ANSI_NULLS OFF
--SET ANSI_DEFAULTS OFF
GO
ALTER PROC ##TESTE_LOG_GERADOR
AS
DECLARE @FUNCAO_ID INT = 12257

select	min(log_gerador_id) 
from	log_gerador lg
where	lg.funcao_id = @FUNCAO_ID
and	lg.tab_status_job_id = 1 
and ( lg.data_inicio is null or lg.data_inicio <= getdate() ) 
OPTION(RECOMPILE)
GO
EXEC ##TESTE_LOG_GERADOR

SP_SPACEUSED LOG_GERADOR

24941050

DBCC TRACEON (2588) WITH NO_INFOMSGS -- TF to enable help to undocumented commands

DBCC HELP ('OPTIMIZER_WHATIF') WITH NO_INFOMSGS

dbcc OPTIMIZER_WHATIF ({property/cost_number | property_name} [, {integer_value | string_value} ])

DBCC TRACEON(3604) WITH NO_INFOMSGS
DBCC OPTIMIZER_WHATIF(0) WITH NO_INFOMSGS;
GO

-- Set ammount of memory in MB, in this case 512GB
DBCC OPTIMIZER_WHATIF(2, 54288);
DBCC OPTIMIZER_WHATIF(1, 12);
DBCC OPTIMIZER_WHATIF(3, 64);
DBCC OPTIMIZER_WHATIF(5, 50);


EXEC ('SET ANSI_NULLS ON

DECLARE @FUNCAO_ID INT = 12527

select	TESTE = min(log_gerador_id) 
from	log_gerador lg
where	lg.funcao_id = @FUNCAO_ID
and	lg.tab_status_job_id = 1 
and ( lg.data_inicio is null or lg.data_inicio <= getdate() ) 
OPTION(RECOMPILE)

SELECT @FUNCAO_ID ')



SP_040_GRAVA_SHIPMENT36