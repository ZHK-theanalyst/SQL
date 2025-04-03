SELECT * 
FROM layoffs;

-- Create a duplicate table with the same structure as layoffs
CREATE TABLE layoffs_duplicate
LIKE layoffs;

-- Copy all data from layoffs into layoffs_duplicate
INSERT layoffs_duplicate
SELECT *
FROM layoffs;

-- Add a row number to identify duplicate records
SELECT * ,
ROW_NUMBER() OVER(PARTITION BY company,location,industry,total_laid_off, 
percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_num
FROM layoffs_duplicate;

-- Using Common Table Expression (CTE) to find duplicates
WITH CTE_duplicate AS
(
SELECT * ,
ROW_NUMBER() OVER(PARTITION BY company,location,industry,total_laid_off, 
percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_num
FROM layoffs_duplicate
)
SELECT *
FROM CTE_duplicate
WHERE row_num >1;

-- Create a new table to store de-duplicated data
CREATE TABLE `layoffs_duplicate1` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_duplicate1;

-- Insert records with row numbers into layoffs_duplicate1
INSERT INTO layoffs_duplicate1
SELECT * ,
ROW_NUMBER() OVER(PARTITION BY company,location,industry,total_laid_off, 
percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_num
FROM layoffs_duplicate;

-- Select only duplicate records in layoffs_duplicate1
SELECT *
FROM layoffs_duplicate1
WHERE row_num > 1;

-- Delete duplicate records
DELETE
FROM layoffs_duplicate1
WHERE row_num > 1;

SELECT *
FROM layoffs_duplicate1;

-- Trim whitespace from company names and update the table
SELECT company, TRIM(company)
FROM layoffs_duplicate1;

UPDATE layoffs_duplicate1
SET company = TRIM(company);

-- Select distinct industry values for data consistency checks
SELECT DISTINCT industry
FROM layoffs_duplicate1
ORDER BY 1;

-- Standardize industry names where values start with 'Crypto'
UPDATE layoffs_duplicate1
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry
FROM layoffs_duplicate1;

-- Check for incorrect country names
SELECT *
FROM layoffs_duplicate1
WHERE country ='United States.';

-- Correct the country name
UPDATE layoffs_duplicate1
SET country = 'United States'
WHERE country = 'United States.';

SELECT *
FROM layoffs_duplicate1
WHERE country ='United States.';

SELECT DISTINCT country
FROM layoffs_duplicate1;

-- Convert string date format to SQL date format
SELECT `date`,
STR_TO_DATE (`date`, '%m/%d/%Y')
FROM layoffs_duplicate1;

UPDATE layoffs_duplicate1
SET `date` = STR_TO_DATE (`date`, '%m/%d/%Y');

SELECT *
FROM layoffs_duplicate1;

-- Change date column type to DATE
ALTER TABLE layoffs_duplicate1
MODIFY COLUMN `date` DATE;

SELECT * 
FROM layoffs_duplicate1;

-- Remove empty industry values by setting them to NULL
UPDATE layoffs_duplicate1
SET industry = null
WHERE industry = '';

-- To populate missing values. Fill missing industry values using company and location matches
SELECT t1.industry, t2.industry
FROM layoffs_duplicate1 AS t1
JOIN layoffs_duplicate1 AS t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


UPDATE layoffs_duplicate1 t1
JOIN layoffs_duplicate1 AS t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Identify records where both total_laid_off and percentage_laid_off are NULL
SELECT *
FROM layoffs_duplicate1
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

-- Delete records with NULL values in both columns
DELETE
FROM layoffs_duplicate1
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

-- Drop the row_num column as it is no longer needed
ALTER TABLE layoffs_duplicate1
DROP COLUMN row_num;

SELECT *
FROM layoffs_duplicate1;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_duplicate1;

SELECT *
FROM layoffs_duplicate1
WHERE percentage_laid_off = 1;

-- Summarize total layoffs by industry where percentage_laid_off is 1
SELECT industry, SUM(total_laid_off) AS t_laid_off
FROM layoffs_duplicate1
WHERE percentage_laid_off = 1
GROUP BY industry
ORDER BY t_laid_off DESC;

SELECT *
FROM layoffs_duplicate1
ORDER BY total_laid_off DESC;

SELECT company, SUM(total_laid_off)
FROM layoffs_duplicate1
GROUP BY company
ORDER BY 2 DESC;

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_duplicate1;

SELECT country, SUM(total_laid_off)
FROM layoffs_duplicate1
GROUP BY country
ORDER BY 2 DESC;

SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_duplicate1
GROUP BY YEAR(`date`)
ORDER BY 2 DESC;

SELECT *, 
SUBSTRING(`date`, 6,2) AS `Month`
FROM layoffs_duplicate1;

SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_duplicate1
GROUP BY company, YEAR(`date`)
ORDER BY SUM(total_laid_off) DESC;

-- Create a ranking system for layoffs per company per year
WITH Company_year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off),
RANK () OVER(PARTITION BY YEAR(`date`))
FROM layoffs_duplicate1
GROUP BY company, YEAR(`date`)
ORDER BY SUM(total_laid_off) DESC
)
SELECT *
FROM Company_year;

select *
from layoffs_duplicate1;


