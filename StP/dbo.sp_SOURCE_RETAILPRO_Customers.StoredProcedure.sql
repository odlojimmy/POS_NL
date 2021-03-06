/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_SOURCE_RETAILPRO_Customers]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






















CREATE PROCEDURE [dbo].[sp_SOURCE_RETAILPRO_Customers]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


TRUNCATE TABLE SOURCE_RETAILPRO_Customers;	
TRUNCATE TABLE STAGING_RETAILPRO_Customers;

--- CREATE MESSAGE VARIABLES
DECLARE @ofr varchar(20);



	
BEGIN TRY

--- IMPORT BRONTO CSV FILE
BULK INSERT SOURCE_RETAILPRO_Customers
FROM 'D:\POS_NL\RetailPro_In\Customers\ODLOCrmCustomer_updated2.csv'
WITH
(
	DATAFILETYPE='char',
	--CODEPAGE='ACP',
	FIRSTROW=2,
	FIELDTERMINATOR=';',
	ROWTERMINATOR='\n'
)


END TRY

BEGIN CATCH
	PRINT 'POS_NL - Customer Data - RetailPro OFR - DB Import failed'

	EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Customer Data - RetailPro OFR - DB Import failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Customer Data - RetailPro OFR - DB Import failed',
	@body_format='HTML';

END CATCH





--- Set NULL instead of ''
UPDATE SOURCE_RETAILPRO_Customers	SET	CodeShop=(CASE WHEN CodeShop='' THEN NULL ELSE CodeShop END),
											CustNr=(CASE WHEN CustNr='' THEN NULL ELSE CustNr END),
											Salutation=(CASE WHEN Salutation='' THEN NULL ELSE Salutation END),
											LastName=(CASE WHEN LastName='' THEN NULL ELSE LastName END),
											FirstName=(CASE WHEN FirstName='' THEN NULL ELSE FirstName END),
											Email=(CASE WHEN Email='' THEN NULL ELSE Email END),
											Birthday=(CASE WHEN Birthday='' THEN NULL ELSE Birthday END),
											Street=(CASE WHEN Street='' THEN NULL ELSE Street END),
											HouseNr=(CASE WHEN HouseNr='' THEN NULL ELSE HouseNr END),
											City=(CASE WHEN City='' THEN NULL ELSE City END),
											PostalCode=(CASE WHEN PostalCode='' THEN NULL ELSE PostalCode END),
											Country=(CASE WHEN Country='' THEN NULL ELSE Country END),
											Phone1=(CASE WHEN Phone1='' THEN NULL ELSE Phone1 END),
											Phone2=(CASE WHEN Phone2='' THEN NULL ELSE Phone2 END),
											NoEmail=(CASE WHEN NoEmail='' THEN NULL ELSE NoEmail END),
											NoPhone=(CASE WHEN NoPhone='' THEN NULL ELSE NoPhone END),
											NoMail=(CASE WHEN NoMail='' THEN NULL ELSE NoMail END),
											LTY_OPT_IN=(CASE WHEN LTY_OPT_IN='' THEN NULL ELSE LTY_OPT_IN END),
											Creationdate=(CASE WHEN Creationdate='' THEN NULL ELSE Creationdate END);



INSERT INTO [dbo].[STAGING_RETAILPRO_Customers] ([Source_System],[Customer_ID],[Email],[Salutation],[Firstname],[Lastname],[Street],[HouseNo],[ZipCode],[City],[State],[Country],[Telephone]
,[Mobile],[Birthday],[Language],[OdloShop],[PostOptIn],[EmailOptIn],[WebShop],[B2BB2C],[LTY_OPT_IN],[LTY_BALANCE],[LastPurchase],[CreditNote],[CustomerType],[CreationDate],[LastModification])
SELECT	'POS OFR' as Source_System,c.CustNr as Customer_ID,c.Email,c.Salutation,c.FirstName,c.LastName,c.Street,c.HouseNr as HouseNo,c.PostalCode as ZipCode,c.City,NULL as [State],
		CASE WHEN l.Country_en IS NULL THEN 'unknown country' ELSE l.Country_en END as Country,c.Phone1,c.Phone2,c.Birthday,
		CASE WHEN l.Language_en IS NULL THEN 'French' ELSE l.Language_en END as Language,CASE WHEN s.Odlo_Short_Name IS NULL THEN 'unknown shop' ELSE s.Odlo_Short_Name END as OdloShop,
		CASE WHEN c.NoMail='0' THEN 'Yes' ELSE 'No' END as PostOptIn,
		CASE WHEN c.NoEmail='0' THEN 'Active' ELSE 'Unsubscribed' END as EmailOptIn,
		CASE WHEN l.WebShop IS NULL THEN 'fr_fr' ELSE l.WebShop END as WebShop,'B2C' as B2BB2C,
		c.LTY_OPT_IN,c.LTY_BALANCE,REPLACE(c.LastPurchase,'/','.') as LastPurchase,c.Credit_Note,c.Type_Customer,
		CONVERT(varchar,CONVERT(date,c.CreationDate,104),104) as CreationDate,CONVERT(varchar,GetDate(),104)  as LastModification
FROM	SOURCE_RETAILPRO_Customers c	LEFT OUTER JOIN LOOKUP_Country_Language_WebShop l ON (c.Country=l.ISO_3)
										LEFT OUTER JOIN LOOKUP_Shop s ON ('00'+c.CodeShop=s.GLN)




--- SET EMAIL to NULL WHERE EMAIL-PATTERN INCORRECT
UPDATE [STAGING_RETAILPRO_Customers] SET Email=NULL WHERE Customer_ID IN (
SELECT	DISTINCT CustNr
FROM	(

SELECT	CustNr,Email,
		CASE	WHEN	Email LIKE '%_@_%_.__%' 
						AND Email NOT LIKE '%[/$\<>,+=äöü]%' 
				THEN 'Could be' 
				ELSE 'Nope' 
				END Validates
FROM	[SOURCE_RETAILPRO_Customers]) as temptable
WHERE	Validates='Nope'
AND		Email IS NOT NULL);




--- CONTROL CHECKs
SET @ofr=(SELECT CAST((SELECT count(*) FROM STAGING_RETAILPRO_Customers) as varchar));


PRINT 'OFR Import Count - '+@ofr
PRINT 'SOURCE RETAILPRO Customers successful'


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
								FROM	STAGING_RETAILPRO_Customers
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
	@subject='POS_NL Interface - Customer Load Results RetailPro OFR',
	@reply_to='markus.pfyl@odlo.com',
	---@importance='High',
	@body=@mbody,
	@body_format='HTML';


----------------------------------------
--- END Send Customer Import Results ---
----------------------------------------







-------------------------------------------------------------------------
--- ONLY TEMPORARY DELETE AS THERE ARE DUPLICATEES IN IMPORT FILE!!!! ---
-------------------------------------------------------------------------
DELETE FROM STAGING_RETAILPRO_Customers
WHERE	Customer_ID IN (
						SELECT	DISTINCT Customer_ID
						FROM	(
						SELECT	Customer_ID,sum(checkcount) as checkcount
						FROM	(
									SELECT	Customer_ID,1 as checkcount
									FROM	STAGING_RETAILPRO_Customers
								) as temp
						GROUP BY Customer_ID
						) as temp1
WHERE checkcount > 1
)













END











GO
