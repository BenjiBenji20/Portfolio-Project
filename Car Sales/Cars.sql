USE [Car Sales - Portfolio Project];
GO

/** Most car sold maker and their average selling price */
SELECT 
	CI.Make,
	COUNT(*) AS TotalCarsByMaker,
	AVG(CSI.SellingPrice) AS AvgPriceByMake
FROM [Car Sales - Portfolio Project]..CarInfo AS CI
	JOIN [Car Sales - Portfolio Project]..CarSalesInfo AS CSI
ON CI.Vin = CSI.Vin
WHERE CI.Make IS NOT NULL AND
	 CSI.SellingPrice IS NOT NULL
GROUP BY CI.Make
ORDER BY TotalCarsByMaker DESC


/** Top 10 highest sold cars */
SELECT TOP 10 Make,
	COUNT(Make) AS TotalCarsByMaker
FROM CarInfo 
WHERE Make IS NOT NULL
GROUP BY Make
ORDER BY TotalCarsByMaker DESC


/** Top 10 most expensive sold cars */
SELECT TOP 10 
	CI.Make,
	CI.Model,
	CSI.SellingPrice,
	COUNT(*) AS TotalSale
FROM [Car Sales - Portfolio Project]..CarInfo AS CI
	JOIN [Car Sales - Portfolio Project]..CarSalesInfo AS CSI
ON CI.Vin = CSI.Vin
WHERE 
	CI.Model IS NOT NULL AND
	CI.Make IS NOT NULL
GROUP BY
	CI.Make,
	CI.Model,
	CSI.SellingPrice
ORDER BY 
	CSI.SellingPrice DESC


/** Average MMR by year */
SELECT 
	CI.Year, 
	CI.Make, 
	AVG(CSI.MMR) as AverageMMR
FROM [Car Sales - Portfolio Project]..CarInfo AS CI
	JOIN [Car Sales - Portfolio Project]..CarSalesInfo AS CSI
ON CI.Vin = CSI.Vin
WHERE 
	CI.Year IS NOT NULL AND
	CSI.MMR IS NOT NULL AND
	CI.Make IS NOT NULL
GROUP BY 
	CI.Year, 
	CI.Make
HAVING 
	COUNT(*) > 5
ORDER BY 
	AverageMMR DESC;
	

/** Cars with low price and cars with high price */
SELECT DISTINCT 
	AVG(CSI.SellingPrice) OVER(PARTITION BY CI.Make) AS AvgPriceByMake,
	CI.Make,
	MAX(CSI.SellingPrice) OVER(PARTITION BY CI.Make) AS HighestPriceByMake,
	MIN(CSI.SellingPrice) OVER(PARTITION BY CI.Make) AS LowestPriceByMake
FROM [Car Sales - Portfolio Project]..CarInfo AS CI
	JOIN [Car Sales - Portfolio Project]..CarSalesInfo AS CSI
ON CI.Vin = CSI.Vin
WHERE CI.Make IS NOT NULL AND
	 CSI.SellingPrice IS NOT NULL AND 
	 Model IS NOT NULL
GROUP BY CI.Make, 
	CSI.SellingPrice, 
	Model
ORDER BY AvgPriceByMake DESC, 
	HighestPriceByMake DESC,
	LowestPriceByMake DESC


 /** Cars with low and high price and their sale */
WITH AvgCarPrice AS ( -- CTE that uses to hold an avg car price
	SELECT 
		AVG(CSI.SellingPrice) AS AvgCarPrice
	FROM [Car Sales - Portfolio Project]..CarInfo AS CI
		JOIN [Car Sales - Portfolio Project]..CarSalesInfo AS CSI
	ON CI.Vin = CSI.Vin
	WHERE CSI.SellingPrice IS NOT NULL
)

SELECT CI. Make,
	CI.Model,
	CSI.SellingPrice,
	AvCP.AvgCarPrice,
	CASE	
		WHEN CSI.SellingPrice < AvCP.AvgCarPrice
		THEN 'Low Price'
		ELSE 'High Price'
	END AS PriceCategory
FROM [Car Sales - Portfolio Project]..CarInfo AS CI
	JOIN [Car Sales - Portfolio Project]..CarSalesInfo AS CSI
ON CI.Vin = CSI.Vin
	CROSS JOIN AvgCarPrice AS AvCP
WHERE 
	CI.Make IS NOT NULL AND
	CI.Model IS NOT NULL AND
	CSI.SellingPrice IS NOT NULL
ORDER BY CI.Make,
	CI.Model


/** Sold cars according to date */
-- Knowing when the trend was.
SELECT 
	CSI.SaleDate,
	COUNT(CI.Model)AS SalesAtDate
FROM [Car Sales - Portfolio Project]..CarInfo AS CI
	JOIN [Car Sales - Portfolio Project]..CarSalesInfo AS CSI
ON CI.Vin = CSI.Vin
WHERE 
	CI.Model IS NOT NULL AND
	CSI.SaleDate IS NOT NULL
GROUP BY 
	CSI.SaleDate,
	CI.Model
ORDER BY
	CSI.SaleDate,
	SalesAtDate


/** Total cars sold by state*/
SELECT 
	State,
	COUNT(*) AS TotalSoldByState
FROM [Car Sales - Portfolio Project]..CarSalesInfo
GROUP BY
	State
ORDER BY 
	TotalSoldByState DESC
