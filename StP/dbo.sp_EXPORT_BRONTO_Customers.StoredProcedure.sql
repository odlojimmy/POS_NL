/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_EXPORT_BRONTO_Customers]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






























CREATE PROCEDURE [dbo].[sp_EXPORT_BRONTO_Customers]

AS
BEGIN
	SET NOCOUNT ON;

DECLARE @String varchar(8000);

TRUNCATE TABLE EXPORT_BRONTO_Customers;

INSERT INTO [dbo].[EXPORT_BRONTO_Customers]
           ([Email]
           ,[Advarics]
           ,[LastName]
           ,[FirstName]
           ,[Gender]
           ,[Street]
           ,[HouseNr]
           ,[PostalCode]
           ,[City]
           ,[County]
           ,[Country]
           ,[Birthday]
           ,[Telephone]
           ,[Mobile]
           ,[EmailOptInStatus]
           ,[PostOptInStatus]
           ,[Creationdate]
           ,[LastModification]
           ,[Lang]
           ,[WebShop]
           ,[Shop])

SELECT	CASE WHEN EmailAddress='' THEN NULL ELSE EmailAddress END as EmailAddress,
		CASE WHEN POSCustomerNumber='' THEN NULL ELSE POSCustomerNumber END as POSCustomerNumber,
		CASE WHEN LastName='' THEN NULL ELSE LastName END as LastName,
		CASE WHEN FirstName='' THEN NULL ELSE FirstName END as FirstName,
		CASE WHEN Gender='' THEN NULL ELSE Gender END as Gender,
		CASE WHEN Street='' THEN NULL ELSE Street END as Street,
		CASE WHEN HouseNumber='' THEN NULL ELSE HouseNumber END as HouseNumber,
		CASE WHEN PostalCode='' THEN NULL ELSE PostalCode END as PostalCode,
		CASE WHEN City='' THEN NULL ELSE City END as City,
		CASE WHEN County='' THEN NULL ELSE County END as County,
		CASE WHEN Country='' THEN NULL ELSE Country END as Country,
		CASE WHEN Birthday='' THEN NULL ELSE Birthday END as Birthday,
		CASE WHEN Telephone='' THEN NULL ELSE Telephone END as Telephone,
		CASE WHEN Mobile='' THEN NULL ELSE Mobile END as Mobile,
		CASE WHEN EmailSubscriptionStatus='' THEN NULL ELSE EmailSubscriptionStatus END as EmailSubscriptionStatus,
		CASE WHEN PostSubscriptionStatus='' THEN NULL ELSE PostSubscriptionStatus END as PostSubscriptionStatus,
		NULL as CreationDate,FORMAT(GetDate(),'yyyy-MM-dd')+' 00:00:00' as LastModification,
		CASE WHEN Language='' THEN NULL ELSE Language END as Language,
		NULL as WebShop,
		CASE WHEN POSShopName='' THEN NULL ELSE POSShopName END as POSShopName
FROM	CORE_BRONTO_Customers;


/* -- Only sync back customerno, email and email-opt-in / old procedure commented
--- EXPORT ODE Customer XML File
SET @String='bcp "SELECT Email,Advarics,LastName,FirstName,Gender,Street,HouseNr,PostalCode,City,County,Country,Birthday,Telephone,Mobile,EmailOptInStatus,PostOptInStatus,Creationdate,LastModification,Lang,WebShop,Shop FROM POS_NL..EXPORT_BRONTO_Customers as Customer WHERE Advarics LIKE ''ODE%'' FOR XML AUTO, TYPE, ELEMENTS, ROOT(''Customers'')" queryout D:\POS_NL\Bronto_Out\Customers\ODE_Subscriber.xml -c -T -t -S -w'
EXEC xp_cmdshell @String

--- Export OAT Customer XML File
SET @String='bcp "SELECT Email,Advarics,LastName,FirstName,Gender,Street,HouseNr,PostalCode,City,County,Country,Birthday,Telephone,Mobile,EmailOptInStatus,PostOptInStatus,Creationdate,LastModification,Lang,WebShop,Shop FROM POS_NL..EXPORT_BRONTO_Customers as Customer WHERE Advarics LIKE ''OAT%'' FOR XML AUTO, TYPE, ELEMENTS, ROOT(''Customers'')" queryout D:\POS_NL\Bronto_Out\Customers\OAT_Subscriber.xml -c -T -t -S -w'
EXEC xp_cmdshell @String

--- Export OCH Customer XML File
SET @String='bcp "SELECT Email,Advarics,LastName,FirstName,Gender,Street,HouseNr,PostalCode,City,County,Country,Birthday,Telephone,Mobile,EmailOptInStatus,PostOptInStatus,Creationdate,LastModification,Lang,WebShop,Shop FROM POS_NL..EXPORT_BRONTO_Customers as Customer WHERE Advarics LIKE ''OCH%'' FOR XML AUTO, TYPE, ELEMENTS, ROOT(''Customers'')" queryout D:\POS_NL\Bronto_Out\Customers\OCH_Subscriber.xml -c -T -t -S -w'
EXEC xp_cmdshell @String
*/

--- EXPORT ODE Customer XML File
SET @String='bcp "SELECT Email,Advarics,FirstName,LastName,Birthday,CASE WHEN UPPER(EmailOptInStatus)=''UNSUB'' THEN ''No'' ELSE ''Yes'' END as EmailOptInStatus FROM POS_NL..EXPORT_BRONTO_Customers as Customer WHERE Advarics LIKE ''ODE%'' FOR XML AUTO, TYPE, ELEMENTS, ROOT(''Customers'')" queryout D:\POS_NL\Bronto_Out\Customers\ODE_Subscriber.xml -c -T -t -S -w'
EXEC xp_cmdshell @String

--- Export OAT Customer XML File
SET @String='bcp "SELECT Email,Advarics,FirstName,LastName,Birthday,CASE WHEN UPPER(EmailOptInStatus)=''UNSUB'' THEN ''No'' ELSE ''Yes'' END as EmailOptInStatus FROM POS_NL..EXPORT_BRONTO_Customers as Customer WHERE Advarics LIKE ''OAT%'' FOR XML AUTO, TYPE, ELEMENTS, ROOT(''Customers'')" queryout D:\POS_NL\Bronto_Out\Customers\OAT_Subscriber.xml -c -T -t -S -w'
EXEC xp_cmdshell @String

--- Export OCH Customer XML File
SET @String='bcp "SELECT Email,Advarics,FirstName,LastName,Birthday,CASE WHEN UPPER(EmailOptInStatus)=''UNSUB'' THEN ''No'' ELSE ''Yes'' END as EmailOptInStatus FROM POS_NL..EXPORT_BRONTO_Customers as Customer WHERE Advarics LIKE ''OCH%'' FOR XML AUTO, TYPE, ELEMENTS, ROOT(''Customers'')" queryout D:\POS_NL\Bronto_Out\Customers\OCH_Subscriber.xml -c -T -t -S -w'
EXEC xp_cmdshell @String




--- PREP FOR OFR EXPORT WITH HEADER INFORMATION
IF OBJECT_ID('tempdb..#temp_ofr') IS NOT NULL DROP TABLE #temp_ofr;

SELECT *
INTO #temp_ofr
FROM POS_NL..EXPORT_BRONTO_Customers as Customer WHERE Advarics LIKE 'OFR%';

TRUNCATE TABLE EXPORT_BRONTO_Customers;

INSERT INTO [dbo].[EXPORT_BRONTO_Customers]  ([Email],[Advarics],[LastName],[FirstName],[Gender],[Street],[HouseNr],[PostalCode]
,[City],[County],[Country],[Birthday],[Telephone],[Mobile],[EmailOptInStatus],[PostOptInStatus],[Creationdate],[LastModification]
,[Lang],[WebShop],[Shop])
VALUES ('Email','CustomerNo','Lastname','Firstname','Gender','Street','HouseNo','PostalCode','City','County','Country','Birthday',
'Telephone','Mobile','EmailOptInStatus','PostOptInStatus','CreationDate','LastModification','Lang','WebShop','Shop')

INSERT INTO EXPORT_BRONTO_Customers
SELECT	*
FROM	#temp_ofr;

IF OBJECT_ID('tempdb..#temp_ofr') IS NOT NULL DROP TABLE #temp_ofr;






--- Export OFR Customer TXT File
DECLARE @fullpath varchar(400);
DECLARE @string1 varchar(8000);

--- SET EMAIL NOTIFICATION VARIABLES
SET @fullpath='D:\POS_NL\Bronto_Out\Customers\OFR_Customers.txt'


SET @string1='bcp "SELECT Email,Advarics,FirstName,LastName,Birthday,CASE WHEN  UPPER(EmailOptInStatus)=''EMAILOPTINSTATUS'' THEN ''EmailOptInStatus'' WHEN UPPER(EmailOptInStatus)=''UNSUB'' THEN ''No'' WHEN UPPER(EmailOptInStatus)=''BOUNCE'' THEN ''Bounced'' ELSE ''Yes'' END as EmailOptInStatus FROM POS_NL..EXPORT_BRONTO_Customers" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S'


BEGIN TRY
EXEC xp_cmdshell @string1
END TRY
BEGIN CATCH
 PRINT 'POS_NL - Bronto RetailPro Export - OFR File Creation failed'
 EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Bronto RetailPro Export - OFR File Creation failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Bronto RetailPro Export - OFR File Creation failed',
	@body_format='HTML';
END CATCH








---TRUNCATE TABLE STAGING_BRONTO_Customers;

PRINT 'EXPORT BRONTO Customers successful'



END

























GO
