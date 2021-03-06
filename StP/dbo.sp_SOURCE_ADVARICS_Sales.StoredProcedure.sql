/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_SOURCE_ADVARICS_Sales]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












CREATE PROCEDURE [dbo].[sp_SOURCE_ADVARICS_Sales]


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--- CLEAR UPDATE TABLES
TRUNCATE TABLE SOURCE_ADVARICS_Sales;

--- CREATE MESSAGE VARIABLES
DECLARE @och varchar(20);
DECLARE @oat varchar(20);
DECLARE @ode varchar(20);
DECLARE @all varchar(20);
DECLARE @var varchar(1); --- only used as virtual variable in merge statement

--- CREATE PROCESSING VARIABLES
DECLARE @path as varchar(200);
DECLARE @filename as varchar(200);
DECLARE @filedate as varchar(8);
DECLARE @fileextension as varchar(4);
DECLARE @full_path as varchar(400);
DECLARE @sql1 as varchar(1000);
DECLARE @XML AS XML, @hDoc AS INT, @SQL NVARCHAR (MAX);

--- SET PROCESSING VARIABLES
SET @filedate=(SELECT CONVERT(VARCHAR(8),GetDate()-1,112))
SET @path='D:\POS_NL\Advarics_In\Sales\'
SET @fileextension='.xml'


----------------------------------------
--- BEGIN UPDATE DWH Conversion Ratios CHF>EUR for order conversion
----------------------------------------

--TRUNCATE TABLE CORE_ConversionRatio;

--INSERT INTO [dbo].[CORE_ConversionRatio]
--           ([CurrencyCode_ISO]
--           ,[Year_Month]
--           ,[Year]
--           ,[Month]
--           ,[Target_CurrencyCode_ISO]
--           ,[ConversionRatio])
--SELECT	HCCR_ISO_CURRENCY_CODE,HCCR_YEAR_MONTH,HCCR_YEAR,HCCR_MONTH,'EUR',HCCR_CONVERSION_RATIO
--FROM	SPOT_APL.dbo.HVIW_CURRENCY_CONVERSION_RATIO
--WHERE	HCCR_DIRECTION='CHF>EUR';


MERGE CORE_ConversionRatio AS Target
USING (	SELECT	HCCR_ISO_CURRENCY_CODE,HCCR_YEAR_MONTH,HCCR_YEAR,HCCR_MONTH,'EUR' as TargetCurrency,HCCR_CONVERSION_RATIO
		FROM	SPOT_APL.dbo.HVIW_CURRENCY_CONVERSION_RATIO
		WHERE	HCCR_DIRECTION='CHF>EUR') AS Source
ON	  (	Target.CurrencyCode_ISO=Source.HCCR_ISO_CURRENCY_CODE
		AND Target.Year_Month=Source.HCCR_YEAR_MONTH
		AND Target.Year=Source.HCCR_YEAR
		AND Target.Month=Source.HCCR_MONTH
		AND Target.Target_CurrencyCode_ISO=Source.TargetCurrency)
WHEN MATCHED THEN
		UPDATE SET @var='1'
WHEN NOT MATCHED BY TARGET THEN
		INSERT (CurrencyCode_ISO,Year_Month,Year,Month,Target_CurrencyCode_ISO,ConversionRatio)
		VALUES (Source.HCCR_ISO_CURRENCY_CODE,Source.HCCR_YEAR_MONTH,Source.HCCR_YEAR,Source.HCCR_MONTH,Source.TargetCurrency,Source.HCCR_CONVERSION_RATIO);





----------------------------------------
--- END UPDATE DWH Conversion Ratios CHF>EUR for order conversion
----------------------------------------



----------------------------------------
--- BEGIN Import OAT XML Sales into XML table
----------------------------------------
TRUNCATE TABLE SOURCE_ADVARICS_IMPORT_XML;
SET @filename='SalesData_OAT_'
SET @full_path=@path+@filename+@filedate+@fileextension;


SET @sql1=N'INSERT INTO [SOURCE_ADVARICS_IMPORT_XML](XMLData, LoadedDateTime)
				SELECT CONVERT(XML, BulkColumn) AS BulkColumn, GETDATE()
				FROM OPENROWSET(BULK '''+@full_path+''', SINGLE_BLOB) AS x'

BEGIN TRY
EXEC(@sql1)

SELECT @XML = XMLData FROM [SOURCE_ADVARICS_IMPORT_XML]

EXEC sp_xml_preparedocument @hDoc OUTPUT, @XML	

INSERT INTO SOURCE_ADVARICS_Sales(ImportDate,BookDate,StoreNo,CustomerNo,ReceiptNo,ReceiptPositionNo,SalesTime,ArticleNo,ColourNo,Size,Gtin,Quantity,PP,SP,Discount) 

SELECT GetDate(),(SELECT BookDate FROM OPENXML(@hDoc, 'SalesDataReport/Items') WITH ([BookDate] [nvarchar](30) '../BookDate')),StoreNo,CustomerNo,ReceiptNo,ReceiptPositionNo,SalesTime,ArticleNo,ColorNo,Size,Gtin,Quantity,PP,SP,Discount
FROM OPENXML(@hDoc, 'SalesDataReport/Items/SalesDataItem')
WITH 
([BookDate] [varchar](100) 'BookDate',[StoreNo] [varchar](100) 'StoreNo',[CustomerNo] [varchar](100) 'CustomerNo',[ReceiptNo] [varchar](100) 'ReceiptNo',[ReceiptPositionNo] [varchar](100) 'ReceiptPositionNo',[SalesTime] [varchar](100) 'SalesTime',
[ArticleNo] [varchar](100) 'ArticleNo',[ColorNo] [varchar](100) 'ColorNo',[Size] [varchar](100) 'Size',[Gtin] [varchar](100) 'Gtin',[Quantity] [varchar](100) 'Quantity',[PP] [varchar](100) 'PP',[SP] [varchar](100) 'SP',[Discount] [varchar](100) 'Discount')

EXEC sp_xml_removedocument @hDoc	

END TRY

BEGIN CATCH
	PRINT 'OAT Sales import failed'

	EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Sales Data - Advarics OAT - DB Import failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Sales Data - Advarics OAT - DB Import failed (loading yesterdays file - perhaps all shops in country were closed and hence no file.)',
	@body_format='HTML';
END CATCH
----------------------------------------
--- END Import OAT XML Sales into XML table
----------------------------------------



----------------------------------------
--- BEGIN Import OCH XML Sales into XML table
----------------------------------------
TRUNCATE TABLE SOURCE_ADVARICS_IMPORT_XML;
SET @filename='SalesData_OCH_'
SET @full_path=@path+@filename+@filedate+@fileextension;

SET @sql1=N'INSERT INTO [SOURCE_ADVARICS_IMPORT_XML](XMLData, LoadedDateTime)
				SELECT CONVERT(XML, BulkColumn) AS BulkColumn, GETDATE()
				FROM OPENROWSET(BULK '''+@full_path+''', SINGLE_BLOB) AS x'

BEGIN TRY

EXEC(@sql1)

SELECT @XML = XMLData FROM [SOURCE_ADVARICS_IMPORT_XML]

EXEC sp_xml_preparedocument @hDoc OUTPUT, @XML	

INSERT INTO SOURCE_ADVARICS_Sales(ImportDate,BookDate,StoreNo,CustomerNo,ReceiptNo,ReceiptPositionNo,SalesTime,ArticleNo,ColourNo,Size,Gtin,Quantity,PP,SP,Discount) 

SELECT GetDate(),(SELECT BookDate FROM OPENXML(@hDoc, 'SalesDataReport/Items') WITH ([BookDate] [nvarchar](30) '../BookDate')),StoreNo,CustomerNo,ReceiptNo,ReceiptPositionNo,SalesTime,ArticleNo,ColorNo,Size,Gtin,Quantity,PP,SP,Discount
FROM OPENXML(@hDoc, 'SalesDataReport/Items/SalesDataItem')
WITH 
([BookDate] [varchar](100) 'BookDate',[StoreNo] [varchar](100) 'StoreNo',[CustomerNo] [varchar](100) 'CustomerNo',[ReceiptNo] [varchar](100) 'ReceiptNo',[ReceiptPositionNo] [varchar](100) 'ReceiptPositionNo',[SalesTime] [varchar](100) 'SalesTime',
[ArticleNo] [varchar](100) 'ArticleNo',[ColorNo] [varchar](100) 'ColorNo',[Size] [varchar](100) 'Size',[Gtin] [varchar](100) 'Gtin',[Quantity] [varchar](100) 'Quantity',[PP] [varchar](100) 'PP',[SP] [varchar](100) 'SP',[Discount] [varchar](100) 'Discount')

EXEC sp_xml_removedocument @hDoc	

END TRY

BEGIN CATCH
	PRINT 'OCH Sales File import failed'

	EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Sales Data - Advarics OCH - DB Import failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Sales Data - Advarics OCH - DB Import failed (loading yesterdays file - perhaps all shops in country were closed and hence no file.)',
	@body_format='HTML';
END CATCH
----------------------------------------
--- END Import OCH XML Sales into XML table
----------------------------------------


----------------------------------------
--- BEGIN Import ODE XML Sales into XML table
----------------------------------------
TRUNCATE TABLE SOURCE_ADVARICS_IMPORT_XML;
SET @filename='SalesData_ODE_'
SET @full_path=@path+@filename+@filedate+@fileextension;

SET @sql1=N'INSERT INTO [SOURCE_ADVARICS_IMPORT_XML](XMLData, LoadedDateTime)
				SELECT CONVERT(XML, BulkColumn) AS BulkColumn, GETDATE()
				FROM OPENROWSET(BULK '''+@full_path+''', SINGLE_BLOB) AS x'

BEGIN TRY
EXEC(@sql1)	

SELECT @XML = XMLData FROM [SOURCE_ADVARICS_IMPORT_XML]

EXEC sp_xml_preparedocument @hDoc OUTPUT, @XML	

INSERT INTO SOURCE_ADVARICS_Sales(ImportDate,BookDate,StoreNo,CustomerNo,ReceiptNo,ReceiptPositionNo,SalesTime,ArticleNo,ColourNo,Size,Gtin,Quantity,PP,SP,Discount) 

SELECT GetDate(),(SELECT BookDate FROM OPENXML(@hDoc, 'SalesDataReport/Items') WITH ([BookDate] [nvarchar](30) '../BookDate')),StoreNo,CustomerNo,ReceiptNo,ReceiptPositionNo,SalesTime,ArticleNo,ColorNo,Size,Gtin,Quantity,PP,SP,Discount
FROM OPENXML(@hDoc, 'SalesDataReport/Items/SalesDataItem')
WITH 
([BookDate] [varchar](100) 'BookDate',[StoreNo] [varchar](100) 'StoreNo',[CustomerNo] [varchar](100) 'CustomerNo',[ReceiptNo] [varchar](100) 'ReceiptNo',[ReceiptPositionNo] [varchar](100) 'ReceiptPositionNo',[SalesTime] [varchar](100) 'SalesTime',
[ArticleNo] [varchar](100) 'ArticleNo',[ColorNo] [varchar](100) 'ColorNo',[Size] [varchar](100) 'Size',[Gtin] [varchar](100) 'Gtin',[Quantity] [varchar](100) 'Quantity',[PP] [varchar](100) 'PP',[SP] [varchar](100) 'SP',[Discount] [varchar](100) 'Discount')

EXEC sp_xml_removedocument @hDoc	

END TRY

BEGIN CATCH
	PRINT 'ODE Sales File import failed'

	EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Sales Data - Advarics ODE - DB Import failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Sales Data - Advarics ODE - DB Import failed (loading yesterdays file - perhaps all shops in country were closed and hence no file.)',
	@body_format='HTML';
END CATCH
----------------------------------------
--- END Import ODE XML Sales into XML table
----------------------------------------

TRUNCATE TABLE [SOURCE_ADVARICS_IMPORT_XML];


--- CONTROL CHECKs
SET @oat=(SELECT count(*) FROM SOURCE_ADVARICS_Sales WHERE Substring(CustomerNo,1,3)='OAT');
SET @och=(SELECT count(*) FROM SOURCE_ADVARICS_Sales WHERE Substring(CustomerNo,1,3)='OCH');
SET @ode=(SELECT count(*) FROM SOURCE_ADVARICS_Sales WHERE Substring(CustomerNo,1,3)='ODE');
SET @all=(SELECT count(*) FROM SOURCE_ADVARICS_Sales);

PRINT 'OAT Sales Import Count - '+@oat
PRINT 'OCH Sales Import Count - '+@och
PRINT 'ODE Sales Import Count - '+@ode
PRINT 'All Sales Import Count - '+@all


PRINT 'SOURCE ADVARICS Sales successful'


------------------------------------------
--- BEGIN Send Customer Import Results ---
------------------------------------------
DECLARE @mxml NVARCHAR(MAX)
DECLARE @mbody NVARCHAR(MAX)

SET @mxml = CAST((	
					
					SELECT	ImportDate as 'td','',
							BookDate as 'td','',
							Shop as 'td','',
							TotalSales as 'td'
					FROM	(
								SELECT CONVERT(varchar,CONVERT(date,s.ImportDate,104),104) as ImportDate,  CONVERT(varchar,CONVERT(date,s.BookDate,104),104) as BookDate,
								CASE WHEN st.Odlo_Short_Name IS NULL THEN 'unknown shop' ELSE st.Odlo_Short_Name END as Shop,CAST(sum(CAST(s.SP as money)) as varchar) TotalSales
								FROM SOURCE_ADVARICS_Sales s LEFT OUTER JOIN (SELECT SUBSTRING(GLN,PATINDEX('%[^0]%',GLN),LEN(GLN)) as GLN,Odlo_Short_Name FROM LOOKUP_Shop) st ON (s.StoreNo=st.GLN)
								GROUP BY s.ImportDate,s.BookDate,st.Odlo_Short_Name
					) as table1
					ORDER BY 1,3,5

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

SET @mbody =	'<html><body><H2>POS_NL Interface - Sales Load Results</H2>
				<table border = 1> 
				<tr>
				<th> ImportDate </th> <th> BookDate </th> <th> Shop </th> <th> TotalSales </th></tr>'    
 
SET @mbody = @mbody + @mxml +'</table></body></html>'

EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL Interface - Sales Load Results',
	@reply_to='markus.pfyl@odlo.com',
	---@importance='High',
	@body=@mbody,
	@body_format='HTML';
----------------------------------------
--- END Send Customer Import Results ---
----------------------------------------


END











GO
