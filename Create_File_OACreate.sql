--- turn on OLE

sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Ole Automation Procedures', 1;
GO
RECONFIGURE;
GO

DECLARE @File VARCHAR(2000) = 'C:\Temp\myfile.txt'
	,@Text VARCHAR(2000) = 'This is the file content. Fill it as you wish'

DECLARE @OLE INT
DECLARE @FileID INT

	EXECUTE sp_OACreate 'Scripting.FileSystemObject'
		,@OLE OUTPUT

	EXECUTE sp_OAMethod @OLE,'OpenTextFile',@FileID OUTPUT,@File,8,1

	EXECUTE sp_OAMethod @FileID,'WriteLine',NULL,@Text

	EXECUTE sp_OADestroy @FileID

	EXECUTE sp_OADestroy @OLE
GO
