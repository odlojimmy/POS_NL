/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_CORE_BRONTO_Customers]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE PROCEDURE [dbo].[sp_CORE_BRONTO_Customers]

AS
BEGIN
	SET NOCOUNT ON;


TRUNCATE TABLE CORE_BRONTO_Customers;

INSERT INTO [dbo].[CORE_BRONTO_Customers]
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

SELECT c.[EmailAddress]
      ---,CASE WHEN UPPER(c.[EmailSubscriptionStatus])='UNSUB' THEN 'No' ELSE 'Yes'END as EmailOptIn,
	  ,c.[EmailSubscriptionStatus] as EmailOptIn
      ,c.[FirstName]
      ,c.[LastName]
      ,CASE WHEN UPPER(c.[Gender])='MALE' THEN 'Herr' WHEN  UPPER(c.[Gender])='FEMALE' THEN 'Frau' ELSE '' END as Gender
      ,c.[Street]
      ,c.[HouseNumber]
      ,c.[PostalCode]
      ,c.[City]
      ,c.[County]
      ,UPPER(c.[Country]) as Country
      ,c.[Birthday]
      ,c.[Telephone]
      ,c.[Mobile]
      ,c.[PostSubscriptionStatus]
	  ,SUBSTRING(s.GLN, PATINDEX('%[^0 ]%', s.GLN + ' '), LEN(s.GLN)) as ShopID
      ,c.[Language]
      ,c.[POSCustomerNumber]
  FROM [dbo].[STAGING_BRONTO_Customers] c LEFT OUTER JOIN LOOKUP_Shop s ON (c.POSShopName=s.Odlo_Short_Name)


--TRUNCATE TABLE STAGING_BRONTO_Customers;


END 






GO
