/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_EXPORT_RETAILPRO_Sales]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[sp_EXPORT_RETAILPRO_Sales]

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


-------------------------------------------
---- BEGIN UPDATE ONLY ONE SALES EXPORT ---
-------------------------------------------
TRUNCATE TABLE EXPORT_RETAILPRO_Sales;

INSERT INTO [dbo].[EXPORT_RETAILPRO_Sales] ([Order_ID],[BookDate],[Source_System],[OdloShopNo],[OdloShop],[Customer_ID],[Email],[SalesTime],[Currency]
,[ReceiptNo],[ReceiptPositionNo],[Category],[ArticleNo],[ArticleDescription],[Colour],[Size],[Gtin],[Quantity],[SalesPrice],[SKU],[Description],[Name])
VALUES ('OrderID','BookDate','SourceSystem','OdloShopNo','OdloShop','CustomerID','Email','SalesTime','Currency','ReceiptNo',
'ReceiptPosNo','Category','ArticleNo','ArticleDesc','Colour','Size','GTIN','Quantity','SalesPrice','SKU','Description','Name')

INSERT INTO [dbo].[EXPORT_RETAILPRO_Sales] ([Order_ID],[BookDate],[Source_System],[OdloShopNo],[OdloShop],[Customer_ID],[Email],[SalesTime],[Currency]
,[ReceiptNo],[ReceiptPositionNo],[Category],[ArticleNo],[ArticleDescription],[Colour],[Size],[Gtin],[Quantity],[SalesPrice],[SKU],[Description],[Name])
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
		,s.[Article]+'-'+s.[Colour]+'-'+s.[Size]
		,s.[Source_System]+' '+s.[OdloShop]
		,CASE WHEN l.ArticleDescription IS NULL THEN 'unkown article' ELSE l.ArticleDescription END +' [Odlo Color: '+s.[Colour]+', Size: '+s.[Size]+']'
FROM	[CORE_RETAILPRO_Sales] s LEFT OUTER JOIN [LOOKUP_Article] l ON (s.Article=l.ArticleNo)
WHERE	Email<>'' --- ONLY EXPORT CUSTOMERS WITH EMAIL (cannot be imported to Bronto without Email)
AND		Category<>'unknown category' --- ONLY EXPORT POSITIONS WITH KNOWN CATEGORY (Rest might be vouchers or other special articles)
AND		s.Quantity>0

--- SET EMAIL NOTIFICATION VARIABLES
SET @path='D:\POS_NL\RetailPro_Out\Sales\'
SET @file='RetailPro_Sales_';
SET @filedate=(SELECT CONVERT(VARCHAR(8),GetDate()-1,112))
SET @fileext='.txt'

SET @fullpath=@path+@file+@filedate+@fileext;

--- CREATE EXPORT FILE
---SET @string='bcp "SELECT * FROM POS_NL..EXPORT_ADVARICS_Sales" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S' --- Old Export
--SET @string='bcp "SELECT Order_ID,BookDate,Email,SKU,ArticleDescription+'' [Odlo Color: ''+Colour+'', Size: ''+Size+'']'',Category,Source_System+'' ''+OdloShop,Quantity,SalesPrice FROM POS_NL..EXPORT_ADVARICS_Sales" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S' --- Old Test Export

SET @string='bcp "SELECT Order_ID,BookDate,Email,SKU,Description,Category,Name,Quantity,SalesPrice FROM POS_NL..EXPORT_RETAILPRO_Sales" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S'


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
								FROM	EXPORT_RETAILPRO_Sales
								WHERE	Order_ID<>'OrderID'
								GROUP BY BookDate,Source_System,OdloShop
					) as table1
					ORDER BY convert(date,BookDate,104),3,5

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

SET @mbody =	'<html><body><H2>POS_NL Interface - OFR Sales Export Results</H2>
				<table border = 1> 
				<tr>
				<th> BookDate </th> <th> SourceSystem </th> <th> OdloShop </th> <th> TotalSales </th></tr>'    
 
SET @mbody = @mbody + @mxml +'</table></body></html>'

EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL Interface - OFR Sales Export Results',
	@reply_to='markus.pfyl@odlo.com',
	---@importance='High',
	@body=@mbody,
	@body_format='HTML';
----------------------------------------
--- END Send Customer Export Results ---
----------------------------------------



--- CONTROL CHECKs
SET @load_result_final=(SELECT count(*) FROM EXPORT_RETAILPRO_Sales WHERE Order_ID<>'OrderID');

PRINT 'Load Result [EXPORT_RETAILPRO_Sales] - '+@load_result_final;
PRINT 'EXPORT RETAILPRO Sales successful'



END








GO
