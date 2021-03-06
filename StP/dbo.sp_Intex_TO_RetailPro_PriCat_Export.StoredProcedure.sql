/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_Intex_TO_RetailPro_PriCat_Export]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





































CREATE PROCEDURE [dbo].[sp_Intex_TO_RetailPro_PriCat_Export]

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
	DECLARE @customerNum varchar(20);
	DECLARE @storeGroupNum varchar(20);
	DECLARE @TodayFullDate varchar(50);

	DECLARE storeGroupList CURSOR
		FOR SELECT distinct store.StoreGroupNum, (select TOP 1 customerNum from [POS_NL].[dbo].[RetailPro_Config_Store] ks where ks.StoreGroupNum = store.StoreGroupNum) test    from [POS_NL].[dbo].[RetailPro_Config_Store] store



	--*************************************************************************************************************************************
	--Init variables
	--*************************************************************************************************************************************
	--Set @TodayFullDate = convert(varchar,datepart(year, getdate())) + '-' +  RIGHT('00' + convert(varchar,datepart(month, getdate())),2) + '-' + right('00' + datepart(DAY, getdate()),2) + 'T' + right('00' + convert(varchar,datepart(HOUR, getdate())),2) + ':' + right('00' + convert(varchar,datepart(MINUTE, getdate())),2) + ':' + right('00' + convert(varchar,datepart(SECOND, getdate())),2) + '+01:00'
	Set @TodayFullDate = convert(varchar,datepart(year, getdate())) + '-' +  RIGHT('00' + convert(varchar,datepart(month, getdate())),2) + '-' + right('00' + convert(varchar,datepart(DAY, getdate())),2) + 'T' + right('00' + convert(varchar,datepart(HOUR, getdate())),2) + ':' + right('00' + convert(varchar,datepart(MINUTE, getdate())),2) + ':' + right('00' + convert(varchar,datepart(SECOND, getdate())),2) + '+01:00'
	
	
	--*************************************************************************************************************************************
	-- PRICAT FILE
	--*************************************************************************************************************************************	
	--Loop through the customers
	OPEN storeGroupList  
	FETCH NEXT FROM storeGroupList   
	INTO @storeGroupNum, @customerNum

  
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		PRINT 'START till table RetailPro_PriCat for store group ' +  @storeGroupNum + ' including e.g. customer ' + @customerNum +  ': '  + CONVERT(VARCHAR(50), getdate(), 131)
		PRINT 'TAG1'
		BEGIN TRANSACTION
		--prepate file list
		--delete all pricat records
		TRUNCATE TABLE [dbo].[RetailPro_PRICAT];

		--VERIFIED - OK - INSERT LEVEL 1 - INVENTORY (Tag1)
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	1 TAG, null PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						null,null,
						null,
						null,null,null,null,null,
						1 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_Config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays


		--VERIFIED - OK - INSERT LEVEL 2 - INVN_STYLE (Tag2)
		PRINT 'TAG2'
		INSERT INTO  [dbo].[RetailPro_PriCat] 
				SELECT	2 TAG, 1 PARENT,
						null [inventory!1!tmp],
						pcr.[Article] [invn_style!2!style_sid], '' [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						null,null,
						null,
						null,null,null,null,null,
						2 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_Config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays

		--VERIFIED - OK - INSERT LEVEL 3 - INVN (Tag3)
		PRINT 'TAG3'
		INSERT INTO  [dbo].[RetailPro_PriCat] 
		SELECT	3 TAG, 1 PARENT,
				null [inventory!1!tmp],
				null [invn_style!2!style_sid], null [invn_style!2!style_code],
				[EAN] + REPLICATE('0',19-len([EAN])) [invn!3!item_sid], [EAN] [invn!3!upc], 0 [invn!3!use_qty_decimals],
				null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
				null,
				null,null,
				null,
				null,null,null,null,null,
				3 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
		from	[POS_NL].[dbo].[RetailPro_Config_Store] rps,
				[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
				[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
		WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
				and ks.KusNr = @customerNum
				--and pcr.CreationDate > @StylesCreatedPastDays

		--VERIFIED - GAPS - scale_no - INSERT LEVEL 4 - INVN_SBS (Tag4)
		PRINT 'TAG4'
		INSERT INTO  [dbo].[RetailPro_PriCat] 
		SELECT	4 TAG, 1 PARENT,
				null [inventory!1!tmp],
				null [invn_style!2!style_sid], null [invn_style!2!style_code],
				null [invn!3!item_sid], null [invn!3!upc], null [invn!3!use_qty_decimals],
				--rps.StoreGroupNum [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], [DCS_Code] [invn_sbs!4!dcs_code], '2' [invn_sbs!4!vend_code], size.sizeCode [inv_sbs!4!scale_no], pcr.[Article] [invn_sbs!4!description1], pcr.ArtGroupText [invn_sbs!4!description2], '' [invn_sbs!4!description3], pcr.ColorText [invn_sbs!4!description4],  pcr.[Size] [invn_sbs!4!siz], [PriceTrade] [invn_sbs!4!lst_rcvd_cost], [Color] [invn_sbs!4!attr],  '' [invn_sbs!4!fc_cost], @TodayFullDate [invn_sbs!4!created_date], @TodayFullDate  [invn_sbs!4!modified_date], '0' [invn_sbs!4!tax_code], '0' [invn_sbs!4!flag], '0' [invn_sbs!4!ext_flag], '' [invn_sbs!4!edi_flag], '0' [invn_sbs!4!kit_type], '100' [invn_sbs!4!max_disc_perc1], '100' [invn_sbs!4!max_disc_perc2], '0' [invn_sbs!4!unorderable], '1' [invn_sbs!4!print_tag], '1' [invn_sbs!4!active], '0' [invn_sbs!4!cms], '0' [invn_sbs!4!regional], 'EUR' [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
				rps.StoreGroupNum [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], [DCS_Code] [invn_sbs!4!dcs_code], '2' [invn_sbs!4!vend_code], size.sizeCode [inv_sbs!4!scale_no], pcr.[Article] [invn_sbs!4!description1], pcr.ArticleDesc [invn_sbs!4!description2], '' [invn_sbs!4!description3], pcr.ColorText [invn_sbs!4!description4],  pcr.[Size] [invn_sbs!4!siz], [PriceTrade] [invn_sbs!4!lst_rcvd_cost], [Color] [invn_sbs!4!attr],  '' [invn_sbs!4!fc_cost], @TodayFullDate [invn_sbs!4!created_date], @TodayFullDate  [invn_sbs!4!modified_date], '0' [invn_sbs!4!tax_code], '0' [invn_sbs!4!flag], '0' [invn_sbs!4!ext_flag], '' [invn_sbs!4!edi_flag], '0' [invn_sbs!4!kit_type], '100' [invn_sbs!4!max_disc_perc1], '100' [invn_sbs!4!max_disc_perc2], '0' [invn_sbs!4!unorderable], '1' [invn_sbs!4!print_tag], '1' [invn_sbs!4!active], '0' [invn_sbs!4!cms], '0' [invn_sbs!4!regional], 'EUR' [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
				null,
				null,null,
				null,
				null,null,null,null,null,
				4 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
		from	[POS_NL].[dbo].[RetailPro_Config_Store] rps,
				[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
				[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr,
				[POS_NL].[dbo].[RetailPro_Config_Size] size
		WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
				and pcr.size = size.size
				and ks.KusNr = @customerNum
				--and pcr.CreationDate > @StylesCreatedPastDays

		--verified - ok - INSERT LEVEL 5 - INVN_SBS_SUPPLS INVENTORY (Tag5)
		PRINT 'TAG5'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	5 TAG, 4 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null  [invn_sbs_suppls!5!tmp],
						null,null,
						null,
						null,null,null,null,null,
						5 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_Config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays

		--VERIFIED - OK - INSERT LEVEL 6 - INVN_SBS_SUPPL INVENTORY (Tag6)
		--1
		PRINT 'TAG6 - 1'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	6 TAG, 5 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						1 [invn_sbs_suppl!6!udf_no],'' [invn_sbs_suppl!6!udf_value],
						null,
						null,null,null,null,null,
						6 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays
		--2
		PRINT 'TAG6 - 2'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	6 TAG, 5 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						2 [invn_sbs_suppl!6!udf_no],'' [invn_sbs_suppl!6!udf_value],
						null,
						null,null,null,null,null,
						6 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays
		--3
		PRINT 'TAG6 - 3'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	6 TAG, 5 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						3 [invn_sbs_suppl!6!udf_no],'' [invn_sbs_suppl!6!udf_value],
						null,
						null,null,null,null,null,
						6 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays
		--4
		PRINT 'TAG6 - 4'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	6 TAG, 5 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						4 [invn_sbs_suppl!6!udf_no],'' [invn_sbs_suppl!6!udf_value],
						null,
						null,null,null,null,null,
						6 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays
		--5
		PRINT 'TAG6 - 5'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	6 TAG, 5 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz],null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],   null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						5 [invn_sbs_suppl!6!udf_no],'' [invn_sbs_suppl!6!udf_value],
						null, 
						null,null,null,null,null,
						6 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays
		--6
		PRINT 'TAG6 - 6'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	6 TAG, 5 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						6 [invn_sbs_suppl!6!udf_no],'' [invn_sbs_suppl!6!udf_value],
						null,
						null,null,null,null,null,
						6 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays
		--7
		PRINT 'TAG6 - 7'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	6 TAG, 5 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						7 [invn_sbs_suppl!6!udf_no],[Season] [invn_sbs_suppl!6!udf_value],
						null,
						null,null,null,null,null,
						6 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays
		--8
		PRINT 'TAG6 - 8'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	6 TAG, 5 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						8 [invn_sbs_suppl!6!udf_no], [MatZus] [invn_sbs_suppl!6!udf_value],
						null,
						null,null,null,null,null,
						6 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays
		--9
		PRINT 'TAG6 - 9'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	6 TAG, 5 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						9 [invn_sbs_suppl!6!udf_no], [SegmentText] [invn_sbs_suppl!6!udf_value],
						null,
						null,null,null,null,null,
						6 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays
		--10
		PRINT 'TAG6 - 10'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	6 TAG, 5 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						10 [invn_sbs_suppl!6!udf_no], [Article] [invn_sbs_suppl!6!udf_value],
						null,
						null,null,null,null,null,
						6 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays
		--11
		PRINT 'TAG6 - 11'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	6 TAG, 5 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						11 [invn_sbs_suppl!6!udf_no], [MatGrpText] [invn_sbs_suppl!6!udf_value],
						null,
						null,null,null,null,null,
						6 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays
		--12
		PRINT 'TAG6 - 12'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	6 TAG, 5 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						12 [invn_sbs_suppl!6!udf_no],'' [invn_sbs_suppl!6!udf_value],
						null,
						null,null,null,null,null,
						6 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays
		--13
		PRINT 'TAG6 - 13'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	6 TAG, 5 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						13 [invn_sbs_suppl!6!udf_no], [ArtGroupText] [invn_sbs_suppl!6!udf_value],
						null,
						null,null,null,null,null,
						6 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays
		--14
		PRINT 'TAG6 - 14'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	6 TAG, 5 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						14 [invn_sbs_suppl!6!udf_no],'' [invn_sbs_suppl!6!udf_value],
						null,
						null,null,null,null,null,
						6 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays

		--INSERT LEVEL 7 - INVN_SBS_PRICES INVENTORY (Tag7)
		PRINT 'TAG7'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	7 TAG, 4 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						null [invn_sbs_suppl!6!udf_no], null [invn_sbs_suppl!6!udf_value],
						null [invn_sbs_prices!7!tmp],
						null,null,null,null,null,
						7 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays

	
		--INSERT LEVEL 8 - INVN_SBS_PRICE INVENTORY (Tag8)
		--1
		PRINT 'TAG8 - 1'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	8 TAG, 7 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						null [invn_sbs_suppl!6!udf_no], null [invn_sbs_suppl!6!udf_value],
						null [invn_sbs_prices!7!tmp],
						--'1' [invn_sbs_price!8!price_lvl], [PriceRetail] [invn_sbs_price!8!price], '' [invn_sbs_price!8!qty_req], 'None' [invn_sbs_price!8!season_code], '0' [invn_sbs_price!8!active_season],
						'1' [invn_sbs_price!8!price_lvl], [PriceRetailBase] [invn_sbs_price!8!price], '' [invn_sbs_price!8!qty_req], 'None' [invn_sbs_price!8!season_code], '0' [invn_sbs_price!8!active_season],
						8 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays
		--2
		PRINT 'TAG8 - 2'
		INSERT INTO  [dbo].[RetailPro_PriCat]
				SELECT	8 TAG, 7 PARENT,
						null [inventory!1!tmp],
						null [invn_style!2!style_sid], null [invn_style!2!style_code],
						null [invn!3!item_sid],null [invn!3!upc],null [invn!3!use_qty_decimals],
						null [invn_sbs!4!sbs_no], null [invn_sbs!4!alu], null [invn_sbs!4!dcs_code], null [invn_sbs!4!vend_code], null [invn_sbs!4!scale_no], null [invn_sbs!4!description1], null [invn_sbs!4!description2], null [invn_sbs!4!description3], null [invn_sbs!4!description4], null [invn_sbs!4!siz], null [invn_sbs!4!lst_rcvd_cost], null [invn_sbs!4!attr],  null [invn_sbs!4!fc_cost], null [invn_sbs!4!created_date], null [invn_sbs!4!modified_date], null [invn_sbs!4!tax_code], null [invn_sbs!4!flag], null [invn_sbs!4!ext_flag], null [invn_sbs!4!edi_flag], null [invn_sbs!4!kit_type], null [invn_sbs!4!max_disc_perc1], null [invn_sbs!4!max_disc_perc2], null [invn_sbs!4!unorderable], null [invn_sbs!4!print_tag], null [invn_sbs!4!active], null [invn_sbs!4!cms], null [invn_sbs!4!regional], null [invn_sbs!4!currency_name], null [invn_sbs!4!fst_price],
						null,
						null [invn_sbs_suppl!6!udf_no], null [invn_sbs_suppl!6!udf_value],
						null [invn_sbs_prices!7!tmp],
						--'2' [invn_sbs_price!8!price_lvl],  [PriceRetailBase] [invn_sbs_price!8!price], '' [invn_sbs_price!8!qty_req], 'None' [invn_sbs_price!8!season_code], '0' [invn_sbs_price!8!active_season],
						'2' [invn_sbs_price!8!price_lvl], [PriceRetail] [invn_sbs_price!8!price], '' [invn_sbs_price!8!qty_req], 'None' [invn_sbs_price!8!season_code], '0' [invn_sbs_price!8!active_season],
						8 [SORT!99!TAGID] , [EAN] [SORT!99!EANID]
				from	[POS_NL].[dbo].[RetailPro_config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum
						--and pcr.CreationDate > @StylesCreatedPastDays



		COMMIT TRANSACTION

		PRINT 'END till table RetailPro_PriCat for customer ' + @customerNum +  ': '  + CONVERT(VARCHAR(50), getdate(), 131)
		PRINT 'START XML export RetailPro_PriCat for customer ' + @customerNum +  ': '  + CONVERT(VARCHAR(50), getdate(), 131)

		--Create XML File for specific customer		
		Set @path = (select conf.value from retailPro_config conf where conf.id = 'ExportPathPriCat')
		--print 'PriCat Path: ' + @path
		Set @path = @path + RIGHT('000' + @storeGroupNum,3) + '000Z' + '\IN\RECVD\'
		print 'PriCat Path: ' + @path
		Set @file = (select conf.value from retailPro_config conf where conf.id = 'ExportFileNamePriCat')	
		SET @filedate = ''
		SET @fileext='.xml'
		SET @fullpath=@path + @file + @fileext;
		print '  XML export to: ' + @fullpath

		SET @string='bcp "SELECT * FROM [POS_NL].[dbo].[RetailPro_PriCat] ORDER BY [SORT!99!EANID], [SORT!99!TAGID],convert(int,[INVN_SBS_SUPPL!6!udf_no]), convert(int,[INVN_SBS_PRICE!8!price_lvl]) for xml explicit, TYPE,ROOT(''INVENTORYS'')" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S'

		BEGIN TRY
			EXEC xp_cmdshell @string
		END TRY
		BEGIN CATCH
			PRINT 'RetailPro Export - PriCat - File Creation failed'
			EXEC msdb.dbo.sp_send_dbmail 
				@recipients='markus.pfyl@odlo.com',
				@from_address='sql@odlo.com',
				@subject='RetailPro Export - PriCat - File Creation failed',
				@reply_to='markus.pfyl@odlo.com',
				@importance='High',
				@body='RetailPro Export - PriCat - File Creation failed for store group ' , 
				@body_format='HTML';
		END CATCH

		PRINT 'END XML export RetailPro_PriCat for customer ' + @customerNum +  ': '  + CONVERT(VARCHAR(50), getdate(), 131)

		--get next store group
		FETCH NEXT FROM storeGroupList   
		INTO @storeGroupNum, @customerNum  
	END

	CLOSE storeGroupList;  
	DEALLOCATE storeGroupList;  


END 




































GO
