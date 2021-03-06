/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_Intex_TO_RetailPro_PriCat_InitRawTable]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
























































CREATE PROCEDURE [dbo].[sp_Intex_TO_RetailPro_PriCat_InitRawTable]

AS
BEGIN
	SET NOCOUNT ON;

	--Variables
	DECLARE @path varchar(200);
	DECLARE @file varchar(50);
	DECLARE @filedate varchar(8);
	DECLARE @fileext varchar(5);
	DECLARE @fullpath varchar(400);
	DECLARE @string varchar(1000);
	DECLARE @Season varchar(50);
	DECLARE @SeasonNext varchar(50);

	DECLARE @Season_Outlet varchar(50);
	DECLARE @SeasonNext_Outlet varchar(50);

	DECLARE @customerNum varchar(20);
	DECLARE @storeGroupNum varchar(20);
	DECLARE @RetailPriceListResolve varchar(20);
	DECLARE @REtailPriceListBase varchar(20);
	DECLARE @StylesCreatedPastDays date;
	DECLARE @StylesCreatedPastDaysNumber int;
	DECLARE @StylesCreatedPastDaysNextSeason date;
	DECLARE @StylesCreatedPastDaysNumberNextSeason int;

	DECLARE @StylesCreatedPastDays_Outlet date;
	DECLARE @StylesCreatedPastDaysNumber_Outlet int;
	DECLARE @StylesCreatedPastDaysNextSeason_Outlet date;
	DECLARE @StylesCreatedPastDaysNumberNextSeason_Outlet int;

	
	--*************************************************************************************************************************************
	--Init variables
	--*************************************************************************************************************************************
	Set @Season = (select conf.value from retailPro_config conf where conf.id = 'RetailProSeason')	
	Set @SeasonNext = (select conf.value from retailPro_config conf where conf.id = 'RetailProSeasonNext')
	Set @Season_Outlet = (select conf.value from retailPro_config conf where conf.id = 'RetailProSeason_Outlet')	
	Set @SeasonNext_Outlet = (select conf.value from retailPro_config conf where conf.id = 'RetailProSeasonNext_Outlet')

	--used for outlets (price list 201. There we need to get the original base price - and we take it out of price list 203)
	Set @RetailPriceListResolve = 201
	Set @RetailPriceListBase = 203

	--Init Variables 
	--NON OUTLET Type current season - only new styles till a certain date
	Set @StylesCreatedPastDaysNumber = (select convert(int, conf.value) *-1 from retailPro_config conf where conf.id = 'RetailProSeason_StylesCreatedPastDays')
	Set @StylesCreatedPastDays = DateAdd(day, @StylesCreatedPastDaysNumber, getDate())
	--next season - only new styles till a certain date
	Set @StylesCreatedPastDaysNumberNextSeason = (select convert(int, conf.value) *-1 from retailPro_config conf where conf.id = 'RetailProSeasonNext_StylesCreatedPastDays')
	Set @StylesCreatedPastDaysNextSeason = DateAdd(day, @StylesCreatedPastDaysNumberNextSeason, getDate())

	--OUTLET type - current season - only new styles till a certain date
	Set @StylesCreatedPastDaysNumber_Outlet = (select convert(int, conf.value) *-1 from retailPro_config conf where conf.id = 'RetailProSeason_Outlet_StylesCreatedPastDays')
	Set @StylesCreatedPastDays_Outlet = DateAdd(day, @StylesCreatedPastDaysNumber, getDate())
	--next season - only new styles till a certain date
	Set @StylesCreatedPastDaysNumberNextSeason_Outlet = (select convert(int, conf.value) *-1 from retailPro_config conf where conf.id = 'RetailProSeasonNext_Outlet_StylesCreatedPastDays')
	Set @StylesCreatedPastDaysNextSeason_Outlet = DateAdd(day, @StylesCreatedPastDaysNumberNextSeason, getDate())

	--*************************************************************************************************************************************
	--clarification on price names
	--*************************************************************************************************************************************
	-- TRADE PRICE = EkPreis
	-- RETAIL PRICE = VkPreis
	-- Price REtial Price = suggested retail price (for regular stores, its the same as retial price, for outlets 

	print 'season (current season): ' + @Season
	print 'season outlet (current season): ' + @Season_Outlet
	print '  StylesCreatedPastDays: ' + convert (VARCHAR(50), @StylesCreatedPastDays, 113)
	print '  StylesCreatedPastDays outlet: ' + convert (VARCHAR(50), @StylesCreatedPastDays_outlet, 113)
	print 'seasonNext (next season): ' + @SeasonNext
	print 'seasonNext outlet (next season): ' + @SeasonNext_Outlet
	print '  StylesCreatedPastDaysNext: ' + convert (VARCHAR(50), @StylesCreatedPastDaysNextSeason, 113)
	print '  StylesCreatedPastDaysNext outlet: ' + convert (VARCHAR(50), @StylesCreatedPastDaysNextSeason_outlet, 113)

	
	--*************************************************************************************************************************************
	--FILL RAW DATA for PriCat
	-- for current retail season
	--*************************************************************************************************************************************	
	BEGIN TRANSACTION
	PRINT 'START fill table RetailPro_PriCat1_Raw (current retail season): '  + CONVERT(VARCHAR(50), getdate(), 113)
	TRUNCATE TABLE [dbo].RetailPro_PriCat1_Raw;
	--*************************************************************************************************************************************
	--OUTLET TYPE
	--*************************************************************************************************************************************
	INSERT INTO RetailPro_PriCat1_Raw 
		SELECT DISTINCT
				ArtStamm.ArtsKey as Season,
				rtrim(ArtStamm.ArtsNr1) as Article,
				left(rtrim(ArtStamm.InterneBez2),30) as Article_Desc,
				'D' + ArtStamm.DivNeu + 'G' + ArtStamm.ProdGroup +'S_' + ArtStamm.Geschlecht  DCS_Code,
				ArtStamm.ProdGroup,
				left(SubgrpTXT.zeile,20) as ProdGroup_txt,
				ArtStamm.Geschlecht as SEX,
				CASE
						WHEN ArtStamm.Geschlecht = 'M' then 'HOMME'
						WHEN ArtStamm.Geschlecht = 'L' then 'FEMME'
						WHEN ArtStamm.Geschlecht = 'U' then 'UNISEXE'
						ELSE 'unknown'
					END as SexText,
				ArtEAN.EANCode,
				rtrim(ArtEAN.Gr) as Size,
				ArtEAN.VerkFarbe as Color,
				left(Farbe.zeile,30) as Color_txt,
				ArtStamm.FedasProdGr as FEDAS,
				FedasTXT.zeile as FEDAS_Text,
				ArtStamm.ZollTafNr as Custom,
				dbo_ArtGroessen2.Gewicht_Brutto as Weight_Brut,
				(dbo_ArtGroessen2.Breite/10)*(dbo_ArtGroessen2.Hoehe/10)*(dbo_ArtGroessen2.Laenge/10) as Volume,
				left(MaterialTXT.zeile,20) as MatGrpTXT,
				ArtStamm.MatGrp,
				left(ArtStamm.MatZus,20),
				MatzusTXT.zeile as MatZusTXT,
				ArtStamm.Segment,
				left(SegmentTXT.zeile,20) as SegmentTXT,
				ArtStamm.DivNeu as Division,
				left(DivneuTXT.zeile,20) as DivNeuTXT,
				ArtStamm.ArtGroup,
				left(TypeTXT.zeile,20) as ArtGroupTXT,
				ArtLieferant.Ursprung as Origin,
				rtrim(ArPreisLst.PreisListe) as Pricelist,
				ArPreisLst.EkPreis as PriceTrade,
				ArPreisLst.VkPreis as PriceRetail,
				'' as PriceListBase,
				'' as RetailBase,
				'OUTLET' as StoreType,
				CASE WHEN (dbo_ArtGroessen2.neu >= ArtFarben.neu)
					THEN
						--size is newer or equal color
						CASE WHEN (ArtFarben.neu = dbo_ArtGroessen2.neu)
							--both new
							THEN 'New Style'
							ELSE 'New Size'
						END
					ELSE
						--new color
						'New color'
				END AS CreationType,
				ArtStamm.Wann as CreationDate,
				ArPreisLst.Wann as CreationDatePrice
				FROM	INTEXSALES.OdloDE.dbo.TpText  FedasTXT 
							LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArtStamm ON ArtStamm.TapKey_FedasProdGr=FedasTXT.tapkey AND ArtStamm.FedasProdGr = FedasTXT.tpwert AND FedasTXT.tanr = 16 AND FedasTXT.sprache = '01' AND FedasTXT.lfd = 1
							RIGHT OUTER JOIN INTEXSALES.OdloDE.dbo.TpText  SubgrpTXT ON ArtStamm.TapKey_ProdGroup=SubgrpTXT.tapkey AND SubgrpTXT.tpwert = ArtStamm.ProdGroup AND SubgrpTXT.tanr = 6 AND SubgrpTXT.lfd = 1 AND SubgrpTXT.sprache = '01',
						INTEXSALES.OdloDE.dbo.ArtGroessen  dbo_ArtGroessen2,
						INTEXSALES.OdloDE.dbo.TpText  MaterialTXT,
						INTEXSALES.OdloDE.dbo.TpText  MatzusTXT,
						INTEXSALES.OdloDE.dbo.TpText  SegmentTXT,
						INTEXSALES.OdloDE.dbo.TpText  DivneuTXT,
						INTEXSALES.OdloDE.dbo.ArtFarben 
							LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArPreisLst ON ArtFarben.ArtsNr1=ArPreisLst.ArtsNr1 and ArtFarben.ArtsNr2=ArPreisLst.ArtsNr2 and ArtFarben.ArtsKey=ArPreisLst.ArtsKey and ArtFarben.VerkFarbe=ArPreisLst.VerkFarbe LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArLfFarbEk ON ArLfFarbEk.ArtsNr1=ArtFarben.ArtsNr1 and ArLfFarbEk.ArtsNr2=ArtFarben.ArtsNr2 and ArLfFarbEk.ArtsKey=ArtFarben.ArtsKey and ArLfFarbEk.VerkFarbe=ArtFarben.VerkFarbe  
							LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArtEAN ON ArtEAN.ArtsNr1=ArtFarben.ArtsNr1 and ArtEAN.ArtsNr2=ArtFarben.ArtsNr2 and ArtEAN.ArtsKey=ArtFarben.ArtsKey and 
						ArtEAN.VerkFarbe=ArtFarben.VerkFarbe,
						INTEXSALES.OdloDE.dbo.TpText  Farbe,
						INTEXSALES.OdloDE.dbo.TpText  TypeTXT,
						INTEXSALES.OdloDE.dbo.ArtLieferant
				WHERE
					  ArtStamm.ArtsNr1=ArtFarben.ArtsNr1 and ArtStamm.ArtsNr2=ArtFarben.ArtsNr2 and ArtStamm.ArtsKey=ArtFarben.ArtsKey  
					  AND ArtLieferant.ArtsNr1=ArLfFarbEk.ArtsNr1 and ArtLieferant.ArtsNr2=ArLfFarbEk.ArtsNr2 and ArtLieferant.ArtsKey=ArLfFarbEk.ArtsKey and ArtLieferant.Lfd=ArLfFarbEk.Lfd and ArtLieferant.HauptLieferantJN = 'J'					  
					  AND ArtStamm.TapKey_ArtGroup=TypeTXT.tapkey AND ArtStamm.ArtGroup = TypeTXT.tpwert AND TypeTXT.tanr = 73 AND TypeTXT.sprache = '01' AND TypeTXT.lfd = 1
					  AND MaterialTXT.tapkey=ArtStamm.TapKey_MatGrp AND MaterialTXT.tpwert = ArtStamm.MatGrp AND MaterialTXT.tanr = 50 AND MaterialTXT.sprache = '01' AND MaterialTXT.lfd = 1
					  AND DivneuTXT.tapkey=ArtStamm.TapKey_DivNeu AND DivneuTXT.tpwert = ArtStamm.DivNeu AND DivneuTXT.tanr = 600 AND DivneuTXT.sprache = '01' AND DivneuTXT.lfd = 1
					  AND SegmentTXT.tapkey=ArtStamm.TapKey_Segment AND SegmentTXT.tpwert = ArtStamm.Segment AND SegmentTXT.tanr = 601 AND SegmentTXT.sprache = '01' AND SegmentTXT.lfd = 1
					  AND dbo_ArtGroessen2.ArtsNr1=ArtEAN.ArtsNr1 and dbo_ArtGroessen2.ArtsNr2=ArtEAN.ArtsNr2 and dbo_ArtGroessen2.ArtsKey=ArtEAN.ArtsKey and  dbo_ArtGroessen2.gr=ArtEAN.gr
					  AND Farbe.tapkey = ArtFarben.TapKey_VerkFarbe AND Farbe.tpwert = ArtFarben.VerkFarbe AND Farbe.tanr = 77 AND Farbe.sprache = '01' AND Farbe.lfd = 1
					  AND MatzusTXT.tapkey=ArtStamm.TapKey_MatZus AND MatzusTXT.tpwert = ArtStamm.MatZus AND MatzusTXT.tanr = 44 AND MatzusTXT.sprache = '01' AND MatzusTXT.lfd = 1
					  --full list for current season
					  AND ArtStamm.ArtsKey  IN  (@Season_Outlet)  					  
					  --for all defined pricelists
					  AND  ArPreisLst.PreisListe  IN (select ks.PreisLst from [POS_NL].[dbo].[RetailPro_Config_Store] rps, [INTEXSALES].[OdloDE].dbo.[KuStamm] ks where rps.customernum = ks.kusnr and rps.StoreType = 'OUTLET')
					  --below commented out to only get new styles (the new styles will get filtered later
					  --and ((ArtStamm.Neu > @StylesCreatedPastDays) OR (ArtFarben.Neu > @StylesCreatedPastDays) OR (dbo_ArtGroessen2.Neu >@StylesCreatedPastDays ))
					  and isnumeric (ArtStamm.ArtsNr1) <> 0

	--*************************************************************************************************************************************
	--NOT OUTLET TYPE (all Franchise and Affiliate/Brand Stores
	--*************************************************************************************************************************************
	INSERT INTO RetailPro_PriCat1_Raw 
		SELECT DISTINCT
				ArtStamm.ArtsKey as Season,
				rtrim(ArtStamm.ArtsNr1) as Article,
				left(rtrim(ArtStamm.InterneBez2),30) as Article_Desc,
				'D' + ArtStamm.DivNeu + 'G' + ArtStamm.ProdGroup +'S_' + ArtStamm.Geschlecht  DCS_Code,
				ArtStamm.ProdGroup,
				left(SubgrpTXT.zeile,20) as ProdGroup_txt,
				ArtStamm.Geschlecht as SEX,
				CASE
						WHEN ArtStamm.Geschlecht = 'M' then 'HOMME'
						WHEN ArtStamm.Geschlecht = 'L' then 'FEMME'
						WHEN ArtStamm.Geschlecht = 'U' then 'UNISEXE'
						ELSE 'unknown'
					END as SexText,
				ArtEAN.EANCode,
				rtrim(ArtEAN.Gr) as Size,
				ArtEAN.VerkFarbe as Color,
				left(Farbe.zeile,30) as Color_txt,
				ArtStamm.FedasProdGr as FEDAS,
				FedasTXT.zeile as FEDAS_Text,
				ArtStamm.ZollTafNr as Custom,
				dbo_ArtGroessen2.Gewicht_Brutto as Weight_Brut,
				(dbo_ArtGroessen2.Breite/10)*(dbo_ArtGroessen2.Hoehe/10)*(dbo_ArtGroessen2.Laenge/10) as Volume,
				left(MaterialTXT.zeile,20) as MatGrpTXT,
				ArtStamm.MatGrp,
				left(ArtStamm.MatZus,20),
				MatzusTXT.zeile as MatZusTXT,
				ArtStamm.Segment,
				left(SegmentTXT.zeile,20) as SegmentTXT,
				ArtStamm.DivNeu as Division,
				left(DivneuTXT.zeile,20) as DivNeuTXT,
				ArtStamm.ArtGroup,
				left(TypeTXT.zeile,20) as ArtGroupTXT,
				ArtLieferant.Ursprung as Origin,
				rtrim(ArPreisLst.PreisListe) as Pricelist,
				ArPreisLst.EkPreis as PriceTrade,
				ArPreisLst.VkPreis as PriceRetail,
				'' as PriceListBase,
				'' as RetailBase,
				'NOT OUTLET' as StoreType,
				CASE WHEN (dbo_ArtGroessen2.neu >= ArtFarben.neu)
					THEN
						--size is newer or equal color
						CASE WHEN (ArtFarben.neu = dbo_ArtGroessen2.neu)
							--both new
							THEN 'New Style'
							ELSE 'New Size'
						END
					ELSE
						--new color
						'New color'
				END AS CreationType,
				ArtStamm.Wann as CreationDate,
				ArPreisLst.Wann as CreationDatePrice
				FROM	INTEXSALES.OdloDE.dbo.TpText  FedasTXT 
							LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArtStamm ON ArtStamm.TapKey_FedasProdGr=FedasTXT.tapkey AND ArtStamm.FedasProdGr = FedasTXT.tpwert AND FedasTXT.tanr = 16 AND FedasTXT.sprache = '01' AND FedasTXT.lfd = 1
							RIGHT OUTER JOIN INTEXSALES.OdloDE.dbo.TpText  SubgrpTXT ON ArtStamm.TapKey_ProdGroup=SubgrpTXT.tapkey AND SubgrpTXT.tpwert = ArtStamm.ProdGroup AND SubgrpTXT.tanr = 6 AND SubgrpTXT.lfd = 1 AND SubgrpTXT.sprache = '01',
						INTEXSALES.OdloDE.dbo.ArtGroessen  dbo_ArtGroessen2,
						INTEXSALES.OdloDE.dbo.TpText  MaterialTXT,
						INTEXSALES.OdloDE.dbo.TpText  MatzusTXT,
						INTEXSALES.OdloDE.dbo.TpText  SegmentTXT,
						INTEXSALES.OdloDE.dbo.TpText  DivneuTXT,
						INTEXSALES.OdloDE.dbo.ArtFarben 
							LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArPreisLst ON ArtFarben.ArtsNr1=ArPreisLst.ArtsNr1 and ArtFarben.ArtsNr2=ArPreisLst.ArtsNr2 and ArtFarben.ArtsKey=ArPreisLst.ArtsKey and ArtFarben.VerkFarbe=ArPreisLst.VerkFarbe LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArLfFarbEk ON ArLfFarbEk.ArtsNr1=ArtFarben.ArtsNr1 and ArLfFarbEk.ArtsNr2=ArtFarben.ArtsNr2 and ArLfFarbEk.ArtsKey=ArtFarben.ArtsKey and ArLfFarbEk.VerkFarbe=ArtFarben.VerkFarbe  
							LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArtEAN ON ArtEAN.ArtsNr1=ArtFarben.ArtsNr1 and ArtEAN.ArtsNr2=ArtFarben.ArtsNr2 and ArtEAN.ArtsKey=ArtFarben.ArtsKey and 
						ArtEAN.VerkFarbe=ArtFarben.VerkFarbe,
						INTEXSALES.OdloDE.dbo.TpText  Farbe,
						INTEXSALES.OdloDE.dbo.TpText  TypeTXT,
						INTEXSALES.OdloDE.dbo.ArtLieferant
				WHERE
					  ArtStamm.ArtsNr1=ArtFarben.ArtsNr1 and ArtStamm.ArtsNr2=ArtFarben.ArtsNr2 and ArtStamm.ArtsKey=ArtFarben.ArtsKey  
					  AND ArtLieferant.ArtsNr1=ArLfFarbEk.ArtsNr1 and ArtLieferant.ArtsNr2=ArLfFarbEk.ArtsNr2 and ArtLieferant.ArtsKey=ArLfFarbEk.ArtsKey and ArtLieferant.Lfd=ArLfFarbEk.Lfd and ArtLieferant.HauptLieferantJN = 'J'					  
					  AND ArtStamm.TapKey_ArtGroup=TypeTXT.tapkey AND ArtStamm.ArtGroup = TypeTXT.tpwert AND TypeTXT.tanr = 73 AND TypeTXT.sprache = '01' AND TypeTXT.lfd = 1
					  AND MaterialTXT.tapkey=ArtStamm.TapKey_MatGrp AND MaterialTXT.tpwert = ArtStamm.MatGrp AND MaterialTXT.tanr = 50 AND MaterialTXT.sprache = '01' AND MaterialTXT.lfd = 1
					  AND DivneuTXT.tapkey=ArtStamm.TapKey_DivNeu AND DivneuTXT.tpwert = ArtStamm.DivNeu AND DivneuTXT.tanr = 600 AND DivneuTXT.sprache = '01' AND DivneuTXT.lfd = 1
					  AND SegmentTXT.tapkey=ArtStamm.TapKey_Segment AND SegmentTXT.tpwert = ArtStamm.Segment AND SegmentTXT.tanr = 601 AND SegmentTXT.sprache = '01' AND SegmentTXT.lfd = 1
					  AND dbo_ArtGroessen2.ArtsNr1=ArtEAN.ArtsNr1 and dbo_ArtGroessen2.ArtsNr2=ArtEAN.ArtsNr2 and dbo_ArtGroessen2.ArtsKey=ArtEAN.ArtsKey and  dbo_ArtGroessen2.gr=ArtEAN.gr
					  AND Farbe.tapkey = ArtFarben.TapKey_VerkFarbe AND Farbe.tpwert = ArtFarben.VerkFarbe AND Farbe.tanr = 77 AND Farbe.sprache = '01' AND Farbe.lfd = 1
					  AND MatzusTXT.tapkey=ArtStamm.TapKey_MatZus AND MatzusTXT.tpwert = ArtStamm.MatZus AND MatzusTXT.tanr = 44 AND MatzusTXT.sprache = '01' AND MatzusTXT.lfd = 1
					  --full list for current season
					  AND ArtStamm.ArtsKey  IN  (@Season)  					  
					  --for all defined pricelists
					  AND  ArPreisLst.PreisListe  IN (select ks.PreisLst from [POS_NL].[dbo].[RetailPro_Config_Store] rps, [INTEXSALES].[OdloDE].dbo.[KuStamm] ks where rps.customernum = ks.kusnr and rps.StoreType <> 'OUTLET')
					  --below commented out to only get new styles (the new styles will get filtered later
					  --and ((ArtStamm.Neu > @StylesCreatedPastDays) OR (ArtFarben.Neu > @StylesCreatedPastDays) OR (dbo_ArtGroessen2.Neu >@StylesCreatedPastDays ))
					  and isnumeric (ArtStamm.ArtsNr1) <> 0
	
	COMMIT TRANSACTION
	PRINT 'END fill table RetailPro_PriCat1_Raw: '  + CONVERT(VARCHAR(50), getdate(), 113)


	--*************************************************************************************************************************************
	--FILL RAW DATA for PriCat
	-- for next retail season
	--*************************************************************************************************************************************
	BEGIN TRANSACTION
	PRINT 'START fill table RetailPro_PriCat2_Raw (next retail season): '  + CONVERT(VARCHAR(50), getdate(), 113)
	TRUNCATE TABLE [dbo].RetailPro_PriCat2_Raw;

	--*************************************************************************************************************************************
	--OUTLET TYPE
	--*************************************************************************************************************************************
	INSERT INTO RetailPro_PriCat2_Raw 
		SELECT DISTINCT
				ArtStamm.ArtsKey as Season,
				rtrim(ArtStamm.ArtsNr1) as Article,
				left(rtrim(ArtStamm.InterneBez2),30) as Article_Desc,
				'D' + ArtStamm.DivNeu + 'G' + ArtStamm.ProdGroup +'S_' + ArtStamm.Geschlecht  DCS_Code,
				ArtStamm.ProdGroup,
				left(SubgrpTXT.zeile,20) as ProdGroup_txt,
				ArtStamm.Geschlecht as SEX,
				CASE
						WHEN ArtStamm.Geschlecht = 'M' then 'HOMME'
						WHEN ArtStamm.Geschlecht = 'L' then 'FEMME'
						WHEN ArtStamm.Geschlecht = 'U' then 'UNISEXE'
						ELSE 'unknown'
					END as SexText,
				ArtEAN.EANCode,
				rtrim(ArtEAN.Gr) as Size,
				ArtEAN.VerkFarbe as Color,
				left(Farbe.zeile,30) as Color_txt,
				ArtStamm.FedasProdGr as FEDAS,
				FedasTXT.zeile as FEDAS_Text,
				ArtStamm.ZollTafNr as Custom,
				dbo_ArtGroessen2.Gewicht_Brutto as Weight_Brut,
				(dbo_ArtGroessen2.Breite/10)*(dbo_ArtGroessen2.Hoehe/10)*(dbo_ArtGroessen2.Laenge/10) as Volume,
				left(MaterialTXT.zeile,20) as MatGrpTXT,
				ArtStamm.MatGrp,
				left(ArtStamm.MatZus,20),
				MatzusTXT.zeile as MatZusTXT,
				ArtStamm.Segment,
				left(SegmentTXT.zeile,20) as SegmentTXT,
				ArtStamm.DivNeu as Division,
				left(DivneuTXT.zeile,20) as DivNeuTXT,
				ArtStamm.ArtGroup,
				left(TypeTXT.zeile,20) as ArtGroupTXT,
				ArtLieferant.Ursprung as Origin,
				rtrim(ArPreisLst.PreisListe) as Pricelist,
				ArPreisLst.EkPreis as PriceTrade,
				ArPreisLst.VkPreis as PriceRetail,
				'' as PriceListBase,
				'' as RetailBase,
				'OUTLET' as StoreType,
				CASE WHEN (dbo_ArtGroessen2.neu >= ArtFarben.neu)
					THEN
						--size is newer or equal color
						CASE WHEN (ArtFarben.neu = dbo_ArtGroessen2.neu)
							--both new
							THEN 'New Style'
							ELSE 'New Size'
						END
					ELSE
						--new color
						'New color'
				END AS CreationType,
				ArtStamm.Wann as CreationDate,
				ArPreisLst.Wann as CreationDatePrice
				FROM	INTEXSALES.OdloDE.dbo.TpText  FedasTXT 
							LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArtStamm ON ArtStamm.TapKey_FedasProdGr=FedasTXT.tapkey AND ArtStamm.FedasProdGr = FedasTXT.tpwert AND FedasTXT.tanr = 16 AND FedasTXT.sprache = '01' AND FedasTXT.lfd = 1
							RIGHT OUTER JOIN INTEXSALES.OdloDE.dbo.TpText  SubgrpTXT ON ArtStamm.TapKey_ProdGroup=SubgrpTXT.tapkey AND SubgrpTXT.tpwert = ArtStamm.ProdGroup AND SubgrpTXT.tanr = 6 AND SubgrpTXT.lfd = 1 AND SubgrpTXT.sprache = '01',
						INTEXSALES.OdloDE.dbo.ArtGroessen  dbo_ArtGroessen2,
						INTEXSALES.OdloDE.dbo.TpText  MaterialTXT,
						INTEXSALES.OdloDE.dbo.TpText  MatzusTXT,
						INTEXSALES.OdloDE.dbo.TpText  SegmentTXT,
						INTEXSALES.OdloDE.dbo.TpText  DivneuTXT,
						INTEXSALES.OdloDE.dbo.ArtFarben 
							LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArPreisLst ON ArtFarben.ArtsNr1=ArPreisLst.ArtsNr1 and ArtFarben.ArtsNr2=ArPreisLst.ArtsNr2 and ArtFarben.ArtsKey=ArPreisLst.ArtsKey and ArtFarben.VerkFarbe=ArPreisLst.VerkFarbe LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArLfFarbEk ON ArLfFarbEk.ArtsNr1=ArtFarben.ArtsNr1 and ArLfFarbEk.ArtsNr2=ArtFarben.ArtsNr2 and ArLfFarbEk.ArtsKey=ArtFarben.ArtsKey and ArLfFarbEk.VerkFarbe=ArtFarben.VerkFarbe  
							LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArtEAN ON ArtEAN.ArtsNr1=ArtFarben.ArtsNr1 and ArtEAN.ArtsNr2=ArtFarben.ArtsNr2 and ArtEAN.ArtsKey=ArtFarben.ArtsKey and 
						ArtEAN.VerkFarbe=ArtFarben.VerkFarbe,
						INTEXSALES.OdloDE.dbo.TpText  Farbe,
						INTEXSALES.OdloDE.dbo.TpText  TypeTXT,
						INTEXSALES.OdloDE.dbo.ArtLieferant
				WHERE
					  ArtStamm.ArtsNr1=ArtFarben.ArtsNr1 and ArtStamm.ArtsNr2=ArtFarben.ArtsNr2 and ArtStamm.ArtsKey=ArtFarben.ArtsKey  
					  AND ArtLieferant.ArtsNr1=ArLfFarbEk.ArtsNr1 and ArtLieferant.ArtsNr2=ArLfFarbEk.ArtsNr2 and ArtLieferant.ArtsKey=ArLfFarbEk.ArtsKey and ArtLieferant.Lfd=ArLfFarbEk.Lfd and ArtLieferant.HauptLieferantJN = 'J'					  
					  AND ArtStamm.TapKey_ArtGroup=TypeTXT.tapkey AND ArtStamm.ArtGroup = TypeTXT.tpwert AND TypeTXT.tanr = 73 AND TypeTXT.sprache = '01' AND TypeTXT.lfd = 1
					  AND MaterialTXT.tapkey=ArtStamm.TapKey_MatGrp AND MaterialTXT.tpwert = ArtStamm.MatGrp AND MaterialTXT.tanr = 50 AND MaterialTXT.sprache = '01' AND MaterialTXT.lfd = 1
					  AND DivneuTXT.tapkey=ArtStamm.TapKey_DivNeu AND DivneuTXT.tpwert = ArtStamm.DivNeu AND DivneuTXT.tanr = 600 AND DivneuTXT.sprache = '01' AND DivneuTXT.lfd = 1
					  AND SegmentTXT.tapkey=ArtStamm.TapKey_Segment AND SegmentTXT.tpwert = ArtStamm.Segment AND SegmentTXT.tanr = 601 AND SegmentTXT.sprache = '01' AND SegmentTXT.lfd = 1
					  AND dbo_ArtGroessen2.ArtsNr1=ArtEAN.ArtsNr1 and dbo_ArtGroessen2.ArtsNr2=ArtEAN.ArtsNr2 and dbo_ArtGroessen2.ArtsKey=ArtEAN.ArtsKey and  dbo_ArtGroessen2.gr=ArtEAN.gr
					  AND Farbe.tapkey = ArtFarben.TapKey_VerkFarbe AND Farbe.tpwert = ArtFarben.VerkFarbe AND Farbe.tanr = 77 AND Farbe.sprache = '01' AND Farbe.lfd = 1
					  AND MatzusTXT.tapkey=ArtStamm.TapKey_MatZus AND MatzusTXT.tpwert = ArtStamm.MatZus AND MatzusTXT.tanr = 44 AND MatzusTXT.sprache = '01' AND MatzusTXT.lfd = 1
					  --full list for current season
					  AND ArtStamm.ArtsKey  IN  (@SeasonNext_Outlet)  					  
					  --for all defined pricelists
					  AND  ArPreisLst.PreisListe  IN (select ks.PreisLst from [POS_NL].[dbo].[RetailPro_Config_Store] rps, [INTEXSALES].[OdloDE].dbo.[KuStamm] ks where rps.customernum = ks.kusnr and rps.StoreType = 'OUTLET')
					  --below commented out to only get new styles (the new styles will get filtered later
					  --and ((ArtStamm.Neu > @StylesCreatedPastDaysNextSeason) OR (ArtFarben.Neu > @StylesCreatedPastDaysNextSeason) OR (dbo_ArtGroessen2.Neu >@StylesCreatedPastDaysNextSeason ))
					  and isnumeric (ArtStamm.ArtsNr1) <> 0

	--*************************************************************************************************************************************
	--NON OUTLET TYPE (Franchise and Affiliate)
	--*************************************************************************************************************************************
	INSERT INTO RetailPro_PriCat2_Raw 
		SELECT DISTINCT
				ArtStamm.ArtsKey as Season,
				rtrim(ArtStamm.ArtsNr1) as Article,
				left(rtrim(ArtStamm.InterneBez2),30) as Article_Desc,
				'D' + ArtStamm.DivNeu + 'G' + ArtStamm.ProdGroup +'S_' + ArtStamm.Geschlecht  DCS_Code,
				ArtStamm.ProdGroup,
				left(SubgrpTXT.zeile,20) as ProdGroup_txt,
				ArtStamm.Geschlecht as SEX,
				CASE
						WHEN ArtStamm.Geschlecht = 'M' then 'HOMME'
						WHEN ArtStamm.Geschlecht = 'L' then 'FEMME'
						WHEN ArtStamm.Geschlecht = 'U' then 'UNISEXE'
						ELSE 'unknown'
					END as SexText,
				ArtEAN.EANCode,
				rtrim(ArtEAN.Gr) as Size,
				ArtEAN.VerkFarbe as Color,
				left(Farbe.zeile,30) as Color_txt,
				ArtStamm.FedasProdGr as FEDAS,
				FedasTXT.zeile as FEDAS_Text,
				ArtStamm.ZollTafNr as Custom,
				dbo_ArtGroessen2.Gewicht_Brutto as Weight_Brut,
				(dbo_ArtGroessen2.Breite/10)*(dbo_ArtGroessen2.Hoehe/10)*(dbo_ArtGroessen2.Laenge/10) as Volume,
				left(MaterialTXT.zeile,20) as MatGrpTXT,
				ArtStamm.MatGrp,
				left(ArtStamm.MatZus,20),
				MatzusTXT.zeile as MatZusTXT,
				ArtStamm.Segment,
				left(SegmentTXT.zeile,20) as SegmentTXT,
				ArtStamm.DivNeu as Division,
				left(DivneuTXT.zeile,20) as DivNeuTXT,
				ArtStamm.ArtGroup,
				left(TypeTXT.zeile,20) as ArtGroupTXT,
				ArtLieferant.Ursprung as Origin,
				rtrim(ArPreisLst.PreisListe) as Pricelist,
				ArPreisLst.EkPreis as PriceTrade,
				ArPreisLst.VkPreis as PriceRetail,
				'' as PriceListBase,
				'' as RetailBase,
				'NOT OUTLET' as StoreType,
				CASE WHEN (dbo_ArtGroessen2.neu >= ArtFarben.neu)
					THEN
						--size is newer or equal color
						CASE WHEN (ArtFarben.neu = dbo_ArtGroessen2.neu)
							--both new
							THEN 'New Style'
							ELSE 'New Size'
						END
					ELSE
						--new color
						'New color'
				END AS CreationType,
				ArtStamm.Wann as CreationDate,
				ArPreisLst.Wann as CreationDatePrice
				FROM	INTEXSALES.OdloDE.dbo.TpText  FedasTXT 
							LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArtStamm ON ArtStamm.TapKey_FedasProdGr=FedasTXT.tapkey AND ArtStamm.FedasProdGr = FedasTXT.tpwert AND FedasTXT.tanr = 16 AND FedasTXT.sprache = '01' AND FedasTXT.lfd = 1
							RIGHT OUTER JOIN INTEXSALES.OdloDE.dbo.TpText  SubgrpTXT ON ArtStamm.TapKey_ProdGroup=SubgrpTXT.tapkey AND SubgrpTXT.tpwert = ArtStamm.ProdGroup AND SubgrpTXT.tanr = 6 AND SubgrpTXT.lfd = 1 AND SubgrpTXT.sprache = '01',
						INTEXSALES.OdloDE.dbo.ArtGroessen  dbo_ArtGroessen2,
						INTEXSALES.OdloDE.dbo.TpText  MaterialTXT,
						INTEXSALES.OdloDE.dbo.TpText  MatzusTXT,
						INTEXSALES.OdloDE.dbo.TpText  SegmentTXT,
						INTEXSALES.OdloDE.dbo.TpText  DivneuTXT,
						INTEXSALES.OdloDE.dbo.ArtFarben 
							LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArPreisLst ON ArtFarben.ArtsNr1=ArPreisLst.ArtsNr1 and ArtFarben.ArtsNr2=ArPreisLst.ArtsNr2 and ArtFarben.ArtsKey=ArPreisLst.ArtsKey and ArtFarben.VerkFarbe=ArPreisLst.VerkFarbe LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArLfFarbEk ON ArLfFarbEk.ArtsNr1=ArtFarben.ArtsNr1 and ArLfFarbEk.ArtsNr2=ArtFarben.ArtsNr2 and ArLfFarbEk.ArtsKey=ArtFarben.ArtsKey and ArLfFarbEk.VerkFarbe=ArtFarben.VerkFarbe  
							LEFT OUTER JOIN INTEXSALES.OdloDE.dbo.ArtEAN ON ArtEAN.ArtsNr1=ArtFarben.ArtsNr1 and ArtEAN.ArtsNr2=ArtFarben.ArtsNr2 and ArtEAN.ArtsKey=ArtFarben.ArtsKey and 
						ArtEAN.VerkFarbe=ArtFarben.VerkFarbe,
						INTEXSALES.OdloDE.dbo.TpText  Farbe,
						INTEXSALES.OdloDE.dbo.TpText  TypeTXT,
						INTEXSALES.OdloDE.dbo.ArtLieferant
				WHERE
					  ArtStamm.ArtsNr1=ArtFarben.ArtsNr1 and ArtStamm.ArtsNr2=ArtFarben.ArtsNr2 and ArtStamm.ArtsKey=ArtFarben.ArtsKey  
					  AND ArtLieferant.ArtsNr1=ArLfFarbEk.ArtsNr1 and ArtLieferant.ArtsNr2=ArLfFarbEk.ArtsNr2 and ArtLieferant.ArtsKey=ArLfFarbEk.ArtsKey and ArtLieferant.Lfd=ArLfFarbEk.Lfd and ArtLieferant.HauptLieferantJN = 'J'					  
					  AND ArtStamm.TapKey_ArtGroup=TypeTXT.tapkey AND ArtStamm.ArtGroup = TypeTXT.tpwert AND TypeTXT.tanr = 73 AND TypeTXT.sprache = '01' AND TypeTXT.lfd = 1
					  AND MaterialTXT.tapkey=ArtStamm.TapKey_MatGrp AND MaterialTXT.tpwert = ArtStamm.MatGrp AND MaterialTXT.tanr = 50 AND MaterialTXT.sprache = '01' AND MaterialTXT.lfd = 1
					  AND DivneuTXT.tapkey=ArtStamm.TapKey_DivNeu AND DivneuTXT.tpwert = ArtStamm.DivNeu AND DivneuTXT.tanr = 600 AND DivneuTXT.sprache = '01' AND DivneuTXT.lfd = 1
					  AND SegmentTXT.tapkey=ArtStamm.TapKey_Segment AND SegmentTXT.tpwert = ArtStamm.Segment AND SegmentTXT.tanr = 601 AND SegmentTXT.sprache = '01' AND SegmentTXT.lfd = 1
					  AND dbo_ArtGroessen2.ArtsNr1=ArtEAN.ArtsNr1 and dbo_ArtGroessen2.ArtsNr2=ArtEAN.ArtsNr2 and dbo_ArtGroessen2.ArtsKey=ArtEAN.ArtsKey and  dbo_ArtGroessen2.gr=ArtEAN.gr
					  AND Farbe.tapkey = ArtFarben.TapKey_VerkFarbe AND Farbe.tpwert = ArtFarben.VerkFarbe AND Farbe.tanr = 77 AND Farbe.sprache = '01' AND Farbe.lfd = 1
					  AND MatzusTXT.tapkey=ArtStamm.TapKey_MatZus AND MatzusTXT.tpwert = ArtStamm.MatZus AND MatzusTXT.tanr = 44 AND MatzusTXT.sprache = '01' AND MatzusTXT.lfd = 1
					  --full list for current season
					  AND ArtStamm.ArtsKey  IN  (@SeasonNext)  					  
					  --for all defined pricelists
					  AND  ArPreisLst.PreisListe  IN (select ks.PreisLst from [POS_NL].[dbo].[RetailPro_Config_Store] rps, [INTEXSALES].[OdloDE].dbo.[KuStamm] ks where rps.customernum = ks.kusnr and rps.StoreType <> 'OUTLET')
					  --below commented out to only get new styles (the new styles will get filtered later
					  --and ((ArtStamm.Neu > @StylesCreatedPastDaysNextSeason) OR (ArtFarben.Neu > @StylesCreatedPastDaysNextSeason) OR (dbo_ArtGroessen2.Neu >@StylesCreatedPastDaysNextSeason ))
					  and isnumeric (ArtStamm.ArtsNr1) <> 0

	
	COMMIT TRANSACTION
	PRINT 'END fill table RetailPro_PriCat2_Raw: '  + CONVERT(VARCHAR(50), getdate(), 113)




	--*************************************************************************************************************************************
	--FILL RAW DATA for PriCat
	-- a) all new styles for current season 
	-- b) all new styles for next season which are not in the current season at all
	--*************************************************************************************************************************************
	BEGIN TRANSACTION

	PRINT 'START fill table RetailPro_PriCat_Raw (both seasons): '  + CONVERT(VARCHAR(50), getdate(), 113)

	TRUNCATE TABLE [dbo].RetailPro_PriCat_Raw;
	----------------------------------------------------------------------------------------------------------------------------------------
	--Fill in all outlet styles
	----------------------------------------------------------------------------------------------------------------------------------------
	--a) fill in current season styles which were only created recently
	INSERT INTO RetailPro_PriCat_Raw select * from RetailPro_PriCat1_Raw where StoreType = 'OUTLET' AND EAN like '76%' and ((CreationDate > @StylesCreatedPastDays_Outlet) OR (CreationDatePrice > @StylesCreatedPastDays_Outlet))
	--b) fill in next season stlyes which were only created recently and which do not exist at all in the existing season
	INSERT INTO RetailPro_PriCat_Raw select * from RetailPro_PriCat2_Raw where StoreType = 'OUTLET' AND EAN like '76%' and ((CreationDate > @StylesCreatedPastDays_Outlet) OR (CreationDatePrice > @StylesCreatedPastDays_Outlet)) and [EAN] not in (select EAN from RetailPro_PriCat1_Raw)
	
	----------------------------------------------------------------------------------------------------------------------------------------
	--Fill in all NON OUTLET styles
	----------------------------------------------------------------------------------------------------------------------------------------
	--a) fill in current season styles which were only created recently
	INSERT INTO RetailPro_PriCat_Raw select * from RetailPro_PriCat1_Raw where StoreType <> 'OUTLET' AND EAN like '76%' and ((CreationDate > @StylesCreatedPastDays) OR (CreationDatePrice > @StylesCreatedPastDays))
	--b) fill in next season stlyes which were only created recently and which do not exist at all in the existing season
	INSERT INTO RetailPro_PriCat_Raw select * from RetailPro_PriCat2_Raw where StoreType <> 'OUTLET' AND EAN like '76%' and ((CreationDate > @StylesCreatedPastDays) OR (CreationDatePrice > @StylesCreatedPastDays)) and [EAN] not in (select EAN from RetailPro_PriCat1_Raw)

	COMMIT TRANSACTION
	PRINT 'END fill table RetailPro_PriCat_Raw: '  + CONVERT(VARCHAR(50), getdate(), 113)


	--*************************************************************************************************************************************
	--Update Outlet prices (they need to have the original price marked as well - so we need to show the 'base' price in addition
	-- outlets do have price list 201 assigned, so update all records with price list 201 and add the 
	-- price list 203 represents standard brand store price list in france
	--*************************************************************************************************************************************
	--Update price on price list 201 where we find a price in price list 203
	BEGIN TRANSACTION
	PRINT 'START update price retail base (201): '  + CONVERT(VARCHAR(50), getdate(), 113)
	UPDATE  pc
		SET pc.PriceRetailBase = pl.vkPreis,
			pc.PriceListBase = pl.PreisListe
		FROM [POS_NL].[dbo].[RetailPro_PriCat_Raw] as pc
			INNER JOIN INTEXSALES.OdloDE.dbo.ArPreisLst as pl 
				ON	pc.Article = pl.ArtsNr1 COLLATE SQL_Latin1_General_CP1_CS_AS and 
					pc.Color = pl.VerkFarbe COLLATE SQL_Latin1_General_CP1_CS_AS and
					pc.Season = pl.ArtsKey COLLATE SQL_Latin1_General_CP1_CS_AS and
					pc.PriceList = @RetailPriceListResolve and --201
					pl.PreisListe = @RetailPriceListBase --203
					
	PRINT 'END update price retail base: '  + CONVERT(VARCHAR(50), getdate(), 113)
	commit transaction

	--update base prices which were not found (and are still empty) with the regular retail price	
	--these are all non outlet prices, update there the base price with regular retail price (all non 201 price lists)
	PRINT 'START update price retail base (other than 201): '  + CONVERT(VARCHAR(50), getdate(), 113)
	BEGIN TRANSACTION
	UPDATE  [POS_NL].[dbo].[RetailPro_PriCat_Raw]
		SET PriceRetailBase = PriceRetail,
			PriceListBase = PriceList
		where PriceList <> @RetailPriceListResolve
	commit transaction

	--format non/empty prices into 0.00
	BEGIN TRANSACTION
	UPDATE  [POS_NL].[dbo].[RetailPro_PriCat_Raw]
		SET PriceRetailBase = '0.00'
		where PriceRetailBase = ''
	commit transaction
	PRINT 'END update price retail base (other than 201): '  + CONVERT(VARCHAR(50), getdate(), 113)
	
	--*************************************************************************************************************************************
	--Special character cleanout
	--*************************************************************************************************************************************
	BEGIN TRANSACTION

	PRINT 'Start replacing characters'  + CONVERT(VARCHAR(50), getdate(), 113)

	--Article description	
	UPDATE [POS_NL].[dbo].[RetailPro_PriCat_Raw]
		SET [ArticleDesc] = left(dbo.RetailPro_ReplaceString(ArticleDesc),30) ,
			[ProdGroupText] = left(dbo.RetailPro_ReplaceString(ProdGroupText),20),
			[FedasText] = dbo.RetailPro_ReplaceString(FedasText),
			[MatGrpText] = dbo.RetailPro_ReplaceString(MatGrpText),
			[MatZusText] = dbo.RetailPro_ReplaceString(MatZusText),
			[SegmentText] = dbo.RetailPro_ReplaceString(SegmentText),
			[CategoryText] = dbo.RetailPro_ReplaceString(CategoryText),
			[ColorText] = left(dbo.RetailPro_ReplaceString(ColorText),30),
			[ArtGroupText] = dbo.RetailPro_ReplaceString(ArtGroupText)

	PRINT 'End replacing characters'  + CONVERT(VARCHAR(50), getdate(), 113)

	commit transaction

END 

























































GO
