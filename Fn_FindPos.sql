Alter Function dbo.Fn_FindPos
(    
    @strInput VARCHAR(8000)
   ,@delimiter VARCHAR(50)
)
RETURNS TABLE 
AS
RETURN 
(
    WITH FindChar (PosNum, Pos)
    AS
    (
        SELECT 
             1 AS PosNum
            ,CHARINDEX(@delimiter,@strInput) AS Pos
        UNION ALL
        SELECT 
             f.PosNum + 1 AS PosNum
            ,CHARINDEX(@delimiter,@strInput,f.pos + 1) AS Pos
        FROM
            FindChar f
        WHERE
            f.PosNum + 1 <= LEN(@strInput)
            AND Pos <> 0
    )
    SELECT
        PosNum
       ,Pos
    FROM
        FindChar
    WHERE
        Pos > 0
)
GO