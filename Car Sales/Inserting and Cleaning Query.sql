/** This query is for cleaning and inserting data from Car_Sales_General_Table into
	two different table, which holds different information.
*/

USE [Car Sales - Portfolio Project]
GO

SELECT * FROM 
[Car Sales - Portfolio Project]..Car_Sales_General_Table

-- Identify duplicate vin
SELECT 
	vin, 
	COUNT(*)
FROM [Car Sales - Portfolio Project]..Car_Sales_General_Table
GROUP BY 
	vin
HAVING 
	COUNT(*) > 1

-- Remove duplicate rows
WITH CTE AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY vin ORDER BY SaleDate DESC) AS rn
    FROM [Car Sales - Portfolio Project]..Car_Sales_General_Table
)
DELETE FROM CTE WHERE rn > 1


-- Converting null column to not null to use as primary key.
DELETE FROM [Car Sales - Portfolio Project]..Car_Sales_General_Table
WHERE vin IS NULL

ALTER TABLE [Car Sales - Portfolio Project]..Car_Sales_General_Table
ALTER COLUMN vin NVARCHAR(255) NOT NULL

ALTER TABLE [Car Sales - Portfolio Project]..Car_Sales_General_Table
ADD CONSTRAINT PK_Vin PRIMARY KEY(vin)


/** Create table to arrange the tablel columns*/
-- CarInfo Table
DROP TABLE IF EXISTS CarInfo
CREATE TABLE CarInfo (
	Vin NVARCHAR(255) PRIMARY KEY,
	Year INT NULL,
	Make NVARCHAR(255) NULL,
	Model NVARCHAR(255) NULL,
	Color NVARCHAR(255) NULL,
	Body NVARCHAR(255) NULL,
	Trim NVARCHAR(255) NULL,
	Condition NVARCHAR(255) NULL,
	Transmission NVARCHAR(255) NULL,
	Odometer NVARCHAR(255) NULL,
	Interior NVARCHAR(255) NULL
)

-- Insert data from general table.
INSERT INTO [Car Sales - Portfolio Project]..CarInfo (Vin, Year, Make, Model, Color, Body,
	Trim, Condition, Transmission, Odometer, Interior)
SELECT Vin, Year, Make, Model, Color, Body,
	Trim, Condition, Transmission, Odometer, Interior
FROM [Car Sales - Portfolio Project]..Car_Sales_General_Table;

SELECT * FROM [Car Sales - Portfolio Project]..CarInfo


-- CarSalesInfo Table
DROP TABLE IF EXISTS CarSalesInfo;
CREATE TABLE CarSalesInfo (
	SalesID INT PRIMARY KEY IDENTITY(1,1),
	Vin NVARCHAR(255),
	Seller NVARCHAR(255) NULL,
	MMR FLOAT NULL,
	SellingPrice FLOAT NULL,
	SaleDateDiffFormat NVARCHAR(255) NULL,
	SaleDate DATE NULL,
	State NVARCHAR(255) NULL,
	FOREIGN KEY(Vin) REFERENCES [Car Sales - Portfolio Project]..CarInfo(Vin)
)

-- Insert data from general table.
INSERT INTO [Car Sales - Portfolio Project]..CarSalesInfo(Vin, Seller, MMR,
	SellingPrice, SaleDateDiffFormat, State)
SELECT Vin, Seller, MMR,
	SellingPrice, saledate, State
FROM [Car Sales - Portfolio Project]..Car_Sales_General_Table


/** UPDATING DATA TO BE WELL PRESENTED*/
-- Converting different date format into sql date format.
-- Update the SaleDate column
UPDATE CarSalesInfo
SET SaleDate = TRY_CAST(
    CONCAT(
        SUBSTRING(SaleDateDiffFormat, 9, 2), '-', -- Day
        SUBSTRING(SaleDateDiffFormat, 5, 3), '-', -- Month
        SUBSTRING(SaleDateDiffFormat, 12, 4)      -- Year
    ) AS DATE)

SELECT SaleDate FROM CarSalesInfo

-- Finally, drop the SaleDateDiffFormat column because its already unnecessary.
ALTER TABLE CarSalesInfo
DROP COLUMN SaleDateDiffFormat

-- Cutting the char of State to only two.
SELECT State 
FROM CarSalesInfo
WHERE LEN(State) > 2

UPDATE [Car Sales - Portfolio Project]..CarSalesInfo 
	SET State = SUBSTRING(State, 1,2)
	WHERE Len(State) > 2

SELECT DISTINCT
	Model,
	COUNT(Model) OVER(PARTITION BY Model),
	SellingPrice
FROM CarInfo JOIN CarSalesInfo
ON CarInfo.Vin = CarSalesInfo.Vin
WHERE 
	Model IS NOT NULL
GROUP BY 
	Model, SellingPrice


SELECT * FROM CarInfo;
SELECT * FROM CarSalesInfo

-- Average Car Selling Price
-- Cars with low selling price
-- Cars with high selling price
-- Most sold car 
