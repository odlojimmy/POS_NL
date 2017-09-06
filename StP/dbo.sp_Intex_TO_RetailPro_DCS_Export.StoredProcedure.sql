/**********************************************************************************************************************/
/*                                                                                                                    */
/* Author:    : unknown                                                                                               */
/* Created:   :                                                                                                       */
/* Change hist: Jimmy Rüedi, 06.09.2017                                                                               */
/*              implemented variables to do the mailsending and things like that                                      */
/*              and removed fullyqualified db addressing to get transportability                                      */
/*                                                                                                                    */
/**********************************************************************************************************************/

ALTER PROCEDURE [dbo].[sp_Intex_TO_RetailPro_DCS_Export]

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
		FOR SELECT distinct store.StoreGroupNum, (select TOP 1 customerNum from [dbo].[RetailPro_Config_Store] ks where ks.StoreGroupNum = store.StoreGroupNum) test    from [dbo].[RetailPro_Config_Store] store

	--- SET EMAIL NOTIFICATION VARIABLES
	DECLARE @mailTo varchar(200), @ccmailTo varchar(200), @replyTo varchar(200), @fromAddress varchar(200), @retailProValidationAddress varchar(200)
	SELECT @mailTo = dbo.GetProcPrm('stdRecipientAddress',1), @ccmailTo = dbo.GetProcPrm('stdCopyRecipientAddress',1), @replyTo = dbo.GetProcPrm('stdReplyTo',1), @fromAddress=dbo.GetProcPrm('stdFromAddress',1),@retailProValidationAddress=dbo.GetProcPrm('retailProValidationAddress',1)



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
			from	[dbo].[RetailPro_Config_Store] rps,
						--[INTEXSALES].[OdloDE].dbo.[KuStamm] ks,
						[IFC_Cache].dbo.[KuStamm] ks,
						[dbo].[RetailPro_PriCat_Raw] pcr
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

		SET @string='bcp "SELECT * FROM  ['+DB_NAME()+'].[dbo].[RetailPro_DCS] for xml explicit, TYPE,ROOT(''DCSS'')" queryout '+'"'+@fullpath+'"'+' -k -w -t; -T -S'
		BEGIN TRY
			EXEC xp_cmdshell @string
		END TRY
		BEGIN CATCH
			PRINT 'RetailPro Export - DCS - File Creation failed'
			EXEC msdb.dbo.sp_send_dbmail 
				@recipients=@retailProValidationAddress,
				@copy_recipients=@ccmailTo,
				@from_address=@fromAddress,
				@reply_to=@replyTo,
				@subject='RetailPro Export - DCS - File Creation failed',
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
