/*
CREATE DATABASE DBForPartitioning
ON PRIMARY
(NAME='DBForPartitioning_1',
FILENAME=
'E:\Databases\Partition\FG1\DBForPartitioning_1.mdf',
SIZE=2,
MAXSIZE=100,
FILEGROWTH=1 ),
FILEGROUP FG2
(NAME = 'DBForPartitioning_2',
FILENAME =
'E:\Databases\Partition\FG2\DBForPartitioning_2.ndf',
SIZE = 2,
MAXSIZE=100,
FILEGROWTH=1 ),
FILEGROUP FG3
(NAME = 'DBForPartitioning_3',
FILENAME =
'E:\Databases\Partition\FG3\DBForPartitioning_3.ndf',
SIZE = 2,
MAXSIZE=100,
FILEGROWTH=1 )
*/

Use DBFOrPartitioning
GO 
-- Confirm Filegroups
SELECT name as [File Group Name]
FROM sys.filegroups
WHERE type = 'FG'
GO -- Confirm Datafiles
SELECT name as [DB File Name],physical_name as [DB File Path] 
FROM sys.database_files
where type_desc = 'ROWS'
GO

CREATE PARTITION FUNCTION salesYearPartitions (datetime)
AS RANGE RIGHT FOR VALUES ( '2009-01-01', '2010-01-01')
GO

CREATE PARTITION SCHEME Test_PartitionScheme
AS PARTITION salesYearPartitions
TO ([PRIMARY], FG2, FG3 )
GO

CREATE TABLE SalesArchival
(SaleTime datetime PRIMARY KEY,
ItemName varchar(50))
ON Test_PartitionScheme (SaleTime);
GO

Use DBFOrPartitioning
GO
INSERT INTO SalesArchival (SaleTime, ItemName)
SELECT '2007-03-25','Item1' UNION ALL
SELECT '2008-10-01','Item2' UNION ALL
SELECT '2009-01-01','Item1' UNION ALL
SELECT '2009-08-09','Item3' UNION ALL
SELECT '2009-12-30','Item2' UNION ALL
SELECT '2010-01-01','Item1' UNION ALL
SELECT '2010-05-24','Item3'
GO
Use DBFOrPartitioning
GO
select partition_id, index_id, partition_number, Rows 
FROM sys.partitions
WHERE OBJECT_NAME(OBJECT_ID)='RESULTS'
GO

SELECT * FROM SalesArchival

--DROP TABLE RESULTS
CREATE TABLE RESULTS (ID UNIQUEIDENTIFIER, TEXTO VARCHAR(100), DATA DATETIME)
--SELECT @XML

DECLARE @XML XML = 
'<Resultados Id="B49DD93E-27BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Mensagem QWEQEasdsada" />
<Resultados Id="01958645-27BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Mensagem QWEQEasdsada" />
<Resultados Id="05958645-27BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Mensagem QWEQEasdsada" />
<Resultados Id="09958645-27BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Mensagem QWEQEasdsada" />
<Resultados Id="0D958645-27BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Mensagem QWEQEasdsada" />
<Resultados Id="11958645-27BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Mensagem QWEQEasdsada" />
<Resultados Id="15958645-27BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Mensagem QWEQEasdsada" />
<Resultados Id="19958645-27BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Mensagem QWEQEasdsada" />
<Resultados Id="1D958645-27BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Mensagem QWEQEasdsada" />
<Resultados Id="21958645-27BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Mensagem QWEQEasdADSADASDAsada" />
<Resultados Id="25958645-27BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Mensagem QWEQEasdADSADASDAsada" />
<Resultados Id="29958645-27BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Mensagem QWEQEasdADSADASDAsada" />
<Resultados Id="2D958645-27BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Mensagem QWEQEasdADSADASDAsada" />
<Resultados Id="E58C1568-50BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Teste" />
<Resultados Id="FCA0ED73-50BC-E211-BE78-F4B7E2D66E8A" Texto="Ativação: Teste 2" />'

INSERT INTO RESULTS(ID, TEXTO, DATA)
select	ref.value('@Id[1]', 'Varchar(100)') Id,
	ref.value('@Texto[1]', 'Varchar(100)') Texto,
	GETDATE() -800
from	@XML.nodes('//Resultados') T(ref)
go 2000

SELECT * FROM RESULTS


select * from [staging_RESULTS_20130514-221257]