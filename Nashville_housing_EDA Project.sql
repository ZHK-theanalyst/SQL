SELECT * 
FROM nashville_housing_data;

-- Creating a new table with the same structure as nashville_housing_data
CREATE TABLE `nashville_housing_data1` (
  `unnamed` int DEFAULT NULL,
  `parcel_id` text,
  `land_use` text,
  `property_address` text,
  `num_suite_condo` text,
  `property_city` text,
  `sale_date` text,
  `sale_price` int DEFAULT NULL,
  `legal_reference` text,
  `sold_as_vacant` text,
  `multiple_parcels_involved_in_sale` text,
  `owner_name` text,
  `address` text,
  `city` text,
  `state` text,
  `acreage` text,
  `tax_district` text,
  `neighborhood` text,
  `land_value` text,
  `building_value` text,
  `total_value` text,
  `finished_area` text,
  `foundation_type` text,
  `year_built` text,
  `exterior_wall` text,
  `grade` text,
  `bedrooms` text,
  `full_bath` text,
  `half_bath` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM nashville_housing_data1;

-- Copying data from the original dataset into the new table
INSERT INTO nashville_housing_data1
SELECT *
FROM nashville_housing_data;

-- Converting sale_date column to date format
UPDATE nashville_housing_data1
SET sale_date = STR_TO_DATE(sale_date, '%d/%m/%Y');

SELECT sale_date, STR_TO_DATE(sale_date, '%d/%m/%Y') AS converted_table
FROM nashville_housing_data1;

-- Modifying column type of sale_date to DATE
ALTER TABLE nashville_housing_data1
MODIFY COLUMN sale_date DATE;

SELECT *
FROM nashville_housing_data;

-- Renaming the 'unnamed' column to 'serial_num'
ALTER TABLE nashville_housing_data1
RENAME COLUMN unnamed TO serial_num;

-- Checking for null property addresses linked to parcel_ids
SELECT a.parcel_id, a.property_address, b.parcel_id, b.property_address
FROM nashville_housing_data1 AS a
JOIN nashville_housing_data1 AS b
	ON a.parcel_id = b.parcel_id
WHERE a.property_address IS NULL;

SELECT parcel_id, property_address
FROM nashville_housing_data1
WHERE property_address IS NULL;

-- Replacing empty strings in property_address column with NULL values
UPDATE nashville_housing_data1
SET property_address = null
WHERE property_address = '';

-- Filling in missing property addresses using available data
SELECT a.parcel_id, a.property_address, b.parcel_id, b.property_address
FROM nashville_housing_data1 AS a
JOIN nashville_housing_data1 AS b
	ON a.parcel_id = b.parcel_id
WHERE a.property_address IS NULL
AND b.property_address IS NOT NULL;

UPDATE nashville_housing_data1 AS a
JOIN nashville_housing_data1 AS b
	ON a.parcel_id = b.parcel_id
SET a.property_address = b.property_address
WHERE a.property_address IS NULL
AND b.property_address IS NOT NULL;

SELECT *
FROM nashville_housing_data1
WHERE property_address IS NULL;

SELECT property_address
FROM nashville_housing_data1;

SELECT DISTINCT(sold_as_vacant), Count(sold_as_vacant)
From nashville_housing_data1
GROUP BY sold_as_vacant;

-- Standardizing values in 'sold_as_vacant' column
Select sold_as_vacant,
	CASE When sold_as_vacant = 'Y' Then 'Yes'
		 When sold_as_vacant = 'N' Then 'No'
		 Else sold_as_vacant
		 End
From nashville_housing_data1;

Update nashville_housing_data1
Set sold_as_vacant = CASE When sold_as_vacant = 'Y' Then 'Yes'
						When sold_as_vacant = 'N' Then 'No'
						Else sold_as_vacant
						End;
                        
Select *
from nashville_housing_data1;

-- Identifying duplicate records using ROW_NUMBER()
With row_num_cte AS(
Select *,
Row_number() Over (
			partition by parcel_id,
						property_address,
                        sale_date,
                        sale_price,
                        legal_reference
                        Order by serial_num) AS row_num
	From nashville_housing_data1)
    Select *
    From row_num_cte
    where row_num > 1;

-- Creating a new cleaned table with the same structure
CREATE TABLE `nashville_housing_data2` (
  `serial_num` int DEFAULT NULL,
  `parcel_id` text,
  `land_use` text,
  `property_address` text,
  `num_suite_condo` text,
  `property_city` text,
  `sale_date` date DEFAULT NULL,
  `sale_price` int DEFAULT NULL,
  `legal_reference` text,
  `sold_as_vacant` text,
  `multiple_parcels_involved_in_sale` text,
  `owner_name` text,
  `address` text,
  `city` text,
  `state` text,
  `acreage` text,
  `tax_district` text,
  `neighborhood` text,
  `land_value` text,
  `building_value` text,
  `total_value` text,
  `finished_area` text,
  `foundation_type` text,
  `year_built` text,
  `exterior_wall` text,
  `grade` text,
  `bedrooms` text,
  `full_bath` text,
  `half_bath` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

Select * 
from nashville_housing_data2;

-- Adding serial_num using ROW_NUMBER() to identify duplicates
INSERT INTO nashville_housing_data2 (
    parcel_id, land_use, property_address, num_suite_condo, property_city, 
    sale_date, sale_price, legal_reference, sold_as_vacant, 
    multiple_parcels_involved_in_sale, owner_name, address, city, state, 
    acreage, tax_district, neighborhood, land_value, building_value, 
    total_value, finished_area, foundation_type, year_built, 
    exterior_wall, grade, bedrooms, full_bath, half_bath, serial_num
)
SELECT 
    parcel_id, land_use, property_address, num_suite_condo, property_city, 
    sale_date, sale_price, legal_reference, sold_as_vacant, 
    multiple_parcels_involved_in_sale, owner_name, address, city, state, 
    acreage, tax_district, neighborhood, land_value, building_value, 
    total_value, finished_area, foundation_type, year_built, 
    exterior_wall, grade, bedrooms, full_bath, half_bath,
    ROW_NUMBER() OVER (
        PARTITION BY parcel_id, property_address, sale_date, sale_price, legal_reference
    ) AS serial_num
FROM nashville_housing_data1;

-- Removing duplicate records
DELETE
FROM nashville_housing_data2
WHERE serial_num > 1;

SELECT *
FROM nashville_housing_data2;

-- Dropping the serial_num column as it's no longer needed
ALTER TABLE nashville_housing_data2
DROP COLUMN serial_num;



                

