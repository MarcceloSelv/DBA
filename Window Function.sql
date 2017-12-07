--Case Dia When 10 Then Sum(Quanti -4) Over(Order By Dia) When 20 Then Sum(Dia -5) Over(Order By Dia) Else Dia End

Select *, Case Dia When 10 Then Sum(Qtde) Over (Order By Dia ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) Else Qtde End,
			Sum(Qtde) Over (Order By Dia ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING)
			,Sum(Qtde) Over (Order By Dia ROWS 1 PRECEDING)
			,Sum(Qtde) Over (Order By Dia ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
			,Sum(Qtde) Over (Order By Dia)
			
From
	(Values('1', 100),
		(2, 200),
		(3, 300),
		(4, 400),
		(5, 500),
		(6, 600),
		(7, 700),
		(8, 800),
		(9, 900),
		(10, 1000)
	)T(Dia, Qtde)

Select 700 + 800 + 900 + 1000

select 100 + 200 + 300 + 400

;With Temp as (
Select *
From
	(Values('1', 100),
		(2, 200),
		(3, 300),
		(4, 400),
		(5, 500),
		(6, 600),
		(7, 700),
		(8, 800),
		(9, 900),
		(10, 1000)
	)T(Dia, Qtde)
)

SELECT *
FROM Temp a
	CROSS APPLY (   SELECT ISNULL(SUM(v), 0)
					FROM (  SELECT TOP(4) b.Qtde
							FROM Temp b
							WHERE b.Dia <= a.Dia
							ORDER BY b.Dia DESC ) x(v)
				) x(s)

--;With Temp As (
--select 
--	T.Dia,
--	Qtde = u.mng
--from wms_core.V1_BEWEG_UND_ARCH u 
--inner join wms_core.artikel a on u.ID_ARTIKEL = a.ID_ARTIKEL and u.ID_KLIENT = a.ID_KLIENT 
--inner join wms_core.billpos b on u.lager = b.lager and u.ID_KLIENT = b.ID_KLIENT 
--	Cross Apply (Select trunc(u.TIME_AEN)) T(Dia)
--where 
--        b.lager = 'LC' 
--    and b.id_klient = '27' 
--    and b.id_contract = '149' 
--    and b.id_event = 'CPNEUE' 
--    and u.ART_BEW = 'WE1Q' 
--    and u.stat = '90' 
--    and a.ART_MAT = 'PNEU' 
--    and TRUNC(u.TIME_AEN) >= to_date('01052017','ddmmyyyy') 
--)

--SELECT *
--FROM Temp a
--	CROSS APPLY (   SELECT ISNULL(SUM(v), 0)
--					FROM (  SELECT TOP(4) b.Qtde
--							FROM Temp b
--							WHERE b.Dia <= a.Dia
--							ORDER BY b.Dia DESC ) x(v)
--				) x(s)