-- ===========================================================
-- Check Constraints
-- How to script out Check Constraints in SQL Server 2005
-- ===========================================================

-- view results in text, to make copying and pasting easier
-- Drop Check Constraints
SELECT
    'ALTER TABLE  ' +
     QuoteName(OBJECT_NAME(so.parent_obj)) +
     CHAR(10) +
     ' DROP CONSTRAINT ' +
     QuoteName(CONSTRAINT_NAME)
 FROM
     INFORMATION_SCHEMA.CHECK_CONSTRAINTS cc
     INNER JOIN sys.sysobjects so
     ON cc.CONSTRAINT_NAME = so.[name]

 -- Recreate Check Constraints
 SELECT
     'ALTER TABLE  ' +
     QuoteName(OBJECT_NAME(so.parent_obj)) +
     CHAR(10) +
     ' ADD CONSTRAINT ' +
     QuoteName(CONSTRAINT_NAME) +
     ' CHECK ' +
     CHECK_CLAUSE
 FROM
     INFORMATION_SCHEMA.CHECK_CONSTRAINTS cc
     INNER JOIN sys.sysobjects so
     ON cc.CONSTRAINT_NAME = so.[name]
