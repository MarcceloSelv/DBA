
--http://blog.devart.com/is-unpivot-the-best-way-for-converting-columns-into-rows.html
--Select x.Col, x.Value
----Into #Temp_Options
--From sys.dm_exec_requests r
--CROSS APPLY
--(		Values ('ansi_defaults', r.ansi_defaults), ('ansi_null_dflt_on', r.ansi_null_dflt_on), ('ansi_nulls', r.ansi_nulls), ('ansi_padding', r.ansi_padding), ('ansi_warnings', r.ansi_warnings), ('arithabort', r.arithabort), ('concat_null_yields_null', r.concat_null_yields_null), ('quoted_identifier', r.quoted_identifier)
--) x (Col, Value)
--Where	r.session_id = @@SPID

Select	Col, Value
--Into	#Temp_Options
From	(Select * From sys.dm_exec_requests r Where	r.session_id = @@SPID) r
		Unpivot
		(	Value
			for Col in (r.ansi_defaults, r.ansi_null_dflt_on, r.ansi_nulls, r.ansi_padding, r.ansi_warnings, r.arithabort, r.concat_null_yields_null, r.quoted_identifier)
		) Unpiv

--Select	Result = Cast(result as xml)
--Into	#Temp_Options
--From (
--	Select	r.ansi_defaults, r.ansi_null_dflt_on, r.ansi_nulls, r.ansi_padding, r.ansi_warnings, r.arithabort, r.concat_null_yields_null, r.quoted_identifier
--	From	sys.dm_exec_requests r
--	Where	R.session_id = @@SPID
--	For Xml Path('t')
--	) T (Result)

--;With Temp as (
--	Select	Col = x.c.value('local-name(.)', 'varchar(50)'),
--			Value = x.c.value('.', 'int')
--	From	#Temp_Options t cross apply t.Result.nodes('/t/*') x(c)
--)

--select object_id('tempdb..#Temp_Options')

--ANSI_PADDING/CONCAT_NULL_YIELDS_NULL/ANSI_WARNINGS/ANSI_NULLS/QUOTED_IDENTIFIER/ANSI_NULL_DFLT_ON/ARITHABORT