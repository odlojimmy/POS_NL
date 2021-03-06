/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_SOURCE_ADVARICS_Customers]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










CREATE PROCEDURE [dbo].[sp_SOURCE_ADVARICS_Customers]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


TRUNCATE TABLE SOURCE_ADVARICS_Customers;	
TRUNCATE TABLE SOURCE_ADVARICS_IMPORT_XML; 
TRUNCATE TABLE STAGING_ADVARICS_Customers;

--- CREATE MESSAGE VARIABLES
DECLARE @och varchar(20);
DECLARE @oat varchar(20);
DECLARE @ode varchar(20);
DECLARE @all varchar(20);

--- CREATE PROCESSING VARIABLES
DECLARE @path as varchar(200);
DECLARE @filename as varchar(200);
DECLARE @filedate as varchar(8);
DECLARE @fileextension as varchar(4);
DECLARE @full_path as varchar(400);
DECLARE @sql1 as varchar(1000);
DECLARE @XML AS XML, @hDoc AS INT, @SQL NVARCHAR (MAX);

--- SET GLOBAL PROCESSING VARIABLES
SET @filedate=(SELECT CONVERT(VARCHAR(8),GetDate()-1,112))
SET @path='D:\POS_NL\Advarics_In\Customers\'
SET @fileextension='.xml'


----------------------------------
--- BEGIN Import OAT Customers ---
----------------------------------	
SET @filename='CustomerData_OAT_'
SET @full_path=@path+@filename+@filedate+@fileextension

SET @sql1=N'INSERT INTO [SOURCE_ADVARICS_IMPORT_XML](XMLData, LoadedDateTime)
				SELECT CONVERT(XML, BulkColumn) AS BulkColumn, GETDATE()
				FROM OPENROWSET(BULK '''+@full_path+''', SINGLE_BLOB) AS x'
	
BEGIN TRY
EXEC(@sql1)
		
SELECT @XML = XMLData FROM SOURCE_ADVARICS_IMPORT_XML

EXEC sp_xml_preparedocument @hDoc OUTPUT, @XML	

INSERT INTO SOURCE_ADVARICS_Customers(
		Email,
		CustNr,
		LastName,
		FirstName,
		Salutation,
		Street,
		HouseNr,
		PostalCode,
		City,
		County,
		Country,
		Birthday,
		Telephone,
		Mobile,
		eMailActiv,
		MailActiv,
		Creationdate,
		LastModification,
		Lang,
		OdloStoreNo) 
SELECT Email, CustNr, LastName, FirstName, Salutation, Street, HouseNr, PostalCode,
City, County, Country, Birthday, Telephone, Mobile, eMailActiv, mailActiv, Creationdate, LastModification, Lang, OdloStoreNo
FROM OPENXML(@hDoc, 'OdloCrmCustomers/Items/OdloCrmCustomer')
WITH 
(
[Email] [varchar](250) 'Email',
[CustNr] [nvarchar](25) 'CustNr',
[LastName] [nvarchar](150) 'LastName',
[FirstName] [nvarchar](150) 'FirstName',
[Salutation] [nvarchar](25) 'Salutation',
[Street] [varchar](250) 'Street',
[HouseNr] [nvarchar](125) 'HouseNr',
[PostalCode] [nvarchar](125) 'PostalCode',
[City] [varchar](250) 'City',
[County] [varchar](150) 'County',
[Country] [varchar](150) 'Country',
[Birthday] [nvarchar](25) 'Birthday',
[Telephone] [nvarchar](125) 'Telephone',
[Mobile] [nvarchar](125) 'Mobile',
[eMailActiv] [nvarchar](250) 'eMailActiv',
[mailActiv] [nvarchar](250) 'mailActiv',
[Creationdate] [nvarchar](125) 'Creationdate',
[LastModification] [nvarchar](150) 'LastModification',
[Lang] [varchar](50) 'Lang',
[OdloStoreNo] [nvarchar](150) 'OdloStoreNo'
)

EXEC sp_xml_removedocument @hDoc

END TRY

BEGIN CATCH
	PRINT 'POS_NL - Customer Data - Advarics OAT - DB Import failed'

	EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Customer Data - Advarics OAT - DB Import failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Customer Data - Advarics OAT - DB Import failed',
	@body_format='HTML';

END CATCH


--- Set NULL instead of ''
UPDATE SOURCE_ADVARICS_Customers	SET	Email=(CASE WHEN Email='' THEN NULL ELSE Email END),
											LastName=(CASE WHEN LastName='' THEN NULL ELSE LastName END),
											FirstName=(CASE WHEN FirstName='' THEN NULL ELSE FirstName END),
											Salutation=(CASE WHEN Salutation='' THEN NULL ELSE Salutation END),
											Street=(CASE WHEN Street='' THEN NULL ELSE Street END),
											HouseNr=(CASE WHEN HouseNr='' THEN NULL ELSE HouseNr END),
											PostalCode=(CASE WHEN PostalCode='' THEN NULL ELSE PostalCode END),
											City=(CASE WHEN City='' THEN NULL ELSE City END),
											County=(CASE WHEN County='' THEN NULL ELSE County END),
											Country=(CASE WHEN Country='' THEN NULL ELSE Country END),
											Birthday=(CASE WHEN Birthday='' THEN NULL ELSE Birthday END),
											Telephone=(CASE WHEN Telephone='' THEN NULL ELSE Telephone END),
											Mobile=(CASE WHEN Mobile='' THEN NULL ELSE Mobile END),
											eMailActiv=(CASE WHEN eMailActiv='' THEN NULL ELSE eMailActiv END),
											mailActiv=(CASE WHEN mailActiv='' THEN NULL ELSE mailActiv END),
											Creationdate=(CASE WHEN Creationdate='' THEN NULL ELSE Creationdate END),
											LastModification=(CASE WHEN LastModification='' THEN NULL ELSE LastModification END),
											Lang=(CASE WHEN Lang='' THEN NULL ELSE Lang END),
											OdloStoreNo=(CASE WHEN OdloStoreNo='' THEN NULL ELSE OdloStoreNo END);



INSERT INTO [dbo].[STAGING_ADVARICS_Customers] ([Source_System],[Customer_ID],[Email],[Salutation],[Firstname],[Lastname],[Street],[HouseNo],[ZipCode],[City],[State],[Country],[Telephone],[Mobile]
,[Birthday],[Language],[OdloShop],[PostOptIn],[EmailOptIn],[WebShop],[B2BB2C],[CreationDate],[LastModification])
SELECT	'POS '+Substring(c.CustNr,1,3) as Source_System,c.CustNr as Customer_ID,c.Email,
		CASE WHEN UPPER(c.Salutation)='HERR' THEN 'Mr.' WHEN UPPER(c.Salutation)='FRAU' THEN 'Ms. Mrs.' WHEN UPPER(c.Salutation)='HERR UND FRAU' THEN 'Mr. and Mrs.' ELSE 'Family' END as Salutation,
		c.FirstName,c.LastName,c.Street,c.HouseNr,c.PostalCode,c.City,c.County as State,CASE WHEN l.Country_en IS NULL THEN 'unknown country' ELSE l.Country_en END as Country,c.Telephone,c.Mobile,
		CONVERT(varchar,CONVERT(date,c.Birthday,104),104) as Birthday,CASE WHEN l.Language_en IS NULL THEN 'English' ELSE l.Language_en END as Language,
		CASE WHEN s.Odlo_Short_Name IS NULL THEN 'unknown shop' ELSE s.Odlo_Short_Name END as OdloShop,
		CASE WHEN UPPER(c.MailActiv)='TRUE' THEN 'Yes' ELSE 'No' END as MailActiv,
		CASE WHEN UPPER(c.eMailActiv)='TRUE' THEN 'Active' ELSE 'Unsubscribed' END as eMailActiv,
		CASE WHEN l.WebShop IS NULL THEN 'world_en' ELSE l.WebShop END as WebShop,
		'B2C' as B2BB2C,CONVERT(varchar,CONVERT(date,c.CreationDate,104),104) as CreationDate,CONVERT(varchar,GetDate(),104)  as LastModification
FROM	SOURCE_ADVARICS_Customers c	LEFT OUTER JOIN LOOKUP_Country_Language_WebShop l ON (c.Country=l.ISO_2)
									LEFT OUTER JOIN LOOKUP_Shop s ON (c.OdloStoreNo=s.GLN);


--- CLEAN UNUSED TABLES
TRUNCATE TABLE SOURCE_ADVARICS_IMPORT_XML;
TRUNCATE TABLE SOURCE_ADVARICS_Customers;

--------------------------------
--- END Import OAT Customers ---
--------------------------------		



----------------------------------
--- BEGIN Import OCH Customers ---
----------------------------------

SET @filename='CustomerData_OCH_'
SET @full_path=@path+@filename+@filedate+@fileextension

SET @sql1=N'INSERT INTO [SOURCE_ADVARICS_IMPORT_XML](XMLData, LoadedDateTime)
				SELECT CONVERT(XML, BulkColumn) AS BulkColumn, GETDATE()
				FROM OPENROWSET(BULK '''+@full_path+''', SINGLE_BLOB) AS x'
	
BEGIN TRY
EXEC(@sql1)
		
SELECT @XML = XMLData FROM SOURCE_ADVARICS_IMPORT_XML

EXEC sp_xml_preparedocument @hDoc OUTPUT, @XML	


INSERT INTO SOURCE_ADVARICS_Customers(
		Email,
		CustNr,
		LastName,
		FirstName,
		Salutation,
		Street,
		HouseNr,
		PostalCode,
		City,
		County,
		Country,
		Birthday,
		Telephone,
		Mobile,
		eMailActiv,
		MailActiv,
		Creationdate,
		LastModification,
		Lang,
		OdloStoreNo) 
SELECT Email, CustNr, LastName, FirstName, Salutation, Street, HouseNr, PostalCode,
City, County, Country, Birthday, Telephone, Mobile, eMailActiv, mailActiv, Creationdate, LastModification, Lang, OdloStoreNo
FROM OPENXML(@hDoc, 'OdloCrmCustomers/Items/OdloCrmCustomer')
WITH 
(
[Email] [varchar](250) 'Email',
[CustNr] [nvarchar](25) 'CustNr',
[LastName] [nvarchar](150) 'LastName',
[FirstName] [nvarchar](150) 'FirstName',
[Salutation] [nvarchar](25) 'Salutation',
[Street] [varchar](250) 'Street',
[HouseNr] [nvarchar](125) 'HouseNr',
[PostalCode] [nvarchar](125) 'PostalCode',
[City] [varchar](250) 'City',
[County] [varchar](150) 'County',
[Country] [varchar](150) 'Country',
[Birthday] [nvarchar](25) 'Birthday',
[Telephone] [nvarchar](125) 'Telephone',
[Mobile] [nvarchar](125) 'Mobile',
[eMailActiv] [nvarchar](250) 'eMailActiv',
[mailActiv] [nvarchar](250) 'mailActiv',
[Creationdate] [nvarchar](125) 'Creationdate',
[LastModification] [nvarchar](150) 'LastModification',
[Lang] [varchar](50) 'Lang',
[OdloStoreNo] [nvarchar](150) 'OdloStoreNo'
)

EXEC sp_xml_removedocument @hDoc

END TRY


BEGIN CATCH
	PRINT 'POS_NL - Customer Data - Advarics OCH - DB Import failed'

	EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Customer Data - Advarics OCH - DB Import failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Customer Data - Advarics OCH - DB Import failed',
	@body_format='HTML';
END CATCH



--- Set NULL instead of ''
UPDATE SOURCE_ADVARICS_Customers	SET	Email=(CASE WHEN Email='' THEN NULL ELSE Email END),
											LastName=(CASE WHEN LastName='' THEN NULL ELSE LastName END),
											FirstName=(CASE WHEN FirstName='' THEN NULL ELSE FirstName END),
											Salutation=(CASE WHEN Salutation='' THEN NULL ELSE Salutation END),
											Street=(CASE WHEN Street='' THEN NULL ELSE Street END),
											HouseNr=(CASE WHEN HouseNr='' THEN NULL ELSE HouseNr END),
											PostalCode=(CASE WHEN PostalCode='' THEN NULL ELSE PostalCode END),
											City=(CASE WHEN City='' THEN NULL ELSE City END),
											County=(CASE WHEN County='' THEN NULL ELSE County END),
											Country=(CASE WHEN Country='' THEN NULL ELSE Country END),
											Birthday=(CASE WHEN Birthday='' THEN NULL ELSE Birthday END),
											Telephone=(CASE WHEN Telephone='' THEN NULL ELSE Telephone END),
											Mobile=(CASE WHEN Mobile='' THEN NULL ELSE Mobile END),
											eMailActiv=(CASE WHEN eMailActiv='' THEN NULL ELSE eMailActiv END),
											mailActiv=(CASE WHEN mailActiv='' THEN NULL ELSE mailActiv END),
											Creationdate=(CASE WHEN Creationdate='' THEN NULL ELSE Creationdate END),
											LastModification=(CASE WHEN LastModification='' THEN NULL ELSE LastModification END),
											Lang=(CASE WHEN Lang='' THEN NULL ELSE Lang END),
											OdloStoreNo=(CASE WHEN OdloStoreNo='' THEN NULL ELSE OdloStoreNo END);


INSERT INTO [dbo].[STAGING_ADVARICS_Customers] ([Source_System],[Customer_ID],[Email],[Salutation],[Firstname],[Lastname],[Street],[HouseNo],[ZipCode],[City],[State],[Country],[Telephone],[Mobile]
,[Birthday],[Language],[OdloShop],[PostOptIn],[EmailOptIn],[WebShop],[B2BB2C],[CreationDate],[LastModification])
SELECT	'POS '+Substring(c.CustNr,1,3) as Source_System,c.CustNr as Customer_ID,c.Email,
		CASE WHEN UPPER(c.Salutation)='HERR' THEN 'Mr.' WHEN UPPER(c.Salutation)='FRAU' THEN 'Ms. Mrs.' WHEN UPPER(c.Salutation)='HERR UND FRAU' THEN 'Mr. and Mrs.' ELSE 'Family' END as Salutation,
		c.FirstName,c.LastName,c.Street,c.HouseNr,c.PostalCode,c.City,c.County as State,CASE WHEN l.Country_en IS NULL THEN 'unknown country' ELSE l.Country_en END as Country,c.Telephone,c.Mobile,
		CONVERT(varchar,CONVERT(date,c.Birthday,104),104) as Birthday,CASE WHEN l.Language_en IS NULL THEN 'English' ELSE l.Language_en END as Language,
		CASE WHEN s.Odlo_Short_Name IS NULL THEN 'unknown shop' ELSE s.Odlo_Short_Name END as OdloShop,
		CASE WHEN UPPER(c.MailActiv)='TRUE' THEN 'Yes' ELSE 'No' END as MailActiv,
		CASE WHEN UPPER(c.eMailActiv)='TRUE' THEN 'Active' ELSE 'Unsubscribed' END as eMailActiv,
		CASE WHEN l.WebShop IS NULL THEN 'world_en' ELSE l.WebShop END as WebShop,
		'B2C' as B2BB2C,CONVERT(varchar,CONVERT(date,c.CreationDate,104),104) as CreationDate,CONVERT(varchar,GetDate(),104)  as LastModification
FROM	SOURCE_ADVARICS_Customers c	LEFT OUTER JOIN LOOKUP_Country_Language_WebShop l ON (c.Country=l.ISO_2)
									LEFT OUTER JOIN LOOKUP_Shop s ON (c.OdloStoreNo=s.GLN);

TRUNCATE TABLE SOURCE_ADVARICS_IMPORT_XML;
TRUNCATE TABLE SOURCE_ADVARICS_Customers;

--------------------------------
--- END Import OCH Customers ---
--------------------------------



----------------------------------
--- BEGIN Import ODE Customers ---
----------------------------------	
SET @filename='CustomerData_ODE_'
SET @full_path=@path+@filename+@filedate+@fileextension

SET @sql1=N'INSERT INTO [SOURCE_ADVARICS_IMPORT_XML](XMLData, LoadedDateTime)
				SELECT CONVERT(XML, BulkColumn) AS BulkColumn, GETDATE()
				FROM OPENROWSET(BULK '''+@full_path+''', SINGLE_BLOB) AS x'
	
BEGIN TRY
EXEC(@sql1)

SELECT @XML = XMLData FROM SOURCE_ADVARICS_IMPORT_XML

EXEC sp_xml_preparedocument @hDoc OUTPUT, @XML	

INSERT INTO SOURCE_ADVARICS_Customers(
		Email,
		CustNr,
		LastName,
		FirstName,
		Salutation,
		Street,
		HouseNr,
		PostalCode,
		City,
		County,
		Country,
		Birthday,
		Telephone,
		Mobile,
		eMailActiv,
		MailActiv,
		Creationdate,
		LastModification,
		Lang,
		OdloStoreNo) 
SELECT Email, CustNr, LastName, FirstName, Salutation, Street, HouseNr, PostalCode,
City, County, Country, Birthday, Telephone, Mobile, eMailActiv, mailActiv, Creationdate, LastModification, Lang, OdloStoreNo
FROM OPENXML(@hDoc, 'OdloCrmCustomers/Items/OdloCrmCustomer')
WITH 
(
[Email] [varchar](250) 'Email',
[CustNr] [nvarchar](25) 'CustNr',
[LastName] [nvarchar](150) 'LastName',
[FirstName] [nvarchar](150) 'FirstName',
[Salutation] [nvarchar](25) 'Salutation',
[Street] [varchar](250) 'Street',
[HouseNr] [nvarchar](125) 'HouseNr',
[PostalCode] [nvarchar](125) 'PostalCode',
[City] [varchar](250) 'City',
[County] [varchar](150) 'County',
[Country] [varchar](150) 'Country',
[Birthday] [nvarchar](25) 'Birthday',
[Telephone] [nvarchar](125) 'Telephone',
[Mobile] [nvarchar](125) 'Mobile',
[eMailActiv] [nvarchar](250) 'eMailActiv',
[mailActiv] [nvarchar](250) 'mailActiv',
[Creationdate] [nvarchar](125) 'Creationdate',
[LastModification] [nvarchar](150) 'LastModification',
[Lang] [varchar](50) 'Lang',
[OdloStoreNo] [nvarchar](150) 'OdloStoreNo'
)

EXEC sp_xml_removedocument @hDoc

END TRY

BEGIN CATCH
	PRINT 'POS_NL - Customer Data - Advarics ODE - DB Import failed'

	EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Customer Data - Advarics ODE - DB Import failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Customer Data - Advarics ODE - DB Import failed',
	@body_format='HTML';

END CATCH


--- Set NULL instead of ''
UPDATE SOURCE_ADVARICS_Customers	SET	Email=(CASE WHEN Email='' THEN NULL ELSE Email END),
											LastName=(CASE WHEN LastName='' THEN NULL ELSE LastName END),
											FirstName=(CASE WHEN FirstName='' THEN NULL ELSE FirstName END),
											Salutation=(CASE WHEN Salutation='' THEN NULL ELSE Salutation END),
											Street=(CASE WHEN Street='' THEN NULL ELSE Street END),
											HouseNr=(CASE WHEN HouseNr='' THEN NULL ELSE HouseNr END),
											PostalCode=(CASE WHEN PostalCode='' THEN NULL ELSE PostalCode END),
											City=(CASE WHEN City='' THEN NULL ELSE City END),
											County=(CASE WHEN County='' THEN NULL ELSE County END),
											Country=(CASE WHEN Country='' THEN NULL ELSE Country END),
											Birthday=(CASE WHEN Birthday='' THEN NULL ELSE Birthday END),
											Telephone=(CASE WHEN Telephone='' THEN NULL ELSE Telephone END),
											Mobile=(CASE WHEN Mobile='' THEN NULL ELSE Mobile END),
											eMailActiv=(CASE WHEN eMailActiv='' THEN NULL ELSE eMailActiv END),
											mailActiv=(CASE WHEN mailActiv='' THEN NULL ELSE mailActiv END),
											Creationdate=(CASE WHEN Creationdate='' THEN NULL ELSE Creationdate END),
											LastModification=(CASE WHEN LastModification='' THEN NULL ELSE LastModification END),
											Lang=(CASE WHEN Lang='' THEN NULL ELSE Lang END),
											OdloStoreNo=(CASE WHEN OdloStoreNo='' THEN NULL ELSE OdloStoreNo END);

INSERT INTO [dbo].[STAGING_ADVARICS_Customers] ([Source_System],[Customer_ID],[Email],[Salutation],[Firstname],[Lastname],[Street],[HouseNo],[ZipCode],[City],[State],[Country],[Telephone],[Mobile]
,[Birthday],[Language],[OdloShop],[PostOptIn],[EmailOptIn],[WebShop],[B2BB2C],[CreationDate],[LastModification])
SELECT	'POS '+Substring(c.CustNr,1,3) as Source_System,c.CustNr as Customer_ID,c.Email,
		CASE WHEN UPPER(c.Salutation)='HERR' THEN 'Mr.' WHEN UPPER(c.Salutation)='FRAU' THEN 'Ms. Mrs.' WHEN UPPER(c.Salutation)='HERR UND FRAU' THEN 'Mr. and Mrs.' ELSE 'Family' END as Salutation,
		c.FirstName,c.LastName,c.Street,c.HouseNr,c.PostalCode,c.City,c.County as State,CASE WHEN l.Country_en IS NULL THEN 'unknown country' ELSE l.Country_en END as Country,c.Telephone,c.Mobile,
		CONVERT(varchar,CONVERT(date,c.Birthday,104),104) as Birthday,CASE WHEN l.Language_en IS NULL THEN 'English' ELSE l.Language_en END as Language,
		CASE WHEN s.Odlo_Short_Name IS NULL THEN 'unknown shop' ELSE s.Odlo_Short_Name END as OdloShop,
		CASE WHEN UPPER(c.MailActiv)='TRUE' THEN 'Yes' ELSE 'No' END as MailActiv,
		CASE WHEN UPPER(c.eMailActiv)='TRUE' THEN 'Active' ELSE 'Unsubscribed' END as eMailActiv,
		CASE WHEN l.WebShop IS NULL THEN 'world_en' ELSE l.WebShop END as WebShop,
		'B2C' as B2BB2C,CONVERT(varchar,CONVERT(date,c.CreationDate,104),104) as CreationDate,CONVERT(varchar,GetDate(),104)  as LastModification
FROM	SOURCE_ADVARICS_Customers c	LEFT OUTER JOIN LOOKUP_Country_Language_WebShop l ON (c.Country=l.ISO_2)
									LEFT OUTER JOIN LOOKUP_Shop s ON (c.OdloStoreNo=s.GLN);

--- CLEAN UNUSED TABLES
TRUNCATE TABLE SOURCE_ADVARICS_IMPORT_XML;
---TRUNCATE TABLE SOURCE_ADVARICS_Customers;

--------------------------------
--- END Import ODE Customers ---
--------------------------------



--- SET EMAIL to NULL WHERE EMAIL-PATTERN INCORRECT
UPDATE [STAGING_ADVARICS_Customers] SET Email=NULL WHERE Customer_ID IN (
SELECT	DISTINCT CustNr
FROM	(

SELECT	CustNr,Email,
		CASE	WHEN	Email LIKE '%_@_%_.__%' 
						AND Email NOT LIKE '%[/$\<>,+=äöü]%' 
				THEN 'Could be' 
				ELSE 'Nope' 
				END Validates
FROM	[SOURCE_ADVARICS_Customers]) as temptable
WHERE	Validates='Nope'
AND		Email IS NOT NULL);





--- CONTROL CHECKs
SET @oat=(SELECT CAST((SELECT count(*) FROM STAGING_ADVARICS_Customers WHERE Substring(Customer_ID,1,3)='OAT') as varchar));
SET @och=(SELECT CAST((SELECT count(*) FROM STAGING_ADVARICS_Customers WHERE Substring(Customer_ID,1,3)='OCH') as varchar));
SET @ode=(SELECT CAST((SELECT count(*) FROM STAGING_ADVARICS_Customers WHERE Substring(Customer_ID,1,3)='ODE') as varchar));
SET @all=(SELECT CAST((SELECT count(*) FROM STAGING_ADVARICS_Customers) as varchar));

PRINT 'OAT Import Count - '+@oat
PRINT 'OCH Import Count - '+@och
PRINT 'ODE Import Count - '+@ode
PRINT 'All Import Count - '+@all
PRINT 'SOURCE ADVARICS Customers successful'


------------------------------------------
--- BEGIN Send Customer Import Results ---
------------------------------------------

DECLARE @mxml NVARCHAR(MAX)
DECLARE @mbody NVARCHAR(MAX)

SET @mxml = CAST((	
					
					SELECT	Source_System as 'td','',
							OdloShop as 'td','',
							LastModification as 'td','',
							CustomerCount as 'td'
					FROM	(
								SELECT	Source_System,OdloShop,LastModification,count(*) as CustomerCount
								FROM	STAGING_ADVARICS_Customers
								GROUP BY Source_System,OdloShop,LastModification
					) as table1
					ORDER BY 1,3,5

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

SET @mbody =	'<html><body><H2>POS_NL Interface - Customer Load Results</H2>
				<table border = 1> 
				<tr>
				<th> System </th> <th> Shop </th> <th> LastModification </th> <th> CustomerCount </th></tr>'    
 
SET @mbody = @mbody + @mxml +'</table></body></html>'

EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL Interface - Customer Load Results',
	@reply_to='markus.pfyl@odlo.com',
	---@importance='High',
	@body=@mbody,
	@body_format='HTML';


----------------------------------------
--- END Send Customer Import Results ---
----------------------------------------



END













GO
