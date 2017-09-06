/**********************************************************************************************************************/
/* Verify ASN records - price has to be there                                                                         */
/* Author:    : unknown                                                                                               */
/* Created:   :                                                                                                       */
/* Change hist: Jimmy Rüedi, 06.09.2017                                                                               */
/*              removed the full qualified dabase addressing of object within this specific database                  */
/*                                                                                                                    */
/*                                                                                                                    */
/**********************************************************************************************************************/


ALTER PROCEDURE [dbo].[sp_Intex_TO_RetailPro_ASN_Verification]

AS
BEGIN
	SET NOCOUNT ON;

	--Variables
	DECLARE @mxml NVARCHAR(MAX)
	DECLARE @mbody NVARCHAR(MAX)


	print 'START Check reatail pro - ASN - data consistency' + CONVERT(VARCHAR(50), getdate(), 113)

	--*************************************************************************************************************************************
	--Verify ASN records - price has to be there
	--*************************************************************************************************************************************
	
	IF EXISTS	(
			SELECT *  FROM [dbo].[RetailPro_ASN_Raw] where (convert(numeric, Cost) = 0) or (Cost is null)
				)

	BEGIN
		--prepare and send email with 0 prices
		print 'RetailPro ASN Export File - Price Missing' + CONVERT(VARCHAR(50), getdate(), 113)

		SET @mxml = CAST((	
				
						SELECT	Customer_Num as 'td','',
								ASN_Date as 'td','',
								ASN_Info as 'td','',
								EAN as 'td'
								
						FROM (
									select Customer_Num, ASN_DATE, ASN_Num + '-' + asn_pos asn_info, ean from [dbo].[RetailPro_ASN_Raw] where (convert(numeric, Cost) = 0) or (Cost is null) 
										) as Temp --Record is locked for more than one hour
						order by Customer_Num, ASN_DATE, ASN_Info


		FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

		SET @mbody =	'<html><body><H2>RetailPro ASN Export File - Missing prices</H2><br>The ASN is not exported into retail pro. Correct the pricing and it will get exported with the next scheduled export.
						<table border = 1> 
						<tr><th>Customer_Num</th> <th>ASN_Date</th> <th>ASN_Info</th> <th>EAN</th>  </tr>'
 
		SET @mbody = @mbody + @mxml +'</table></body></html>'

		EXEC msdb.dbo.sp_send_dbmail 
			@recipients='retailpro_validation@odlo.com',
			@from_address='sql@odlo.com',
			@subject='RetailPro ASN Export File -Missign prices',
			@reply_to='markus.pfyl@odlo.com',
			---@importance='High',
			@body=@mbody,
			@body_format='HTML';


		--delete these ASN records without prices - they then get retried tomorrow again (info by email which ASN affected so they can get corrected)
		DELETE [dbo].[RetailPro_ASN_Raw]
			WHERE asn_num in (select distinct ASN_Num from [dbo].[RetailPro_ASN_Raw] where (convert(numeric, Cost) = 0) or (Cost is null))


		print 'END Check reatail pro - ASN - data consistency' + CONVERT(VARCHAR(50), getdate(), 113)
	END
	ELSE
	BEGIN
		print 'END Check reatail pro - ASN - data consistency - NO EXCEPTION RECORDS FOUND' + CONVERT(VARCHAR(50), getdate(), 113)
	END 


END






















GO
