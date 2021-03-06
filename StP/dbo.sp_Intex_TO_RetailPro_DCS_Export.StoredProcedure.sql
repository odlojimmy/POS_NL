/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_Intex_TO_RetailPro_DCS_Export]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






















CREATE PROCEDURE [dbo].[sp_Intex_TO_RetailPro_DCS_Export]

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
	--DECLARE @Season varchar(50);
	DECLARE @customerNum varchar(20);
	DECLARE @storeGroupNum varchar(20);
	DECLARE @StylesCreatedPastDays date;
	DECLARE @StylesCreatedPastDaysNumber int;

	DECLARE storeGroupList CURSOR
		FOR SELECT distinct store.StoreGroupNum, (select TOP 1 customerNum from [POS_NL].[dbo].[RetailPro_Config_Store] ks where ks.StoreGroupNum = store.StoreGroupNum) test    from [POS_NL].[dbo].[RetailPro_Config_Store] store




	--*************************************************************************************************************************************
	-- DCS File
	--*************************************************************************************************************************************
		--Loop through the customers
	OPEN storeGroupList  
	FETCH NEXT FROM storeGroupList   
	INTO @storeGroupNum, @customerNum

	
	WHILE @@FETCH_STATUS = 0  
	BEGIN

		PRINT 'START fill table RetailPro_DCS for store ' + @storeGroupNum + ' '  + CONVERT(VARCHAR(8), getdate(), 131)
		BEGIN TRANSACTION
		--delete all dcs records
		TRUNCATE TABLE [dbo].[RetailPro_DCS];
		--Fill dcs records again
	
		--- INSERT DCS Info
		INSERT INTO [dbo].[RetailPro_DCS] ([TAG],[PARENT],[dcs!1!dcs_code],[dcs!1!sbs_no],[dcs!1!d_name],[dcs!1!c_name],[dcs!1!s_name],[dcs!1!d_long_name],[dcs!1!c_long_name],[dcs!1!s_long_name],[dcs!1!use_qty_decimals],[dcs!1!margin_type],[dcs!1!margin_value],[dcs!1!active],[dcs!1!regional],[dcs!1!ptrn_name])
			SELECT distinct 
						1 TAG, null PARENT,
						pcr.DCS_Code dcs_Code, rps.StoreGroupNum sbs_no,
						CategoryText, [ProdGroupText],[SexText],
						'','','',0,0,0,1,0,0
			from	[POS_NL].[dbo].[RetailPro_Config_Store] rps,
						[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[POS_NL].[dbo].[RetailPro_PriCat_Raw] pcr
				WHERE	rps.customernum = ks.kusnr and pcr.PriceList = ks.PreisLst COLLATE SQL_Latin1_General_CP1_CS_AS
						and ks.KusNr = @customerNum

	
		COMMIT TRANSACTION
		PRINT 'END fill table RetailPro_DCS for store ' + @storeGroupNum + ' '  + CONVERT(VARCHAR(8), getdate(), 131) 
		PRINT 'START XML export RetailPro_DCS for store ' + @storeGroupNum + ' '  + CONVERT(VARCHAR(8), getdate(), 131)

		--create XML File
		Set @path = (select conf.value from retailPro_config conf where conf.id = 'ExportPathDCS')
		Print 'DCS Path: ' + @Path
		Set @Path = @path + RIGHT('000' + @storeGroupNum,3) + '000Z' + '\IN\RECVD\'
		Print 'DCS Path: ' + @Path
		Set @file = (select conf.value from retailPro_config conf where conf.id = 'ExportFileNameDCS')	
		SET @filedate = ''
		SET @fileext='.xml'
		SET @fullpath=@path+@file+@fileext;
		--SET @fullpath=@path+@file + '_storegroup_' + @storeGroupNum + @filedate+@fileext;
		PRINT 'DCS FullPath: ' + @fullpath

		SET @string='bcp "SELECT * FROM [POS_NL].[dbo].[RetailPro_DCS] for xml explicit, TYPE,ROOT(''DCSS'')" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S'
		BEGIN TRY
			EXEC xp_cmdshell @string
		END TRY
		BEGIN CATCH
			PRINT 'RetailPro Export - DCS - File Creation failed'
			EXEC msdb.dbo.sp_send_dbmail 
				@recipients='retailpro_validation@odlo.com',
				@from_address='sql@odlo.com',
				@subject='RetailPro Export - DCS - File Creation failed',
				@reply_to='markus.pfyl@odlo.com',
				@importance='High',
				@body='RetailPro Export - DCS - File Creation failed',
				@body_format='HTML';
		END CATCH

		PRINT 'END XML export RetailPro_DCS: '  + CONVERT(VARCHAR(8), getdate(), 131)

		--get next store group
		FETCH NEXT FROM storeGroupList   
		INTO @storeGroupNum, @customerNum  
	END

	CLOSE storeGroupList;  
	DEALLOCATE storeGroupList;  





END 





















GO
