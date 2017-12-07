@@echo off

del errors /f /s /q

rd Errors

md Errors


FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d TREINAMENTO  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB57.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d COMERCIAL  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB58.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d NOVORUMO  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB59.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d SIGNA  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB60.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d TEKE  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB61.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d CORPORATE  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB62.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d DUANELLI  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB63.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d JADLOG  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB64.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d LOGMAIS  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB65.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d LUAJO  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB66.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d PANALPINA  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB67.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d MULTIEMPRESA  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB68.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d APRESENTACAO  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB69.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d PORTAL  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB70.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d TRANSFINOTTI  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB71.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d TRANSPADUA  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB72.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d NEUBINHO  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB73.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d VCT  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB74.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d RODOPASSOS  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB75.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d SERRAFRIO  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB76.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d TRANSMEDICAL  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB77.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d AUTOLOG  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB78.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d AEG  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB79.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d ATTILIN  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB80.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d PNT  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB81.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d NORDESTAO  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB82.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d PISANE  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB83.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d ALIANCA  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB84.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d SPRINTER  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB85.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d AUTOLOGREP  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB86.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d RODOREI  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB87.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d MOBILE  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB88.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d INTERMARITIMA  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB89.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d ANALISE  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB90.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d TESTESPRINTER  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB91.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d ECARGOIMG  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB92.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d NORDESTAONEW  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB93.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d ASIA  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB94.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d DUASALIANCAS  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB95.txt" -I )

FOR %%A IN (*.SQL) DO ( sqlcmd -S 177.185.9.173 -d COVRE  -U SISTEMA -P SYSUSER -i "%%A" -o "Errors\%%AError_DB96.txt" -I )

