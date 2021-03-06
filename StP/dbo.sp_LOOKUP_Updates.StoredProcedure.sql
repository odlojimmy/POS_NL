/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_LOOKUP_Updates]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[sp_LOOKUP_Updates]

AS
BEGIN
	SET NOCOUNT ON;


IF EXISTS (	SELECT	DISTINCT a.DART_SEASON,a.DART_DIVISION_DESC,a.DART_ARTICLE_NUMBER,a.DART_ARTICLE_DESCRIPTION
			FROM	SPOT_APL.dbo.DART_ARTICLE a LEFT OUTER JOIN (	SELECT	DART_ARTICLE_NUMBER,max(DART_SEASON) as MaxSeason
																	FROM	SPOT_APL.dbo.DART_ARTICLE
																	GROUP BY DART_ARTICLE_NUMBER
																) as b ON (a.DART_SEASON=b.MaxSeason AND a.DART_ARTICLE_NUMBER=b.DART_ARTICLE_NUMBER)
			WHERE b.MaxSeason IS NOT NULL)

BEGIN
	TRUNCATE TABLE [LOOKUP_Article]
	INSERT INTO [dbo].[LOOKUP_Article]
           ([Max_Season]
           ,[Category]
           ,[ArticleNo]
           ,[ArticleDescription])
	SELECT	DISTINCT a.DART_SEASON,a.DART_DIVISION_DESC,a.DART_ARTICLE_NUMBER,a.DART_ARTICLE_DESCRIPTION
	FROM	SPOT_APL.dbo.DART_ARTICLE a LEFT OUTER JOIN (	SELECT	DART_ARTICLE_NUMBER,max(DART_SEASON) as MaxSeason
															FROM	SPOT_APL.dbo.DART_ARTICLE
															GROUP BY DART_ARTICLE_NUMBER
														) as b ON (a.DART_SEASON=b.MaxSeason AND a.DART_ARTICLE_NUMBER=b.DART_ARTICLE_NUMBER)
	WHERE b.MaxSeason IS NOT NULL;
END
ELSE
BEGIN
	SELECT GetDate();
END


/*--- Old script

TRUNCATE TABLE [LOOKUP_Article];

INSERT INTO [dbo].[LOOKUP_Article]
           ([Max_Season]
           ,[Category]
           ,[ArticleNo]
           ,[ArticleDescription])
SELECT	DISTINCT a.DART_SEASON,a.DART_DIVISION_DESC,a.DART_ARTICLE_NUMBER,a.DART_ARTICLE_DESCRIPTION
FROM	SPOT_APL.dbo.DART_ARTICLE a LEFT OUTER JOIN (	SELECT	DART_ARTICLE_NUMBER,max(DART_SEASON) as MaxSeason
														FROM	SPOT_APL.dbo.DART_ARTICLE
														GROUP BY DART_ARTICLE_NUMBER
													) as b ON (a.DART_SEASON=b.MaxSeason AND a.DART_ARTICLE_NUMBER=b.DART_ARTICLE_NUMBER)
WHERE b.MaxSeason IS NOT NULL;

*/ --- Old script

--- CONTROL CHECKs

PRINT 'LOOKUP Updates done'


END 


GO
