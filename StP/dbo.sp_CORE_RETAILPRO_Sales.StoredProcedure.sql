/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_CORE_RETAILPRO_Sales]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










CREATE PROCEDURE [dbo].[sp_CORE_RETAILPRO_Sales]


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


DECLARE @all varchar(20);
DECLARE @var varchar(1); --- Only used as placeholder in the MERGE-Statement

TRUNCATE TABLE [CORE_RETAILPRO_Sales];

INSERT INTO [dbo].[CORE_RETAILPRO_Sales] ([ImportDate],[BookDate],[Source_System],[OdloShopNo],[OdloShop],[Customer_ID],[Email],[ReceiptNo],[ReceiptPositionNo],[SalesTime],[Article],[Colour]
			,[Size],[Gtin],[Currency],[Quantity],[PurchasePrice],[SalesPrice],[Discount])

SELECT CONVERT(varchar,CONVERT(date,GetDate(),104),104) as ImportDate
	  ,CONVERT(varchar,CONVERT(date,s.BookDate,104),104) as BookDate
	  ,'POS '+Substring(s.CustomerNo,1,3) as Source_System
	  ,s.StoreNo as OdloShopNo
	  ,CASE WHEN st.[Odlo_Short_Name] IS NULL THEN 'unknown shop' ELSE st.[Odlo_Short_Name] END as OdloShop
      ,s.[CustomerNo]
	  ,CASE WHEN c.Email IS NULL THEN '' ELSE c.Email END as Email
	  ,s.[ReceiptNo]
      ,s.[ReceiptPositionNo]
	  ,s.[SalesTime]
	  ,s.[ArticleNo]
	  ,s.[ColourNo]
	  ,s.[Size]
      ,s.[Gtin]
	  ,CASE WHEN Substring(s.CustomerNo,1,3)='OCH' THEN 'CHF' ELSE 'EUR' END as Currency
	  ,CAST(CAST(s.[Quantity] as float) as int) as Quantity
      ,CASE WHEN CAST(CAST(s.[Quantity] as float) as int)<0 THEN CAST(s.[PP] as money)*-1 ELSE CAST(s.[PP] as money) END as PP
      ,CASE WHEN CAST(CAST(s.[Quantity] as float) as int)<0 THEN CAST(s.[SP] as money)*-1 ELSE CAST(s.[SP] as money) END as PP
      ,CASE WHEN CAST(CAST(s.[Quantity] as float) as int)<0 THEN CAST(s.[Discount] as money)*-1 ELSE CAST(s.[Discount] as money) END as Discount      
FROM [dbo].[SOURCE_RETAILPRO_Sales] s	LEFT OUTER JOIN (SELECT SUBSTRING(GLN,PATINDEX('%[^0]%',GLN),LEN(GLN)) as GLN,Odlo_Short_Name FROM LOOKUP_Shop) st ON (s.StoreNo=st.GLN)
										LEFT OUTER JOIN CORE_Customers_RetailPro c ON (s.CustomerNo=c.Customer_ID)




--- CLEAR UNUSED TABLES
---TRUNCATE TABLE [SOURCE_RETAILPRO_Sales];


MERGE CORE_Sales_RetailPro AS Target
USING (	SELECT [ImportDate],[BookDate],[Source_System],[OdloShopNo],[OdloShop],[Customer_ID],[Email],[ReceiptNo],[ReceiptPositionNo],[SalesTime]
				,[Article],[Colour],[Size],[Gtin],[Currency],[Quantity],[PurchasePrice],[SalesPrice],[Discount]
		FROM [dbo].[CORE_RETAILPRO_Sales]) AS Source
ON (Target.BookDate=Source.BookDate AND Target.Customer_ID=Source.Customer_ID AND Target.ReceiptNo=Source.ReceiptNo AND Target.ReceiptPositionNo=Source.ReceiptPositionNo AND Target.SalesTime=Source.SalesTime)
WHEN MATCHED THEN
	UPDATE SET @var='1'
WHEN NOT MATCHED BY TARGET THEN
	INSERT ([ImportDate],[BookDate],[Source_System],[OdloShopNo],[OdloShop],[Customer_ID],[Email],[ReceiptNo],[ReceiptPositionNo],[SalesTime],[Article],[Colour],[Size],[Gtin],[Currency],[Quantity],
			[PurchasePrice],[SalesPrice],[Discount])
	VALUES (Source.ImportDate,Source.BookDate,Source.Source_System,Source.OdloShopNo,Source.OdloShop,Source.Customer_ID,Source.Email,Source.ReceiptNo,Source.ReceiptPositionNo,Source.SalesTime,
			Source.Article,Source.Colour,Source.Size,Source.Gtin,Source.Currency,Source.Quantity,Source.PurchasePrice,Source.SalesPrice,Source.Discount);


--- CONTROL CHECKs
SET @all=(SELECT count(*) FROM [CORE_RETAILPRO_Sales]);


TRUNCATE TABLE [SOURCE_RETAILPRO_Sales];


PRINT 'All Sales Import Count - '+@all


PRINT 'CORE RETAILPRO Sales successful'




END









GO
