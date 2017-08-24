SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[RetailPro_ReplaceSTring](@text varchar(100))  
RETURNS varchar(100) 
AS   
-- Returns the stock level for the product.  
BEGIN  
    

	SELECT @text = REPLACE(@text,[StringToReplace],[ReplacementString]) FROM [dbo].RetailPro_Config_ReplaceString;

    RETURN @text;  
END;  


GO


