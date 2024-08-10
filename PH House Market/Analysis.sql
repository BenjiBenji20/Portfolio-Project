USE [Mini Project]
GO

SELECT * 
FROM dbo.HouseDescription hd 
JOIN dbo.HouseLocation hl
ON hd.HouseDescID = hl.HouseLocationID
ORDER BY Price;


/** Price Analysis*/
-- Calculating the avg price of house (MEAN)
SELECT 
	AVG(Price) [Average House Price]
FROM dbo.HouseDescription;


-- Calculating the most freq house price (MODE)
SELECT 
	Price,
	COUNT(*) [Frequency of Price]
FROM dbo.HouseDescription 
WHERE Price <> 0 -- to filter the null price
GROUP BY Price
ORDER BY [Frequency of Price] DESC;


 -- Middle price of houses (median)
WITH Index_Position AS (
	SELECT
		Price,
		ROW_NUMBER() OVER(ORDER BY Price) Mid_Row
	FROM dbo.HouseDescription
)
SELECT 
	Price [Median Price]
FROM Index_Position
WHERE Mid_Row = FLOOR((SELECT COUNT(Price) FROM dbo.HouseDescription) / 2);


-- Calculating Range
SELECT 
	MAX(Price) - MIN(Price) [Range] 
FROM dbo.HouseDescription
WHERE Price <> 0; -- to filter the null price


-- Filtering price outside the extreme price range using IQR (filtering outliers)
DECLARE @UpperBound DECIMAL(10, 2);
DECLARE @LowerBound DECIMAL(10, 2);

-- store proc from data cleaning tab
EXEC Outlier_Using_IQR @UpperBound OUTPUT, @LowerBound OUTPUT;

SELECT 
	HouseDescID,
	Bedroom,
	Bathroom,
	FloorArea,
	LandArea,
	Price [Over and Under Price(Outlier)]
FROM dbo.HouseDescription
WHERE Price < @LowerBound OR Price > @UpperBound
ORDER BY Price DESC;


-- Price comparison across different location
-- Sum of price on each location
SELECT DISTINCT
	Location,
	SUM(Price) [Sum on each Location]
FROM dbo.HouseDescription hd
JOIN dbo.HouseLocation hl
ON hd.HouseDescID = hl.HouseLocationID
GROUP BY Location
ORDER BY SUM(Price) DESC;



/** Location-Based Analysis*/
-- Most and least expensive location
WITH UpperBound AS (
	SELECT TOP 50 PERCENT
		Location [Upper Bound Location],
		COUNT(Location) [Number of Houses],
		SUM(Price) [Sum on each Location],
		ROW_NUMBER() OVER(ORDER BY SUM(Price) DESC) Row -- Assigns a row number
	FROM dbo.HouseDescription hd
	JOIN dbo.HouseLocation hl
	ON hd.HouseDescID = hl.HouseLocationID
	GROUP BY Location
	ORDER BY SUM(Price) DESC
),
LowerBound AS (
	SELECT TOP 50 PERCENT
		Location [Lower Bound Location],
		COUNT(Location) [Number of Houses],
		SUM(Price) [Sum on each Location],
		ROW_NUMBER() OVER(ORDER BY SUM(Price) ASC) Row -- Assigns a row number
	FROM dbo.HouseDescription hd
	JOIN dbo.HouseLocation hl
	ON hd.HouseDescID = hl.HouseLocationID
	GROUP BY Location
	ORDER BY SUM(Price) ASC
)

SELECT
	u.[Upper Bound Location],
	u.[Number of Houses],
	u.[Sum on each Location],
	l.[Lower Bound Location],
	l.[Number of Houses],
	l.[Sum on each Location]
FROM UpperBound u
FULL JOIN LowerBound l
ON u.Row = l.Row;


-- Number of houses available on each location
SELECT DISTINCT
	Location,
	COUNT(Location) [Number of Houses]
FROM dbo.HouseLocation
GROUP BY Location
ORDER BY COUNT(Location) DESC;



/** Size and area analysis*/
-- Correlation between floor area and land area with price.
SELECT 
	FloorArea,
	LandArea,
	MAX(Price) OVER(PARTITION BY Bedroom, Bathroom 
					ORDER BY FloorArea, LandArea DESC) [Highest Price with Large Area]
FROM dbo.HouseDescription
ORDER BY [Highest Price with Large Area] DESC;


-- Average floor and land area per location.
SELECT DISTINCT
	Location,
	AVG(FloorArea) [Average Floor Area],
	AVG(LandArea) [Average Land Area]
FROM dbo.HouseLocation hl
JOIN dbo.HouseDescription hd
ON hl.HouseLocationID = hd.HouseDescID
GROUP BY Location;



/** Room analysis*/
-- Distribution of the number of bedrooms and bathrooms.
SELECT
	Bedroom [Number of Bedroom], 
	COUNT(Bedroom) Count
FROM dbo.HouseDescription
GROUP BY Bedroom
ORDER BY COUNT(Bedroom) DESC;

SELECT 
	Bathroom [Number of Bathroom],
	COUNT(Bathroom) Count
FROM dbo.HouseDescription
GROUP BY Bathroom
ORDER BY COUNT(Bathroom) DESC;


-- Average number of bedrooms and bathrooms per location.
SELECT DISTINCT
	Location,
	AVG(Bathroom) [Average Number of Bathroom],
	AVG(Bedroom) [Average Number of Bedroom]
FROM dbo.HouseDescription hd
JOIN dbo.HouseLocation hl
ON hd.HouseDescID = hl.HouseLocationID
GROUP BY Location
ORDER BY AVG(Bathroom) DESC, AVG(Bedroom) DESC;



/** Descriptive analysis*/
-- Frequency of missing description
SELECT 
	Description,
	COUNT(Description) [Frequency]
FROM dbo.HouseDescription
WHERE Description = 'Unassigned'
GROUP BY Description;
