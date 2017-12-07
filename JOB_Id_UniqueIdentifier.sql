SELECT	(SELECT name FROM msdb..SYSJOBS WHERE JOB_ID = T.JOB_ID), *
FROM	LOG_GERADOR_AUDIT LA
		OUTER APPLY (SELECT JOB_ID = Case When LA.ProgramName LIKE 'SQLAgent%' Then Convert(uniqueidentifier, convert(VARBINARY(MAX), Ltrim(Rtrim(Substring(LA.ProgramName, Charindex('(Job ', LA.ProgramName) + 5, 34))), 1)) Else Null End) T