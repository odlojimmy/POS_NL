/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2012 (11.0.3128)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2012
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
/****** Object:  StoredProcedure [dbo].[sp_SOURCE_BRONTO_Customers]    Script Date: 24.08.2017 15:23:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










CREATE PROCEDURE [dbo].[sp_SOURCE_BRONTO_Customers]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


--- CREATE MESSAGE VARIABLES
DECLARE @all varchar(20);

TRUNCATE TABLE SOURCE_BRONTO_Customers;	
---TRUNCATE TABLE SOURCE_BRONTO_CustomersN;




--- IMPORT BRONTO CSV FILE
BULK INSERT SOURCE_BRONTO_Customers
FROM 'D:\POS_NL\Bronto_In\Customers\updated.csv'
--FROM 'D:\POS_NL\Bronto_In\Customers\updated_new2.csv'


WITH
(
	DATAFILETYPE='char',
	CODEPAGE='1252',
	FIRSTROW=2,
	FIELDTERMINATOR=',',
	ROWTERMINATOR='\n'
)

/*
--- IMPORT BRONTO CSV FILE
BULK INSERT SOURCE_BRONTO_CustomersN
FROM 'D:\POS_NL\Bronto_In\Customers\updated.csv'
WITH
(
	DATAFILETYPE='widechar',
	--CODEPAGE='code_page',
	FIRSTROW=2,
	FIELDTERMINATOR=',',
	ROWTERMINATOR='\n'
)

*/

---SELECT * FROM SOURCE_BRONTO_Customers
---SELECT * FROM SOURCE_BRONTO_CustomersN



UPDATE SOURCE_BRONTO_Customers
SET	EmailAddress = REPLACE(EmailAddress,'"',''),
	EmailSubscriptionStatus = REPLACE(EmailSubscriptionStatus,'"',''),
	FirstName = REPLACE(FirstName,'"',''),
	LastName = REPLACE(LastName,'"',''),
	Gender = REPLACE(Gender,'"',''),
	Street = REPLACE(Street,'"',''),
	HouseNumber = REPLACE(HouseNumber,'"',''),
	PostalCode = REPLACE(PostalCode,'"',''),
	City = REPLACE(City,'"',''),
	Country = REPLACE(Country,'"',''),
	Birthday = REPLACE(Birthday,'"',''),
	Telephone = REPLACE(Telephone,'"',''),
	Mobile = REPLACE(Mobile,'"',''),
	PostSubscriptionStatus = REPLACE(PostSubscriptionStatus,'"',''),
	POSShopName = REPLACE(POSShopName,'"',''),
	Language = REPLACE(Language,'"',''),
	POSCustomerNumber = REPLACE(POSCustomerNumber,'"',''),
	ModifiedDate = REPLACE(ModifiedDate,'"','');



-- PRINT STATUS MESSAGAE
SET @all=(SELECT count(*) FROM SOURCE_BRONTO_Customers)
PRINT 'All Import Count - '+@all
PRINT 'SOURCE BRONTO Customers successful'




END



GO
