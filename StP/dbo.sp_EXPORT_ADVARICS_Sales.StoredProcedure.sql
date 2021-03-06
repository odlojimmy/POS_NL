/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_EXPORT_ADVARICS_Sales]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
















CREATE PROCEDURE [dbo].[sp_EXPORT_ADVARICS_Sales]

AS
BEGIN
	SET NOCOUNT ON;

--- DECLARE EMAIL NOTIFICATION VARIABLES
DECLARE @header_filename varchar(50);
DECLARE @file varchar(50);
DECLARE @detail_filename varchar(50);
DECLARE @filedate varchar(8);
DECLARE @fileext varchar(5);
DECLARE @filepath varchar(200);
DECLARE @path varchar(200);
DECLARE @fullpath varchar(400);
DECLARE @header_fullpath varchar(400);
DECLARE @detail_fullpath varchar(400);
DECLARE @string varchar(8000);
DECLARE @header_string varchar(8000);
DECLARE @detail_string varchar(8000);

DECLARE @load_result_final varchar(20);



--- Reset all emails to ''
UPDATE CORE_ADVARICS_Sales SET Email='' WHERE Email IS NULL;

-------------------------------------------
---- BEGIN UPDATE ONLY ONE SALES EXPORT ---
-------------------------------------------
TRUNCATE TABLE EXPORT_ADVARICS_Sales;

INSERT INTO [dbo].[EXPORT_ADVARICS_Sales] ([Order_ID],[BookDate],[Source_System],[OdloShopNo],[OdloShop],[Customer_ID],[Email],[SalesTime],[Currency]
,[ReceiptNo],[ReceiptPositionNo],[Category],[ArticleNo],[ArticleDescription],[Colour],[Size],[Gtin],[Quantity],[SalesPrice],[SKU],[Description],[Name])
VALUES ('OrderID','BookDate','SourceSystem','OdloShopNo','OdloShop','CustomerID','Email','SalesTime','Currency','ReceiptNo',
'ReceiptPosNo','Category','ArticleNo','ArticleDesc','Colour','Size','GTIN','Quantity','SalesPrice','SKU','Description','Name')

INSERT INTO [dbo].[EXPORT_ADVARICS_Sales] ([Order_ID],[BookDate],[Source_System],[OdloShopNo],[OdloShop],[Customer_ID],[Email],[SalesTime],[Currency]
,[ReceiptNo],[ReceiptPositionNo],[Category],[ArticleNo],[ArticleDescription],[Colour],[Size],[Gtin],[Quantity],[SalesPrice],[SKU],[Description],[Name])
SELECT	*
FROM	(
SELECT	CONCAT(CONCAT(CONCAT(s.OdloShopNo,s.BookDate),s.SalesTime),s.ReceiptNo) as ORDER_ID,
		s.[BookDate],
		s.[Source_System],
		s.[OdloShopNo],
		s.[OdloShop],
		s.[Customer_ID],
		s.[Email],
		s.[SalesTime],
		s.[Currency],
		s.[ReceiptNo],
		s.[ReceiptPositionNo],
		CASE WHEN l.Category IS NULL THEN 'unknown category' ELSE l.Category END as Category,
		s.[Article],
		CASE WHEN l.ArticleDescription IS NULL THEN 'unkown article' ELSE l.ArticleDescription END as ArticleDescription
		,s.[Colour]
		,s.[Size]
		,s.[Gtin]
		,s.[Quantity]
		,s.[SalesPrice]
		,s.[Article]+'-'+s.[Colour]+'-'+s.[Size] as SKU
		,s.[Source_System]+' '+s.[OdloShop] as SourceSystem
		,CASE WHEN l.ArticleDescription IS NULL THEN 'unkown article' ELSE l.ArticleDescription END +' [Odlo Color: '+s.[Colour]+', Size: '+s.[Size]+']' as ADescription
FROM	[CORE_ADVARICS_Sales] s LEFT OUTER JOIN [LOOKUP_Article] l ON (s.Article=l.ArticleNo)
) as temptable
WHERE	CAST(Quantity as int)>0
AND		(Category<>'unknown category' OR ArticleDescription<>'unkown article')
AND		Email<>''




--- FX CONVERSION FOR 'CHF' Positions into 'EUR' --- ONLY FOR EXPORT FILE INTO BRONTO
UPDATE EXPORT_ADVARICS_Sales SET SalesPrice=CASE WHEN s.Currency='CHF' THEN CAST(ROUND(s.SalesPrice*c.ConversionRatio,2) as money) ELSE s.SalesPrice END
FROM EXPORT_ADVARICS_Sales s LEFT OUTER JOIN CORE_ConversionRatio c ON (s.Currency=c.CurrencyCode_ISO AND CAST(Substring(s.BookDate,7,4) as int)=c.Year AND CAST(Substring(BookDate,4,2) as int)=c.Month)
WHERE Order_ID<>'OrderID'




--- SET EMAIL NOTIFICATION VARIABLES
SET @path='D:\POS_NL\Advarics_Out\Sales\'
SET @file='Advarics_Sales_';
SET @filedate=(SELECT CONVERT(VARCHAR(8),GetDate()-1,112))
SET @fileext='.txt'

SET @fullpath=@path+@file+@filedate+@fileext;

--- CREATE EXPORT FILE
---SET @string='bcp "SELECT * FROM POS_NL..EXPORT_ADVARICS_Sales" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S' --- Old Export
--SET @string='bcp "SELECT Order_ID,BookDate,Email,SKU,ArticleDescription+'' [Odlo Color: ''+Colour+'', Size: ''+Size+'']'',Category,Source_System+'' ''+OdloShop,Quantity,SalesPrice FROM POS_NL..EXPORT_ADVARICS_Sales" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S' --- Old Test Export

SET @string='bcp "SELECT Order_ID,BookDate,Email,SKU,Description,Category,Name,Quantity,SalesPrice FROM POS_NL..EXPORT_ADVARICS_Sales" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S'


BEGIN TRY
EXEC xp_cmdshell @string
END TRY
BEGIN CATCH
 PRINT 'POS_NL - Sales Export - File Creation failed'
 EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Sales Export - File Creation failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Sales Export - File Creation failed',
	@body_format='HTML';
END CATCH
-----------------------------------------
---- END UPDATE ONLY ONE SALES EXPORT ---
-----------------------------------------



---------------------------------------
--- BEGIN Send Sales Export Results ---
---------------------------------------
DECLARE @mxml NVARCHAR(MAX)
DECLARE @mbody NVARCHAR(MAX)

SET @mxml = CAST((	
					
					SELECT	BookDate as 'td','',
							Source_System as 'td','',
							OdloShop as 'td','',
							TotalSales as 'td'
					FROM	(
								SELECT	BookDate,Source_System,OdloShop,CAST(sum(CAST(SalesPrice as money)) as varchar) as TotalSales
								FROM	EXPORT_ADVARICS_Sales
								WHERE	Order_ID<>'OrderID'
								GROUP BY BookDate,Source_System,OdloShop
					) as table1
					ORDER BY 1,3,5

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

SET @mbody =	'<html><body><H2>POS_NL Interface - Sales Export Results</H2>
				<table border = 1> 
				<tr>
				<th> BookDate </th> <th> SourceSystem </th> <th> OdloShop </th> <th> TotalSales </th></tr>'    
 
SET @mbody = @mbody + @mxml +'</table></body></html>'

EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL Interface - Sales Export Results',
	@reply_to='markus.pfyl@odlo.com',
	---@importance='High',
	@body=@mbody,
	@body_format='HTML';
----------------------------------------
--- END Send Customer Export Results ---
----------------------------------------


--- CONTROL CHECKs
SET @load_result_final=(SELECT count(*) FROM EXPORT_ADVARICS_Sales WHERE Order_ID<>'OrderID');

PRINT 'Load Result [EXPORT_ADVARICS_Sales] - '+@load_result_final;
PRINT 'EXPORT ADVARICS Sales successful'



END
























GO
