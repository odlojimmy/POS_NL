/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_Intex_TO_RetailPro_ASN_Export]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

























CREATE PROCEDURE [dbo].[sp_Intex_TO_RetailPro_ASN_Export]

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
	DECLARE @odloEntity varchar(8);
	DECLARE @customerNum varchar(20);
	DECLARE @storeGroupNum varchar(20);
	DECLARE @StoreIDWithinGroup varchar(20);
	DECLARE @TodayFullDate varchar(50);
	DECLARE @BodyText varchar(500);
	DECLARE @LogMessages varchar(1);

	DECLARE storeList CURSOR
		FOR SELECT store.[StoreGroupNum], store.StoreIDWithinGroup, store.CustomerNum from [POS_NL].[dbo].[RetailPro_Config_Store] store

	

	--*************************************************************************************************************************************
	--Init variables
	--*************************************************************************************************************************************
	Set @odloEntity = (select conf.value from retailPro_config conf where conf.id = 'OdloFREntityName')	
	Set @TodayFullDate = convert(varchar,datepart(year, getdate())) + '-' +  RIGHT('00' + convert(varchar,datepart(month, getdate())),2) + '-' + right('00' + convert(varchar,datepart(DAY, getdate())),2) + 'T' + right('00' + convert(varchar,datepart(HOUR, getdate())),2) + ':' + right('00' + convert(varchar,datepart(MINUTE, getdate())),2) + ':' + right('00' + convert(varchar,datepart(SECOND, getdate())),2) + '+01:00'
	set @LogMessages = 'N'

	print @TodayFullDate

	--*************************************************************************************************************************************
	-- ASN File
	--*************************************************************************************************************************************	
	--Loop through the customers
	OPEN storeList  
	FETCH NEXT FROM storeList   
	INTO @storeGroupNum, @StoreIDWithinGroup, @customerNum

	
	--Init Variables 

  
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		PRINT 'START fill table   - RetailPro_ASN for store (group ' +  @storeGroupNum + ', storeIDWithinGroup ' + @StoreIDWithinGroup + ', customer ' + @customerNum +  ') '  + CONVERT(VARCHAR(8), getdate(), 131)
		if (@LogMessages = 'Y') Begin PRINT 'TAG1' END
		--BEGIN TRANSACTION
		--prepate file list
		--delete all pricat records
		PRINT '  truncate table'
		TRUNCATE TABLE [dbo].[RetailPro_ASN];


		--INSERT LEVEL 2 - Voucher (Tag2)
		if (@LogMessages = 'Y') Begin PRINT 'TAG1' END
		INSERT INTO  [dbo].[RetailPro_ASN]
				SELECT	DISTINCT
						1 TAG, null PARENT,
						--tag1
						'100000000000' + asn.asn_num [Voucher!1!vou_sid], rps.StoreGroupNum [Voucher!1!sbs_no],
						rps.StoreIDWithinGroup [Voucher!1!store_no], asn.asn_num [Voucher!1!vou_no],
						'' [Voucher!1!vou_type], '2' [Voucher!1!vou_class],
						'2' [Voucher!1!vend_code], '2' [Voucher!1!payee_code],
						'1' [Voucher!1!workstation], '' [Voucher!1!orig_store_no],
						'0' [Voucher!1!status], '0' [Voucher!1!proc_status],
						'' [Voucher!1!pkg_no], asn.asn_num [Voucher!1!shipment_no],
						'0' [Voucher!1!cost_handling_code],  '0' [Voucher!1!update_price_flag],
						'1' [Voucher!1!use_vat],
						@TodayFullDate [Voucher!1!created_date], @TodayFullDate [Voucher!1!modified_date],
						'0' [Voucher!1!audited], '1' [Voucher!1!cms],
						'0' [Voucher!1!verified], '0' [Voucher!1!held],
						'1' [Voucher!1!active], '1' [Voucher!1!rate],
						'1' [Voucher!1!controller], '1' [Voucher!1!orig_controller],
						'0' [Voucher!1!slip_flag], '0' [Voucher!1!pending_override],
						rps.StoreGroupNum [Voucher!1!empl_sbs_no], @odloEntity [Voucher!1!empl_name],
						'FRANCE' [Voucher!1!tax_area_name], rps.StoreGroupNum [Voucher!1!approvby_sbs_no],
						@odloEntity [Voucher!1!approvby_empl_name],
						rps.StoreGroupNum [Voucher!1!createdby_sbs_no], @odloEntity [Voucher!1!createdby_empl_name],
						rps.StoreGroupNum [Voucher!1!modifiedby_sbs_no], @odloEntity [Voucher!1!modifiedby_empl_name],
						--tag2
						null [Vend_Invoice!2!temp],
						--tag3
						null [Vou_Comments!3!temp],
						--tag4
						null [Vou_Comment!4!comment_no], null [Vou_Comment!4!comments],
						--tag5
						null [Vou_Items!5!temp],
						--tag6
						null [Vou_Item!6!item_pos], null [Vou_Item!6!item_sid],
						null [Vou_Item!6!qty], null [Vou_Item!6!orig_qty],
						null [Vou_Item!6!cost], null [Vou_Item!6!fc_cost],
						null [Vou_Item!6!tax_code], null [Vou_Item!6!currency_name],

						--end with tagid
						1 [SORT!99!TAGID], asn.asn_num [SORT!99!ASN]												
				from	[POS_NL].[dbo].[RetailPro_Config_Store] rps,
						[POS_NL].[dbo].[RetailPro_ASN_Raw] asn
				WHERE	asn.[CUSTOMER_NUM] = rps.[CustomerNum] AND
						asn.[CUSTOMER_NUM] = @customerNum

		--INSERT LEVEL 2 - Vend_Invoice (Tag2)
		if (@LogMessages = 'Y') Begin PRINT 'TAG2' END
		INSERT INTO  [dbo].[RetailPro_ASN]
				SELECT	DISTINCT 2 TAG, 1 PARENT,
						--tag1
						null [Voucher!1!vou_sid], null [Voucher!1!sbs_no],
						null [Voucher!1!store_no], null [Voucher!1!vou_no],
						null [Voucher!1!vou_type], null [Voucher!1!vou_class],
						null [Voucher!1!vend_code], null [Voucher!1!payee_code],
						null [Voucher!1!workstation], null  [Voucher!1!orig_store_no],
						null [Voucher!1!status], null [Voucher!1!proc_status],
						null [Voucher!1!pkg_no], null [Voucher!1!shipment_no],
						null [Voucher!1!cost_handling_code], null [Voucher!1!update_price_flag],
						null [Voucher!1!use_vat],
						null [Voucher!1!created_date], null [Voucher!1!modified_date],
						null [Voucher!1!audited], null [Voucher!1!cms], 
						null [Voucher!1!verified], null [Voucher!1!held],
						null [Voucher!1!active], null [Voucher!1!rate],
						null [Voucher!1!controller], null [Voucher!1!orig_controller],
						null [Voucher!1!slip_flag], null [Voucher!1!pending_override],
						null [Voucher!1!empl_sbs_no], null [Voucher!1!empl_name],
						null [Voucher!1!tax_area_name], null [Voucher!1!approvby_sbs_no],
						null [Voucher!1!approvby_empl_name],
						null [Voucher!1!createdby_sbs_no], null [Voucher!1!createdby_empl_name],
						null [Voucher!1!modifiedby_sbs_no], null [Voucher!1!modifiedby_empl_name],
						--tag2
						null [Vend_Invoice!2!temp],						
						--tag3
						null [Vou_Comments!3!temp],
						--tag4
						null [Vou_Comment!4!comment_no], null [Vou_Comment!4!comments],
						--tag5
						null [Vou_Items!5!temp],
						--tag6
						null [Vou_Item!6!item_pos], null [Vou_Item!6!item_sid],
						null [Vou_Item!6!qty], null [Vou_Item!6!orig_qty],
						null [Vou_Item!6!cost], null [Vou_Item!6!fc_cost],
						null [Vou_Item!6!tax_code], null [Vou_Item!6!currency_name],

						--end with tagid
						2 [SORT!99!TAGID], asn.asn_num [SORT!99!ASN]												
				from	[POS_NL].[dbo].[RetailPro_Config_Store] rps,
						[POS_NL].[dbo].[RetailPro_ASN_Raw] asn
				WHERE	asn.[CUSTOMER_NUM] = rps.[CustomerNum] AND
						asn.[CUSTOMER_NUM] = @customerNum

		--INSERT LEVEL 3 - Vou_Comments (Tag3)
		if (@LogMessages = 'Y') Begin PRINT 'TAG3' END
		INSERT INTO  [dbo].[RetailPro_ASN]
				SELECT	DISTINCT 3 TAG, 1 PARENT,
						--tag1
						null [Voucher!1!vou_sid], null [Voucher!1!sbs_no],
						null [Voucher!1!store_no], null [Voucher!1!vou_no],
						null [Voucher!1!vou_type], null [Voucher!1!vou_class],
						null [Voucher!1!vend_code], null [Voucher!1!payee_code],
						null [Voucher!1!workstation], null  [Voucher!1!orig_store_no],
						null [Voucher!1!status], null [Voucher!1!proc_status],
						null [Voucher!1!pkg_no], null [Voucher!1!shipment_no],
						null [Voucher!1!cost_handling_code], null [Voucher!1!update_price_flag],
						null [Voucher!1!use_vat],
						null [Voucher!1!created_date], null [Voucher!1!modified_date],
						null [Voucher!1!audited], null [Voucher!1!cms], 
						null [Voucher!1!verified], null [Voucher!1!held],
						null [Voucher!1!active], null [Voucher!1!rate],
						null [Voucher!1!controller], null [Voucher!1!orig_controller],
						null [Voucher!1!slip_flag], null [Voucher!1!pending_override],
						null [Voucher!1!empl_sbs_no], null [Voucher!1!empl_name],
						null [Voucher!1!tax_area_name], null [Voucher!1!approvby_sbs_no],
						null [Voucher!1!approvby_empl_name],
						null [Voucher!1!createdby_sbs_no], null [Voucher!1!createdby_empl_name],
						null [Voucher!1!modifiedby_sbs_no], null [Voucher!1!modifiedby_empl_name],
						--tag2
						null [Vend_Invoice!2!temp],						
						--tag3
						null [Vou_Comments!3!temp],						
						--tag4
						null [Vou_Comment!4!comment_no], null [Vou_Comment!4!comments],
						--tag5
						null [Vou_Items!5!temp],
						--tag6
						null [Vou_Item!6!item_pos], null [Vou_Item!6!item_sid],
						null [Vou_Item!6!qty], null [Vou_Item!6!orig_qty],
						null [Vou_Item!6!cost], null [Vou_Item!6!fc_cost],
						null [Vou_Item!6!tax_code], null [Vou_Item!6!currency_name],

						--end with tagid
						3 [SORT!99!TAGID], asn.asn_num [SORT!99!ASN]												
				from	[POS_NL].[dbo].[RetailPro_Config_Store] rps,
						[POS_NL].[dbo].[RetailPro_ASN_Raw] asn
				WHERE	asn.[CUSTOMER_NUM] = rps.[CustomerNum] AND
						asn.[CUSTOMER_NUM] = @customerNum

		if (@LogMessages = 'Y') Begin PRINT 'TAG4 - a' END
		INSERT INTO  [dbo].[RetailPro_ASN]
				SELECT	DISTINCT 4 TAG, 3 PARENT,
						--tag1
						null [Voucher!1!vou_sid], null [Voucher!1!sbs_no],
						null [Voucher!1!store_no], null [Voucher!1!vou_no],
						null [Voucher!1!vou_type], null [Voucher!1!vou_class],
						null [Voucher!1!vend_code], null [Voucher!1!payee_code],
						null [Voucher!1!workstation], null  [Voucher!1!orig_store_no],
						null [Voucher!1!status], null [Voucher!1!proc_status],
						null [Voucher!1!pkg_no], null [Voucher!1!shipment_no],
						null [Voucher!1!cost_handling_code], null [Voucher!1!update_price_flag],
						null [Voucher!1!use_vat],
						null [Voucher!1!created_date], null [Voucher!1!modified_date],
						null [Voucher!1!audited], null [Voucher!1!cms], 
						null [Voucher!1!verified], null [Voucher!1!held],
						null [Voucher!1!active], null [Voucher!1!rate],
						null [Voucher!1!controller], null [Voucher!1!orig_controller],
						null [Voucher!1!slip_flag], null [Voucher!1!pending_override],
						null [Voucher!1!empl_sbs_no], null [Voucher!1!empl_name],
						null [Voucher!1!tax_area_name], null [Voucher!1!approvby_sbs_no],
						null [Voucher!1!approvby_empl_name],
						null [Voucher!1!createdby_sbs_no], null [Voucher!1!createdby_empl_name],
						null [Voucher!1!modifiedby_sbs_no], null [Voucher!1!modifiedby_empl_name],
						--tag2
						null [Vend_Invoice!2!temp],		
						--tag3
						null [Vou_Comments!3!temp],										
						--tag4
						'1' [Vou_Comment!4!comment_no], 'Code Client: ' + asn.CUSTOMER_NUM [Vou_Comment!4!comments],
						--tag5
						null [Vou_Items!5!temp],
						--tag6
						null [Vou_Item!6!item_pos], null [Vou_Item!6!item_sid],
						null [Vou_Item!6!qty], null [Vou_Item!6!orig_qty],
						null [Vou_Item!6!cost], null [Vou_Item!6!fc_cost],
						null [Vou_Item!6!tax_code], null [Vou_Item!6!currency_name],

						--end with tagid
						4 [SORT!99!TAGID], asn.asn_num [SORT!99!ASN]												
				from	[POS_NL].[dbo].[RetailPro_Config_Store] rps,
						[POS_NL].[dbo].[RetailPro_ASN_Raw] asn
				WHERE	asn.[CUSTOMER_NUM] = rps.[CustomerNum] AND
						asn.[CUSTOMER_NUM] = @customerNum

		if (@LogMessages = 'Y') Begin PRINT 'TAG4 - b' END
		INSERT INTO  [dbo].[RetailPro_ASN]
				SELECT	DISTINCT 4 TAG, 3 PARENT,
						--tag1
						null [Voucher!1!vou_sid], null [Voucher!1!sbs_no],
						null [Voucher!1!store_no], null [Voucher!1!vou_no],
						null [Voucher!1!vou_type], null [Voucher!1!vou_class],
						null [Voucher!1!vend_code], null [Voucher!1!payee_code],
						null [Voucher!1!workstation], null  [Voucher!1!orig_store_no],
						null [Voucher!1!status], null [Voucher!1!proc_status],
						null [Voucher!1!pkg_no], null [Voucher!1!shipment_no],
						null [Voucher!1!cost_handling_code], null [Voucher!1!update_price_flag],
						null [Voucher!1!use_vat],
						null [Voucher!1!created_date], null [Voucher!1!modified_date],
						null [Voucher!1!audited], null [Voucher!1!cms], 
						null [Voucher!1!verified], null [Voucher!1!held],
						null [Voucher!1!active], null [Voucher!1!rate],
						null [Voucher!1!controller], null [Voucher!1!orig_controller],
						null [Voucher!1!slip_flag], null [Voucher!1!pending_override],
						null [Voucher!1!empl_sbs_no], null [Voucher!1!empl_name],
						null [Voucher!1!tax_area_name], null [Voucher!1!approvby_sbs_no],
						null [Voucher!1!approvby_empl_name],
						null [Voucher!1!createdby_sbs_no], null [Voucher!1!createdby_empl_name],
						null [Voucher!1!modifiedby_sbs_no], null [Voucher!1!modifiedby_empl_name],
						--tag2
						null [Vend_Invoice!2!temp],	
						--tag3
						null [Vou_Comments!3!temp],															
						--tag4
						'2' [Vou_Comment!4!comment_no], 'Date BL: ' + asn.ASN_DATE [Vou_Comment!4!comments],
						--tag5
						null [Vou_Items!5!temp],
						--tag6
						null [Vou_Item!6!item_pos], null [Vou_Item!6!item_sid],
						null [Vou_Item!6!qty], null [Vou_Item!6!orig_qty],
						null [Vou_Item!6!cost], null [Vou_Item!6!fc_cost],
						null [Vou_Item!6!tax_code], null [Vou_Item!6!currency_name],

						--end with tagid
						4 [SORT!99!TAGID], asn.asn_num [SORT!99!ASN]												
				from	[POS_NL].[dbo].[RetailPro_Config_Store] rps,
						[POS_NL].[dbo].[RetailPro_ASN_Raw] asn
				WHERE	asn.[CUSTOMER_NUM] = rps.[CustomerNum] AND
						asn.[CUSTOMER_NUM] = @customerNum

		if (@LogMessages = 'Y') Begin  PRINT 'TAG4 - c' END
		INSERT INTO  [dbo].[RetailPro_ASN]
				SELECT	DISTINCT 4 TAG, 3 PARENT,
						--tag1
						null [Voucher!1!vou_sid], null [Voucher!1!sbs_no],
						null [Voucher!1!store_no], null [Voucher!1!vou_no],
						null [Voucher!1!vou_type], null [Voucher!1!vou_class],
						null [Voucher!1!vend_code], null [Voucher!1!payee_code],
						null [Voucher!1!workstation], null  [Voucher!1!orig_store_no],
						null [Voucher!1!status], null [Voucher!1!proc_status],
						null [Voucher!1!pkg_no], null [Voucher!1!shipment_no],
						null [Voucher!1!cost_handling_code], null [Voucher!1!update_price_flag],
						null [Voucher!1!use_vat],
						null [Voucher!1!created_date], null [Voucher!1!modified_date],
						null [Voucher!1!audited], null [Voucher!1!cms], 
						null [Voucher!1!verified], null [Voucher!1!held],
						null [Voucher!1!active], null [Voucher!1!rate],
						null [Voucher!1!controller], null [Voucher!1!orig_controller],
						null [Voucher!1!slip_flag], null [Voucher!1!pending_override],
						null [Voucher!1!empl_sbs_no], null [Voucher!1!empl_name],
						null [Voucher!1!tax_area_name], null [Voucher!1!approvby_sbs_no],
						null [Voucher!1!approvby_empl_name],
						null [Voucher!1!createdby_sbs_no], null [Voucher!1!createdby_empl_name],
						null [Voucher!1!modifiedby_sbs_no], null [Voucher!1!modifiedby_empl_name],
						--tag2
						null [Vend_Invoice!2!temp],		
						--tag3
						null [Vou_Comments!3!temp],														
						--tag4
						'3' [Vou_Comment!4!comment_no], 'Commentaire: ' + asn.ASN_Comment [Vou_Comment!4!comments],
						--tag5
						null [Vou_Items!5!temp],
						--tag6
						null [Vou_Item!6!item_pos], null [Vou_Item!6!item_sid],
						null [Vou_Item!6!qty], null [Vou_Item!6!orig_qty],
						null [Vou_Item!6!cost], null [Vou_Item!6!fc_cost],
						null [Vou_Item!6!tax_code], null [Vou_Item!6!currency_name],

						--end with tagid
						4 [SORT!99!TAGID], asn.asn_num [SORT!99!ASN]												
				from	[POS_NL].[dbo].[RetailPro_Config_Store] rps,
						[POS_NL].[dbo].[RetailPro_ASN_Raw] asn
				WHERE	asn.[CUSTOMER_NUM] = rps.[CustomerNum] AND
						asn.[CUSTOMER_NUM] = @customerNum

		if (@LogMessages = 'Y') Begin PRINT 'TAG5' END
		INSERT INTO  [dbo].[RetailPro_ASN]
				SELECT	DISTINCT 5 TAG, 1 PARENT,
						--tag1
						null [Voucher!1!vou_sid], null [Voucher!1!sbs_no],
						null [Voucher!1!store_no], null [Voucher!1!vou_no],
						null [Voucher!1!vou_type], null [Voucher!1!vou_class],
						null [Voucher!1!vend_code], null [Voucher!1!payee_code],
						null [Voucher!1!workstation], null  [Voucher!1!orig_store_no],
						null [Voucher!1!status], null [Voucher!1!proc_status],
						null [Voucher!1!pkg_no], null [Voucher!1!shipment_no],
						null [Voucher!1!cost_handling_code], null [Voucher!1!update_price_flag],
						null [Voucher!1!use_vat],
						null [Voucher!1!created_date], null [Voucher!1!modified_date],
						null [Voucher!1!audited], null [Voucher!1!cms], 
						null [Voucher!1!verified], null [Voucher!1!held],
						null [Voucher!1!active], null [Voucher!1!rate],
						null [Voucher!1!controller], null [Voucher!1!orig_controller],
						null [Voucher!1!slip_flag], null [Voucher!1!pending_override],
						null [Voucher!1!empl_sbs_no], null [Voucher!1!empl_name],
						null [Voucher!1!tax_area_name], null [Voucher!1!approvby_sbs_no],
						null [Voucher!1!approvby_empl_name],
						null [Voucher!1!createdby_sbs_no], null [Voucher!1!createdby_empl_name],
						null [Voucher!1!modifiedby_sbs_no], null [Voucher!1!modifiedby_empl_name],
						--tag2
						null [Vend_Invoice!2!temp],		
						--tag3
						null [Vou_Comments!3!temp],														
						--tag4
						null [Vou_Comment!4!comment_no], null [Vou_Comment!4!comments],
						--tag5
						null [Vou_Items!5!temp],
						--tag6
						null [Vou_Item!6!item_pos], null [Vou_Item!6!item_sid],
						null [Vou_Item!6!qty], null [Vou_Item!6!orig_qty],
						null [Vou_Item!6!cost], null [Vou_Item!6!fc_cost],
						null [Vou_Item!6!tax_code], null [Vou_Item!6!currency_name],

						--end with tagid
						5 [SORT!99!TAGID], asn.asn_num [SORT!99!ASN]												
				from	[POS_NL].[dbo].[RetailPro_Config_Store] rps,
						[POS_NL].[dbo].[RetailPro_ASN_Raw] asn
				WHERE	asn.[CUSTOMER_NUM] = rps.[CustomerNum] AND
						asn.[CUSTOMER_NUM] = @customerNum


		if (@LogMessages = 'Y') Begin PRINT 'TAG6' END
		INSERT INTO  [dbo].[RetailPro_ASN]
				SELECT	DISTINCT 6 TAG, 5 PARENT,
						--tag1
						null [Voucher!1!vou_sid], null [Voucher!1!sbs_no],
						null [Voucher!1!store_no], null [Voucher!1!vou_no],
						null [Voucher!1!vou_type], null [Voucher!1!vou_class],
						null [Voucher!1!vend_code], null [Voucher!1!payee_code],
						null [Voucher!1!workstation], null  [Voucher!1!orig_store_no],
						null [Voucher!1!status], null [Voucher!1!proc_status],
						null [Voucher!1!pkg_no], null [Voucher!1!shipment_no],
						null [Voucher!1!cost_handling_code], null [Voucher!1!update_price_flag],
						null [Voucher!1!use_vat],
						null [Voucher!1!created_date], null [Voucher!1!modified_date],
						null [Voucher!1!audited], null [Voucher!1!cms], 
						null [Voucher!1!verified], null [Voucher!1!held],
						null [Voucher!1!active], null [Voucher!1!rate],
						null [Voucher!1!controller], null [Voucher!1!orig_controller],
						null [Voucher!1!slip_flag], null [Voucher!1!pending_override],
						null [Voucher!1!empl_sbs_no], null [Voucher!1!empl_name],
						null [Voucher!1!tax_area_name], null [Voucher!1!approvby_sbs_no],
						null [Voucher!1!approvby_empl_name],
						null [Voucher!1!createdby_sbs_no], null [Voucher!1!createdby_empl_name],
						null [Voucher!1!modifiedby_sbs_no], null [Voucher!1!modifiedby_empl_name],
						--tag2
						null [Vend_Invoice!2!temp],		
						--tag3
						null [Vou_Comments!3!temp],														
						--tag4
						null [Vou_Comment!4!comment_no], null [Vou_Comment!4!comments],
						--tag5
						null [Vou_Items!5!temp],
						--tag6
						--creates sequence number within one asn
						ROW_NUMBER() over(PARTITION BY asn.[asn_num] ORDER BY asn.[ASN_POS])  [Vou_Item!6!item_pos] , asn.EAN + REPLICATE('0',19-len(asn.EAN)) [Vou_Item!6!item_sid],
						asn.qty [Vou_Item!6!qty], asn.qty [Vou_Item!6!orig_qty],
						asn.costNet [Vou_Item!6!cost], '' [Vou_Item!6!fc_cost],
						'0' [Vou_Item!6!tax_code], asn.Currency_Name [Vou_Item!6!currency_name],

						--end with tagid
						6 [SORT!99!TAGID], asn.asn_num [SORT!99!ASN]												
				from	[POS_NL].[dbo].[RetailPro_Config_Store] rps,
						[POS_NL].[dbo].[RetailPro_ASN_Raw] asn
				WHERE	asn.[CUSTOMER_NUM] = rps.[CustomerNum] AND
						asn.[CUSTOMER_NUM] = @customerNum

		--commit
		--COMMIT TRANSACTION


		--END for customer
		if (@LogMessages = 'Y')
		Begin 
			PRINT 'END fill table   - RetailPro_ASN for store (group ' +  @storeGroupNum + ', storeIDWithinGroup ' + @StoreIDWithinGroup + ', customer ' + @customerNum +  ') '  + CONVERT(VARCHAR(8), getdate(), 131)
			PRINT 'START XML export - RetailPro_ASN for store (group ' +  @storeGroupNum + ', storeIDWithinGroup ' + @StoreIDWithinGroup + ', customer ' + @customerNum +  ') '  + CONVERT(VARCHAR(8), getdate(), 131)
		END

		--Create XML File for specific customer		
		Set @path = (select conf.value from retailPro_config conf where conf.id = 'ExportPathASN')
		if (@LogMessages = 'Y') Begin print 'ASN path: ' + @path END
		Set @path = @path + + RIGHT('000' + @storeGroupNum,3) + RIGHT('000' + @StoreIDWithinGroup,3) + 'Z' + '\IN\RECVD\'
		if (@LogMessages = 'Y') Begin print 'ASN path: ' + @path END
		Set @file = (select conf.value from retailPro_config conf where conf.id = 'ExportFileNameASN')	
		SET @filedate = '_' + @customerNum
		SET @fileext='.xml'
		SET @fullpath=@path + @file + @fileext;

		if (@LogMessages = 'Y') Begin print '  XML export to: ' + @fullpath END

		SET @string='bcp "SELECT * FROM [POS_NL].[dbo].[RetailPro_ASN] ORDER BY [SORT!99!ASN], [SORT!99!TAGID], convert(int,[Vou_Item!6!item_pos]), convert(int,[Vou_Comment!4!comment_no]) for xml explicit, TYPE,ROOT(''VOUCHERS'')" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S'

		print '--start export file'
		EXEC xp_cmdshell @string
		--successfully exported, set flag for these ASN records
		if (@LogMessages = 'Y') Begin print '--end export file'		END

		if (@LogMessages = 'Y') Begin print '--start intex table update - consider ASN numbers for customer' + @customerNum END
		UPDATE [INTEXSALES].[OdloDE].dbo.ReKopf
				SET EDILieferscheinJN = 'J', Wer = 'batch', Wann = getdate()
				WHERE [LNr] in (SELECT distinct (cast([SORT!99!ASN] AS INT)) FROM [POS_NL].[dbo].[RetailPro_ASN]) 			
		if (@LogMessages = 'Y') Begin print '--end intex table update - consider ASN numbers for customer' + @customerNum END
		
		
		/*
		print '--before begin transaction'		
		BEGIN TRANSACTION myUpdate
		print '--after begin transaction'	
			
		BEGIN TRY			
			
			----------------------------------------------------------------------------------------------------------------------------------------------
			--Update Intex with flag that 'EDI' message ASN is exported
			----------------------------------------------------------------------------------------------------------------------------------------------			
			print '--start intex table update - consider ASN numbers for customer' + @customerNum
			UPDATE [INTEXSALES].[OdloDE].dbo.ReKopf
				SET EDILieferscheinJN = 'J', Wer = 'batch', Wann = getdate()
				WHERE [LNr] in (SELECT distinct (cast([SORT!99!ASN] AS INT)) FROM [POS_NL].[dbo].[RetailPro_ASN]) 			
			print '--end intex table update - consider ASN numbers for customer' + @customerNum
			
			------------------------------------------------------------------------------------------------------
			--export file
			------------------------------------------------------------------------------------------------------
			print '--start export file'
			EXEC xp_cmdshell @string
			--successfully exported, set flag for these ASN records
			print '--end export file'					
			
		END TRY
		
		BEGIN CATCH
			--rollback
			print '--before rollback transaction'		
			ROLLBACK TRANSACTION myUpdate
			print '--after rollback transaction'		

			--send email
			Set @BodyText = 'RetailPro Export - ASN - File Creation failed for store group: ' + @customerNum
			PRINT 'RetailPro Export - ASN - File Creation failed'
			EXEC msdb.dbo.sp_send_dbmail 
				@recipients='markus.pfyl@odlo.com',
				@from_address='sql@odlo.com',
				@subject='RetailPro Export - ASN - File Creation failed',
				@reply_to='markus.pfyl@odlo.com',
				@importance='High',
				@body= @BodyText, 
				@body_format='HTML';
		END CATCH

		
		print '--before commit transaction'
		COMMIT TRANSACTION myUpdate
		print '--after commit transaction'
		*/


		if (@LogMessages = 'Y')
		Begin
			PRINT 'END XML export - RetailPro_ASN for customer for store (group ' +  @storeGroupNum + ', storeIDWithinGroup ' + @StoreIDWithinGroup + ', customer ' + @customerNum +  ') '  + CONVERT(VARCHAR(8), getdate(), 131)
		END

		--get next store group
		FETCH NEXT FROM storeList   
		INTO @storeGroupNum, @StoreIDWithinGroup, @customerNum
	END

	CLOSE storeList;  
	DEALLOCATE storeList;  


END 






















































GO
