SELECT
	RowNumber,
	StartTime,
	frame = T.p.value('(executionStack/frame)[1]', 'varchar(max)'),
	inputbuf = T.p.value('(inputbuf)[1]', 'varchar(max)'),
	isolationlevel = T.p.value('@isolationlevel', 'varchar(500)'),
	victim = T.p.value('../../@victim', 'varchar(500)'),
	id = T.p.value('@id', 'varchar(500)'),
	procName = T.p.value('(executionStack/frame/@procname)[1]', 'varchar(500)'),
	TextData
From
	(
	Select	TextData = Cast(TextData as xml),
		RowNumber,
		StartTime
	From
		TRACELOCK2
	Where
		TextData Like '<deadlock-list>%'
	And	TextData Not Like '%drop index%'
	) tl
	Outer Apply tl.TextData.nodes('//deadlock-list/deadlock/process-list/process') T(p)

