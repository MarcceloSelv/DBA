DECLARE @blockedProcessChains TABLE(chainid DATETIME, chainxml xml);
DECLARE @bprXML xml,
        @chainXML xml,
        @newResourceXml xml,
        @newOwnerXml xml,
        @newWaiterXml xml;
DECLARE    @blockingspid INT,
        @blockingecid INT,
        @blockingid VARCHAR(30),
        @blockingprocess xml,
        @blockedspid INT,
        @blockedecid INT,
        @blockedid VARCHAR(30),
        @blockedprocess xml,
        @chainid DATETIME,
        @waitresource NVARCHAR(50)
 
SET NOCOUNT ON
 
DECLARE bpCursor CURSOR
FOR SELECT CAST(textData AS xml), endtime
FROM BloquedProcessReport --hey, remember to save to a trace table in this database named blocked
WHERE eventClass = 137
 
OPEN bpCursor
 
FETCH NEXT FROM bpCursor INTO @bprXML, @chainid
WHILE @@FETCH_STATUS = 0
BEGIN
    --retrieve info
    SELECT
        @blockingspid = @bprXML.value('/blocked-process-report[1]/blocking-process[1]/process[1]/@spid', 'int'),
        @blockingecid = @bprXML.value('/blocked-process-report[1]/blocking-process[1]/process[1]/@ecid', 'int'),
        @blockingprocess = CAST(@bprXML.query('/blocked-process-report[1]/blocking-process[1]/process[1]') AS xml),
        @blockedspid = @bprXML.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@spid', 'int'),
        @blockedecid = @bprXML.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@ecid', 'int'),
        @blockedprocess = CAST(@bprXML.query('/blocked-process-report[1]/blocked-process[1]/process[1]') AS xml),
        @waitresource = @bprXML.value('/blocked-process-report[1]/blocked-process[1]/process[1]/@waitresource', 'nvarchar(50)')
 
    --update process ids
    SET @blockingid = 'process' + CAST(@blockingspid AS VARCHAR(10)) + '_' + CAST(@blockingecid AS VARCHAR(10))
    SET @blockedid = 'process' + CAST(@blockedspid AS VARCHAR(10)) + '_' + CAST(@blockedecid AS VARCHAR(10))
    SET @blockingprocess.modify('insert attribute id {sql:variable("@blockingid")} into (/process[1])')
    SET @blockedprocess.modify('replace value of (/process/@id)[1] with sql:variable("@blockedid")')
 
    --find chain
    SET @chainXml = CAST('<deadlock-list><deadlock><process-list></process-list><resource-list></resource-list></deadlock></deadlock-list>' AS xml);
    IF EXISTS (SELECT chainid FROM @blockedProcessChains WHERE chainid = @chainid)
        SELECT @chainXML = chainxml
        FROM @blockedProcessChains
        WHERE chainid = @chainid;
    ELSE
        INSERT @blockedProcessChains(chainid, chainxml)
        valueS (@chainid, @chainXML);
 
    --find blocked process (add or replace)
    IF (@chainXML.exist('//process-list/process[@ecid = sql:variable("@blockedecid") and @spid = sql:variable("@blockedspid")]') = 1)
        SET @chainXML.modify('delete //process-list/process[@ecid = sql:variable("@blockedecid") and @spid = sql:variable("@blockedspid")]')
    SET @chainXML.modify('insert sql:variable("@blockedprocess") into (//process-list)[1] ')
 
    --find blocking process (add if needed)
    IF NOT (@chainXML.exist('//process-list/process[@ecid = sql:variable("@blockingecid") and @spid = sql:variable("@blockingspid")]') = 1)
        SET @chainXML.modify('insert sql:variable("@blockingprocess") into (//process-list)[1] ')
 
    --find resource (add resource if needed)
    IF NOT (@chainXML.exist('//resource-list/unknownlock[@resource=sql:variable("@waitresource")]') = 1)
    BEGIN
        SET @newResourceXml = CAST('<unknownlock><owner-list /><waiter-list /></unknownlock>' AS xml);
        SET @newResourceXml.modify('insert attribute resource {sql:variable("@waitresource")} into (/unknownlock[1])');
        SET @chainXML.modify('insert sql:variable("@newResourceXml") into (//resource-list)[1] ');
    END
 
    --find owner
    IF NOT (@chainXML.exist('//unknownlock[@resource=sql:variable("@waitresource")]//owner[@id=sql:variable("@blockingid")]') = 1)
    BEGIN
        -- add owner if needed
        SET @newOwnerXml = CAST('<owner />' AS xml);
        SET @newOwnerXml.modify('insert attribute id {sql:variable("@blockingid")} into (/owner[1])');
        SET @chainXML.modify('insert sql:variable("@newOwnerXml") into (//unknownlock[@resource=sql:variable("@waitresource")]/owner-list)[1]');
    END
 
    --find waiter
    IF NOT (@chainXML.exist('//unknownlock[@resource=sql:variable("@waitresource")]//waiter[@id=sql:variable("@blockedid")]') = 1)
    BEGIN
        -- add waiter if needed
        SET @newWaiterXml = CAST('<waiter requestType="wait" />' AS xml);
        SET @newWaiterXml.modify('insert attribute id {sql:variable("@blockedid")} into (/waiter[1])');
        SET @chainXML.modify('insert sql:variable("@newWaiterXml") into (//unknownlock[@resource=sql:variable("@waitresource")]/waiter-list)[1]');
    END
 
    -- update chain
    UPDATE @blockedProcessChains
    SET chainxml = @chainXML
    WHERE chainid = @chainid
 
    FETCH NEXT FROM bpCursor INTO @bprXML, @chainid
END
CLOSE bpCursor;
DEALLOCATE bpCursor;
 
-- update list with victim ids
WITH rankedEvents AS
(
   SELECT ROW_NUMBER() OVER (PARTITION BY EndTime ORDER BY Duration DESC) AS myRank ,
       CAST (TextData AS XML) AS TextData,
       EndTime
   FROM BloquedProcessReport --hey, remember to save to a trace table in this database named blocked
   WHERE EventClass = 137
),
blockers AS
(
    SELECT EndTime,
        'process' +
        re.TextData.value('(//blocking-process/process/@spid)[1]', 'varchar(10)') +
        '_' +
        re.TextData.value('(//blocking-process/process/@ecid)[1]', 'varchar(10)') AS processId
    FROM rankedEvents re
    WHERE myRank = 1
)
UPDATE @blockedProcessChains
SET chainxml.modify('insert attribute victim {sql:column("processId")} into (//deadlock)[1]')
FROM @blockedProcessChains bpc
JOIN blockers b ON bpc.ChainId = b.EndTime
 
SELECT * 
INTO #blockedProcessChains
FROM	@blockedProcessChains;

Select CAST (TextData AS XML) AS TextData, EndTime From BloquedProcessReport

Select	*
From	#blockedProcessChains
Order by 1