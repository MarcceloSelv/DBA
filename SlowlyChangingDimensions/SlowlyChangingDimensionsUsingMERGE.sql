--http://www.sqlservercentral.com/articles/MERGE/73805/
--http://www.sqlservercentral.com/scripts/TEMPLATE/107173/
-- Base table

CREATE TABLE [dbo].[Client](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ClientName] [varchar](150) NULL,
	[Country] [varchar](50) NULL,
	[Town] [varchar](50) NULL,
	[County] [varchar](50) NULL,
	[Address1] [varchar](50) NULL,
	[Address2] [varchar](50) NULL,
	[ClientType] [varchar](20) NULL,
	[ClientSize] [varchar](10) NULL,
 CONSTRAINT [PK_Client] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]


-- Data

SET IDENTITY_INSERT [dbo].[Client] ON
INSERT [dbo].[Client] ([ID], [ClientName], [Country], [Town], [County], [Address1], [Address2], [ClientType], [ClientSize]) VALUES (1, N'John Smith', N'UK', N'Uttoxeter', N'Staffs', N'4, Grove Drive', NULL, N'Private', N'M')
INSERT [dbo].[Client] ([ID], [ClientName], [Country], [Town], [County], [Address1], [Address2], [ClientType], [ClientSize]) VALUES (2, N'Bauhaus Motors', N'UK', N'Oxford', N'Oxon', N'Suite 27', N'12-14 Turl Street', N'Business', N'S')
INSERT [dbo].[Client] ([ID], [ClientName], [Country], [Town], [County], [Address1], [Address2], [ClientType], [ClientSize]) VALUES (7, N'Honest Fred', N'UK', N'Stoke', N'Staffs', NULL, NULL, N'Business', N'S')
INSERT [dbo].[Client] ([ID], [ClientName], [Country], [Town], [County], [Address1], [Address2], [ClientType], [ClientSize]) VALUES (8, N'Fast Eddie', N'Wales', N'Cardiff', NULL, NULL, NULL, N'Business', N'L')
INSERT [dbo].[Client] ([ID], [ClientName], [Country], [Town], [County], [Address1], [Address2], [ClientType], [ClientSize]) VALUES (9, N'Slow Sid', N'France', N'Avignon', N'Vaucluse', N'2, Rue des Courtisans', NULL, N'Private', N'M')
SET IDENTITY_INSERT [dbo].[Client] OFF


-- SCD1 table

CREATE TABLE [dbo].[Client_SCD1](
	[ClientID] [int] IDENTITY(1,1) NOT NULL,
	[BusinessKey] [int] NOT NULL,
	[ClientName] [varchar](150) NULL,
	[Country] [varchar](50) NULL,
	[Town] [varchar](50) NULL,
	[County] [varchar](50) NULL,
	[Address1] [varchar](50) NULL,
	[Address2] [varchar](50) NULL,
	[ClientType] [varchar](20) NULL,
	[ClientSize] [varchar](10) NULL
) 



-- SCD2 table

CREATE TABLE [dbo].[Client_SCD2](
	[ClientID] [int] IDENTITY(1,1) NOT NULL,
	[BusinessKey] [int] NOT NULL,
	[ClientName] [varchar](150) NULL,
	[Country] [varchar](50) NULL,
	[Town] [varchar](50) NULL,
	[County] [varchar](50) NULL,
	[Address1] [varchar](50) NULL,
	[Address2] [varchar](50) NULL,
	[ClientType] [varchar](20) NULL,
	[ClientSize] [varchar](10) NULL,
	ValidFrom INT NULL,
	ValidTo INT NULL,
	IsCurrent BIT  NULL
) ON [PRIMARY]


-- SCD3 table

CREATE TABLE [dbo].[Client_SCD3](
	[ClientID] [int] IDENTITY(1,1) NOT NULL,
	[BusinessKey] [int] NOT NULL,
	[ClientName] [varchar](150) NULL,
	[Country] [varchar](50) NULL,
	[Country_Prev1] [varchar](50) NULL,
	[Country_Prev1_ValidTo] [char] (8) NULL,
	[Country_Prev2] [varchar](50) NULL,
	[Country_Prev2_ValidTo] [char] (8)  NULL,
) 


-- SCD4_History table

CREATE TABLE [dbo].[Client_SCD4_History]
(
	[HistoryID] [int] IDENTITY(1,1) NOT NULL,
	[BusinessKey] [int] NOT NULL,
	[ClientName] [varchar](150) NULL,
	[Country] [varchar](50) NULL,
	[Town] [varchar](50) NULL,
	[County] [varchar](50) NULL,
	[Address1] [varchar](50) NULL,
	[Address2] [varchar](50) NULL,
	[ClientType] [varchar](20) NULL,
	[ClientSize] [varchar](10) NULL,
	[ValidFrom] [int] NULL,
	[ValidTo] [int] NULL
) 

-- Processes

-- SCD 1

MERGE		dbo.Client_SCD1				AS DST
USING		CarSales.dbo.Client			AS SRC
ON		(SRC.ID = DST.BusinessKey)

WHEN NOT MATCHED THEN

INSERT (BusinessKey, ClientName, Country, Town, County, Address1, Address2, ClientType, ClientSize)
VALUES (SRC.ID, SRC.ClientName, SRC.Country, SRC.Town, SRC.County, Address1, Address2, ClientType, ClientSize)

WHEN MATCHED 
AND (
	 ISNULL(DST.ClientName,'') <> ISNULL(SRC.ClientName,'')  
	 OR ISNULL(DST.Country,'') <> ISNULL(SRC.Country,'') 
	 OR ISNULL(DST.Town,'') <> ISNULL(SRC.Town,'')
	 OR ISNULL(DST.Address1,'') <> ISNULL(SRC.Address1,'')
	 OR ISNULL(DST.Address2,'') <> ISNULL(SRC.Address2,'')
	 OR ISNULL(DST.ClientType,'') <> ISNULL(SRC.ClientType,'')
	 OR ISNULL(DST.ClientSize,'') <> ISNULL(SRC.ClientSize,'')
	 )

THEN UPDATE 

SET 
	 DST.ClientName = SRC.ClientName  
	 ,DST.Country = SRC.Country 
	 ,DST.Town = SRC.Town
	 ,DST.Address1 = SRC.Address1
	 ,DST.Address2 = SRC.Address2
	 ,DST.ClientType = SRC.ClientType
	 ,DST.ClientSize = SRC.ClientSize
;



-- SCD 2

DECLARE @Yesterday INT =  (YEAR(DATEADD(dd,-1,GETDATE())) * 10000) + (MONTH(DATEADD(dd,-1,GETDATE())) * 100) + DAY(DATEADD(dd,-1,GETDATE()))
DECLARE @Today INT =  (YEAR(GETDATE()) * 10000) + (MONTH(GETDATE()) * 100) + DAY(GETDATE())

-- Outer insert - the updated records are added to the SCD2 table
INSERT INTO dbo.Client_SCD2 (BusinessKey, ClientName, Country, Town, County, Address1, Address2, ClientType, ClientSize, ValidFrom, IsCurrent)

SELECT ID, ClientName, Country, Town, County, Address1, Address2, ClientType, ClientSize, @Today, 1
FROM
(
-- Merge statement
MERGE INTO		dbo.Client_SCD2				AS DST
USING			dbo.Client			AS SRC
ON				(SRC.ID = DST.BusinessKey)

-- New records inserted
WHEN NOT MATCHED THEN 

INSERT (BusinessKey, ClientName, Country, Town, County, Address1, Address2, ClientType, ClientSize, ValidFrom, IsCurrent)
VALUES (SRC.ID, SRC.ClientName, SRC.Country, SRC.Town, SRC.County, Address1, Address2, ClientType, ClientSize, @Today, 1)

-- Existing records updated if data changes
WHEN MATCHED 
AND IsCurrent = 1
AND (
	 ISNULL(DST.ClientName,'') <> ISNULL(SRC.ClientName,'')  
	 OR ISNULL(DST.Country,'') <> ISNULL(SRC.Country,'') 
	 OR ISNULL(DST.Town,'') <> ISNULL(SRC.Town,'')
	 OR ISNULL(DST.Address1,'') <> ISNULL(SRC.Address1,'')
	 OR ISNULL(DST.Address2,'') <> ISNULL(SRC.Address2,'')
	 OR ISNULL(DST.ClientType,'') <> ISNULL(SRC.ClientType,'')
	 OR ISNULL(DST.ClientSize,'') <> ISNULL(SRC.ClientSize,'')
	 )

-- Update statement for a changed dimension record, to flag as no longer active
THEN UPDATE 

SET DST.IsCurrent = 0, DST.ValidTo = @Yesterday

OUTPUT	SRC.ID, SRC.ClientName, SRC.Country, SRC.Town, SRC.County, SRC.Address1, SRC.Address2, SRC.ClientType, SRC.ClientSize, $Action AS MergeAction

) AS MRG

WHERE MRG.MergeAction = 'UPDATE'
;



-- SCD 3

DECLARE @Yesterday VARCHAR(8) = CAST(YEAR(DATEADD(dd,-1,GETDATE())) AS CHAR(4)) + RIGHT('0' + CAST(MONTH(DATEADD(dd,-1,GETDATE())) AS VARCHAR(2)),2) + RIGHT('0' + CAST(DAY(DATEADD(dd,-1,GETDATE())) AS VARCHAR(2)),2)

MERGE		dbo.Client_SCD3				AS DST
USING		dbo.Client			AS SRC
ON			(SRC.ID = DST.BusinessKey)

WHEN NOT MATCHED THEN

INSERT (BusinessKey, ClientName, Country)
VALUES (SRC.ID, SRC.ClientName, SRC.Country)

WHEN MATCHED 
AND		(DST.Country <> SRC.Country
		 OR DST.ClientName <> SRC.ClientName)

THEN UPDATE 

SET		DST.Country = SRC.Country
		,DST.ClientName = SRC.ClientName
		,DST.Country_Prev1 = DST.Country
		,DST.Country_Prev1_ValidTo = @Yesterday
		,DST.Country_Prev2 = DST.Country_Prev1
		,DST.Country_Prev2_ValidTo = DST.Country_Prev1_ValidTo
;




-- SCD 4

DECLARE @Yesterday INT =  (YEAR(DATEADD(dd,-1,GETDATE())) * 10000) + (MONTH(DATEADD(dd,-1,GETDATE())) * 100) + DAY(DATEADD(dd,-1,GETDATE()))
DECLARE @Today INT =  (YEAR(GETDATE()) * 10000) + (MONTH(GETDATE()) * 100) + DAY(GETDATE())

DECLARE  @Client_SCD4 TABLE
(
	[BusinessKey] [int] NULL,
	[ClientName] [varchar](150) NULL,
	[Country] [varchar](50) NULL,
	[Town] [varchar](50) NULL,
	[County] [varchar](50) NULL,
	[Address1] [varchar](50) NULL,
	[Address2] [varchar](50) NULL,
	[ClientType] [varchar](20) NULL,
	[ClientSize] [varchar](10) NULL,
	[MergeAction] [varchar](10) NULL
) 



-- Merge statement
MERGE		dbo.Client_SCD1					AS DST
USING		dbo.Client				AS SRC
ON			(SRC.ID = DST.BusinessKey)

WHEN NOT MATCHED THEN

INSERT (BusinessKey, ClientName, Country, Town, Address1, Address2, ClientType, ClientSize)
VALUES (SRC.ID, SRC.ClientName, SRC.Country, SRC.Town, SRC.Address1, SRC.Address2, SRC.ClientType, SRC.ClientSize)

WHEN MATCHED 
AND		
	 ISNULL(DST.ClientName,'') <> ISNULL(SRC.ClientName,'')  
	 OR ISNULL(DST.Country,'') <> ISNULL(SRC.Country,'') 
	 OR ISNULL(DST.Town,'') <> ISNULL(SRC.Town,'')
	 OR ISNULL(DST.Address1,'') <> ISNULL(SRC.Address1,'')
	 OR ISNULL(DST.Address2,'') <> ISNULL(SRC.Address2,'')
	 OR ISNULL(DST.ClientType,'') <> ISNULL(SRC.ClientType,'')
	 OR ISNULL(DST.ClientSize,'') <> ISNULL(SRC.ClientSize,'')

THEN UPDATE 

SET			 
	 DST.ClientName = SRC.ClientName  
	 ,DST.Country = SRC.Country 
	 ,DST.Town = SRC.Town
	 ,DST.Address1 = SRC.Address1
	 ,DST.Address2 = SRC.Address2
	 ,DST.ClientType = SRC.ClientType
	 ,DST.ClientSize = SRC.ClientSize


OUTPUT DELETED.BusinessKey, DELETED.ClientName, DELETED.Country, DELETED.Town, DELETED.Address1, DELETED.Address2, DELETED.ClientType, DELETED.ClientSize, $Action AS MergeAction
INTO	@Client_SCD4 (BusinessKey, ClientName, Country, Town, Address1, Address2, ClientType, ClientSize, MergeAction)
;

-- Update history table to set final date and current flag

UPDATE		TP4

SET			TP4.ValidTo = @Yesterday

FROM		dbo.Client_SCD4_History TP4
			INNER JOIN @Client_SCD4 TMP
			ON TP4.BusinessKey = TMP.BusinessKey

WHERE		TP4.ValidTo IS NULL


-- Add latest history records to history table

INSERT INTO dbo.Client_SCD4_History (BusinessKey, ClientName, Country, Town, Address1, Address2, ClientType, ClientSize, ValidTo)

SELECT BusinessKey, ClientName, Country, Town, Address1, Address2, ClientType, ClientSize, @Yesterday 
FROM @Client_SCD4



