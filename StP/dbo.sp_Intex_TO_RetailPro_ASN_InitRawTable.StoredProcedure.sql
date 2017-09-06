/**********************************************************************************************************************/
/* Get the raw data for further processing the advanced shipping notices                                              */
/* Author:    : unknown                                                                                               */
/* Created:   :                                                                                                       */
/* Change hist: Jimmy Rüedi, 06.09.2017                                                                               */
/*              removed the full qualified dabase addressing of object within this specific database                  */
/*              changed the source db to the ifc_cache to relief the INTEXTSALES- DB                                  */
/*                                                                                                                    */
/**********************************************************************************************************************/

ALTER PROCEDURE [dbo].[sp_Intex_TO_RetailPro_ASN_InitRawTable]

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
	DECLARE @customerNum varchar(20);
	DECLARE @storeGroupNum varchar(20);

	--DECLARE storeGroupList CURSOR
	--	FOR SELECT distinct store.StoreGroupNum, (select TOP 1 customerNum from [dbo].[RetailPro_Config_Store] ks where ks.StoreGroupNum = store.StoreGroupNum) test    from [dbo].[RetailPro_Config_Store] store


	--*************************************************************************************************************************************
	--Init variables
	--*************************************************************************************************************************************
	Set @Season = (select conf.value from retailPro_config conf where conf.id = 'RetailProSeason')	

	
	--*************************************************************************************************************************************
	--FILL RAW DATA for ASN
	--*************************************************************************************************************************************
	--BEGIN TRANSACTION

	PRINT 'START fill table RetailPro_ASN_Raw: '  + CONVERT(VARCHAR(50), getdate(), 113)

	TRUNCATE TABLE [dbo].RetailPro_ASN_Raw;
	-- MPFLY 31/01/17 - replace top with the 'wrong' insert below
	
	INSERT INTO RetailPro_ASN_Raw 
			SELECT	rpo.KusNr as [CustomerNumber],
					CONVERT(varchar, rko.LSDatum, 104) as [ASN_DATE],
					rtrim(rko.Info1) as [ASN_COMMENT],
					rpo.LNr AS [delivNumber],
					rpo.RePNr as [delivNumberPosition],
					ltrim(rtrim(LEFT(ean.EANCode, 20))) AS [EAN],
					--mpf 01/06/17: added type 13 (returns) in addition - returns need to have minus quanitites
					--rgr.Teile as [QTY],
					CASE 
						WHEN rko.Art = '13' THEN rgr.Teile * -1
						ELSE rgr.Teile
					END as [QTY],
					rpo.EprFW as [Cost],
					rpo.Rabatt as [Discount],
					ltrim(str(round(rpo.EprFW * (100 - rpo.Rabatt)/100,4),10,2)) as[CostNet],
					rko.Waehrung as [Currency_Name],
					getDate() AS [LOAD_DATE]	
		--> START JRU 06.09.2018 moving the datasource to the cache db to relief the INTEX live DB
		--FROM	 [INTEXSALES].[OdloDE].dbo.ReKopf rko
		--		,[INTEXSALES].[OdloDE].dbo.RePosi rpo
		--		,[INTEXSALES].[OdloDE].dbo.ReGroesse rgr
		--		,[INTEXSALES].[OdloDE].[dbo].[ArtEAN] ean
		--		,[INTEXSALES].[OdloDE].[dbo].[ArtStamm]  art
		--> END JRU 06.09.2018
		FROM	 [IFC_Cache].dbo.ReKopf rko
				,[IFC_Cache].dbo.RePosi rpo
				,[IFC_Cache].dbo.ReGroesse rgr
				,[IFC_Cache].[dbo].[ArtEAN] ean
				,[IFC_Cache].[dbo].[ArtStamm]  art		WHERE (
				rpo.LNr = rko.LNr
				AND rpo.Jahr = rko.Jahr
				AND rpo.RekKey = rko.RekKey
				)
			AND (
				rpo.LNr = rgr.LNr
				AND rpo.Jahr = rgr.Jahr
				AND rpo.RekKey = rgr.RekKey
				AND rpo.RePNr = rgr.RePNr
				)			
			AND (
				ean.[ArtsNr1] = rpo.[ArtsNr1]
				AND ean.[ArtsNr2] = rpo.[ArtsNr2]
				AND ean.[ArtsKey] = rpo.[ArtsKey]
				AND ean.[VerkFarbe] = rpo.[VerkFarbe]
				AND ean.[GGanKey] = rgr.[GGanKey]
				AND ean.[GGNr] = rgr.[GGNr]
				AND ean.[Gr] = rgr.[Gr]
				)
			and art.artsnr1 not like 'IN%'
			AND ean.artsnr1 = art.artsnr1 and ean.artsnr2  = art.artsnr2 and ean.artskey = art.artskey
			AND rko.EDILieferscheinJN <> 'J'
			AND art.DivNeu not in (90,93,94,95,96)
			AND rko.Status1 >= 2
			--mpf 01/06/17: added type 13 (returns) in addition
			AND rko.Art in ('01','02','04','07','09','13','17','98','99')
			AND rko.KusNr in (select customernum from [dbo].[RetailPro_Config_Store])
			and rgr.Teile > 0
			--AND rko.Neu > '01-01-2016' --> Assuming, this is jest for perfomance reasons, we set half a year back
			AND rko.Neu > DATEADD(month,-6,GETDATE())
			--and rko.Jahr = '2016'
			--and rko.lnr = '2008225'
			--and  rko.KusNr = '200514'

		
	
	--COMMIT TRANSACTION
	PRINT 'END fill table RetailPro_ASN_Raw: '  + CONVERT(VARCHAR(50), getdate(), 113)



	--*************************************************************************************************************************************
	--Special character cleanout
	--*************************************************************************************************************************************
	--BEGIN TRANSACTION

	PRINT 'Start replacing characters' + CONVERT(VARCHAR(50), getdate(), 113)

	--Article description	
	UPDATE [dbo].[RetailPro_ASN_Raw]
		SET [ASN_Comment] = dbo.RetailPro_ReplaceString(ASN_Comment)

	PRINT 'End replacing characters' + CONVERT(VARCHAR(50), getdate(), 113)

	--commit transaction



END 
































GO
