/*
A Simple script to verify whether your SQL Server is running on a Physical Box or a Virtual machine without RDP'ing into your server.
Note: This Script works only on 2008R2 SP1 and above..
*/
SELECT SERVERPROPERTY('computernamephysicalnetbios') AS ServerName
,dosi.virtual_machine_type_desc
,Server_type = CASE 
    WHEN dosi.virtual_machine_type = 1
	THEN 'Virtual' 
    ELSE 'Physical'
END
FROM sys.dm_os_sys_info dosi

/* If you have a CMS configured, run the below Script from your CMS against multiple servers*/

SELECT dosi.virtual_machine_type_desc
,Server_type = CASE 
    WHEN dosi.virtual_machine_type = 1
	THEN 'Virtual' 
    ELSE 'Physical'
END
FROM sys.dm_os_sys_info dosi 