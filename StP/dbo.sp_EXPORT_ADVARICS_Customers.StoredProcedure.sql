/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_EXPORT_ADVARICS_Customers]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
























CREATE PROCEDURE [dbo].[sp_EXPORT_ADVARICS_Customers]

AS
BEGIN
	SET NOCOUNT ON;


DECLARE @load_result_export varchar(20);

TRUNCATE TABLE [dbo].[EXPORT_ADVARICS_Customers];

--- INSERT Header Line
INSERT INTO [dbo].[EXPORT_ADVARICS_Customers] ([Source_System],[Customer_ID],[Email],[Gender],[Firstname],[Lastname],[Street],[HouseNo],[ZipCode],[City],[State],[Country],
			[Telephone],[Mobile],[Birthday],[Language],[OdloShop],[PostOptIn],[EmailOptIn],[WebShop],[B2BB2C],[CreationDate],[LastModification])
VALUES ('source_system','pos_customer_no','email_address','gender','fistname','lastname','street','house_no','postal_code','city','state_province','country','phone_home','phone_mobile','birthday','language','odlo_shop','postaloptin','status','webshop','customer_type','creation_date','last_modification');

--- INSERT All Customers with Email
INSERT INTO [dbo].[EXPORT_ADVARICS_Customers] ([Source_System],[Customer_ID],[Email],[Gender],[Firstname],[Lastname],[Street],[HouseNo],[ZipCode],[City],[State],[Country]
			,[Telephone],[Mobile],[Birthday],[Language],[OdloShop],[PostOptIn],[EmailOptIn],[WebShop],[B2BB2C],[CreationDate],[LastModification])
--- SCRIPT TO LOAD ALL CUSTOMERS WITH OptInStatus "Active" or "Unsubscribed" if not created and unsubscribed directly
SELECT [Source_System],[Customer_ID],[Email],
		CASE WHEN [Salutation]='Mr.' THEN 'Male'
			 WHEN [Salutation]='Ms. Mrs.' THEN 'Female' ELSE NULL END as [Gender],[Firstname],[Lastname],[Street],[HouseNo],[ZipCode],[City],[State],[Country],[Telephone],[Mobile],REPLACE(Birthday,'.','/') as Birthday,[Language]
		,[OdloShop],[PostOptIn],[EmailOptIn],[WebShop],[B2BB2C],
		REPLACE([CreationDate],'.','/') as CreationDate,
		REPLACE([LastModification],'.','/') as LastModification
FROM	[dbo].[CORE_ADVARICS_Customers]
WHERE	[Email] IS NOT NULL
AND		(
			[EmailOptIn]='Active'
			OR
			[CreationDate]<>FORMAT(DATEADD(day,-1,GetDate()),'dd.MM.yyyy')
		);




--- CLEAR UNUSED TABLES
---TRUNCATE TABLE CORE_ADVARICS_Customers;	

DECLARE @String varchar(8000);
--- DECLARE EMAIL NOTIFICATION VARIABLES
DECLARE @filename varchar(50);
DECLARE @filecompany varchar(15);
DECLARE @filedate varchar(8);
DECLARE @fileext varchar(5);
DECLARE @filepath varchar(200);
DECLARE @fullpath varchar(400);
DECLARE @unsub varchar(5);

--- SET EMAIL NOTIFICATION VARIABLES
SET @filepath='D:\POS_NL\Advarics_Out\Customers\'

SET @filedate=(SELECT CONVERT(VARCHAR(8),GetDate()-1,112))
SET @fileext='.txt'
SET @unsub='_Unsub'




--- CREATE EXPORT FILE - OAT
SET @filename='Advarics_Customers_';
SET @filecompany='_OAT';
SET @fullpath=@filepath+@filename+@filedate+@filecompany+@fileext;

SET @String='bcp "SELECT Source_System,Customer_ID,Email,Gender,Firstname,Lastname,Street,HouseNo,ZipCode,City,State,Country,Telephone,Mobile,Birthday,Language,OdloShop,PostOptIn,EmailOptIn,WebShop,B2BB2C FROM POS_NL..EXPORT_ADVARICS_Customers WHERE Source_System IN (''Source_System'',''POS OAT'') AND [EmailOptIn]<>''Unsubscribed''" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S'

BEGIN TRY
EXEC xp_cmdshell @String
END TRY
BEGIN CATCH
 PRINT 'POS_NL - Customer Export OAT - File Creation failed'
 EXEC msdb.dbo.sp_send_dbmail 
	@recipients='jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Customer Export OAT - File Creation failed',
	@reply_to='jimmy.rueedi@odlo.com',
	@importance='High',
	@body='POS_NL - Customer Export OAT - File Creation failed',
	@body_format='HTML';
END CATCH
--- END EXPORT FILE - OAT


--- CREATE EXPORT FILE - OAT UNSUBCRIBED
SET @filename='Advarics_Cust_';
SET @filecompany='_OAT';
SET @fullpath=@filepath+@filename+@filedate+@filecompany+@unsub+@fileext;

SET @String='bcp "SELECT Source_System,Customer_ID,Email,Gender,Firstname,Lastname,Street,HouseNo,ZipCode,City,State,Country,Telephone,Mobile,Birthday,Language,OdloShop,PostOptIn,EmailOptIn,WebShop,B2BB2C FROM POS_NL..EXPORT_ADVARICS_Customers WHERE Source_System IN (''Source_System'',''POS OAT'') AND ([EmailOptIn]=''Unsubscribed'' OR Source_System=''Source_System'')" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S'

BEGIN TRY
EXEC xp_cmdshell @String
END TRY
BEGIN CATCH
 PRINT 'POS_NL - Customer Export OAT UNSUBSCRIBED - File Creation failed'
 EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Customer Export OAT UNSUBSCRIBED - File Creation failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Customer Export OAT UNSUBSCRIBED - File Creation failed',
	@body_format='HTML';
END CATCH
--- END EXPORT FILE - OAT













--- CREATE EXPORT FILE - ODE
SET @filename='Advarics_Customers_';
SET @filecompany='_ODE';
SET @fullpath=@filepath+@filename+@filedate+@filecompany+@fileext;

SET @String='bcp "SELECT Source_System,Customer_ID,Email,Gender,Firstname,Lastname,Street,HouseNo,ZipCode,City,State,Country,Telephone,Mobile,Birthday,Language,OdloShop,PostOptIn,EmailOptIn,WebShop,B2BB2C FROM POS_NL..EXPORT_ADVARICS_Customers WHERE Source_System IN (''Source_System'',''POS ODE'') AND [EmailOptIn]<>''Unsubscribed''" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S'

BEGIN TRY
EXEC xp_cmdshell @String
END TRY
BEGIN CATCH
 PRINT 'POS_NL - Customer Export ODE - File Creation failed'
 EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Customer Export ODE - File Creation failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Customer Export ODE - File Creation failed',
	@body_format='HTML';
END CATCH
--- END EXPORT FILE - ODE

--- CREATE EXPORT FILE - ODE UNSUBCRIBED
SET @filename='Advarics_Cust_';
SET @filecompany='_ODE';
SET @fullpath=@filepath+@filename+@filedate+@filecompany+@unsub+@fileext;

SET @String='bcp "SELECT Source_System,Customer_ID,Email,Gender,Firstname,Lastname,Street,HouseNo,ZipCode,City,State,Country,Telephone,Mobile,Birthday,Language,OdloShop,PostOptIn,EmailOptIn,WebShop,B2BB2C FROM POS_NL..EXPORT_ADVARICS_Customers WHERE Source_System IN (''Source_System'',''POS ODE'') AND ([EmailOptIn]=''Unsubscribed'' OR Source_System=''Source_System'')" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S'

BEGIN TRY
EXEC xp_cmdshell @String
END TRY
BEGIN CATCH
 PRINT 'POS_NL - Customer Export ODE UNSUBSCRIBED - File Creation failed'
 EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Customer Export ODE UNSUBSCRIBED - File Creation failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Customer Export ODE UNSUBSCRIBED - File Creation failed',
	@body_format='HTML';
END CATCH
--- END EXPORT FILE - ODE







--- CREATE EXPORT FILE - OCH
SET @filename='Advarics_Customers_';
SET @filecompany='_OCH';
SET @fullpath=@filepath+@filename+@filedate+@filecompany+@fileext;

SET @String='bcp "SELECT Source_System,Customer_ID,Email,Gender,Firstname,Lastname,Street,HouseNo,ZipCode,City,State,Country,Telephone,Mobile,Birthday,Language,OdloShop,PostOptIn,EmailOptIn,WebShop,B2BB2C FROM POS_NL..EXPORT_ADVARICS_Customers WHERE Source_System IN (''Source_System'',''POS OCH'') AND [EmailOptIn]<>''Unsubscribed''" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S'

BEGIN TRY
EXEC xp_cmdshell @String
END TRY
BEGIN CATCH
 PRINT 'POS_NL - Customer Export OCH - File Creation failed'
 EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Customer Export OCH - File Creation failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Customer Export OCH - File Creation failed',
	@body_format='HTML';
END CATCH
--- END EXPORT FILE - OCH

--- CREATE EXPORT FILE - OCH UNSUBCRIBED
SET @filename='Advarics_Cust_';
SET @filecompany='_OCH';
SET @fullpath=@filepath+@filename+@filedate+@filecompany+@unsub+@fileext;

SET @String='bcp "SELECT Source_System,Customer_ID,Email,Gender,Firstname,Lastname,Street,HouseNo,ZipCode,City,State,Country,Telephone,Mobile,Birthday,Language,OdloShop,PostOptIn,EmailOptIn,WebShop,B2BB2C FROM POS_NL..EXPORT_ADVARICS_Customers WHERE Source_System IN (''Source_System'',''POS OCH'') AND ([EmailOptIn]=''Unsubscribed'' OR Source_System=''Source_System'')" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S'

BEGIN TRY
EXEC xp_cmdshell @String
END TRY
BEGIN CATCH
 PRINT 'POS_NL - Customer Export OCH UNSUBSCRIBED - File Creation failed'
 EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Customer Export OCH UNSUBSCRIBED - File Creation failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Customer Export OCH UNSUBSCRIBED - File Creation failed',
	@body_format='HTML';
END CATCH
--- END EXPORT FILE - OCH







--- CONTROL CHECKs
SET @load_result_export=(SELECT count(*) FROM [EXPORT_ADVARICS_Customers]);

PRINT 'Load Result [EXPORT_ADVARICS_Customers] - '+@load_result_export;
PRINT 'EXPORT ADVARICS Customers successful'


------------------------------------------
--- BEGIN Send Customer Export Results ---
------------------------------------------

DECLARE @mxml NVARCHAR(MAX)
DECLARE @mbody NVARCHAR(MAX)

SET @mxml = CAST((	
					
					SELECT	Source_System as 'td','',
							OdloShop as 'td','',
							EmailOptIn as 'td','',
							CustomerCount as 'td'
					FROM	(
								SELECT	Source_System,OdloShop,EmailOptIn,count(Customer_ID) as CustomerCount
								FROM	[EXPORT_ADVARICS_Customers]
								WHERE	Source_System<>'Source_System'
								GROUP BY Source_System,OdloShop,EmailOptIn
					) as table1
					ORDER BY 1,3,5

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

SET @mbody =	'<html><body><H2>POS_NL Interface - Customer Export Results</H2>
				<table border = 1> 
				<tr>
				<th> System </th> <th> Shop </th> <th> EmailStatus </th> <th> CustomerCount </th></tr>'    
 
SET @mbody = @mbody + @mxml +'</table></body></html>'

EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL Interface - Customer Export Results',
	@reply_to='markus.pfyl@odlo.com',
	---@importance='High',
	@body=@mbody,
	@body_format='HTML';


----------------------------------------
--- END Send Customer Export Results ---
----------------------------------------




END























GO
