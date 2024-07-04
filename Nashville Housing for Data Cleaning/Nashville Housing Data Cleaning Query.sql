/** This query is for data cleaning.
*/

USE NashvilleHousing..NashvilleHousingDB;
GO



/** Standardize SaleDate column*/
SELECT SaleDate
FROM NashvilleHousing..NashvilleHousingDB

ALTER TABLE NashvilleHousing..NashvilleHousingDB -- Adding table
ADD SaleDateUpdated Date

UPDATE NashvilleHousing..NashvilleHousingDB -- Update date format
SET SaleDateUpdated = CONVERT(DATE, SaleDate)

ALTER TABLE NashvilleHousing..NashvilleHousingDB -- DROP table
DROP COLUMN SaleDate

SELECT SaleDateUpdated FROM NashvilleHousing..NashvilleHousingDB -- Check if the table reflects in DB



/** Populating null property address column */
SELECT PropertyAddress -- Checks the null rows
FROM NashvilleHousing..NashvilleHousingDB
WHERE PropertyAddress IS NULL

-- Populating null rows
SELECT 
	A.ParcelID,
	A.PropertyAddress,
	B.ParcelID,
	B.PropertyAddress,
	ISNULL(A.PropertyAddress, B.PropertyAddress) -- Populating null rows to A table from value of B table
	AS PropertyAddressUpdated
FROM 
	NashvilleHousing..NashvilleHousingDB AS A
	JOIN NashvilleHousing..NashvilleHousingDB AS B
ON 
	A.ParcelID = B.ParcelID -- Joining 2 tables with same id
	AND A.UniqueID <> B.UniqueID -- unique id shouldnt be the same
WHERE 
	A.PropertyAddress IS NULL

-- Update null rows from PropertyAddress column 
UPDATE A 
SET 
	PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress) -- Updating null value
FROM 
	NashvilleHousing..NashvilleHousingDB AS A
	JOIN NashvilleHousing..NashvilleHousingDB AS B
ON 
	A.ParcelID = B.ParcelID -- Joining 2 tables with same id
	AND A.UniqueID <> B.UniqueID -- unique id shouldnt be the same
WHERE 
	A.PropertyAddress IS NULL



/** Breaking out address into individual address (address, city, state)*/
SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS State
FROM 
	NashvilleHousing..NashvilleHousingDB

-- Create new 2 columns to split the value of property address column
ALTER TABLE NashvilleHousing..NashvilleHousingDB
ADD AddressOfProperty NVARCHAR(255)

UPDATE NashvilleHousing..NashvilleHousingDB
SET AddressOfProperty = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousing..NashvilleHousingDB
ADD CityOfProperty NVARCHAR(255)

UPDATE NashvilleHousing..NashvilleHousingDB
SET CityOfProperty = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))


-- Owner Address
SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM 
	NashvilleHousing..NashvilleHousingDB

ALTER TABLE NashvilleHousing..NashvilleHousingDB
ADD AddressOfOwner NVARCHAR(255)

UPDATE NashvilleHousing..NashvilleHousingDB
SET AddressOfOwner = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing..NashvilleHousingDB
ADD CityOfOwner NVARCHAR(255)

UPDATE NashvilleHousing..NashvilleHousingDB
SET CityOfOwner = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing..NashvilleHousingDB
ADD StateOfOwner NVARCHAR(255)

UPDATE NashvilleHousing..NashvilleHousingDB
SET StateOfOwner = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


/**  Update SoldAsVacant column where N = No and Y = Yes*/
SELECT DISTINCT 
	SoldAsVacant,
	COUNT(SoldASVacant) AS NoOfDistinctResponse
FROM NashvilleHousing..NashvilleHousingDB
GROUP BY
	SoldAsVacant
ORDER BY 
	SoldAsVacant DESC

-- Updating using case statement
SELECT
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END AS SoldAsVacantUpdated
FROM NashvilleHousing..NashvilleHousingDB

UPDATE NashvilleHousing..NashvilleHousingDB
SET SoldAsVacant = CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END

SELECT DISTINCT SoldAsVacant -- Checks if reflect in db
FROM NashvilleHousing..NashvilleHousingDB



/** Remove duplicate values*/
WITH NoOfDuplicateRowsCTE 
AS (
	SELECT *,
		ROW_NUMBER() OVER(
			PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				OwnerName,
				OwnerAddress
			ORDER BY UniqueID
			) AS NoOfDuplicateRows
	FROM NashvilleHousing..NashvilleHousingDB
)
DELETE FROM NoOfDuplicateRowsCTE
WHERE NoOfDuplicateRows > 1



/** Remove unused columns*/
ALTER TABLE NashvilleHousing..NashvilleHousingDB
DROP COLUMN PropertyAddress, 
	OwnerAddress,
	TaxDistrict

SELECT * FROM NashvilleHousing..NashvilleHousingDB
