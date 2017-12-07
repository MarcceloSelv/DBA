SET ANSI_NULLS OFF

-- Succeed
SELECT * FROM TAB_TIPO_VEICULO WHERE perc_comissao_motorista = NULL

SET ANSI_NULLS On

-- Succeed
SELECT * FROM TAB_TIPO_VEICULO WHERE perc_comissao_motorista = NULL


SET QUOTED_IDENTIFIER ON

-- Will succeed.
CREATE TABLE "select" ("identity" INT IDENTITY NOT NULL, "order" INT NOT NULL);

SET QUOTED_IDENTIFIER OFF
-- Will not succeed.
CREATE TABLE "select" ("identity" INT IDENTITY NOT NULL, "order" INT NOT NULL);
