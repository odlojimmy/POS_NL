/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_CORE_RETAILPRO_Customers]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE PROCEDURE [dbo].[sp_CORE_RETAILPRO_Customers]

AS
BEGIN
	SET NOCOUNT ON;

DECLARE @load_result varchar(25);

TRUNCATE TABLE CORE_RETAILPRO_Customers;

INSERT INTO [dbo].[CORE_RETAILPRO_Customers]
           ([Source_System]
           ,[Customer_ID]
           ,[Email]
           ,[Salutation]
           ,[Firstname]
           ,[Lastname]
           ,[Street]
           ,[HouseNo]
           ,[ZipCode]
           ,[City]
           ,[State]
           ,[Country]
           ,[Telephone]
           ,[Mobile]
           ,[Birthday]
           ,[Language]
           ,[OdloShop]
           ,[PostOptIn]
           ,[EmailOptIn]
           ,[WebShop]
           ,[B2BB2C]
		   ,[LTY_OPT_IN]
		   ,[LTY_BALANCE]
		   ,[LastPurchase]
		   ,[CreditNote]
		   ,[CustomerType]
           ,[CreationDate]
           ,[LastModification])
SELECT c.[Source_System]
		,c.[Customer_ID]
      ,IsNull(c.[Email],'') as Email
	  ,c.[Salutation]
	  ,c.[FirstName]
      ,c.[LastName]
      ,c.[Street]
      ,c.[HouseNo]
      ,c.[ZipCode]
      ,c.[City]
	  ,c.[State]
      ,c.[Country]
	  ,c.[Telephone]
      ,c.[Mobile]
      ,c.[Birthday]
      ,c.[Language]
	  ,c.[OdloShop]
	  ,c.[PostOptIn]
      ,c.[EmailOptIn]
      ,c.[WebShop]
	  ,c.[B2BB2C]
	  ,c.[LTY_OPT_IN]
	  ,c.[LTY_BALANCE]
	  ,c.[LastPurchase]
	  ,c.[CreditNote]
	  ,c.[CustomerType]
      ,c.[Creationdate]
      ,c.[LastModification]
FROM  [dbo].[STAGING_RETAILPRO_Customers] c



UPDATE [CORE_RETAILPRO_Customers] SET Email=NULL WHERE Email='';



--- UPDATE CORE_Customers
MERGE CORE_Customers_RetailPro AS Target
USING (	SELECT	Source_System,Customer_ID,Email,Salutation,Firstname,Lastname,Street,HouseNo,ZipCode,City,State,Country,Telephone,Mobile,Birthday,Language,OdloShop,PostOptIn,
				EmailOptIn,WebShop,B2BB2C,LTY_OPT_IN,LTY_BALANCE,LastPurchase,CreditNote,CustomerType,CreationDate,LastModification
		FROM	CORE_RETAILPRO_Customers) AS Source
ON (Target.Customer_ID=Source.Customer_ID)
WHEN MATCHED THEN
	UPDATE SET	Source_System=Source.Source_System,Email=Source.Email,Salutation=Source.Salutation,Firstname=Source.Firstname,Lastname=Source.Lastname,Street=Source.Street,
				HouseNo=Source.HouseNo,ZipCode=Source.ZipCode,City=Source.City,State=Source.State,Country=Source.Country,Telephone=Source.Telephone,Mobile=Source.Mobile,
				Birthday=Source.Birthday,Language=Source.Language,OdloShop=Source.OdloShop,PostOptIn=Source.PostOptIn,EmailOptIn=Source.EmailOptIn,WebShop=Source.WebShop,
				B2BB2C=Source.B2BB2C,
				LTY_OPT_IN=Source.LTY_OPT_IN,LTY_BALANCE=Source.LTY_BALANCE,LastPurchase=Source.LastPurchase,CreditNote=Source.CreditNote,CustomerType=Source.CustomerType,
				CreationDate=Source.CreationDate,LastModification=Source.LastModification
WHEN NOT MATCHED BY TARGET THEN
	INSERT (Source_System,Customer_ID,Email,Salutation,Firstname,Lastname,Street,HouseNo,ZipCode,City,State,Country,Telephone,Mobile,Birthday,Language,OdloShop,PostOptIn,
			EmailOptIn,WebShop,B2BB2C,LTY_OPT_IN,LTY_BALANCE,LastPurchase,CreditNote,CustomerType,CreationDate,LastModification)
	VALUES (Source.Source_System,Source.Customer_ID,Source.Email,Source.Salutation,Source.Firstname,Source.LastName,Source.Street,Source.HouseNo,Source.ZipCode,Source.City,
			Source.State,Source.Country,Source.Telephone,Source.Mobile,Source.Birthday,Source.Language,Source.OdloShop,Source.PostOptIn,Source.EmailOptIn,Source.WebShop,
			Source.B2BB2C,
			Source.LTY_OPT_IN,Source.LTY_BALANCE,Source.LastPurchase,Source.CreditNote,Source.CustomerType,
			Source.CreationDate,Source.LastModification);



INSERT INTO [dbo].[INTERFACE_HISTORY_RETAILPRO_Customers]
           ([Source_System]
           ,[Customer_ID]
           ,[Email]
           ,[Salutation]
           ,[Firstname]
           ,[Lastname]
           ,[Street]
           ,[HouseNo]
           ,[ZipCode]
           ,[City]
           ,[State]
           ,[Country]
           ,[Telephone]
           ,[Mobile]
           ,[Birthday]
           ,[Language]
           ,[OdloShop]
           ,[PostOptIn]
           ,[EmailOptIn]
           ,[WebShop]
           ,[B2BB2C]
		   ,[LTY_OPT_IN]
		   ,[LTY_BALANCE]
		   ,[LastPurchase]
		   ,[CreditNote]
		   ,[CustomerType]
           ,[CreationDate]
           ,[LastModification])
SELECT [Source_System]
      ,[Customer_ID]
      ,[Email]
      ,[Salutation]
      ,[Firstname]
      ,[Lastname]
      ,[Street]
      ,[HouseNo]
      ,[ZipCode]
      ,[City]
      ,[State]
      ,[Country]
      ,[Telephone]
      ,[Mobile]
      ,[Birthday]
      ,[Language]
      ,[OdloShop]
      ,[PostOptIn]
      ,[EmailOptIn]
      ,[WebShop]
      ,[B2BB2C]
	  ,[LTY_OPT_IN]
	  ,[LTY_BALANCE]
	  ,[LastPurchase]
	  ,[CreditNote]
	  ,[CustomerType]
      ,[CreationDate]
      ,[LastModification]
  FROM [dbo].[CORE_RETAILPRO_Customers];







--- CONTROL CHECKs
SET @load_result=(SELECT count(*) FROM [CORE_RETAILPRO_Customers])
PRINT 'Load Result [CORE_RETAILPRO_Customers] - '+@load_result;
PRINT 'CORE RETAILPRO Customers successful'


END 








GO
