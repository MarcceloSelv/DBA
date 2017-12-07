/*****************************************************
  This is the script to validate the proper objects
  used by the Reporter for RML reporting

  OWNER:  RDORR and KEITHELM

	  This requires SQL 2005 or later to execute
*****************************************************/


----------------------------------------------------------------------------------------------
--	Validate version
----------------------------------------------------------------------------------------------
declare @strVersion varchar(10)

set @strVersion = cast(SERVERPROPERTY('ProductVersion') as varchar(10))
if( (select cast( substring(@strVersion, 0, charindex('.', @strVersion)) as int)) < 9)
begin
	raiserror('Reporter requires SQL Server 2005 or later.', 16, 1)
end
go


----------------------------------------------------------------------------------------------
--	Validate we have some data.  Should be TimeInterval information at least and batch or stmt partial aggs
----------------------------------------------------------------------------------------------
if (0 = (select count(*) from ReadTrace.tblTimeIntervals) or
    (0 = (select count(*) from ReadTrace.tblBatchPartialAggs) and 0 = (select count(*) from ReadTrace.tblStmtPartialAggs)))
begin
	raiserror('The ReadTrace database does not appear to contain valid data points.  Recheck the load process and filters.', 16, 2)
end
go
