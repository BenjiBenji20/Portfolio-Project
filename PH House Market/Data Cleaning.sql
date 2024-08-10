USE [Mini Project];
GO

-- Observe the table
SELECT * FROM dbo.PhilippineHousing;

---- Observe the table
--SELECT Longitude
--FROM dbo.PhilippineHousing
--WHERE Longitude IS NULL;

/** Separate the table with appropriate columns
	change the datatypes according to the 
	value it holds.*/
DROP TABLE IF EXISTS HouseDescription;
CREATE TABLE HouseDescription (
	HouseDescID INT PRIMARY KEY,
	Description NVARCHAR(MAX),
	Price FLOAT,
	Bedroom INT,
	Bathroom INT,
	FloorArea FLOAT,
	LandArea FLOAT
);

INSERT INTO dbo.HouseDescription
SELECT HouseID,
	Description,
	Price,
	Bedrooms,
	Bathrooms,
	[Floor Area],
	[Land Area]
FROM dbo.PhilippineHousing 

DROP TABLE IF EXISTS HouseLocation;
CREATE TABLE HouseLocation (
	HouseLocationID INT PRIMARY KEY,
	Location NVARCHAR(255),
	Latitude FLOAT,
	Longitude FLOAT,
	FOREIGN KEY(HouseLocationID) REFERENCES dbo.HouseDescription(HouseDescID)
);

INSERT INTO dbo.HouseLocation
SELECT HouseID,
	Location,
	Latitude,
	Longitude
FROM dbo.PhilippineHousing;



/** Data Cleaning
	- Null and Blank value handling
	- Duplicate Rows
	- Finding Outliers */

-- Null and Blank value handling
UPDATE dbo.HouseDescription
SET Description = COALESCE(NULLIF(Description, ''), 'Unassigned'),
	Price = ISNULL(Price, 0),
	Bedroom = ISNULL(Bedroom, 0),
	Bathroom = ISNULL(Bathroom, 0),
	FloorArea = ISNULL(FloorArea, 0),
	LandArea = ISNULL(LandArea, 0);

--SELECT Location, Latitude, Longitude
--FROM dbo.HouseLocation
--WHERE Location IS NULL OR Latitude IS NULL OR Longitude IS NULL

UPDATE dbo.HouseLocation
SET Location = COALESCE(NULLIF(Location, ''), 'Unassigned');



-- Duplicate Rows
-- Check for duplicates
SELECT Description,
	Price,
	Bedroom,
	FloorArea,
	Location,
	Latitude,
	Longitude,
	COUNT(*) Duplicates
FROM dbo.HouseDescription d
JOIN dbo.HouseLocation l
ON d.HouseDescID = l.HouseLocationID
GROUP BY Description,
	Price,
	Bedroom,
	FloorArea,
	Location,
	Latitude,
	Longitude
HAVING COUNT(*) > 1;

-- Identify duplicates and store them in a temporary table
WITH Duplicate AS (
    SELECT 
        l.HouseLocationID,
        d.HouseDescID,
        ROW_NUMBER() OVER(
            PARTITION BY 
                d.Description,
                d.Price,
                d.Bedroom,
                d.FloorArea,
                l.Location,
                l.Latitude,
                l.Longitude
            ORDER BY 
                d.HouseDescID
        ) AS DuplicateRow
    FROM 
        dbo.HouseDescription d
    JOIN 
        dbo.HouseLocation l
    ON 
        d.HouseDescID = l.HouseLocationID  
)

-- Store each id in temporary table
SELECT HouseLocationID, HouseDescID
INTO #TempDuplicate -- temporary table to store duplicates
FROM Duplicate
WHERE DuplicateRow > 1;

-- Delete duplicates from HouseLocation using the temporary table
DELETE FROM dbo.HouseLocation
WHERE HouseLocationID IN (
    SELECT HouseLocationID
    FROM #TempDuplicate
);

-- Delete duplicates from HouseDescription using the temporary table
DELETE FROM dbo.HouseDescription
WHERE HouseDescID IN (
    SELECT HouseDescID
    FROM #TempDuplicate
);

-- Drop the temporary table as it's no longer needed
DROP TABLE #TempDuplicate;



-- Finding Outliers
SELECT * FROM dbo.HouseDescription d
JOIN dbo.HouseLocation l
ON d.HouseDescID = l.HouseLocationID;


-- Using ZScore
SELECT * FROM (
	SELECT
		HouseDescID,
		Price,
		(AVG(Price) OVER() - Price) / STDEV(Price) OVER() Zscore
	FROM dbo.HouseDescription
	)[Zscore Table]
WHERE Zscore > 3 OR Zscore < 3;

-- 3 Standard deviation away from the mean
SELECT * FROM (
	SELECT 
		HouseDescID,
		Price,
		(AVG(Price) OVER() - Price) / STDEV(Price) OVER() Zscore
	FROM 
		dbo.HouseDescription
) AS [ZScore Table]
WHERE Zscore > 2.576 OR Zscore < -2.576;

-- 2 Standard deviation away from the mean
SELECT * FROM (
	SELECT 
		HouseDescID,
		Price,
		(AVG(Price) OVER() - Price) / STDEV(Price) OVER() Zscore
	FROM 
		dbo.HouseDescription
) AS [ZScore Table]
WHERE Zscore > 1.96 OR Zscore < -1.96;

-- 1 Standard deviation away from the mean
SELECT * FROM (
	SELECT 
		HouseDescID,
		Price,
		(AVG(Price) OVER() - Price) / STDEV(Price) OVER() Zscore
	FROM 
		dbo.HouseDescription
) AS [ZScore Table]
WHERE Zscore > 1.645 OR Zscore < -1.645;


-- Using IQR method
-- Begin to create store procedure to calculate IQR
DROP PROCEDURE IF EXISTS Outlier_Using_IQR;
CREATE PROCEDURE Outlier_Using_IQR
	@UpperBound DECIMAL(10,2) OUTPUT,
	@LowerBound DECIMAL(10,2) OUTPUT

	AS
		BEGIN
			-- Declare variable to store calculate value
			DECLARE @Count INT;
			DECLARE @Q3 DECIMAL(10,2);
			DECLARE @Q1 DECIMAL(10,2);
			DECLARE @IQR DECIMAL(10,2);
			DECLARE @Outlier DECIMAL(10,2);

			-- Get the count value
			SELECT @Count = COUNT(Price) FROM dbo.HouseDescription;

			WITH OrderedList AS (
				SELECT Price, 
					ROW_NUMBER() OVER(ORDER BY Price) AS RowNumber -- Sorting value in asc
				FROM dbo.HouseDescription
			),
			QuartileBreaks AS (	-- Retrieve each quartile its like (arr.length / 2 + 1) + arr.length / 2 + 1
				SELECT Price,
					(SELECT Price
					 FROM OrderedList
					 WHERE RowNumber = FLOOR((SELECT COUNT(Price) FROM dbo.HouseDescription) * 0.75)
					) AS QThreeUpper,

					(SELECT Price
					 FROM OrderedList
					 WHERE RowNumber = FLOOR((SELECT COUNT(Price) FROM dbo.HouseDescription) * 0.65 + 1)
					) AS QThreeLower,

					(SELECT Price
					 FROM OrderedList
					 WHERE RowNumber = FLOOR((SELECT COUNT(Price) FROM dbo.HouseDescription) * 0.25 + 1)
					) AS QOneUpper,

					(SELECT Price
					 FROM OrderedList
					 WHERE RowNumber = FLOOR((SELECT COUNT(Price) FROM dbo.HouseDescription) * 0.25)
					) AS QOneLower
			
				FROM OrderedList
			)

			-- Calculate for IQR
			SELECT 
				@Q3 = (QThreeUpper + QThreeLower) / 2,
				@Q1 = (QOneUpper + QOneLower) / 2
			FROM QuartileBreaks;

			SET @IQR = @Q3 - @Q1;

			-- Calculate the outlier
			SET @UpperBound = @Q3 + 1.5 * @IQR;
			SET @LowerBound = @Q1 - 1.5 * @IQR;
		END;

-- Declare variables to hold the lower and upper bound calculation
DECLARE @UpperBound DECIMAL(10,2);
DECLARE @LowerBound DECIMAL(10,2);

-- Execute the procedure and capture the output values
EXEC Outlier_Using_IQR @UpperBound OUTPUT, @LowerBound OUTPUT;

/** Retrieve using select statement by applying condition
	where price is above or below the boundary.*/
SELECT 
	HouseDescID,
	Description,
	Price [Over and Under Price (Outlier)]
FROM dbo.HouseDescription
WHERE Price < @LowerBound OR Price > @UpperBound
ORDER BY Price DESC;
