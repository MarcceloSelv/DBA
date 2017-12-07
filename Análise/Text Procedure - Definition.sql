
SELECT OBJECT_ID('ECARGOTESTE..SP_040_CALC_ICMS_RODOV_NOVO178')


DECLARE @S varchar(max)

SELECT @S = ''

SELECT @S = @S + '
' + OBJECT_DEFINITION(OBJECT_ID) FROM ECARGOTESTE.SYS.PROCEDURES WHERE OBJECT_ID = OBJECT_ID('ECARGOTESTE..SP_040_CALC_ICMS_RODOV_NOVO178')

SELECT @S AS [processing-instruction(x)] FOR XML PATH('')


SELECT	TOP 4  OBJECT_NAME(OBJECT_ID)
FROM	sys.sql_modules
ORDER BY DATALENGTH(definition) DESC

SELECT	T.item
FROM	ECARGOTESTE.sys.sql_modules sm
	CROSS APPLY (
	SELECT *
	FROM	master.dbo.Split(sm.definition, CHAR(13) + CHAR(10)) 
	) T
WHERE	OBJECT_ID = 549836200


convert(xml,'<xml><![CDATA[' + cast(details as varchar(max)) + ']]></xml>')

https://connect.microsoft.com/SQLServer/feedback/details/499618/ssms-allow-large-text-to-be-displayed-in-as-a-link

http://www.ssmstoolspack.com/