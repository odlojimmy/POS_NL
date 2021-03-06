/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_STAGING_BRONTO_Customers]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE PROCEDURE [dbo].[sp_STAGING_BRONTO_Customers]

AS
BEGIN
	SET NOCOUNT ON;

DECLARE @load_result varchar(20);

TRUNCATE TABLE STAGING_BRONTO_Customers;


INSERT INTO [dbo].[STAGING_BRONTO_Customers]
           ([EmailAddress]
           ,[EmailSubscriptionStatus]
           ,[FirstName]
           ,[LastName]
           ,[Gender]
           ,[Street]
           ,[HouseNumber]
           ,[PostalCode]
           ,[City]
		   ,[County]
           ,[Country]
           ,[Birthday]
           ,[Telephone]
           ,[Mobile]
           ,[PostSubscriptionStatus]
           ,[POSShopName]
           ,[Language]
           ,[POSCustomerNumber])


--- commented 16.08.2016/cls replaced with below to exclude contacts that were synced from Advarics to Bronto the last two days...
--SELECT	EmailAddress,EmailSubscriptionStatus,FirstName,LastName,Gender,Street,HouseNumber,PostalCode,City,'' as County,Country,Birthday,Telephone,Mobile,PostSubscriptionStatus,POSShopName,Language,POSCustomerNumber
--FROM	SOURCE_BRONTO_Customers c LEFT OUTER JOIN (SELECT DISTINCT Customer_ID FROM INTERFACE_HISTORY_ADVARICS_Customers WHERE LastModification=(SELECT	CAST(FORMAT(GetDate()-1,'dd.MM.yyyy') as varchar)))  as pos ON (c.POSCustomerNumber=pos.Customer_ID)
--WHERE	(POSCustomerNumber LIKE 'OAT%' OR POSCustomerNumber LIKE 'ODE%' OR POSCustomerNumber LIKE 'OCH%')
--AND		pos.Customer_ID IS NULL;


--- SELECT Bronto Contacts that have not been synced from POS yesterday and today morning (no match from customer comparison yesterday)
SELECT	EmailAddress,EmailSubscriptionStatus,FirstName,LastName,Gender,Street,HouseNumber,PostalCode,City,'' as County,Country,Birthday,Telephone,Mobile,PostSubscriptionStatus,POSShopName,Language,POSCustomerNumber
FROM	SOURCE_BRONTO_Customers c
WHERE	(	POSCustomerNumber LIKE 'OAT%'
			OR POSCustomerNumber LIKE 'ODE%'
			OR POSCustomerNumber LIKE 'OCH%')
AND		POSCustomerNumber NOT IN (
						SELECT	DISTINCT Customer_ID
						FROM	INTERFACE_HISTORY_ADVARICS_Customers
						WHERE	(	LastModification=FORMAT(DATEADD(day,0,GetDate()),'dd.MM.yyyy')
									OR
									LastModification=FORMAT(DATEADD(day,-1,GetDate()),'dd.MM.yyyy')
								)
					)

UNION ALL

SELECT	EmailAddress,EmailSubscriptionStatus,FirstName,LastName,Gender,Street,HouseNumber,PostalCode,City,'' as County,Country,Birthday,Telephone,Mobile,PostSubscriptionStatus,POSShopName,Language,POSCustomerNumber
FROM	SOURCE_BRONTO_Customers c
WHERE	POSCustomerNumber LIKE 'OFR%'
AND		POSCustomerNumber NOT IN (
						SELECT	DISTINCT Customer_ID
						FROM	INTERFACE_HISTORY_RETAILPRO_Customers
						WHERE	(	LastModification=FORMAT(DATEADD(day,0,GetDate()),'dd.MM.yyyy')
									OR
									LastModification=FORMAT(DATEADD(day,-1,GetDate()),'dd.MM.yyyy')
								)
					)







END 







GO
