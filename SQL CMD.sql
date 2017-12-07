:Connect 201.55.75.227 -U SISTEMA -P SYSUSER
GO
SELECT @@SERVERNAME
GO
:Connect 192.168.3.3 -U SISTEMA -P SYSUSER
GO
SELECT @@SERVERNAME
GO
:SETVAR SourceServer 201.55.75.227
:CONNECT $(SourceServer) -U SISTEMA -P SYSUSER
GO
SELECT @@SERVERNAME, '$(SourceServer)';
GO
!!DIR C:\

--The Database Engine Query Editor supports the following SQLCMD script keywords:
--[!!:]GO[count]
!! <command>
:exit(statement)
:Quit
:r <filename>
:setvar <var> <value>
:connect server[\instance] [-l login_timeout] [-U user [-P password]]
:on error [ignore|exit]
:error <filename>|stderr|stdout
:out <filename>|stderr|stdout


SELECT * FROM sys.objects WHERE NAME LIKE '%TRACKING%' AND TYPE = 'U'