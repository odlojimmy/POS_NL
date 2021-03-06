
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_SOURCE_RETAILPRO_Sales]


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--- CLEAR UPDATE TABLES
TRUNCATE TABLE SOURCE_RETAILPRO_Sales;

--- CREATE MESSAGE VARIABLES
DECLARE @all varchar(20);
DECLARE @var varchar(1); --- only used as virtual variable in merge statement

-- JRU, 29.08.2017 START
-- TABLE VARIABLE to handle the import and possible duplicates
DECLARE @SOURCE_RETAILPRO_Sales TABLE (
	[StoreGroupNo] [varchar](100) NULL,
	[StoreNo] [varchar](100) NULL,
	[Gtin] [varchar](100) NULL,
	[ArticleNo] [varchar](100) NULL,
	[ColourNo] [varchar](100) NULL,
	[Size] [varchar](100) NULL,
	[Quantity] [varchar](100) NULL,
	[SP] [varchar](100) NULL,
	[PP] [varchar](100) NULL,
	[Discount] [varchar](100) NULL,
	[SalesTime] [varchar](100) NULL,
	[ReceiptNo] [varchar](100) NULL,
	[ReceiptPositionNo] [varchar](100) NULL,
	[BookDate] [varchar](100) NULL,
	[CustomerNo] [varchar](100) NULL
) 
-- JRU, 29.08.2017 END
	
BEGIN TRY

--- IMPORT BRONTO CSV FILE
BULK INSERT SOURCE_RETAILPRO_Sales
FROM 'D:\POS_NL\RetailPro_In\Sales\ODLOCrmSalesFR.csv'
WITH
(
	DATAFILETYPE='char',
	--CODEPAGE='ACP',
	FIRSTROW=2,
	FIELDTERMINATOR=';',
	ROWTERMINATOR='\n'
)

--- CHANGE VALUE FIELDS CHARACTER FOR CORRECT AMOUNT CALCULATION
UPDATE SOURCE_RETAILPRO_Sales
SET	SP=REPLACE(SP,',','.'),
	PP=REPLACE(PP,',','.'),
	Discount=REPLACE(Discount,',','.');

-- JRU, 29.08.2017 START
-- remove duplicates, if any

INSERT @SOURCE_RETAILPRO_Sales (  StoreGroupNo, StoreNo, Gtin, ArticleNo, ColourNo, Size, Quantity, SP, PP, Discount, SalesTime, ReceiptNo, ReceiptPositionNo, BookDate, CustomerNo )
(SELECT 
StoreGroupNo, StoreNo, Gtin, ArticleNo, ColourNo, Size, Quantity, SP, PP, Discount, SalesTime, ReceiptNo, ReceiptPositionNo, BookDate, CustomerNo
 FROM SOURCE_RETAILPRO_Sales
 GROUP BY StoreGroupNo, StoreNo, Gtin, ArticleNo, ColourNo, Size, Quantity, SP, PP, Discount, SalesTime, ReceiptNo, ReceiptPositionNo, BookDate, CustomerNo
 )
 DELETE SOURCE_RETAILPRO_Sales where 1=1
 INSERT INTO SOURCE_RETAILPRO_Sales (StoreGroupNo, StoreNo, Gtin, ArticleNo, ColourNo, Size, Quantity, SP, PP, Discount, SalesTime, ReceiptNo, ReceiptPositionNo, BookDate, CustomerNo )
 (SELECT StoreGroupNo, StoreNo, Gtin, ArticleNo, ColourNo, Size, Quantity, SP, PP, Discount, SalesTime, ReceiptNo, ReceiptPositionNo, BookDate, CustomerNo FROM @SOURCE_RETAILPRO_Sales)

-- JRU, 29.08.2017 END

END TRY

BEGIN CATCH
	PRINT 'POS_NL - Sales Data - RetailPro OFR - DB Import failed'

	EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL - Sales Data - RetailPro OFR - DB Import failed',
	@reply_to='markus.pfyl@odlo.com',
	@importance='High',
	@body='POS_NL - Sales Data - RetailPro OFR - DB Import failed',
	@body_format='HTML';

END CATCH





SET @all=(SELECT count(*) FROM SOURCE_RETAILPRO_Sales);

PRINT 'OFR Sales Import Count - '+@all


PRINT 'SOURCE RETAILPRO Sales successful'



------------------------------------------
--- BEGIN Send OFR SALES Import Results ---
------------------------------------------
DECLARE @mxml NVARCHAR(MAX)
DECLARE @mbody NVARCHAR(MAX)

SET @mxml = CAST((	
					
					SELECT	BookDate as 'td','',
							Shop as 'td','',
							TotalSales as 'td'
					FROM	(
								SELECT   CONVERT(varchar,CONVERT(date,s.BookDate,104),104) as BookDate,
								CASE WHEN st.Odlo_Short_Name IS NULL THEN 'unknown shop' ELSE st.Odlo_Short_Name END as Shop,CAST(sum(CAST(s.SP as money)) as varchar) TotalSales
								FROM SOURCE_RETAILPRO_Sales s LEFT OUTER JOIN (SELECT SUBSTRING(GLN,PATINDEX('%[^0]%',GLN),LEN(GLN)) as GLN,Odlo_Short_Name FROM LOOKUP_Shop) st ON (s.StoreNo=st.GLN)
								GROUP BY s.BookDate,st.Odlo_Short_Name
					) as table1
					ORDER BY convert(date,BookDate,104),3,5

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

SET @mbody =	'<html><body><H2>POS_NL Interface - OFR Sales Load Results</H2>
				<table border = 1> 
				<tr>
				<th> BookDate </th> <th> Shop </th> <th> TotalSales </th></tr>'    
 
SET @mbody = @mbody + @mxml +'</table></body></html>'

EXEC msdb.dbo.sp_send_dbmail 
	@recipients='markus.pfyl@odlo.com',
	@copy_recipients = 'jimmy.rueedi@odlo.com',
	@from_address='sql@odlo.com',
	@subject='POS_NL Interface - OFR Sales Load Results',
	@reply_to='markus.pfyl@odlo.com',
	---@importance='High',
	@body=@mbody,
	@body_format='HTML';
----------------------------------------
--- END Send Customer Import Results ---
----------------------------------------



END







GO
