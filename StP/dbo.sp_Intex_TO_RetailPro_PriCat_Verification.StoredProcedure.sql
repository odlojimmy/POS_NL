/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_Intex_TO_RetailPro_PriCat_Verification]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



























CREATE PROCEDURE [dbo].[sp_Intex_TO_RetailPro_PriCat_Verification]

AS
BEGIN
	SET NOCOUNT ON;

	--Variables
	DECLARE @mxml NVARCHAR(MAX)
	DECLARE @mbody NVARCHAR(MAX)

	DECLARE @StylesCreatedPastDays date;
	DECLARE @StylesCreatedPastDaysNumber int;



	
	--Init Variables 
	Set @StylesCreatedPastDaysNumber = (select convert(int, conf.value) *-1 from retailPro_config conf where conf.id = 'StylesCreatedPastDays') - 90
	Set @StylesCreatedPastDays = DateAdd(day, @StylesCreatedPastDaysNumber, getDate())

	print 'Check reatail pro - data consistency: ' + convert (VARCHAR(50), @StylesCreatedPastDays, 113)

	--*************************************************************************************************************************************
	--Check Config Store Consistency
	--*************************************************************************************************************************************
	IF OBJECT_ID('tempdb..#retailprocustomerconfig') IS NOT NULL DROP TABLE #retailprocustomerconfig

	BEGIN TRANSACTION
	SELECT distinct store.StoreGroupNum StoreGroupNum, ks.PreisLst PriceList
		INTO #retailprocustomerconfig
		FROM [POS_NL].[dbo].[RetailPro_Config_Store] store, [INTEXSALES].[OdloDE].dbo.[KuStamm] ks
		where ltrim(store.customernum) = ltrim(convert(varchar, ks.kusnr)) 
		order by store.StoreGroupNum
	COMMIT TRANSACTION

	IF EXISTS (
		select StoreGroupNum, count(*) CountDifferentPriceLists
			from #retailprocustomerconfig
			group by StoreGroupNum
			having count(*) > 1)
	BEGIN
		--
		print 'RetailPro PriCat Export File - Multiple Price Lists for the same shop group found: '+ convert (VARCHAR(50), @StylesCreatedPastDays, 113)

		SET @mxml = CAST((	
				
						SELECT	StoreGroupNum as 'td','',
								CountDifferentPriceLists as 'td'
						FROM (
									select  StoreGroupNum, count(*) CountDifferentPriceLists from #retailprocustomerconfig
										group by StoreGroupNum
										having count(*) > 1) as Temp --Record is locked for more than one hour


		FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

		SET @mbody =	'<html><body><H2>RetailPro PriCat Export File - Multiple Price Lists for the same shop group found/H2>
						<table border = 1> 
						<tr><th>StoreGroupNum</th><th>CountDifferentPriceLists</th> </tr>'    
 
		SET @mbody = @mbody + @mxml +'</table></body></html>'

		EXEC msdb.dbo.sp_send_dbmail 
			@recipients='retailpro_validation@odlo.com',
			@from_address='sql@odlo.com',
			@subject='RetailPro PriCat Export File - Multiple Price Lists for the same shop group found',
			@reply_to='markus.pfyl@odlo.com',
			---@importance='High',
			@body=@mbody,
			@body_format='HTML';

			RAISERROR('Error in Store Config. The StoreGroup contains different pricelists (pricelists need to be unique within a storegroup',16,1);
	END 



	--*************************************************************************************************************************************
	--Check Config Size Consistency
	--*************************************************************************************************************************************
	IF EXISTS (
			--select distinct gr from INTEXSALES.OdloDE.dbo.ArtEAN ean
			--	where ean.artskey = '011162H' and ean.gr COLLATE SQL_Latin1_General_CP1_CS_AS not in (select size from [POS_NL].[dbo].[RetailPro_Config_Size]) )
			select distinct pc.size from [POS_NL].[dbo].[RetailPro_PriCat_Raw] pc
				where pc.size not in (select size from [POS_NL].[dbo].[RetailPro_Config_Size]) )

	BEGIN
		--
		print 'RetailPro PriCat Export File - Missing Size Config Found: ' + convert (VARCHAR(50), @StylesCreatedPastDays, 113)

		SET @mxml = CAST((	
				
						SELECT	Size as 'td'
						FROM (
									--select distinct gr size from INTEXSALES.OdloDE.dbo.ArtEAN ean
									--	where ean.artskey = '011162H' and ean.gr COLLATE SQL_Latin1_General_CP1_CS_AS not in (select size from [POS_NL].[dbo].[RetailPro_Config_Size]) 
									select distinct pc.size from [POS_NL].[dbo].[RetailPro_PriCat_Raw] pc
										where pc.size not in (select size from [POS_NL].[dbo].[RetailPro_Config_Size])
										) as Temp --Record is locked for more than one hour


		FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

		SET @mbody =	'<html><body><H2>RetailPro PriCat Export File - Missign Size Config Found/H2>
						<table border = 1> 
						<tr><th>Size</th> </tr>'    
 
		SET @mbody = @mbody + @mxml +'</table></body></html>'

		EXEC msdb.dbo.sp_send_dbmail 
			@recipients='retailpro_validation@odlo.com',
			@from_address='sql@odlo.com',
			@subject='RetailPro PriCat Export File -Missign Size Config Found',
			@reply_to='markus.pfyl@odlo.com',
			---@importance='High',
			@body=@mbody,
			@body_format='HTML';

			RAISERROR('Error in Store Config. Missing Sizes identified',16,1);
	END 


	--*************************************************************************************************************************************
	--Check article description in french - if it's missing or not
	--*************************************************************************************************************************************
	IF EXISTS (
			--select distinct gr from INTEXSALES.OdloDE.dbo.ArtEAN ean
			--	where ean.artskey = '011162H' and ean.gr COLLATE SQL_Latin1_General_CP1_CS_AS not in (select size from [POS_NL].[dbo].[RetailPro_Config_Size]) )
			SELECT distinct season, article FROM [POS_NL].[dbo].[RetailPro_PriCat_Raw] where ArticleDesc = '' )

	BEGIN
		--
		print 'RetailPro PriCat Export File - Missing Article Description2 (French) found: '

		SET @mxml = CAST((	
				
						SELECT	Season as 'td','',
								Article as 'td'
						FROM (
									SELECT distinct season, article FROM [POS_NL].[dbo].[RetailPro_PriCat_Raw] where ArticleDesc = '' 
										) as Temp --Record is locked for more than one hour


		FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

		SET @mbody =	'<html><body><H2>RetailPro PriCat Export File - Missign Article Description2 (French) found</H2>
						The articles are still exported to retailpro. But please update with proper description2<table border = 1> 
						<tr><th>Season</th> <th>Article</th> </tr>'    
 
		SET @mbody = @mbody + @mxml +'</table></body></html>'

		EXEC msdb.dbo.sp_send_dbmail 
			@recipients='retailpro_validation@odlo.com',
			@from_address='sql@odlo.com',
			@subject='RetailPro PriCat Export File -Missign Article Description2 (French) found',
			@reply_to='markus.pfyl@odlo.com',
			---@importance='High',
			@body=@mbody,
			@body_format='HTML';

			--Import still keeps going - do not stop
			--RAISERROR('Error in Article Description2 - missing value',16,1);
	END 




	--*************************************************************************************************************************************
	--Check Config for missing prices
	--*************************************************************************************************************************************
	print 'RetailPro PriCat Export File - Missing price check - ' + convert(varchar, @StylesCreatedPastDays, 104)
	IF EXISTS (
		SELECT Season, Article, Color, Size, CreationDate, PriceList, PriceTrade, PriceRetail, PriceRetailBase
			FROM [POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
			where ((convert(numeric, pcr.priceTrade) = 0) OR (convert(numeric, pcr.PriceRetail) = 0) OR (convert(numeric, pcr.priceRetailBase) = 0)) 
				--and	pcr.CreationDate > @StylesCreatedPastDays
			)

	BEGIN
		--
		print 'RetailPro PriCat Export File - Missing Prices: ' + convert (VARCHAR(50), @StylesCreatedPastDays, 113)

		SET @mxml = CAST((	
				
						SELECT	Season  as 'td','',
								Article as 'td','',
								Color as 'td','',
								Size as 'td','',
								CreationDate as 'td','',
								PriceList as 'td','',
								PriceTrade as 'td','',
								PriceRetail as 'td','',
								PriceListBase as 'td','',
								PriceRetailBase as 'td'
						FROM (
									SELECT Season, Article, Color, Size, CreationDate, PriceList, PriceTrade, PriceRetail, PriceListBase, PriceRetailBase
										FROM [POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
										where ((convert(numeric, pcr.priceTrade) = 0) OR (convert(numeric, pcr.PriceRetail) = 0) OR (convert(numeric, pcr.priceRetailBase) = 0)) 
												--and	pcr.CreationDate > @StylesCreatedPastDays 
												--and pcr.pricelist = '200'
										) as Temp --Record is locked for more than one hour
						order by Season, PriceList, Article, Color, Size


		FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

		SET @mbody =	'<html><body><H2>RetailPro PriCat Export File - missing prices</H2>
						<br>Attention, these below styles are not exported into retailPro. They are only getting exported once a price gets defined.</br>
						<table border = 1> 
						<tr> <th>Season</th> <th>Article</th> <th>Color</th> <th>Size</th> <th>CreationDate</th> <th>PriceList</th> <th>TradePrice (EK)</th> <th>PriceRetail (VK)</th> <th>PriceListBase</th> <th>PriceRetailBase (VK)</th> </tr>'    
 
		SET @mbody = @mbody + @mxml +'</table></body></html>'

		EXEC msdb.dbo.sp_send_dbmail 
			@recipients='retailpro_validation@odlo.com',
			@from_address='sql@odlo.com',
			@subject='RetailPro PriCat Export File - missing prices',
			@reply_to='markus.pfyl@odlo.com',
			---@importance='High',
			@body=@mbody,
			@body_format='HTML';

		--remove the 0 price records
		BEGIN TRANSACTION
			
		
		print 'Delete missing prices: ' + convert (VARCHAR(50), @StylesCreatedPastDays, 113)
		DELETE [POS_NL].[dbo].[RetailPro_PriCat_Raw]
			where ((convert(numeric, priceTrade) = 0) OR (convert(numeric, PriceRetail) = 0) OR (convert(numeric, priceRetailBase) = 0)) 

		COMMIT TRANSACTION

	END 

END





























GO
