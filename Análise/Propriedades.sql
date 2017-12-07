SELECT    100     [SortOrder]    ,'BuildClrVersion' [SERVERPROPERTY]    ,SERVERPROPERTY('BuildClrVersion')    [VALUE]

UNION
SELECT    200    ,'Collation'        ,SERVERPROPERTY('Collation')

UNION
SELECT    200    ,'CollationID'        ,SERVERPROPERTY('CollationID')

UNION
SELECT    200    ,'ComparisonStyle'    ,SERVERPROPERTY('ComparisonStyle')

UNION
SELECT    20    ,'ComputerNamePhysicalNetBIOS'    ,SERVERPROPERTY('ComputerNamePhysicalNetBIOS')

UNION
SELECT    30    ,'Edition'            ,SERVERPROPERTY('Edition')

UNION
SELECT    30    ,'EditionID'
        ,CASE SERVERPROPERTY('EditionID')
            WHEN -1253826760    THEN 'Desktop'
            WHEN -1592396055    THEN 'Express'
            WHEN -1534726760    THEN 'Standard'
            WHEN 1333529388        THEN 'Workgroup'
            WHEN 1804890536        THEN 'Enterprise'
            WHEN -323382091        THEN 'Personal'
            WHEN -2117995310    THEN 'Developer'
            WHEN 610778273        THEN 'Enterprise Evaluation'
            WHEN 1044790755        THEN 'Windows Embedded SQL'
            WHEN 4161255391        THEN 'Express with Advanced Services'
            WHEN 1872460670        THEN 'Enterprise Edition: Core-based Licensing'
            WHEN 284895786        THEN 'Business Intelligence'
            WHEN 133711905        THEN 'Express with Advanced Services'
            WHEN 1293598313        THEN 'Web'
            ELSE 'UNKNOWN'
        END

UNION
SELECT    30    ,'EngineEdition'
        ,CASE SERVERPROPERTY('EngineEdition')
            WHEN 1 THEN 'Personal or Desktop'
            WHEN 2 THEN 'Standard or Web or Business Intelligence.'
            WHEN 200 THEN 'Standard'
            WHEN 3 THEN 'Enterprise'
            WHEN 4 THEN 'Express'
            WHEN 5 THEN 'Azure'
            ELSE    'UNKNOWN'
        END

UNION
SELECT    30    ,'HadrManagerStatus'
        ,CASE SERVERPROPERTY('HadrManagerStatus')
            WHEN 0 THEN 'Not started, pending communication'
            WHEN 1 THEN 'Started and running'
            WHEN 2 THEN 'Not started and failed.'
            ELSE    'UNKNOWN'
        END

UNION
SELECT    20    ,'InstanceName'            ,SERVERPROPERTY('InstanceName')

UNION
SELECT    35    ,'IsClustered'
        ,CASE SERVERPROPERTY('IsClustered')
            WHEN 1 THEN 'Clusered'
            WHEN 0 THEN 'Not clustered'
            ELSE 'UNKNOWN'
        END

UNION
SELECT    35    ,'IsHadrEnabled'
        ,CASE SERVERPROPERTY('IsHadrEnabled')
            WHEN 1 THEN 'The AlwaysOn Availability Groups feature is enabled.'
            WHEN 0 THEN 'The AlwaysOn Availability Groups feature is disabled'
            ELSE 'UNKNOWN'
        END

UNION
SELECT    35    ,'IsFullTextInstalled'
        ,CASE SERVERPROPERTY('IsFullTextInstalled')
            WHEN 1 THEN 'Full-text and semantic indexing components are installed'
            WHEN 0 THEN 'Full-text and semantic indexing components are not installed'
            ELSE 'UNKNOWN'
        END


UNION
SELECT    35    ,'IsIntegratedSecurityOnly'
        ,CASE SERVERPROPERTY('IsIntegratedSecurityOnly')
            WHEN 1 THEN 'Integrated security (Windows Authentication)'
            WHEN 0 THEN 'Not integrated security. (Both Windows Authentication and SQL Server Authentication)'
            ELSE 'UNKNOWN'
        END

UNION
SELECT    35    ,'IsSingleUser'
        ,CASE SERVERPROPERTY('IsSingleUser')
            WHEN 1 THEN 'Single user'
            WHEN 0 THEN 'Not single user'
            ELSE 'UNKNOWN'
        END

UNION
SELECT    35    ,'IsLocalDB'
        ,CASE SERVERPROPERTY('IsLocalDB')
            WHEN 1 THEN 'LocalDB'
            WHEN 0 THEN 'Not LocalDB'
            ELSE 'UNKNOWN'
        END

UNION
SELECT    40    ,'LCID'                    ,SERVERPROPERTY('LCID')

UNION
SELECT    35    ,'LicenseType'            ,SERVERPROPERTY('LicenseType')

UNION
SELECT    20    ,'MachineName'            ,COALESCE(SERVERPROPERTY('MachineName'),'UNKNOWN')

UNION
SELECT    200    ,'ProcessID'            ,SERVERPROPERTY('ProcessID')

UNION
SELECT    15    ,'ProductVersion'        ,SERVERPROPERTY('ProductVersion')

UNION
SELECT    15    ,'ProductLevel'            ,SERVERPROPERTY('ProductLevel')

UNION
SELECT    200    ,'ResourceLastUpdateDateTime' ,SERVERPROPERTY('ResourceLastUpdateDateTime')

UNION
SELECT    15    ,'ResourceVersion'        ,SERVERPROPERTY('ResourceVersion')

UNION
SELECT    10    ,'ServerName'            ,SERVERPROPERTY('ServerName')

UNION
SELECT    200    ,'SqlCharSet'            ,SERVERPROPERTY('SqlCharSet')

UNION
SELECT    200    ,'SqlCharSetName'        ,SERVERPROPERTY('SqlCharSetName')

UNION
SELECT    200    ,'SqlSortOrder'            ,SERVERPROPERTY('SqlSortOrder')

UNION
SELECT    200    ,'SqlSortOrderName'        ,SERVERPROPERTY('SqlSortOrderName')

UNION
SELECT    200    ,'FilestreamShareName'    ,SERVERPROPERTY('FilestreamShareName')

UNION
SELECT    200    ,'FilestreamConfiguredLevel',SERVERPROPERTY('FilestreamConfiguredLevel')

UNION
SELECT    200    ,'FilestreamEffectiveLevel',SERVERPROPERTY('FilestreamEffectiveLevel')

UNION
SELECT    300
        ,'Database ' + D.state_desc
        ,D.[name]
FROM    sys.databases D

UNION    SELECT    400
        ,'LinkedServer '
        ,D.srvname
FROM    sys.sysservers D

ORDER

BY    [SORTORDER]
    ,[SERVERPROPERTY]


