/**********************************************************************************************************************/
/* update the season in the table RetailPro_Config                                                                    */
/* Author:    : unknown                                                                                               */
/* Created:   :                                                                                                       */
/* Change hist: Jimmy Rüedi, 06.09.2017                                                                               */
/*              removed the full qualified dabase addressing of object within this specific database                  */
/*                                                                                                                    */
/*                                                                                                                    */
/**********************************************************************************************************************/

ALTER PROCEDURE [dbo].[sp_Intex_TO_RetailPro_General_Init]

AS
BEGIN
	SET NOCOUNT ON;

	--only purpose is to update the season in the table RetailPro_Config
	
	DECLARE @CurrentSeason varchar(8);
	DECLARE @NextSeason varchar(8);

	--get the season from the season master table
	set @CurrentSeason = (Select DSEA_KEY from [GENERAL_CHECK_Reports].[dbo].[SYSTEM_SEASON_RANGES] where JOB = 'RETAILPRO_CURRENT_SEASON')
	set @NextSeason = (Select DSEA_KEY from [GENERAL_CHECK_Reports].[dbo].[SYSTEM_SEASON_RANGES] where JOB = 'RETIALPRO_NEXT_SEASON')
	--verify content
	print @CurrentSeason
	print @NextSeason
	--update retail pro interface with the right season
	Update [RetailPro_Config] set [Value] = @CurrentSeason where [ID] in ('RetailProSeason','RetailProSeason_Outlet')
	Update [RetailPro_Config] set [Value] = @NextSeason where [ID] in ('RetailProSeasonNext','RetailProSeasonNext_Outlet')

END 

GO
